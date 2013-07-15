package a3d.io.loaders.parsers;

import flash.display.BitmapData;
import flash.errors.Error;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.net.URLRequest;
import flash.Vector;
import haxe.xml.Fast;

import a3d.animators.SkeletonAnimationSet;
import a3d.animators.data.JointPose;
import a3d.animators.data.Skeleton;
import a3d.animators.data.SkeletonJoint;
import a3d.animators.data.SkeletonPose;
import a3d.animators.nodes.AnimationNodeBase;
import a3d.animators.nodes.SkeletonClipNode;
import a3d.core.base.CompactSubGeometry;
import a3d.core.base.Geometry;
import a3d.core.base.SkinnedSubGeometry;
import a3d.utils.Debug;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.io.loaders.misc.ResourceDependency;
import a3d.materials.ColorMaterial;
import a3d.materials.ColorMultiPassMaterial;
import a3d.materials.MaterialBase;
import a3d.materials.MultiPassMaterialBase;
import a3d.materials.SinglePassMaterialBase;
import a3d.materials.TextureMaterial;
import a3d.materials.TextureMultiPassMaterial;
import a3d.materials.methods.BasicAmbientMethod;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.utils.DefaultMaterialManager;
import a3d.textures.BitmapTexture;
import a3d.textures.Texture2DBase;

using Reflect;

/**
 * DAEParser provides a parser for the DAE data type.
 */
class DAEParser extends ParserBase
{
	public static inline var CONFIG_USE_GPU:Int = 1;
	public static inline var CONFIG_DEFAULT:Int = CONFIG_USE_GPU;
	public static inline var PARSE_GEOMETRIES:Int = 1;
	public static inline var PARSE_IMAGES:Int = 2;
	public static inline var PARSE_MATERIALS:Int = 4;
	public static inline var PARSE_VISUAL_SCENES:Int = 8;
	public static var PARSE_DEFAULT:Int = PARSE_GEOMETRIES | PARSE_IMAGES | PARSE_MATERIALS | PARSE_VISUAL_SCENES;

	private static var _numInstances:Int = 0;

	
	private var _doc:Xml;
	private var _ns:Namespace;
	private var _parseState:Int = 0;
	private var _imageList:XMLList;
	private var _imageCount:Int;
	private var _currentImage:Int;
	private var _dependencyCount:Int = 0;
	private var _configFlags:Int;
	private var _parseFlags:Int;
	private var _libImages:StringMap<DAEImage>;
	private var _libMaterials:StringMap<DAEMaterial>;
	private var _libEffects:StringMap<DAEEffect>;
	private var _libGeometries:StringMap<DAEGeometry>;
	private var _libControllers:StringMap<DAEController>;
	private var _libAnimations:StringMap<DAEAnimation>;
	private var _scene:DAEScene;
	private var _root:DAEVisualScene;
	//private var _rootContainer : ObjectContainer3D;
	private var _geometries:Vector<Geometry>;
	private var _animationInfo:DAEAnimationInfo;
	//private var _animators : Vector.<IAnimator>;
	private var _rootNodes:Vector<AnimationNodeBase>;
	private var _defaultBitmapMaterial:MaterialBase;
	private var _defaultColorMaterial:ColorMaterial;
	private var _defaultColorMaterialMulti:ColorMultiPassMaterial;
	
	/**
	 * @param    configFlags    Bitfield to configure the parser. @see DAEParser.CONFIG_USE_GPU etc.
	 */
	public function new(configFlags:Int = 0)
	{
		_configFlags = configFlags > 0 ? configFlags : CONFIG_DEFAULT;
		_parseFlags = PARSE_DEFAULT;

		_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
		_defaultColorMaterial = new ColorMaterial(0xff0000);
		_defaultColorMaterialMulti = new ColorMultiPassMaterial(0xff0000);
	
		super(ParserDataFormat.PLAIN_TEXT);
	}

	public function getGeometryByName(name:String, clone:Bool = false):Geometry
	{
		if (_geometries == null)
			return null;

		var geometry:Geometry;
		for (geometry in _geometries)
		{
			if (geometry.name == name)
				return (clone ? geometry.clone() : geometry);
		}

		return null;
	}

	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "dae";
	}

	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		if (Std.instance(data, String).indexOf("COLLADA") != -1 || 
			Std.instance(data,String).indexOf("collada") != -1)
			return true;

		return false;
	}

	override public function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (resourceDependency.assets.length != 1)
			return;
			
		var resource:Texture2DBase = Std.instance(resourceDependency.assets[0],Texture2DBase);
		_dependencyCount--;

		if (resource && Std.instance(resource,BitmapTexture).bitmapData)
		{
			var image:DAEImage = Std.instance(_libImages[resourceDependency.id],DAEImage);

			if (image)
				image.resource = Std.instance(resource,BitmapTexture);
		}

		if (_dependencyCount == 0)
			_parseState = DAEParserState.PARSE_MATERIALS;
	}

	override public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		_dependencyCount--;

		if (_dependencyCount == 0)
			_parseState = DAEParserState.PARSE_MATERIALS;
	}

	override private function proceedParsing():Bool
	{
		if (_defaultBitmapMaterial == null)
			_defaultBitmapMaterial = buildDefaultMaterial();

		switch (_parseState)
		{
			case DAEParserState.LOAD_XML:
				try
				{
					_doc = new XML(getTextData());
					_ns = _doc.namespace();
					_imageList = _doc._ns::library_images._ns::image;
					_imageCount = _dependencyCount = _imageList.length();
					_currentImage = 0;
					_parseState = _imageCount > 0 ? DAEParserState.PARSE_IMAGES : DAEParserState.PARSE_MATERIALS;

				}
				catch (e:Error)
				{
					return ParserBase.PARSING_DONE;
				}
				
			case DAEParserState.PARSE_IMAGES:
				_libImages = parseLibrary(_doc._ns::library_images._ns::image, DAEImage);
				for (var imageId:String in _libImages)
				{
					var image:DAEImage = Std.instance(_libImages[imageId],DAEImage);
					addDependency(image.id, new URLRequest(image.init_from));
				}
				pauseAndRetrieveDependencies();
				

			case DAEParserState.PARSE_MATERIALS:
				_libMaterials = parseLibrary(_doc._ns::library_materials._ns::material, DAEMaterial);
				_libEffects = parseLibrary(_doc._ns::library_effects._ns::effect, DAEEffect);
				setupMaterials();
				_parseState = DAEParserState.PARSE_GEOMETRIES;
				

			case DAEParserState.PARSE_GEOMETRIES:
				_libGeometries = parseLibrary(_doc._ns::library_geometries._ns::geometry, DAEGeometry);
				_geometries = translateGeometries();
				_parseState = DAEParserState.PARSE_CONTROLLERS;
				

			case DAEParserState.PARSE_CONTROLLERS:
				_libControllers = parseLibrary(_doc._ns::library_controllers._ns::controller, DAEController);
				_parseState = DAEParserState.PARSE_VISUAL_SCENE;
				

			case DAEParserState.PARSE_VISUAL_SCENE:
				_scene = null;
				_root = null;
				_libAnimations = parseLibrary(_doc._ns::library_animations._ns::animation, DAEAnimation);
				//_animators = new Vector.<IAnimator>();
				_rootNodes = new Vector<AnimationNodeBase>();

				if (_doc.._ns::scene && _doc.._ns::scene.length())
				{
					_scene = new DAEScene(_doc.._ns::scene[0]);

					var list:XMLList = _doc.._ns::visual_scene.(@id == _scene.instance_visual_scene.url);

					if (list.length())
					{
						//_rootContainer = new ObjectContainer3D();
						_root = new DAEVisualScene(this, list[0]);
						_root.updateTransforms(_root);
						_animationInfo = parseAnimationInfo();
						parseSceneGraph(_root);
					}
				}
				_parseState = isAnimated ? DAEParserState.PARSE_ANIMATIONS : DAEParserState.PARSE_COMPLETE;
				

			case DAEParserState.PARSE_ANIMATIONS:
				_parseState = DAEParserState.PARSE_COMPLETE;
				

			case DAEParserState.PARSE_COMPLETE:
				//finalizeAsset(_rootContainer, "COLLADA_ROOT_" + (_numInstances++));
				return ParserBase.PARSING_DONE;
		}

		return ParserBase.MORE_TO_PARSE;
	}


	private function buildDefaultMaterial(map:BitmapData = null):MaterialBase
	{
		//TODO:fix this duplication mess
		if (map != null)
		{
			if (materialMode < 2)
				_defaultBitmapMaterial = new TextureMaterial(new BitmapTexture(map));
			else
				_defaultBitmapMaterial = new TextureMultiPassMaterial(new BitmapTexture(map));
		}
		else if (materialMode < 2)
			_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
		else
			_defaultBitmapMaterial = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());

		return _defaultBitmapMaterial;
	}

	private function applySkinBindShape(geometry:Geometry, skin:DAESkin):Void
	{
		var vec:Vector3D = new Vector3D();
		var i:Int;
		var sub:CompactSubGeometry;
		for (sub in geometry.subGeometries)
		{
			var vertexData:Vector<Float> = sub.vertexData;

			i = sub.vertexOffset;
			while ( i < vertexData.length)
			{
				vec.x = vertexData[i + 0];
				vec.y = vertexData[i + 1];
				vec.z = vertexData[i + 2];
				vec = skin.bind_shape_matrix.transformVector(vec);
				vertexData[i + 0] = vec.x;
				vertexData[i + 1] = vec.y;
				vertexData[i + 2] = vec.z;
				
				 i += sub.vertexStride;
			}
			sub.updateData(vertexData);
		}
	}

	private function applySkinController(geometry:Geometry, mesh:DAEMesh, skin:DAESkin, skeleton:Skeleton):Void
	{
		var sub:CompactSubGeometry;
		var skinned_sub_geom:SkinnedSubGeometry;
		var primitive:DAEPrimitive;
		var jointIndices:Vector<Float>;
		var jointWeights:Vector<Float>;
		var i:Int, j:Int, k:Int, l:Int;

		for (i in 0...geometry.subGeometries.length)
		{
			sub = CompactSubGeometry(geometry.subGeometries[i]);
			primitive = mesh.primitives[i];
			jointIndices = new Vector<Float>(skin.maxBones * primitive.vertices.length, true);
			jointWeights = new Vector<Float>(skin.maxBones * primitive.vertices.length, true);
			l = 0;

			for (j in 0...primitive.vertices.length)
			{
				var weights:Vector<DAEVertexWeight> = skin.weights[primitive.vertices[j].daeIndex];

				for (k in 0...weights.length)
				{
					var influence:DAEVertexWeight = weights[k];
					// indices need to be multiplied by 3 (amount of matrix registers)
					jointIndices[l] = influence.joint * 3;
					jointWeights[l++] = influence.weight;
				}

				for (k in weights.length...skin.maxBones)
				{
					jointIndices[l] = 0;
					jointWeights[l++] = 0;
				}
			}

			skinned_sub_geom = new SkinnedSubGeometry(skin.maxBones);
			skinned_sub_geom.updateData(sub.vertexData.concat());
			skinned_sub_geom.updateIndexData(sub.indexData);
			skinned_sub_geom.updateJointIndexData(jointIndices);
			skinned_sub_geom.updateJointWeightsData(jointWeights);
			geometry.subGeometries[i] = skinned_sub_geom;
			geometry.subGeometries[i].parentGeometry = geometry;
		}
	}

	private function parseAnimationInfo():DAEAnimationInfo
	{
		var info:DAEAnimationInfo = new DAEAnimationInfo();
		info.minTime = Number.MAX_VALUE;
		info.maxTime = -info.minTime;
		info.numFrames = 0;

		var animation:DAEAnimation;
		for (animation in _libAnimations)
		{
			var channel:DAEChannel;
			for (channel in animation.channels)
			{
				var node:DAENode = _root.findNodeById(channel.targetId);
				if (node != null)
				{
					node.channels.push(channel);
					info.minTime = Math.min(info.minTime, channel.sampler.minTime);
					info.maxTime = Math.max(info.maxTime, channel.sampler.maxTime);
					info.numFrames = Math.max(info.numFrames, channel.sampler.input.length);
				}
			}
		}

		return info;
	}

	private function parseLibrary<T>(list:XMLList, clas:Class<T>):StringMap<T>
	{
		var library:StringMap<T> = new StringMap<T>();
		for (i in 0...list.length)
		{
			var obj:T = Type.createInstance(clas, [list[i]]);
			library.set(obj.id, obj);
		}

		return library;
	}

	private function parseSceneGraph(node:DAENode, parent:ObjectContainer3D = null, tab:String = ""):Void
	{
		var _tab:String = tab + "-";

		Debug.trace(_tab + node.name);

		if (node.type != "JOINT")
		{
			Debug.trace(_tab + "ObjectContainer3D : " + node.name);

			var container:ObjectContainer3D;

			if (node.instance_geometries.length > 0)
				container = processGeometries(node, parent);
			else if (node.instance_controllers.length > 0)
				container = processControllers(node, parent);
			else
			{
				// trace("Should be a container " + node.id)
				container = new ObjectContainer3D();
				container.name = node.id;
				container.transform.rawData = node.matrix.rawData;
				finalizeAsset(container, node.id);

				if (parent)
					parent.addChild(container);
			}

			parent = container;
		}
		for (i in 0...node.nodes.length)
			parseSceneGraph(node.nodes[i], parent, _tab);
	}

	private function processController(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		var geometry:Geometry;
		if (controller == null)
			return null;

		if (controller.morph != null)
		{
			geometry = processControllerMorph(controller, instance);
		}
		else if (controller.skin != null)
		{
			geometry = processControllerSkin(controller, instance);
		}

		return geometry;
	}

	private function processControllerMorph(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		Debug.trace(" * processControllerMorph : " + controller);

		var morph:DAEMorph = controller.morph;

		var base:Geometry = processController(_libControllers[morph.source], instance);
		if (base == null)
			return null;

		var targets:Vector<Geometry> = new Vector<Geometry>();
		base = getGeometryByName(morph.source);
		var vertexData:Vector<Float>;
		var sub:CompactSubGeometry;
		var startWeight:Float = 1.0;
		var j:Int, k:Int;
		var geometry:Geometry;

		for (i in 0...morph.targets.length)
		{
			geometry = getGeometryByName(morph.targets[i]);
			if (geometry == null)
				return null;

			targets.push(geometry);
			startWeight -= morph.weights[i];
		}

		for (i in 0...base.subGeometries.length)
		{
			sub = CompactSubGeometry(base.subGeometries[i]);
			vertexData = sub.vertexData.concat();
			for (v in 0...Std.int(vertexData.length / 13))
			{
				j = sub.vertexOffset + v * sub.vertexStride;
				vertexData[j] = morph.method == "NORMALIZED" ? startWeight * sub.vertexData[j] : sub.vertexData[j];
				for (k in 0...morph.targets.length)
				{
					vertexData[j] += morph.weights[k] * targets[k].subGeometries[i].vertexData[j];
				}
			}
			sub.updateData(vertexData);
		}

		return base;
	}

	private function processControllerSkin(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		Debug.trace(" * processControllerSkin : " + controller);

		var geometry:Geometry = getGeometryByName(controller.skin.source);

		if (geometry == null)
			geometry = processController(_libControllers[controller.skin.source], instance);

		if (geometry == null)
			return null;

		var skeleton:Skeleton = parseSkeleton(instance);
		var daeGeometry:DAEGeometry = _libGeometries[geometry.name];
		applySkinBindShape(geometry, controller.skin);
		applySkinController(geometry, daeGeometry.mesh, controller.skin, skeleton);
		controller.skin.userData = skeleton;

		finalizeAsset(skeleton);

		return geometry;
	}

	private function processControllers(node:DAENode, container:ObjectContainer3D):Mesh
	{
		Debug.trace(" * processControllers : " + node.name);

		var instance:DAEInstanceController;
		var daeGeometry:DAEGeometry;
		var controller:DAEController;
		var effects:Vector<DAEEffect>;
		var geometry:Geometry;
		var mesh:Mesh;
		var skeleton:Skeleton;
		var clip:SkeletonClipNode;
		//var anim:SkeletonAnimation;
		var animationSet:SkeletonAnimationSet;
		var i:Int, j:Int;
		var hasMaterial:Bool;
		var weights:UInt;
		var jpv:UInt;

		for (i in 0...node.instance_controllers.length)
		{
			instance = node.instance_controllers[i];
			controller = Std.instance(_libControllers[instance.url],DAEController);

			geometry = processController(controller, instance);
			if (geometry == null)
				continue;

			daeGeometry = Std.instance(_libGeometries[geometry.name],DAEGeometry);
			effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);

			mesh = new Mesh(geometry, null);
			hasMaterial = false;

			if (node.name != "")
				mesh.name = node.name;

			if (effects.length > 0)
			{
				for (j in 0...mesh.subMeshes.length)
				{
					if (effects[j].material != null)
					{
						mesh.subMeshes[j].material = effects[j].material;
						hasMaterial = true;
					}
				}
			}

			if (!hasMaterial)
				mesh.material = _defaultBitmapMaterial;

			if (container != null)
				container.addChild(mesh);

			if (controller.skin != null && Std.is(controller.skin.userData,Skeleton))
			{
				if (animationSet == null)
					animationSet = new SkeletonAnimationSet(controller.skin.maxBones);

				skeleton = Std.instance(controller.skin.userData,Skeleton);

				clip = processSkinAnimation(controller.skin, mesh, skeleton);
				clip.looping = true;

				weights = SkinnedSubGeometry(mesh.geometry.subGeometries[0]).jointIndexData.length;
				jpv = weights / (mesh.geometry.subGeometries[0].vertexData.length / 3);
				//anim = new SkeletonAnimation(skeleton, jpv);

				//var state:SkeletonAnimationState = SkeletonAnimationState(mesh.animationState);
				//animator = new SmoothSkeletonAnimator(state);
				//SmoothSkeletonAnimator(animator).addSequence(SkeletonAnimationSequence(sequence));
				clip.name = "node_" + _rootNodes.length;
				animationSet.addAnimation(clip);

				//_animators.push(animator);
				_rootNodes.push(clip);
			}

			finalizeAsset(mesh);
		}

		if (animationSet != null)
			finalizeAsset(animationSet);

		return mesh;
	}

	private function processSkinAnimation(skin:DAESkin, mesh:Mesh, skeleton:Skeleton):SkeletonClipNode
	{
		Debug.trace(" * processSkinAnimation : " + mesh.name);

		//var useGPU : Bool = _configFlags & CONFIG_USE_GPU ? true : false;
		//var animation : SkeletonAnimation = new SkeletonAnimation(skeleton, skin.maxBones, useGPU);
		var animated:Bool = isAnimatedSkeleton(skeleton);
		var duration:Float = _animationInfo.numFrames == 0 ? 1.0 : _animationInfo.maxTime - _animationInfo.minTime;
		var numFrames:Int = Math.max(_animationInfo.numFrames, (animated ? 50 : 2));
		var frameDuration:Float = duration / numFrames;

		var t:Float = 0;
		var i:Int, j:Int;
		var clip:SkeletonClipNode = new SkeletonClipNode();
		//mesh.geometry.animation = animation;
		var skeletonPose:SkeletonPose;
		var identity:Matrix3D;
		var matrix:Matrix3D;
		var node:DAENode;
		var pose:JointPose;

		for (i in 0...numFrames)
		{
			skeletonPose = new SkeletonPose();

			for (j in 0...skin.joints.length)
			{
				node = _root.findNodeById(skin.joints[j]) || _root.findNodeBySid(skin.joints[j]);
				pose = new JointPose();
				matrix = node.getAnimatedMatrix(t) || node.matrix;
				pose.name = skin.joints[j];
				pose.orientation.fromMatrix(matrix);
				pose.translation.copyFrom(matrix.position);

				if (Math.isNaN(pose.orientation.x))
				{
					if (!identity)
						identity = new Matrix3D();
					pose.orientation.fromMatrix(identity);
				}

				skeletonPose.jointPoses.push(pose);
			}

			t += frameDuration;
			clip.addFrame(skeletonPose, frameDuration * 1000);
		}

		finalizeAsset(clip);

		return clip;
	}

	private function isAnimatedSkeleton(skeleton:Skeleton):Bool
	{
		var node:DAENode;

		for (i in 0...skeleton.joints.length)
		{
			try
			{
				node = _root.findNodeById(skeleton.joints[i].name);
				if (node == null)
					node = _root.findNodeBySid(skeleton.joints[i].name);
			}
			catch (e:Error)
			{
				trace("Errors found in skeleton joints data");
				return false;
			}
			if (node != null && node.channels.length != 0)
				return true;
		}

		return false;
	}

	private function processGeometries(node:DAENode, container:ObjectContainer3D):Mesh
	{
		Debug.trace(" * processGeometries : " + node.name);
		var instance:DAEInstanceGeometry;
		var daeGeometry:DAEGeometry;
		var effects:Vector<DAEEffect>;
		var mesh:Mesh;
		var geometry:Geometry;
		var i:Int, j:Int;

		for (i in 0...node.instance_geometries.length)
		{
			instance = node.instance_geometries[i];
			daeGeometry = Std.instance(_libGeometries[instance.url],DAEGeometry);

			if (daeGeometry != null && daeGeometry.mesh != null)
			{
				geometry = getGeometryByName(instance.url);
				effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);

				if (geometry != null)
				{
					mesh = new Mesh(geometry);

					if (node.name != "")
						mesh.name = node.name;

					if (effects.length == geometry.subGeometries.length)
					{
						for (j in 0...mesh.subMeshes.length)
						{
							mesh.subMeshes[j].material = effects[j].material;
						}
					}
					mesh.transform = node.matrix;

					if (container != null)
						container.addChild(mesh);

					finalizeAsset(mesh);
				}
			}
		}

		return mesh;
	}

	private function getMeshEffects(bindMaterial:DAEBindMaterial, mesh:DAEMesh):Vector<DAEEffect>
	{
		var effects:Vector<DAEEffect> = new Vector<DAEEffect>();
		if (bindMaterial == null)
			return effects;

		var material:DAEMaterial;
		var effect:DAEEffect;
		var instance:DAEInstanceMaterial;
		var i:Int, j:Int;

		for (i in 0...mesh.primitives.length)
		{
			if (bindMaterial.instance_material == null)
				continue;
				
			for (j in 0...bindMaterial.instance_material.length)
			{
				instance = bindMaterial.instance_material[j];
				if (mesh.primitives[i].material == instance.symbol)
				{
					material = Std.instance(_libMaterials[instance.target],DAEMaterial);
					effect = _libEffects[material.instance_effect.url];
					if (effect != null)
						effects.push(effect);
					break;
				}
			}
		}

		return effects;
	}

	private function parseSkeleton(instance_controller:DAEInstanceController):Skeleton
	{
		if (instance_controller.skeleton.length == 0)
			return null;

		Debug.trace(" * parseSkeleton : " + instance_controller);

		var controller:DAEController = Std.instance(_libControllers[instance_controller.url],DAEController);
		var skeletonId:String = instance_controller.skeleton[0];
		var skeletonRoot:DAENode = _root.findNodeById(skeletonId) || _root.findNodeBySid(skeletonId);

		if (skeletonRoot == null)
			return null;

		var skeleton:Skeleton = new Skeleton();
		skeleton.joints = new Vector<SkeletonJoint>(controller.skin.joints.length, true);
		parseSkeletonHierarchy(skeletonRoot, controller.skin, skeleton);

		return skeleton;
	}

	private function parseSkeletonHierarchy(node:DAENode, skin:DAESkin, skeleton:Skeleton, parent:Int = -1, tab:String = ""):Void
	{
		var _tab:String = tab + "-";

		Debug.trace(_tab + "[" + node.id + "," + node.sid + "]");

		var jointIndex:Int = skin.jointSourceType == "IDREF_array" ? skin.getJointIndex(node.id) : skin.getJointIndex(node.sid);

		if (jointIndex >= 0)
		{
			var joint:SkeletonJoint = new SkeletonJoint();
			joint.parentIndex = parent;

			if (!Math.isNaN(jointIndex) && jointIndex < skin.joints.length)
			{
				if (skin.joints[jointIndex])
					joint.name = skin.joints[jointIndex];
			}
			else
			{
				Debug.trace("Error: skin.joints index out of range");
				return;
			}

			var ibm:Matrix3D = skin.inv_bind_matrix[jointIndex];

			joint.inverseBindPose = ibm.rawData;

			skeleton.joints[jointIndex] = joint;
		}
		else
		{
			Debug.trace(_tab + "no jointIndex!");
		}

		for (i in 0...node.nodes.length)
		{
			try
			{
				parseSkeletonHierarchy(node.nodes[i], skin, skeleton, jointIndex);
			}
			catch (e:Error)
			{
				trace(e.message);
			}
		}
	}

	private function setupMaterial(material:DAEMaterial, effect:DAEEffect):MaterialBase
	{
		if (effect == null || material == null)
			return null;

		var mat:MaterialBase
		if (materialMode < 2)
			mat = _defaultColorMaterial;
		else
			mat = new ColorMultiPassMaterial(_defaultColorMaterial.color);

		var textureMaterial:TextureMaterial;
		var ambient:DAEColorOrTexture = effect.shader.props["ambient"];
		var diffuse:DAEColorOrTexture = effect.shader.props["diffuse"];
		var specular:DAEColorOrTexture = effect.shader.props["specular"];
		var shininess:Float = effect.shader.props.hasOwnProperty("shininess") ? Number(effect.shader.props["shininess"]) : 10;
		var transparency:Float = effect.shader.props.hasOwnProperty("transparency") ? Number(effect.shader.props["transparency"]) : 1;

		if (diffuse != null && diffuse.texture != null && effect.surface != null)
		{
			var image:DAEImage = _libImages.get(effect.surface.init_from);

			if (image.resource !== null && isBitmapDataValid(image.resource.bitmapData))
			{
				mat = buildDefaultMaterial(image.resource.bitmapData);
				if (materialMode < 2)
					TextureMaterial(mat).alpha = transparency;
			}
			else
			{
				mat = buildDefaultMaterial();
			}

		}

		else if (diffuse != null && diffuse.color != null)
		{
			if (materialMode < 2)
				mat = new ColorMaterial(diffuse.color.rgb, transparency);
			else
				mat = new ColorMultiPassMaterial(diffuse.color.rgb);
		}
		trace("mat = " + materialMode);
		if (mat != null)
		{
			if (materialMode < 2)
			{
				SinglePassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
				SinglePassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
				SinglePassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
				SinglePassMaterialBase(mat).ambientColor = (ambient && ambient.color) ? ambient.color.rgb : 0x303030;
				SinglePassMaterialBase(mat).specularColor = (specular && specular.color) ? specular.color.rgb : 0x202020;
				SinglePassMaterialBase(mat).gloss = shininess;
				SinglePassMaterialBase(mat).ambient = 1;
				SinglePassMaterialBase(mat).specular = 1;
			}
			else
			{
				MultiPassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
				MultiPassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
				MultiPassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
				MultiPassMaterialBase(mat).ambientColor = (ambient && ambient.color) ? ambient.color.rgb : 0x303030;
				MultiPassMaterialBase(mat).specularColor = (specular && specular.color) ? specular.color.rgb : 0x202020;
				MultiPassMaterialBase(mat).gloss = shininess;
				MultiPassMaterialBase(mat).ambient = 1;
				MultiPassMaterialBase(mat).specular = 1;

			}
		}

		mat.name = material.id;
		finalizeAsset(mat);

		return mat;
	}

	private function setupMaterials():Void
	{
		var material:DAEMaterial;
		for (material in _libMaterials)
		{
			if (_libEffects.hasOwnProperty(material.instance_effect.url))
			{
				var effect:DAEEffect = Std.instance(_libEffects[material.instance_effect.url],DAEEffect);
				effect.material = setupMaterial(material, effect);
			}
		}
	}

	private function translateGeometries():Vector<Geometry>
	{
		var geometries:Vector<Geometry> = new Vector<Geometry>();
		var daeGeometry:DAEGeometry;
		var geometry:Geometry;

		for (var id:String in _libGeometries)
		{
			daeGeometry = Std.instance(_libGeometries[id],DAEGeometry);
			if (daeGeometry.mesh)
			{
				geometry = translateGeometry(daeGeometry.mesh);
				if (geometry.subGeometries.length != 0)
				{
					if (id && Math.isNaN(Number(id)))
						geometry.name = id;
					geometries.push(geometry);

					finalizeAsset(geometry);
				}
			}
		}

		return geometries;
	}

	private function translateGeometry(mesh:DAEMesh):Geometry
	{
		var geometry:Geometry = new Geometry();
		for (i in 0...mesh.primitives.length)
		{
			var sub:CompactSubGeometry = translatePrimitive(mesh, mesh.primitives[i]);
			if (sub != null)
				geometry.addSubGeometry(sub);
		}

		return geometry;
	}

	private function translatePrimitive(mesh:DAEMesh, primitive:DAEPrimitive, reverseTriangles:Bool = true, autoDeriveVertexNormals:Bool = true, autoDeriveVertexTangents:Bool = true):CompactSubGeometry
	{
		var sub:CompactSubGeometry = new CompactSubGeometry();
		var indexData:Vector<UInt> = new Vector<UInt>();
		var data:Vector<Float> = new Vector<Float>();
		var faces:Vector<DAEFace> = primitive.create(mesh);
		var v:DAEVertex, f:DAEFace;
		var i:Int, j:Int;

		// vertices, normals and uvs
		for (i in 0...primitive.vertices.length)
		{
			v = primitive.vertices[i];
			data.push(v.x, v.y, v.z);
			data.push(v.nx, v.ny, v.nz);
			data.push(0, 0, 0);

			if (v.numTexcoordSets > 0)
			{
				data.push(v.uvx, 1.0 - v.uvy);
				if (v.numTexcoordSets > 1)
					data.push(v.uvx2, 1.0 - v.uvy2);
				else
					data.push(v.uvx, 1.0 - v.uvy);
			}
			else
			{
				data.push(0, 0, 0, 0);
			}
		}

		// triangles
		for (i in 0...faces.length)
		{
			f = faces[i];
			for (j in 0...f.vertices.length)
			{
				v = f.vertices[j];
				indexData.push(v.index);
			}
		}

		if (reverseTriangles)
			indexData.reverse();

		sub.autoDeriveVertexNormals = autoDeriveVertexNormals;
		sub.autoDeriveVertexTangents = autoDeriveVertexTangents;
		sub.updateData(data);
		sub.updateIndexData(indexData);

		return sub;
	}

	public function get geometries():Vector<Geometry>
	{
		return _geometries;
	}

	public function get effects():Dynamic
	{
		return _libEffects;
	}

	public function get images():Dynamic
	{
		return _libImages;
	}

	public function get materials():Dynamic
	{
		return _libMaterials;
	}

	public function get isAnimated():Bool
	{
		return (_doc._ns::library_animations._ns::animation.length() > 0);
	}

}

class DAEAnimationInfo
{
	public var minTime:Float;
	public var maxTime:Float;
	public var numFrames:UInt;

	public function new()
	{
	}
}

class DAEElement
{
	public static var USE_LEFT_HANDED:Bool = true;
	public var id:String;
	public var name:String;
	public var sid:String;
	public var userData:Dynamic;
	private var ns:Namespace;

	public function new(element:XML = null)
	{
		if (element)
			deserialize(element);
	}

	public function deserialize(element:XML):Void
	{
		ns = element.namespace();
		id = element.@id.toString();
		name = element.@name.toString();
		sid = element.@sid.toString();
	}

	public function dispose():Void
	{
	}

	private function traverseChildHandler(child:XML, nodeName:String):Void
	{
	}

	private function traverseChildren(element:XML, name:String = null):Void
	{
		var children:XMLList = name ? element.ns::[name] : element.children();
		var count:Int = children.length();

		for (i in 0...count)
			traverseChildHandler(children[i], children[i].name().localName);
	}

	private function convertMatrix(matrix:Matrix3D):Void
	{
		var indices:Vector<Int> = Vector.ofArray([2, 6, 8, 9, 11, 14]);
		var raw:Vector<Float> = matrix.rawData;
		for (i in 0...indices.length)
			raw[indices[i]] *= -1.0;

		matrix.rawData = raw;
	}

	private function getRootElement(element:XML):XML
	{
		var tmp:XML = element;
		while (tmp.name().localName != "COLLADA")
			tmp = tmp.parent();

		return (tmp.name().localName == "COLLADA" ? tmp : null);
	}

	private function readFloatArray(element:XML):Vector<Float>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var floats:Vector<Float> = new Vector<Float>();

		for (i in 0...parts.length)
			floats.push(Std.parseFloat(parts[i]));

		return floats;
	}

	private function readIntArray(element:XML):Vector<Int>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var ints:Vector<Int> = new Vector<Int>();

		for (i in 0...parts.length)
			ints.push(Std.parseInt(parts[i], 10));

		return ints;
	}

	private function readStringArray(element:XML):Vector<String>
	{
		var raw:String = readText(element);
		var parts:Array = raw.split(/\s+/);
		var strings:Vector<String> = new Vector<String>();

		for (i in 0...parts.length)
			strings.push(parts[i]);

		return strings;
	}

	private function readIntAttr(element:XML, name:String, defaultValue:Int = 0):Int
	{
		var v:Int = Std.parseInt(element.@[name], 10);
		v = v == 0 ? defaultValue : v;
		return v;
	}

	private function readText(element:XML):String
	{
		return trimString(element.text().toString());
	}

	private function trimString(s:String):String
	{
		return s.replace(/^\s+/, "").replace(/\s+$/, "");
	}
}

class DAEImage extends DAEElement
{
	public var init_from:String;
	public var resource:*;

	public function new(element:XML = null):Void
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		init_from = readText(element.ns::init_from[0]);
		resource = null;
	}
}

class DAEParam extends DAEElement
{
	public var type:String;

	public function new(element:XML = null):Void
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
	}
}

class DAEAccessor extends DAEElement
{
	public var params:Vector<DAEParam>;
	public var source:String;
	public var stride:Int;
	public var count:Int;

	public function new(element:XML = null):Void
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.params = new Vector<DAEParam>();
		this.source = element.@source.toString().replace(/^#/, "");
		this.stride = readIntAttr(element, "stride", 1);
		this.count = readIntAttr(element, "count", 0);
		traverseChildren(element, "param");
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "param")
			this.params.push(new DAEParam(child));
	}
}

class DAESource extends DAEElement
{
	public var accessor:DAEAccessor;
	public var type:String;
	public var floats:Vector<Float>;
	public var ints:Vector<Int>;
	public var bools:Vector<Bool>;
	public var strings:Vector<String>;

	public function new(element:XML = null):Void
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "float_array":
				this.type = nodeName;
				this.floats = readFloatArray(child);
				
			case "int_array":
				this.type = nodeName;
				this.ints = readIntArray(child);
				
			case "bool_array":
				throw new Error("Cannot handle bool_array");
				
			case "Name_array":
			case "IDREF_array":
				this.type = nodeName;
				this.strings = readStringArray(child);
				
			case "technique_common":
				this.accessor = new DAEAccessor(child.ns::accessor[0]);
		}
	}
}

class DAEInput extends DAEElement
{
	public var semantic:String;
	public var source:String;
	public var offset:Int;
	public var set:Int;

	public function DAEInput(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);

		this.semantic = element.@semantic.toString();
		this.source = element.@source.toString().replace(/^#/, "");
		this.offset = readIntAttr(element, "offset");
		this.set = readIntAttr(element, "set");
	}
}

class DAEVertex
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var nx:Float;
	public var ny:Float;
	public var nz:Float;
	public var uvx:Float;
	public var uvy:Float;
	public var uvx2:Float;
	public var uvy2:Float;
	public var numTexcoordSets:UInt = 0;
	public var index:UInt = 0;
	public var daeIndex:UInt = 0;

	public function DAEVertex(numTexcoordSets:UInt)
	{
		this.numTexcoordSets = numTexcoordSets;
		x = y = z = nx = ny = nz = uvx = uvy = uvx2 = uvy2 = 0;
	}

	public function get hash():String
	{
		var s:String = format(x);
		s += "_" + format(y);
		s += "_" + format(z);
		s += "_" + format(nx);
		s += "_" + format(ny);
		s += "_" + format(nz);
		s += "_" + format(uvx);
		s += "_" + format(uvy);
		s += "_" + format(uvx2);
		s += "_" + format(uvy2);
		return s;
	}

	private function format(v:Float, numDecimals:Int = 2):String
	{
		return v.toFixed(numDecimals);
	}
}

class DAEFace
{
	public var vertices:Vector<DAEVertex>;

	public function DAEFace():Void
	{
		this.vertices = new Vector<DAEVertex>();
	}
}

class DAEPrimitive extends DAEElement
{
	public var type:String;
	public var material:String;
	public var count:Int;
	public var vertices:Vector<DAEVertex>;
	private var _inputs:Vector<DAEInput>;
	private var _p:Vector<Int>;
	private var _vcount:Vector<Int>;
	private var _texcoordSets:Vector<Int>;

	public function DAEPrimitive(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.material = element.@material.toString();
		this.count = readIntAttr(element, "count", 0);

		_inputs = new Vector<DAEInput>();
		_p = null;
		_vcount = null;

		var list:XMLList = element.ns::input;

		for (i in 0...list.length())
		{
			_inputs.push(new DAEInput(list[i]));
		}

		if (element.ns::p && element.ns::p.length())
			_p = readIntArray(element.ns::p[0]);

		if (element.ns::vcount && element.ns::vcount.length())
			_vcount = readIntArray(element.ns::vcount[0]);
	}

	public function create(mesh:DAEMesh):Vector<DAEFace>
	{
		if (!prepareInputs(mesh))
			return null;

		var faces:Vector<DAEFace> = new Vector<DAEFace>();
		var input:DAEInput;
		var source:DAESource;
		//var numInputs : uint = _inputs.length;  //shared inputs offsets VERTEX and TEXCOORD
		var numInputs:UInt;
		if (_inputs.length > 1)
		{
			var offsets:Array = [];
			for each (var daei:DAEInput in _inputs)
			{
				if (!offsets[daei.offset])
				{
					offsets[daei.offset] = true;
					numInputs++;
				}
			}
		}
		else
		{
			numInputs = _inputs.length;
		}

		var idx:UInt = 0, index:UInt;
		var i:UInt, j:UInt;
		var vertexDict:Dynamic = {};
		var idx32:UInt;
		this.vertices = new Vector<DAEVertex>();

		while (idx < _p.length)
		{
			var vcount:UInt = _vcount != null ? _vcount.shift() : 3;
			var face:DAEFace = new DAEFace();

			for (i in 0...vcount)
			{
				var t:UInt = i * numInputs;
				var vertex:DAEVertex = new DAEVertex(_texcoordSets.length);

				for (j in 0..._inputs.length)
				{
					input = _inputs[j];
					index = _p[idx + t + input.offset];
					source = Std.instance(mesh.sources[input.source],DAESource);
					idx32 = index * source.accessor.params.length;

					switch (input.semantic)
					{
						case "VERTEX":
							vertex.x = source.floats[idx32 + 0];
							vertex.y = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
							{
								vertex.z = -source.floats[idx32 + 2];
							}
							else
							{
								vertex.z = source.floats[idx32 + 2];
							}
							vertex.daeIndex = index;
						case "NORMAL":
							vertex.nx = source.floats[idx32 + 0];
							vertex.ny = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
							{
								vertex.nz = -source.floats[idx32 + 2];
							}
							else
							{
								vertex.nz = source.floats[idx32 + 2];
							}
						case "TEXCOORD":
							if (input.set == _texcoordSets[0])
							{
								vertex.uvx = source.floats[idx32 + 0];
								vertex.uvy = source.floats[idx32 + 1];
							}
							else
							{
								vertex.uvx2 = source.floats[idx32 + 0];
								vertex.uvy2 = source.floats[idx32 + 1];
							}
						default:
					}
				}
				var hash:String = vertex.hash;

				if (vertexDict[hash])
				{
					face.vertices.push(vertexDict[hash]);
				}
				else
				{
					vertex.index = this.vertices.length;
					vertexDict[hash] = vertex;
					face.vertices.push(vertex);
					this.vertices.push(vertex);
				}
			}

			if (face.vertices.length > 3)
			{
				// triangulate
				var v0:DAEVertex = face.vertices[0];
				for (k in 1...face.vertices.length - 1)
				{
					var f:DAEFace = new DAEFace();
					f.vertices.push(v0);
					f.vertices.push(face.vertices[k]);
					f.vertices.push(face.vertices[k + 1]);
					faces.push(f);
				}

			}
			else if (face.vertices.length == 3)
			{
				faces.push(face);
			}
			idx += (vcount * numInputs);
		}
		return faces;
	}

	private function prepareInputs(mesh:DAEMesh):Bool
	{
		var input:DAEInput;
		var i:UInt, j:UInt;
		var result:Bool = true;
		_texcoordSets = new Vector<Int>();

		for (i in 0..._inputs.length)
		{
			input = _inputs[i];

			if (input.semantic == "TEXCOORD")
				_texcoordSets.push(input.set);

			if (!mesh.sources.exists(input.source))
			{
				result = false;
				if (input.source == mesh.vertices.id)
				{
					for (j in 0...mesh.vertices.inputs.length)
					{
						if (mesh.vertices.inputs[j].semantic == "POSITION")
						{
							input.source = mesh.vertices.inputs[j].source;
							result = true;
							break;
						}
					}
				}
			}
		}

		return result;
	}
}

class DAEVertices extends DAEElement
{
	public var mesh:DAEMesh;
	public var inputs:Vector<DAEInput>;

	public function new(mesh:DAEMesh, element:XML = null)
	{
		this.mesh = mesh;
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.inputs = new Vector<DAEInput>();
		traverseChildren(element, "input");
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		nodeName = nodeName;
		this.inputs.push(new DAEInput(child));
	}
}

class DAEGeometry extends DAEElement
{
	public var mesh:DAEMesh;
	public var meshName:String = "";

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
		meshName = element.attribute("name");
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "mesh")
			this.mesh = new DAEMesh(this, child); //case "spline"//case "convex_mesh":
	}
}

class DAEMesh extends DAEElement
{
	public var geometry:DAEGeometry;
	public var sources:StringMap<DAESource>;
	public var vertices:DAEVertices;
	public var primitives:Vector<DAEPrimitive>;

	public function new(geometry:DAEGeometry, element:XML = null)
	{
		this.geometry = geometry;
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.sources = new StringMap<DAESource>();
		this.vertices = null;
		this.primitives = new Vector<DAEPrimitive>();
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources.set(source.id, source);
			case "vertices":
				this.vertices = new DAEVertices(this, child);
			case "triangles","polylist","polygon":
				this.primitives.push(new DAEPrimitive(child));
		}
	}
}

class DAEBindMaterial extends DAEElement
{
	public var instance_material:Vector<DAEInstanceMaterial>;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_material = new Vector<DAEInstanceMaterial>();
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "technique_common")
		{
			for (i in 0...child.children().length())
				this.instance_material.push(new DAEInstanceMaterial(child.children()[i]));
		}
	}
}

class DAEBindVertexInput extends DAEElement
{
	public var semantic:String;
	public var input_semantic:String;
	public var input_set:Int;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.semantic = element.@semantic.toString();
		this.input_semantic = element.@input_semantic.toString();
		this.input_set = readIntAttr(element, "input_set");
	}
}

class DAEInstance extends DAEElement
{
	public var url:String;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.url = element.@url.toString().replace(/^#/, "");
	}
}

class DAEInstanceController extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	public var skeleton:Vector<String>;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		this.skeleton = new Vector<String>();
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "skeleton":
				this.skeleton.push(readText(child).replace(/^#/, ""));
			case "bind_material":
				this.bind_material = new DAEBindMaterial(child);
		}
	}
}

class DAEInstanceEffect extends DAEInstance
{
	public function new(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceGeometry extends DAEInstance
{
	public var bind_material:DAEBindMaterial;

	public function DAEInstanceGeometry(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "bind_material")
			this.bind_material = new DAEBindMaterial(child);
	}
}

class DAEInstanceMaterial extends DAEInstance
{
	public var target:String;
	public var symbol:String;
	public var bind_vertex_input:Vector<DAEBindVertexInput>;

	public function DAEInstanceMaterial(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.target = element.@target.toString().replace(/^#/, "");
		this.symbol = element.@symbol.toString();
		this.bind_vertex_input = new Vector<DAEBindVertexInput>();
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "bind_vertex_input")
			this.bind_vertex_input.push(new DAEBindVertexInput(child));
	}
}

class DAEInstanceNode extends DAEInstance
{
	public function DAEInstanceNode(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceVisualScene extends DAEInstance
{
	public function DAEInstanceVisualScene(element:XML = null)
	{
		super(element);
	}
}

class DAEColor
{
	public var r:Float;
	public var g:Float;
	public var b:Float;
	public var a:Float;

	public function DAEColor()
	{
	}

	public function get rgb():UInt
	{
		var c:UInt = 0;
		c |= int(r * 255.0) << 16;
		c |= int(g * 255.0) << 8;
		c |= int(b * 255.0);

		return c;
	}

	public function get rgba():UInt
	{
		return (int(a * 255.0) << 24 | this.rgb);
	}
}

class DAETexture
{
	public var texture:String;
	public var texcoord:String;

	public function DAETexture()
	{
	}
}

class DAEColorOrTexture extends DAEElement
{
	public var color:DAEColor;
	public var texture:DAETexture;

	public function DAEColorOrTexture(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.color = null;
		this.texture = null;
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "color":
				var values:Vector<Float> = readFloatArray(child);
				this.color = new DAEColor();
				this.color.r = values[0];
				this.color.g = values[1];
				this.color.b = values[2];
				this.color.a = values.length > 3 ? values[3] : 1.0;
				

			case "texture":
				this.texture = new DAETexture();
				this.texture.texcoord = child.@texcoord.toString();
				this.texture.texture = child.@texture.toString();
				

			default:
				
		}
	}
}

class DAESurface extends DAEElement
{
	public var type:String;
	public var init_from:String;

	public function DAESurface(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
		this.init_from = readText(element.ns::init_from[0]);
	}
}

class DAESampler2D extends DAEElement
{
	public var source:String;

	public function DAESampler2D(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.source = readText(element.ns::source[0]);
	}
}

class DAEShader extends DAEElement
{
	public var type:String;
	public var props:Dynamic;

	public function DAEShader(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.props = {};
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "ambient":
			case "diffuse":
			case "specular":
			case "emission":
			case "transparent":
			case "reflective":
				this.props[nodeName] = new DAEColorOrTexture(child);
				
			case "shininess":
			case "reflectivity":
			case "transparency":
			case "index_of_refraction":
				this.props[nodeName] = Std.parseFloat(readText(child.ns::float[0]));
				
			default:
				trace("[WARNING] unhandled DAEShader property: " + nodeName);
		}
	}
}

class DAEEffect extends DAEElement
{
	public var shader:DAEShader;
	public var surface:DAESurface;
	public var sampler:DAESampler2D;
	public var material:*;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.shader = null;
		this.surface = null;
		this.sampler = null;
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "profile_COMMON")
			deserializeProfile(child);
	}

	private function deserializeProfile(element:XML):Void
	{
		var children:XMLList = element.children();

		for (i in 0...children.length())
		{
			var child:XML = children[i];
			var name:String = child.name().localName;

			switch (name)
			{
				case "technique":
					deserializeShader(child);
					
				case "newparam":
					deserializeNewParam(child);
			}
		}
	}

	private function deserializeNewParam(element:XML):Void
	{
		var children:XMLList = element.children();

		for (i in 0...children.length())
		{
			var child:XML = children[i];
			var name:String = child.name().localName;

			switch (name)
			{
				case "surface":
					this.surface = new DAESurface(child);
					this.surface.sid = element.@sid.toString();
					
				case "sampler2D":
					this.sampler = new DAESampler2D(child);
					this.sampler.sid = element.@sid.toString();
					
				default:
					trace("[WARNING] unhandled newparam: " + name);
			}
		}
	}

	private function deserializeShader(technique:XML):Void
	{
		var children:XMLList = technique.children();
		this.shader = null;

		for (i in 0...children.length())
		{
			var child:XML = children[i];
			var name:String = child.name().localName;

			switch (name)
			{
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					this.shader = new DAEShader(child);
			}
		}
	}
}

class DAEMaterial extends DAEElement
{
	public var instance_effect:DAEInstanceEffect;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_effect = null;
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "instance_effect")
			this.instance_effect = new DAEInstanceEffect(child);
	}
}

class DAETransform extends DAEElement
{
	public var type:String;
	public var data:Vector<Float>;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.data = readFloatArray(element);
	}

	public function get matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();

		switch (this.type)
		{
			case "matrix":
				matrix = new Matrix3D(this.data);
				matrix.transpose();
				
			case "scale":
				matrix.appendScale(this.data[0], this.data[1], this.data[2]);
				
			case "translate":
				matrix.appendTranslation(this.data[0], this.data[1], this.data[2]);
				
			case "rotate":
				var axis:Vector3D = new Vector3D(this.data[0], this.data[1], this.data[2]);
				matrix.appendRotation(this.data[3], axis);
		}

		return matrix;
	}
}

class DAENode extends DAEElement
{
	public var type:String;
	public var parent:DAENode;
	public var parser:DAEParser;
	public var nodes:Vector<DAENode>;
	public var transforms:Vector<DAETransform>;
	public var instance_controllers:Vector<DAEInstanceController>;
	public var instance_geometries:Vector<DAEInstanceGeometry>;
	public var world:Matrix3D;
	public var channels:Vector<DAEChannel>;
	private var _root:XML;

	public function new(parser:DAEParser, element:XML = null, parent:DAENode = null)
	{
		this.parser = parser;
		this.parent = parent;
		this.channels = new Vector<DAEChannel>();

		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);

		_root = getRootElement(element);

		this.type = element.@type.toString().length ? element.@type.toString() : "NODE";
		this.nodes = new Vector<DAENode>();
		this.transforms = new Vector<DAETransform>();
		this.instance_controllers = new Vector<DAEInstanceController>();
		this.instance_geometries = new Vector<DAEInstanceGeometry>();
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		var instances:XMLList;
		var instance:DAEInstance;

		switch (nodeName)
		{
			case "node":
				this.nodes.push(new DAENode(this.parser, child, this));
				

			case "instance_controller":
				instance = new DAEInstanceController(child);
				this.instance_controllers.push(instance);
				

			case "instance_geometry":
				this.instance_geometries.push(new DAEInstanceGeometry(child));
				

			case "instance_node":
				instance = new DAEInstanceNode(child);
				instances = _root.ns::library_nodes.ns::node.(@id == instance.url);
				if (instances.length())
					this.nodes.push(new DAENode(this.parser, instances[0], this));
				

			case "matrix":
			case "translate":
			case "scale":
			case "rotate":
				this.transforms.push(new DAETransform(child));
				
		}
	}

	public function getMatrixBySID(sid:String):Matrix3D
	{
		var transform:DAETransform = getTransformBySID(sid);
		if (transform)
			return transform.matrix;

		return null;
	}

	public function getTransformBySID(sid:String):DAETransform
	{
		for each (var transform:DAETransform in this.transforms)
			if (transform.sid == sid)
				return transform;

		return null;
	}

	public function getAnimatedMatrix(time:Float):Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		var tdata:Vector<Float>;
		var odata:Vector<Float>;
		var channelsBySID:Dynamic = {};
		var transform:DAETransform;
		var channel:DAEChannel;
		var minTime:Float = Number.MAX_VALUE;
		var maxTime:Float = -minTime;
		var i:UInt;
		//var j : uint;
		//var frame : int;

		for (i  in 0...this.channels.length)
		{
			channel = this.channels[i];
			minTime = Math.min(minTime, channel.sampler.minTime);
			minTime = Math.max(maxTime, channel.sampler.maxTime);
			channelsBySID[channel.targetSid] = channel;
		}

		for (i in 0...this.transforms.length)
		{
			transform = this.transforms[i];
			tdata = transform.data;
			if (channelsBySID.hasOwnProperty(transform.sid))
			{
				var m:Matrix3D = new Matrix3D();
				//var found : Bool = false;
				var frameData:DAEFrameData = null;
				channel = Std.instance(channelsBySID[transform.sid],AEChannel);
				frameData = channel.sampler.getFrameData(time);

				if (frameData)
				{
					odata = frameData.data;

					switch (transform.type)
					{
						case "matrix":
							if (channel.arrayAccess)
							{
								//m.rawData = tdata;
								//m.transpose();
								if (channel.arrayIndices.length > 1)
								{
									//	m.rawData[channel.arrayIndices[0] * 4 + channel.arrayIndices[1]] = odata[0];
									//	trace(channel.arrayIndices[0] * 4 + channel.arrayIndices[1])
								}

							}
							else if (channel.dotAccess)
							{
								trace("unhandled matrix array access");

							}
							else if (odata.length == 16)
							{
								m.rawData = odata;
								m.transpose();

							}
							else
							{
								trace("unhandled matrix " + transform.sid + " " + odata);
							}
							

						case "rotate":
							if (channel.arrayAccess)
							{
								trace("unhandled rotate array access");

							}
							else if (channel.dotAccess)
							{

								switch (channel.dotAccessor)
								{
									case "ANGLE":
										m.appendRotation(odata[0], new Vector3D(tdata[0], tdata[1], tdata[2]));
										
									default:
										trace("unhandled rotate dot access " + channel.dotAccessor);
								}

							}
							else
							{
								trace("unhandled rotate");
							}
							

						case "scale":
							if (channel.arrayAccess)
							{
								trace("unhandled scale array access");

							}
							else if (channel.dotAccess)
							{

								switch (channel.dotAccessor)
								{
									case "X":
										m.appendScale(odata[0], tdata[1], tdata[2]);
										
									case "Y":
										m.appendScale(tdata[0], odata[0], tdata[2]);
										
									case "Z":
										m.appendScale(tdata[0], tdata[1], odata[0]);
										
									default:
										trace("unhandled scale dot access " + channel.dotAccessor);
								}

							}
							else
							{
								trace("unhandled scale: " + odata.length);
							}
							

						case "translate":
							if (channel.arrayAccess)
							{
								trace("unhandled translate array access");

							}
							else if (channel.dotAccess)
							{

								switch (channel.dotAccessor)
								{
									case "X":
										m.appendTranslation(odata[0], tdata[1], tdata[2]);
										
									case "Y":
										m.appendTranslation(tdata[0], odata[0], tdata[2]);
										
									case "Z":
										m.appendTranslation(tdata[0], tdata[1], odata[0]);
										
									default:
										trace("unhandled translate dot access " + channel.dotAccessor);
								}

							}
							else
							{
								m.appendTranslation(odata[0], odata[1], odata[2]);
							}
							

						default:
							trace("unhandled transform type " + transform.type);
							continue;
					}
					matrix.prepend(m);

				}
				else
				{
					matrix.prepend(transform.matrix);
				}

			}
			else
			{
				matrix.prepend(transform.matrix);
			}
		}

		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);

		return matrix;
	}

	public function get matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		for (i in 0...this.transforms.length)
			matrix.prepend(this.transforms[i].matrix);

		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);

		return matrix;
	}
}

class DAEVisualScene extends DAENode
{
	public function new(parser:DAEParser, element:XML = null)
	{
		super(parser, element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
	}

	public function findNodeById(id:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.id == id)
			return node;

		for (i in 0...node.nodes.length)
		{
			var result:DAENode = findNodeById(id, node.nodes[i]);
			if (result)
				return result;
		}

		return null;
	}

	public function findNodeBySid(sid:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.sid == sid)
			return node;

		for (i in 0...node.nodes.length)
		{
			var result:DAENode = findNodeBySid(sid, node.nodes[i]);
			if (result)
				return result;
		}

		return null;
	}

	public function updateTransforms(node:DAENode, parent:DAENode = null):Void
	{
		node.world = node.matrix.clone();
		if (parent && parent.world)
			node.world.append(parent.world);

		for (i in 0...node.nodes.length)
			updateTransforms(node.nodes[i], node);
	}
}

class DAEScene extends DAEElement
{
	public var instance_visual_scene:DAEInstanceVisualScene;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_visual_scene = null;
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "instance_visual_scene")
			this.instance_visual_scene = new DAEInstanceVisualScene(child);
	}
}

class DAEMorph extends DAEEffect
{
	public var source:String;
	public var method:String;
	public var targets:Vector<String>;
	public var weights:Vector<Float>;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.source = element.@source.toString().replace(/^#/, "");
		this.method = element.@method.toString();
		this.method = this.method.length ? this.method : "NORMALIZED";
		this.targets = new Vector<String>();
		this.weights = new Vector<Float>();

		var sources:Dynamic = {};
		var source:DAESource;
		var input:DAEInput;
		var list:XMLList = element.ns::source;

		if (element.ns::targets && element.ns::targets.length() > 0)
		{
			for (i in 0...list.length())
			{
				source = new DAESource(list[i]);
				sources[source.id] = source;
			}
			list = element.ns::targets[0].ns::input;
			for (i in 0...list.length())
			{
				input = new DAEInput(list[i]);
				source = sources[input.source];
				switch (input.semantic)
				{
					case "MORPH_TARGET":
						this.targets = source.strings;
						
					case "MORPH_WEIGHT":
						this.weights = source.floats;
				}
			}
		}
	}
}

class DAEVertexWeight
{
	public var vertex:UInt;
	public var joint:UInt;
	public var weight:Float;

	public function new()
	{
	}
}

class DAESkin extends DAEElement
{
	public var source:String;
	public var bind_shape_matrix:Matrix3D;
	public var joints:Vector<String>;
	public var inv_bind_matrix:Vector<Matrix3D>;
	public var weights:Vector<Vector<DAEVertexWeight>>;
	public var jointSourceType:String;
	public var maxBones:UInt;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);

		this.source = element.@source.toString().replace(/^#/, "");
		this.bind_shape_matrix = new Matrix3D();
		this.inv_bind_matrix = new Vector<Matrix3D>();
		this.joints = new Vector<String>();
		this.weights = new Vector<Vector<DAEVertexWeight>>();

		var children:XMLList = element.children();
		var i:UInt;
		var sources:Dynamic = {};

		for (i in 0...element.ns::source.length())
		{
			var source:DAESource = new DAESource(element.ns::source[i]);
			sources[source.id] = source;
		}

		for (i in 0...children.length())
		{
			var child:XML = children[i];
			var name:String = child.name().localName;

			switch (name)
			{
				case "bind_shape_matrix":
					parseBindShapeMatrix(child);
					
				case "source":
					
				case "joints":
					parseJoints(child, sources);
					
				case "vertex_weights":
					parseVertexWeights(child, sources);
					
				default:
					
			}
		}
	}

	public function getJointIndex(joint:String):Int
	{
		for (i in 0...this.joints.length)
		{
			if (this.joints[i] == joint)
				return i;
		}
		return -1;
	}

	private function parseBindShapeMatrix(element:XML):Void
	{
		var values:Vector<Float> = readFloatArray(element);
		this.bind_shape_matrix = new Matrix3D(values);
		this.bind_shape_matrix.transpose();
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(this.bind_shape_matrix);
	}

	private function parseJoints(element:XML, sources:Dynamic):Void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var source:DAESource;

		for (i in 0...list.length())
		{
			input = new DAEInput(list[i]);
			source = sources[input.source];

			switch (input.semantic)
			{
				case "JOINT":
					this.joints = source.strings;
					this.jointSourceType = source.type;
					
				case "INV_BIND_MATRIX":
					var j:Int = 0; 
					while (j < source.floats.length)
					{
						var matrix:Matrix3D = new Matrix3D(source.floats.slice(j, j + source.accessor.stride));
						matrix.transpose();
						if (DAEElement.USE_LEFT_HANDED)
						{
							convertMatrix(matrix);
						}
						inv_bind_matrix.push(matrix);
						
						j += source.accessor.stride;
					}
			}
		}
	}

	private function parseVertexWeights(element:XML, sources:Dynamic):Void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var inputs:Vector<DAEInput> = new Vector<DAEInput>();
		var source:DAESource;
		var i:UInt, j:UInt, k:UInt;

		if (!element.ns::vcount.length() || !element.ns::v.length())
			throw new Error("Can't parse vertex weights");

		var vcount:Vector<Int> = readIntArray(element.ns::vcount[0]);
		var v:Vector<Int> = readIntArray(element.ns::v[0]);
		var numWeights:UInt = Std.parseInt(element.@count.toString(), 10);
		numWeights = numWeights;
		var index:Int = 0;
		this.maxBones = 0;

		for (i in 0...list.length())
			inputs.push(new DAEInput(list[i]));

		for (i in 0...vcount.length)
		{
			var numBones:UInt = vcount[i];
			var vertex_weights:Vector<DAEVertexWeight> = new Vector<DAEVertexWeight>();

			this.maxBones = Math.max(this.maxBones, numBones);

			for (j in 0...numBones)
			{
				var influence:DAEVertexWeight = new DAEVertexWeight();

				for (k in 0...inputs.length)
				{
					input = inputs[k];
					source = sources[input.source];

					switch (input.semantic)
					{
						case "JOINT":
							influence.joint = v[index + input.offset];
							
						case "WEIGHT":
							influence.weight = source.floats[v[index + input.offset]];
							
						default:
							
					}
				}
				influence.vertex = i;
				vertex_weights.push(influence);
				index += inputs.length;
			}

			this.weights.push(vertex_weights);
		}
	}
}

class DAEController extends DAEElement
{
	public var skin:DAESkin;
	public var morph:DAEMorph;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.skin = null;
		this.morph = null;

		if (element.ns::skin && element.ns::skin.length())
		{
			this.skin = new DAESkin(element.ns::skin[0]);
		}
		else if (element.ns::morph && element.ns::morph.length())
		{
			this.morph = new DAEMorph(element.ns::morph[0]);
		}
		else
		{
			throw new Error("DAEController: could not find a <skin> or <morph> element");
		}
	}
}

class DAESampler extends DAEElement
{
	public var input:Vector<Float>;
	public var output:Vector<Vector<Float>>;
	public var dataType:String;
	public var interpolation:Vector<String>;
	public var minTime:Float;
	public var maxTime:Float;
	private var _inputs:Vector<DAEInput>;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		var list:XMLList = element.ns::input;
		_inputs = new Vector<DAEInput>();

		for (i in 0...list.length())
			_inputs.push(new DAEInput(list[i]));
	}

	public function create(sources:Dynamic):Void
	{
		var input:DAEInput;
		var source:DAESource;
		var i:Int, j:Int;
		this.input = new Vector<Float>();
		this.output = new Vector<Vector<Float>>();
		this.interpolation = new Vector<String>();
		this.minTime = 0;
		this.maxTime = 0;

		for (i in 0..._inputs.length)
		{
			input = _inputs[i];
			source = sources[input.source];

			switch (input.semantic)
			{
				case "INPUT":
					this.input = source.floats;
					this.minTime = this.input[0];
					this.maxTime = this.input[this.input.length - 1];
					
				case "OUTPUT":
					j = 0; 
					while (j < source.floats.length)
					{
						this.output.push(source.floats.slice(j, j + source.accessor.stride));
						j += source.accessor.stride;
					}
					this.dataType = source.accessor.params[0].type;
					
				case "INTEROLATION":
					this.interpolation = source.strings;
			}
		}
	}

	public function getFrameData(time:Float):DAEFrameData
	{
		var frameData:DAEFrameData = new DAEFrameData(0, time);

		if (this.input == null || this.input.length == 0)
			return null;

		var a:Float, b:Float;
		var i:Int;
		frameData.valid = true;
		frameData.time = time;

		if (time <= this.input[0])
		{
			frameData.frame = 0;
			frameData.dt = 0;
			frameData.data = this.output[0];

		}
		else if (time >= this.input[this.input.length - 1])
		{
			frameData.frame = this.input.length - 1;
			frameData.dt = 0;
			frameData.data = this.output[frameData.frame];

		}
		else
		{

			for (i in 0...this.input.length - 1)
			{
				if (time >= this.input[i] && time < this.input[i + 1])
				{
					frameData.frame = i;
					frameData.dt = (time - this.input[i]) / (this.input[i + 1] - this.input[i]);
					frameData.data = this.output[i];
					break;
				}
			}

			for (i in 0...frameData.data.length)
			{
				a = this.output[frameData.frame][i];
				b = this.output[frameData.frame + 1][i];
				frameData.data[i] += frameData.dt * (b - a);
			}
		}

		return frameData;
	}
}

class DAEFrameData
{
	public var frame:UInt;
	public var time:Float;
	public var data:Vector<Float>;
	public var dt:Float;
	public var valid:Bool;

	public function new(frame:UInt = 0, time:Float = 0.0, dt:Float = 0.0, valid:Bool = false)
	{
		this.frame = frame;
		this.time = time;
		this.dt = dt;
		this.valid = valid;
	}
}

class DAEChannel extends DAEElement
{
	public var source:String;
	public var target:String;
	public var sampler:DAESampler;
	public var targetId:String;
	public var targetSid:String;
	public var arrayAccess:Bool;
	public var dotAccess:Bool;
	public var dotAccessor:String;
	public var arrayIndices:Array;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);

		this.source = element.@source.toString().replace(/^#/, "");
		this.target = element.@target.toString();
		this.sampler = null;
		var parts:Array = this.target.split("/");
		this.targetId = parts.shift();
		this.arrayAccess = this.dotAccess = false;
		var tmp:String = parts.shift();

		if (tmp.indexOf("(") >= 0)
		{
			parts = tmp.split("(");
			this.arrayAccess = true;
			this.arrayIndices = new Array();
			this.targetSid = parts.shift();
			for (i in 0...parts.length)
				this.arrayIndices.push(Std.parseInt(parts[i].replace(")", ""), 10));

		}
		else if (tmp.indexOf(".") >= 0)
		{
			parts = tmp.split(".");
			this.dotAccess = true;
			this.targetSid = parts[0];
			this.dotAccessor = parts[1];

		}
		else
		{
			this.targetSid = tmp;
		}
	}
}

class DAEAnimation extends DAEElement
{
	public var samplers:Vector<DAESampler>;
	public var channels:Vector<DAEChannel>;
	public var sources:Dynamic;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.samplers = new Vector<DAESampler>();
		this.channels = new Vector<DAEChannel>();
		this.sources = {};
		traverseChildren(element);
		setupChannels(this.sources);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName)
		{
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
				
			case "sampler":
				this.samplers.push(new DAESampler(child));
				
			case "channel":
				this.channels.push(new DAEChannel(child));
		}
	}

	private function setupChannels(sources:Dynamic):Void
	{
		var channel:DAEChannel
		for (channel in this.channels)
		{
			var sampler:DAESampler
			for (sampler in this.samplers)
			{
				if (channel.source == sampler.id)
				{
					sampler.create(sources);
					channel.sampler = sampler;
					break;
				}
			}
		}
	}
}

class DAELightType extends DAEElement
{
	public var color:DAEColor;

	public function new(element:XML = null)
	{
		super(element);
	}

	override public function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}

	override private function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "color")
		{
			var f:Vector<Float> = readFloatArray(child);
			this.color = new DAEColor();
			color.r = f[0];
			color.g = f[1];
			color.b = f[2];
			color.a = f.length > 3 ? f[3] : 1.0;
		}
	}
}

class DAEParserState
{
	public static inline var LOAD_XML:UInt = 0;
	public static inline var PARSE_IMAGES:UInt = 1;
	public static inline var PARSE_MATERIALS:UInt = 2;
	public static inline var PARSE_GEOMETRIES:UInt = 3;
	public static inline var PARSE_CONTROLLERS:UInt = 4;
	public static inline var PARSE_VISUAL_SCENE:UInt = 5;
	public static inline var PARSE_ANIMATIONS:UInt = 6;
	public static inline var PARSE_COMPLETE:UInt = 7;
}
