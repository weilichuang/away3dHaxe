package a3d.core.traverse;

import flash.geom.Vector3D;


import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.data.EntityListItem;
import a3d.core.data.EntityListItemPool;
import a3d.core.data.RenderableListItem;
import a3d.core.data.RenderableListItemPool;
import a3d.core.partition.NodeBase;
import a3d.entities.Entity;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;
import a3d.materials.MaterialBase;
import a3d.math.Plane3D;



/**
 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
 * considered potientially visible.
 *
 * @see a3d.partition.Partition3D
 * @see a3d.partition.Entity
 */
class EntityCollector extends PartitionTraverser
{
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
	private var _numEntities:UInt;
	private var _numLights:UInt;
	private var _numTriangles:UInt;
	private var _numMouseEnableds:UInt;
	private var _camera:Camera3D;
	private var _numDirectionalLights:UInt;
	private var _numPointLights:UInt;
	private var _numLightProbes:UInt;
	private var _cameraForward:Vector3D;
	private var _customCullPlanes:Vector<Plane3D>;
	private var _cullPlanes:Vector<Plane3D>;
	private var _numCullPlanes:UInt;

	/**
	 * Creates a new EntityCollector object.
	 */
	public function EntityCollector()
	{
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
	 * The camera that provides the visible frustum.
	 */
	private inline function get_camera():Camera3D
	{
		return _camera;
	}

	private inline function set_camera(value:Camera3D):Void
	{
		_camera = value;
		_entryPoint = _camera.scenePosition;
		_cameraForward = _camera.forwardVector;
		_cullPlanes = _camera.frustumPlanes;
	}

	private inline function get_cullPlanes():Vector<Plane3D>
	{
		return _customCullPlanes;
	}

	private inline function set_cullPlanes(value:Vector<Plane3D>):Void
	{
		_customCullPlanes = value;
	}

	/**
	 * The amount of IRenderable objects that are mouse-enabled.
	 */
	private inline function get_numMouseEnableds():UInt
	{
		return _numMouseEnableds;
	}

	/**
	 * The sky box object if encountered.
	 */
	private inline function get_skyBox():IRenderable
	{
		return _skyBox;
	}

	/**
	 * The list of opaque IRenderable objects that are considered potentially visible.
	 * @param value
	 */
	private inline function get_opaqueRenderableHead():RenderableListItem
	{
		return _opaqueRenderableHead;
	}

	private inline function set_opaqueRenderableHead(value:RenderableListItem):Void
	{
		_opaqueRenderableHead = value;
	}

	/**
	 * The list of IRenderable objects that require blending and are considered potentially visible.
	 * @param value
	 */
	private inline function get_blendedRenderableHead():RenderableListItem
	{
		return _blendedRenderableHead;
	}

	private inline function set_blendedRenderableHead(value:RenderableListItem):Void
	{
		_blendedRenderableHead = value;
	}

	private inline function get_entityHead():EntityListItem
	{
		return _entityHead;
	}

	/**
	 * The lights of which the affecting area intersects the camera's frustum.
	 */
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

	/**
	 * Clears all objects in the entity collector.
	 */
	public function clear():Void
	{
		_cullPlanes = _customCullPlanes ? _customCullPlanes : (_camera ? _camera.frustumPlanes : null);
		_numCullPlanes = _cullPlanes ? _cullPlanes.length : 0;
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
		var enter:Bool = collectionMark != node.collectionMark && node.isInFrustum(_cullPlanes, _numCullPlanes);
		node.collectionMark = collectionMark;
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
		if (material)
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
	 * The total number of triangles collected, and which will be pushed to the render engine.
	 */
	private inline function get_numTriangles():UInt
	{
		return _numTriangles;
	}

	/**
	 * Cleans up any data at the end of a frame.
	 */
	public function cleanUp():Void
	{
	}
}
