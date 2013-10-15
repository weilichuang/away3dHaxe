package a3d.materials.passes;

import a3d.core.base.IRenderable;
import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.errors.AbstractMethodError;
import a3d.events.ShadingMethodEvent;
import a3d.materials.compilation.ShaderCompiler;
import a3d.materials.LightSources;
import a3d.materials.MaterialBase;
import a3d.materials.methods.BasicAmbientMethod;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicNormalMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.methods.MethodVOSet;
import a3d.materials.methods.ShaderMethodSetup;
import a3d.materials.methods.ShadowMapMethodBase;
import a3d.math.FMatrix3D;
import a3d.textures.Texture2DBase;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DProgramType;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.Vector;

class CompiledPass extends MaterialPassBase
{
	public var enableLightFallOff(get,set):Bool;
	public var forceSeparateMVP(get,set):Bool;
	public var numPointLights(get,null):Int;
	public var numDirectionalLights(get,null):Int;
	public var numLightProbes(get,null):Int;
	public var preserveAlpha(get,set):Bool;
	public var animateUVs(get,set):Bool;
	/**
	 * The tangent space normal map to influence the direction of the surface for each texel.
	 */
	public var normalMap(get,set):Texture2DBase;
	public var normalMethod(get,set):BasicNormalMethod;
	public var ambientMethod(get,set):BasicAmbientMethod;
	public var shadowMethod(get,set):ShadowMapMethodBase;
	public var diffuseMethod(get,set):BasicDiffuseMethod;
	public var specularMethod(get,set):BasicSpecularMethod;
	public var specularLightSources(get,set):Int;
	public var diffuseLightSources(get, set):Int;
	
	//internal use
	public var passes:Vector<MaterialPassBase>;
	public var passesDirty:Bool;

	private var _specularLightSources:Int = 0x01;
	private var _diffuseLightSources:Int = 0x03;

	private var _vertexCode:String;
	private var _fragmentLightCode:String;
	private var _framentPostLightCode:String;

	private var _vertexConstantData:Vector<Float> ;
	private var _fragmentConstantData:Vector<Float>;
	private var _commonsDataIndex:Int;
	private var _probeWeightsIndex:Int;
	private var _uvBufferIndex:Int;
	private var _secondaryUVBufferIndex:Int;
	private var _normalBufferIndex:Int;
	private var _tangentBufferIndex:Int;
	private var _sceneMatrixIndex:Int;
	private var _sceneNormalMatrixIndex:Int;
	private var _lightFragmentConstantIndex:Int;
	private var _cameraPositionIndex:Int;
	private var _uvTransformIndex:Int;
	private var _lightProbeDiffuseIndices:Vector<UInt>;
	private var _lightProbeSpecularIndices:Vector<UInt>;

	private var _ambientLightR:Float;
	private var _ambientLightG:Float;
	private var _ambientLightB:Float;

	private var _compiler:ShaderCompiler;

	private var _methodSetup:ShaderMethodSetup;

	private var _usingSpecularMethod:Bool;
	private var _usesNormals:Bool;
	private var _preserveAlpha:Bool = true;
	private var _animateUVs:Bool;

	private var _numPointLights:Int;
	private var _numDirectionalLights:Int;
	private var _numLightProbes:Int;

	private var _enableLightFallOff:Bool = true;

	private var _forceSeparateMVP:Bool;

	public function new(material:MaterialBase)
	{
		super();
		
		_material = material;
		
		_vertexConstantData = new Vector<Float>();
		_fragmentConstantData = new Vector<Float>();

		init();
	}

	
	private function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}

	private function set_enableLightFallOff(value:Bool):Bool
	{
		if (value != _enableLightFallOff)
			invalidateShaderProgram(true);
		_enableLightFallOff = value;
		
		return _enableLightFallOff;
	}
	
	
	private function get_forceSeparateMVP():Bool
	{
		return _forceSeparateMVP;
	}

	private function set_forceSeparateMVP(value:Bool):Bool
	{
		return _forceSeparateMVP = value;
	}

	
	private function get_numPointLights():Int
	{
		return _numPointLights;
	}

	
	private function get_numDirectionalLights():Int
	{
		return _numDirectionalLights;
	}

	
	private function get_numLightProbes():Int
	{
		return _numLightProbes;
	}

	/**
	 * @inheritDoc
	 */
	override public function updateProgram(stage3DProxy:Stage3DProxy):Void
	{
		reset(stage3DProxy.profile);
		super.updateProgram(stage3DProxy);
	}

	/**
	 * Resets the compilation state.
	 */
	private function reset(profile:Context3DProfile):Void
	{
		initCompiler(profile);
		updateShaderProperties();
		initConstantData();
		cleanUp();
	}

	private function updateUsedOffsets():Void
	{
		_numUsedVertexConstants = _compiler.numUsedVertexConstants;
		_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
		_numUsedStreams = _compiler.numUsedStreams;
		_numUsedTextures = _compiler.numUsedTextures;
		_numUsedVaryings = _compiler.numUsedVaryings;
		_numUsedFragmentConstants = _compiler.numUsedFragmentConstants;
	}

	private function initConstantData():Void
	{
		_vertexConstantData.length = _numUsedVertexConstants * 4;
		_fragmentConstantData.length = _numUsedFragmentConstants * 4;

		initCommonsData();
		if (_uvTransformIndex >= 0)
			initUVTransformData();
		if (_cameraPositionIndex >= 0)
			_vertexConstantData[_cameraPositionIndex + 3] = 1;

		updateMethodConstants();
	}

	private function initCompiler(profile:Context3DProfile):Void
	{
		_compiler = createCompiler(profile);
		_compiler.forceSeperateMVP = _forceSeparateMVP;
		_compiler.numPointLights = _numPointLights;
		_compiler.numDirectionalLights = _numDirectionalLights;
		_compiler.numLightProbes = _numLightProbes;
		_compiler.methodSetup = _methodSetup;
		_compiler.diffuseLightSources = _diffuseLightSources;
		_compiler.specularLightSources = _specularLightSources;
		_compiler.setTextureSampling(_smooth, _repeat, _mipmap);
		_compiler.setConstantDataBuffers(_vertexConstantData, _fragmentConstantData);
		_compiler.animateUVs = _animateUVs;
		_compiler.alphaPremultiplied = _alphaPremultiplied && _enableBlending;
		_compiler.preserveAlpha = _preserveAlpha && _enableBlending;
		_compiler.enableLightFallOff = _enableLightFallOff;
		_compiler.compile();
	}

	private function createCompiler(profile:Context3DProfile):ShaderCompiler
	{
		throw new AbstractMethodError();
	}

	private function updateShaderProperties():Void
	{
		_animatableAttributes = _compiler.animatableAttributes;
		_animationTargetRegisters = _compiler.animationTargetRegisters;
		_vertexCode = _compiler.vertexCode;
		_fragmentLightCode = _compiler.fragmentLightCode;
		_framentPostLightCode = _compiler.fragmentPostLightCode;
		_shadedTarget = _compiler.shadedTarget;
		_usingSpecularMethod = _compiler.usingSpecularMethod;
		_usesNormals = _compiler.usesNormals;
		_needUVAnimation = _compiler.needUVAnimation;
		_UVSource = _compiler.UVSource;
		_UVTarget = _compiler.UVTarget;

		updateRegisterIndices();
		updateUsedOffsets();
	}

	private function updateRegisterIndices():Void
	{
		_uvBufferIndex = _compiler.uvBufferIndex;
		_uvTransformIndex = _compiler.uvTransformIndex;
		_secondaryUVBufferIndex = _compiler.secondaryUVBufferIndex;
		_normalBufferIndex = _compiler.normalBufferIndex;
		_tangentBufferIndex = _compiler.tangentBufferIndex;
		_lightFragmentConstantIndex = _compiler.lightFragmentConstantIndex;
		_cameraPositionIndex = _compiler.cameraPositionIndex;
		_commonsDataIndex = _compiler.commonsDataIndex;
		_sceneMatrixIndex = _compiler.sceneMatrixIndex;
		_sceneNormalMatrixIndex = _compiler.sceneNormalMatrixIndex;
		_probeWeightsIndex = _compiler.probeWeightsIndex;
		_lightProbeDiffuseIndices = _compiler.lightProbeDiffuseIndices;
		_lightProbeSpecularIndices = _compiler.lightProbeSpecularIndices;
	}

	
	private function get_preserveAlpha():Bool
	{
		return _preserveAlpha;
	}

	private function set_preserveAlpha(value:Bool):Bool
	{
		if (_preserveAlpha == value)
			return _preserveAlpha;
		_preserveAlpha = value;
		invalidateShaderProgram();
		return _preserveAlpha;
	}

	
	private function get_animateUVs():Bool
	{
		return _animateUVs;
	}

	private function set_animateUVs(value:Bool):Bool
	{
		if (_animateUVs == value)
			return value;
			
		_animateUVs = value;
		
		invalidateShaderProgram();
		
		return value;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return _mipmap;
		return super.mipmap = value;
	}

	
	private function get_normalMap():Texture2DBase
	{
		return _methodSetup.normalMethod.normalMap;
	}

	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		return _methodSetup.normalMethod.normalMap = value;
	}

	
	private function get_normalMethod():BasicNormalMethod
	{
		return _methodSetup.normalMethod;
	}

	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		return _methodSetup.normalMethod = value;
	}

	
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _methodSetup.ambientMethod;
	}

	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		return _methodSetup.ambientMethod = value;
	}

	
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _methodSetup.shadowMethod;
	}

	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		return _methodSetup.shadowMethod = value;
	}

	
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _methodSetup.diffuseMethod;
	}

	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		return _methodSetup.diffuseMethod = value;
	}

	
	private function get_specularMethod():BasicSpecularMethod
	{
		return _methodSetup.specularMethod;
	}

	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		return _methodSetup.specularMethod = value;
	}

	private function init():Void
	{
		_methodSetup = new ShaderMethodSetup();
		_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();
		_methodSetup.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_methodSetup.dispose();
		_methodSetup = null;
	}

	/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 */
	override public function invalidateShaderProgram(updateMaterial:Bool = true):Void
	{
		var oldPasses:Vector<MaterialPassBase> = passes;
		passes = new Vector<MaterialPassBase>();

		if (_methodSetup != null)
			addPassesFromMethods();

		if (oldPasses == null || passes.length != oldPasses.length)
		{
			passesDirty = true;
			return;
		}

		for (i in 0...passes.length)
		{
			if (passes[i] != oldPasses[i])
			{
				passesDirty = true;
				return;
			}
		}

		super.invalidateShaderProgram(updateMaterial);
	}

	private function addPassesFromMethods():Void
	{
		if (_methodSetup.normalMethod != null && _methodSetup.normalMethod.hasOutput)
			addPasses(_methodSetup.normalMethod.passes);
		if (_methodSetup.ambientMethod != null)
			addPasses(_methodSetup.ambientMethod.passes);
		if (_methodSetup.shadowMethod != null)
			addPasses(_methodSetup.shadowMethod.passes);
		if (_methodSetup.diffuseMethod != null)
			addPasses(_methodSetup.diffuseMethod.passes);
		if (_methodSetup.specularMethod != null)
			addPasses(_methodSetup.specularMethod.passes);
	}

	/**
	 * Adds passes to the list.
	 */
	private function addPasses(passes:Vector<MaterialPassBase>):Void
	{
		if (passes == null)
			return;

		var len:Int = passes.length;
		for (i in 0...len)
		{
			passes[i].material = material;
			passes[i].lightPicker = _lightPicker;
			this.passes.push(passes[i]);
		}
	}

	private function initUVTransformData():Void
	{
		_vertexConstantData[_uvTransformIndex] = 1;
		_vertexConstantData[_uvTransformIndex + 1] = 0;
		_vertexConstantData[_uvTransformIndex + 2] = 0;
		_vertexConstantData[_uvTransformIndex + 3] = 0;
		_vertexConstantData[_uvTransformIndex + 4] = 0;
		_vertexConstantData[_uvTransformIndex + 5] = 1;
		_vertexConstantData[_uvTransformIndex + 6] = 0;
		_vertexConstantData[_uvTransformIndex + 7] = 0;
	}

	private function initCommonsData():Void
	{
		_fragmentConstantData[_commonsDataIndex] = .5;
		_fragmentConstantData[_commonsDataIndex + 1] = 0;
		_fragmentConstantData[_commonsDataIndex + 2] = 1 / 255;
		_fragmentConstantData[_commonsDataIndex + 3] = 1;
	}

	private function cleanUp():Void
	{
		_compiler.dispose();
		_compiler = null;
	}

	private function updateMethodConstants():Void
	{
		if (_methodSetup.normalMethod != null)
			_methodSetup.normalMethod.initConstants(_methodSetup.normalMethodVO);
		if (_methodSetup.diffuseMethod != null)
			_methodSetup.diffuseMethod.initConstants(_methodSetup.diffuseMethodVO);
		if (_methodSetup.ambientMethod != null)
			_methodSetup.ambientMethod.initConstants(_methodSetup.ambientMethodVO);
		if (_usingSpecularMethod)
			_methodSetup.specularMethod.initConstants(_methodSetup.specularMethodVO);
		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.initConstants(_methodSetup.shadowMethodVO);
	}

	private function updateLightConstants():Void
	{

	}

	private function updateProbes(stage3DProxy:Stage3DProxy):Void
	{

	}

	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}


	/**
	 * @inheritDoc
	 */
	override public function getVertexCode():String
	{
		return _vertexCode;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCode(animatorCode:String):String
	{
		return _fragmentLightCode + animatorCode + _framentPostLightCode;
	}

// RENDER LOOP

	/**
	 * @inheritDoc
	 */
	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		super.activate(stage3DProxy, camera);

		if (_usesNormals)
			_methodSetup.normalMethod.activate(_methodSetup.normalMethodVO, stage3DProxy);
			
		_methodSetup.ambientMethod.activate(_methodSetup.ambientMethodVO, stage3DProxy);
		
		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.activate(_methodSetup.shadowMethodVO, stage3DProxy);
			
		_methodSetup.diffuseMethod.activate(_methodSetup.diffuseMethodVO, stage3DProxy);
		
		if (_usingSpecularMethod)
			_methodSetup.specularMethod.activate(_methodSetup.specularMethodVO, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		var i:UInt;
		var context:Context3DProxy = stage3DProxy.context3D;
		if (_uvBufferIndex >= 0)
			renderable.activateUVBuffer(_uvBufferIndex, stage3DProxy);
			
		if (_secondaryUVBufferIndex >= 0)
			renderable.activateSecondaryUVBuffer(_secondaryUVBufferIndex, stage3DProxy);
			
		if (_normalBufferIndex >= 0)
			renderable.activateVertexNormalBuffer(_normalBufferIndex, stage3DProxy);
			
		if (_tangentBufferIndex >= 0)
			renderable.activateVertexTangentBuffer(_tangentBufferIndex, stage3DProxy);

		if (_animateUVs)
		{
			var uvTransform:Matrix = renderable.uvTransform;
			if (uvTransform != null)
			{
				_vertexConstantData[_uvTransformIndex] = uvTransform.a;
				_vertexConstantData[_uvTransformIndex + 1] = uvTransform.b;
				_vertexConstantData[_uvTransformIndex + 3] = uvTransform.tx;
				_vertexConstantData[_uvTransformIndex + 4] = uvTransform.c;
				_vertexConstantData[_uvTransformIndex + 5] = uvTransform.d;
				_vertexConstantData[_uvTransformIndex + 7] = uvTransform.ty;
			}
			else
			{
				_vertexConstantData[_uvTransformIndex] = 1;
				_vertexConstantData[_uvTransformIndex + 1] = 0;
				_vertexConstantData[_uvTransformIndex + 3] = 0;
				_vertexConstantData[_uvTransformIndex + 4] = 0;
				_vertexConstantData[_uvTransformIndex + 5] = 1;
				_vertexConstantData[_uvTransformIndex + 7] = 0;
			}
		}

		_ambientLightR = _ambientLightG = _ambientLightB = 0;

		if (usesLights())
			updateLightConstants();

		if (usesProbes())
			updateProbes(stage3DProxy);

		if (_sceneMatrixIndex >= 0)
		{
			renderable.getRenderSceneTransform(camera).copyRawDataTo(_vertexConstantData, _sceneMatrixIndex, true);
			viewProjection.copyRawDataTo(_vertexConstantData, 0, true);
		}
		else
		{
			var matrix3D:Matrix3D = FMatrix3D.CALCULATION_MATRIX;
			matrix3D.copyFrom(renderable.getRenderSceneTransform(camera));
			matrix3D.append(viewProjection);
			matrix3D.copyRawDataTo(_vertexConstantData, 0, true);
		}

		if (_sceneNormalMatrixIndex >= 0)
			renderable.inverseSceneTransform.copyRawDataTo(_vertexConstantData, _sceneNormalMatrixIndex, false);

		if (_usesNormals)
			_methodSetup.normalMethod.setRenderState(_methodSetup.normalMethodVO, renderable, stage3DProxy, camera);

		var ambientMethod:BasicAmbientMethod = _methodSetup.ambientMethod;
		ambientMethod.lightAmbientR = _ambientLightR;
		ambientMethod.lightAmbientG = _ambientLightG;
		ambientMethod.lightAmbientB = _ambientLightB;
		ambientMethod.setRenderState(_methodSetup.ambientMethodVO, renderable, stage3DProxy, camera);

		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.setRenderState(_methodSetup.shadowMethodVO, renderable, stage3DProxy, camera);
			
		_methodSetup.diffuseMethod.setRenderState(_methodSetup.diffuseMethodVO, renderable, stage3DProxy, camera);
		
		if (_usingSpecularMethod)
			_methodSetup.specularMethod.setRenderState(_methodSetup.specularMethodVO, renderable, stage3DProxy, camera);
			
		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.setRenderState(_methodSetup.colorTransformMethodVO, renderable, stage3DProxy, camera);

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		for (i in 0...methods.length)
		{
			var mset:MethodVOSet = methods[i];
			mset.method.setRenderState(mset.data, renderable, stage3DProxy, camera);
		}

		context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexConstantData, _numUsedVertexConstants);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentConstantData, _numUsedFragmentConstants);

		renderable.activateVertexBuffer(0, stage3DProxy);
		context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
	}

	private function usesProbes():Bool
	{
		return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
	}

	private function usesLights():Bool
	{
		return (_numPointLights > 0 || _numDirectionalLights > 0) && ((_diffuseLightSources | _specularLightSources) & LightSources.LIGHTS) != 0;
	}

	/**
	 * @inheritDoc
	 */
	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);

		if (_usesNormals)
			_methodSetup.normalMethod.deactivate(_methodSetup.normalMethodVO, stage3DProxy);
			
		_methodSetup.ambientMethod.deactivate(_methodSetup.ambientMethodVO, stage3DProxy);
		
		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.deactivate(_methodSetup.shadowMethodVO, stage3DProxy);
			
		_methodSetup.diffuseMethod.deactivate(_methodSetup.diffuseMethodVO, stage3DProxy);
		
		if (_usingSpecularMethod)
			_methodSetup.specularMethod.deactivate(_methodSetup.specularMethodVO, stage3DProxy);
	}

//	override private function updateLights() : void
//	{
//		for (i in 0..._passes.length)
//			_passes[i].lightPicker = _lightPicker;
//	}

	
	private function get_specularLightSources():Int
	{
		return _specularLightSources;
	}

	private function set_specularLightSources(value:Int):Int
	{
		return _specularLightSources = value;
	}

	
	private function get_diffuseLightSources():Int
	{
		return _diffuseLightSources;
	}

	private function set_diffuseLightSources(value:Int):Int
	{
		return _diffuseLightSources = value;
	}
}
