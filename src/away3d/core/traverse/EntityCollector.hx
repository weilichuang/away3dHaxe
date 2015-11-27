package away3d.core.traverse;

import away3d.core.base.IRenderable;
import away3d.core.data.EntityListItem;
import away3d.core.data.EntityListItemPool;
import away3d.core.data.RenderableListItem;
import away3d.core.data.RenderableListItemPool;
import away3d.core.partition.NodeBase;
import away3d.entities.Camera3D;
import away3d.entities.Entity;
import away3d.entities.lights.DirectionalLight;
import away3d.entities.lights.LightBase;
import away3d.entities.lights.LightProbe;
import away3d.entities.lights.PointLight;
import away3d.materials.MaterialBase;
import away3d.math.Plane3D;
import flash.geom.Vector3D;
import flash.Vector;


/**
 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
 * considered potientially visible.
 *
 * @see away3d.partition.Partition3D
 * @see away3d.partition.Entity
 */
class EntityCollector extends PartitionTraverser
{
	/**
	 * The amount of IRenderable objects that are mouse-enabled.
	 */
	public var numMouseEnableds(get, null):Int;
	
	/**
	 * The camera that provides the visible frustum.
	 */
	public var camera(get, set):Camera3D;
	
	public var cullPlanes(get, set):Vector<Plane3D>;
	/**
	 * The sky box object if encountered.
	 */
	public var skyBox(get, null):IRenderable;
	/**
	 * The list of opaque IRenderable objects that are considered potentially visible.
	 * @param value
	 */
	public var opaqueRenderableHead(get, set):RenderableListItem;
	/**
	 * The list of IRenderable objects that require blending and are considered potentially visible.
	 * @param value
	 */
	public var blendedRenderableHead(get, set):RenderableListItem;
	
	public var entityHead(get, null):EntityListItem;
	
	/**
	 * The lights of which the affecting area intersects the camera's frustum.
	 */
	public var lights(get, null):Vector<LightBase>;
	public var directionalLights(get, null):Vector<DirectionalLight>;
	public var pointLights(get, null):Vector<PointLight>;
	public var lightProbes(get, null):Vector<LightProbe>;
	
	/**
	 * The total number of triangles collected, and which will be pushed to the render engine.
	 */
	public var numTriangles(get,null):Int;
	
	private var _skyBox:IRenderable;
	private var _opaqueRenderableHead:RenderableListItem;
	private var _blendedRenderableHead:RenderableListItem;
	private var _entityHead:EntityListItem;
	private var _renderableListItemPool:RenderableListItemPool;
	private var _entityListItemPool:EntityListItemPool;
	private var _lights:Vector<LightBase>;
	private var _directionalLights:Vector<DirectionalLight>;
	private var _pointLights:Vector<PointLight>;
	private var _lightProbes:Vector<LightProbe>;
	private var _numEntities:Int;
	private var _numLights:Int;
	private var _numTriangles:Int;
	private var _numMouseEnableds:Int;
	private var _camera:Camera3D;
	private var _numDirectionalLights:Int;
	private var _numPointLights:Int;
	private var _numLightProbes:Int;
	private var _cameraForward:Vector3D;
	private var _customCullPlanes:Vector<Plane3D>;
	private var _cullPlanes:Vector<Plane3D>;
	private var _numCullPlanes:Int;

	/**
	 * Creates a new EntityCollector object.
	 */
	public function new()
	{
		super();
		init();
	}

	private function init():Void
	{
		_lights = new Vector<LightBase>();
		_directionalLights = new Vector<DirectionalLight>();
		_pointLights = new Vector<PointLight>();
		_lightProbes = new Vector<LightProbe>();
		_renderableListItemPool = new RenderableListItemPool();
		_entityListItemPool = new EntityListItemPool();
	}

	/**
	 * Clears all objects in the entity collector.
	 */
	public function clear():Void
	{
		if (_camera != null)
		{
			_entryPoint = _camera.scenePosition;
			_cameraForward = _camera.forwardVector;
		}
		else
		{
			_entryPoint = null;
			_cameraForward = null;
		}
		_cullPlanes = _customCullPlanes != null ? _customCullPlanes : (_camera != null ? _camera.frustumPlanes : null);
		_numCullPlanes = _cullPlanes != null ? _cullPlanes.length : 0;
		_numTriangles = _numMouseEnableds = 0;
		_blendedRenderableHead = null;
		_opaqueRenderableHead = null;
		_entityHead = null;
		_renderableListItemPool.freeAll();
		_entityListItemPool.freeAll();
		_skyBox = null;
		if (_numLights > 0)
			_lights.length = _numLights = 0;
		if (_numDirectionalLights > 0)
			_directionalLights.length = _numDirectionalLights = 0;
		if (_numPointLights > 0)
			_pointLights.length = _numPointLights = 0;
		if (_numLightProbes > 0)
			_lightProbes.length = _numLightProbes = 0;
	}

	/**
	 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
	 *
	 * @param node The Partition3DNode object to frustum-test.
	 */
	override public function enterNode(node:NodeBase):Bool
	{
		var enter:Bool = PartitionTraverser.collectionMark != node.collectionMark && node.isInFrustum(_cullPlanes, _numCullPlanes);
		node.collectionMark = PartitionTraverser.collectionMark;
		return enter;
	}

	/**
	 * Adds a skybox to the potentially visible objects.
	 * @param renderable The skybox to add.
	 */
	override public function applySkyBox(renderable:IRenderable):Void
	{
		_skyBox = renderable;
	}

	/**
	 * Adds an IRenderable object to the potentially visible objects.
	 * @param renderable The IRenderable object to add.
	 */
	override public function applyRenderable(renderable:IRenderable):Void
	{
		var material:MaterialBase;
		var entity:Entity = renderable.sourceEntity;
		if (renderable.mouseEnabled)
			++_numMouseEnableds;
			
		_numTriangles += renderable.numTriangles;

		material = renderable.material;
		if (material != null)
		{
			var item:RenderableListItem = _renderableListItemPool.getItem();
			item.renderable = renderable;
			item.materialId = material.uniqueId;
			item.renderOrderId = material.renderOrderId;
			item.cascaded = false;
			
			var dx:Float = _entryPoint.x - entity.x;
			var dy:Float = _entryPoint.y - entity.y;
			var dz:Float = _entryPoint.z - entity.z;
			
			// project onto camera's z-axis
			item.zIndex = dx * _cameraForward.x + dy * _cameraForward.y + dz * _cameraForward.z + entity.zOffset;
			item.renderSceneTransform = renderable.getRenderSceneTransform(_camera);
			if (material.requiresBlending)
			{
				item.next = _blendedRenderableHead;
				_blendedRenderableHead = item;
			}
			else
			{
				item.next = _opaqueRenderableHead;
				_opaqueRenderableHead = item;
			}
		}
	}

	/**
	 * @inheritDoc
	 */
	override public function applyEntity(entity:Entity):Void
	{
		++_numEntities;

		var item:EntityListItem = _entityListItemPool.getItem();
		item.entity = entity;

		item.next = _entityHead;
		_entityHead = item;
	}

	/**
	 * Adds a light to the potentially visible objects.
	 * @param light The light to add.
	 */
	override public function applyUnknownLight(light:LightBase):Void
	{
		_lights[_numLights++] = light;
	}

	override public function applyDirectionalLight(light:DirectionalLight):Void
	{
		_lights[_numLights++] = light;
		_directionalLights[_numDirectionalLights++] = light;
	}

	override public function applyPointLight(light:PointLight):Void
	{
		_lights[_numLights++] = light;
		_pointLights[_numPointLights++] = light;
	}

	override public function applyLightProbe(light:LightProbe):Void
	{
		_lights[_numLights++] = light;
		_lightProbes[_numLightProbes++] = light;
	}
	
	/**
	 * Cleans up any data at the end of a frame.
	 */
	public function cleanUp():Void
	{
	}


	private inline function get_camera():Camera3D
	{
		return _camera;
	}

	private function set_camera(value:Camera3D):Camera3D
	{
		_camera = value;
		_entryPoint = _camera.scenePosition;
		_cameraForward = _camera.forwardVector;
		_cullPlanes = _camera.frustumPlanes;
		
		return _camera;
	}

	
	private inline function get_cullPlanes():Vector<Plane3D>
	{
		return _customCullPlanes;
	}

	private function set_cullPlanes(value:Vector<Plane3D>):Vector<Plane3D>
	{
		return _customCullPlanes = value;
	}

	
	private inline function get_numMouseEnableds():Int
	{
		return _numMouseEnableds;
	}

	
	private inline function get_skyBox():IRenderable
	{
		return _skyBox;
	}

	
	private inline function get_opaqueRenderableHead():RenderableListItem
	{
		return _opaqueRenderableHead;
	}

	private inline function set_opaqueRenderableHead(value:RenderableListItem):RenderableListItem
	{
		return _opaqueRenderableHead = value;
	}

	
	private inline function get_blendedRenderableHead():RenderableListItem
	{
		return _blendedRenderableHead;
	}

	private inline function set_blendedRenderableHead(value:RenderableListItem):RenderableListItem
	{
		return _blendedRenderableHead = value;
	}

	
	private inline function get_entityHead():EntityListItem
	{
		return _entityHead;
	}

	
	private inline function get_lights():Vector<LightBase>
	{
		return _lights;
	}

	
	private inline function get_directionalLights():Vector<DirectionalLight>
	{
		return _directionalLights;
	}

	
	private inline function get_pointLights():Vector<PointLight>
	{
		return _pointLights;
	}

	
	private inline function get_lightProbes():Vector<LightProbe>
	{
		return _lightProbes;
	}
	
	private function get_numTriangles():Int
	{
		return _numTriangles;
	}

	
}
