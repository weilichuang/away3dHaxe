package a3d.core.traverse;


import a3d.core.base.IRenderable;
import a3d.core.data.RenderableListItem;
import a3d.entities.Entity;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;
import a3d.materials.MaterialBase;
import flash.geom.Vector3D;


/**
 * The EntityCollector class is a traverser for scene partitions that collects all scene graph entities that are
 * considered potientially visible.
 *
 * @see a3d.partition.Partition3D
 * @see a3d.partition.Entity
 */
class ShadowCasterCollector extends EntityCollector
{
	/**
	 * Creates a new EntityCollector object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * Adds an IRenderable object to the potentially visible objects.
	 * @param renderable The IRenderable object to add.
	 */
	override public function applyRenderable(renderable:IRenderable):Void
	{
		// the test for material is temporary, you SHOULD be hammered with errors if you try to render anything without a material
		var material:MaterialBase = renderable.material;
		var entity:Entity = renderable.sourceEntity;
		if (renderable.castsShadows && material != null)
		{
			var item:RenderableListItem = _renderableListItemPool.getItem();
			item.renderable = renderable;
			item.next = _opaqueRenderableHead;
			item.cascaded = false;
			
			var entityScenePos:Vector3D = entity.scenePosition;
			var dx:Float = _entryPoint.x - entityScenePos.x;
			var dy:Float = _entryPoint.y - entityScenePos.y;
			var dz:Float = _entryPoint.z - entityScenePos.z;
				
			item.zIndex = dx * _cameraForward.x + dy * _cameraForward.y + dz * _cameraForward.z;
			item.renderSceneTransform = renderable.getRenderSceneTransform(_camera);
			item.renderOrderId = material.depthPassId;
			_opaqueRenderableHead = item;
		}
	}

	override public function applyUnknownLight(light:LightBase):Void
	{
	}

	override public function applyDirectionalLight(light:DirectionalLight):Void
	{
	}

	override public function applyPointLight(light:PointLight):Void
	{
	}

	override public function applyLightProbe(light:LightProbe):Void
	{
	}

	override public function applySkyBox(renderable:IRenderable):Void
	{
	}
}
