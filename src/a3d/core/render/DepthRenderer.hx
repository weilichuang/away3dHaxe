package a3d.core.render;

import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.textures.TextureBase;
import flash.geom.Rectangle;


import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.data.RenderableListItem;
import a3d.core.traverse.EntityCollector;
import a3d.entities.Entity;
import a3d.materials.MaterialBase;
import a3d.math.Plane3D;



/**
 * The DepthRenderer class renders 32-bit depth information encoded as RGBA
 */
class DepthRenderer extends RendererBase
{
	private var _activeMaterial:MaterialBase;
	private var _renderBlended:Bool;
	private var _distanceBased:Bool;
	private var _disableColor:Bool;

	/**
	 * Creates a new DepthRenderer object.
	 * @param renderBlended Indicates whether semi-transparent objects should be rendered.
	 * @param distanceBased Indicates whether the written depth value is distance-based or projected depth-based
	 */
	public function new(renderBlended:Bool = false, distanceBased:Bool = false)
	{
		super();
		_renderBlended = renderBlended;
		_distanceBased = distanceBased;
		_backgroundR = 1;
		_backgroundG = 1;
		_backgroundB = 1;
	}

	private inline function get_disableColor():Bool
	{
		return _disableColor;
	}

	private inline function set_disableColor(value:Bool):Void
	{
		_disableColor = value;
	}

	override private inline function set_backgroundR(value:Float):Void
	{
	}

	override private inline function set_backgroundG(value:Float):Void
	{
	}

	override private inline function set_backgroundB(value:Float):Void
	{
	}

	public function renderCascades(entityCollector:EntityCollector, target:TextureBase, numCascades:UInt, scissorRects:Vector<Rectangle>, cameras:Vector<Camera3D>):Void
	{
		_renderTarget = target;
		_renderTargetSurface = 0;
		_renderableSorter.sort(entityCollector);
		_stage3DProxy.setRenderTarget(target, true, 0);
		_context.clear(1, 1, 1, 1, 1, 0);
		_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		_context.setDepthTest(true, Context3DCompareMode.LESS);

		var head:RenderableListItem = entityCollector.opaqueRenderableHead;
		var first:Bool = true;
		for (var i:Int = numCascades - 1; i >= 0; --i)
		{
			_stage3DProxy.scissorRect = scissorRects[i];
			drawCascadeRenderables(head, cameras[i], first ? null : cameras[i].frustumPlanes);
			first = false;
		}

		if (_activeMaterial)
			_activeMaterial.deactivateForDepth(_stage3DProxy);

		_activeMaterial = null;

		//line required for correct rendering when using away3d with starling. DO NOT REMOVE UNLESS STARLING INTEGRATION IS RETESTED!
		_context.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);

		_stage3DProxy.scissorRect = null;
	}

	private function drawCascadeRenderables(item:RenderableListItem, camera:Camera3D, cullPlanes:Vector<Plane3D>):Void
	{
		var material:MaterialBase;

		while (item)
		{
			if (item.cascaded)
			{
				item = item.next;
				continue;
			}

			var renderable:IRenderable = item.renderable;
			var entity:Entity = renderable.sourceEntity;

			// if completely in front, it will fall in a different cascade
			// do not use near and far planes
			if (!cullPlanes || entity.worldBounds.isInFrustum(cullPlanes, 4))
			{
				material = renderable.material;
				if (_activeMaterial != material)
				{
					if (_activeMaterial)
						_activeMaterial.deactivateForDepth(_stage3DProxy);
					_activeMaterial = material;
					_activeMaterial.activateForDepth(_stage3DProxy, camera, false);
				}

				_activeMaterial.renderDepth(renderable, _stage3DProxy, camera, camera.viewProjection);
			}
			else
				item.cascaded = true;

			item = item.next;
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function draw(entityCollector:EntityCollector, target:TextureBase):Void
	{
		_context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		_context.setDepthTest(true, Context3DCompareMode.LESS);
		drawRenderables(entityCollector.opaqueRenderableHead, entityCollector);

		if (_disableColor)
			_context.setColorMask(false, false, false, false);

		if (_renderBlended)
			drawRenderables(entityCollector.blendedRenderableHead, entityCollector);

		if (_activeMaterial)
			_activeMaterial.deactivateForDepth(_stage3DProxy);

		if (_disableColor)
			_context.setColorMask(true, true, true, true);

		_activeMaterial = null;
	}

	/**
	 * Draw a list of renderables.
	 * @param renderables The renderables to draw.
	 * @param entityCollector The EntityCollector containing all potentially visible information.
	 */
	private function drawRenderables(item:RenderableListItem, entityCollector:EntityCollector):Void
	{
		var camera:Camera3D = entityCollector.camera;
		var item2:RenderableListItem;

		while (item)
		{
			_activeMaterial = item.renderable.material;

			// otherwise this would result in depth rendered anyway because fragment shader kil is ignored
			if (_disableColor && _activeMaterial.hasDepthAlphaThreshold())
			{
				item2 = item;
				// fast forward
				do
				{
					item2 = item2.next;
				} while (item2 && item2.renderable.material == _activeMaterial);
			}
			else
			{
				_activeMaterial.activateForDepth(_stage3DProxy, camera, _distanceBased);
				item2 = item;
				do
				{
					_activeMaterial.renderDepth(item2.renderable, _stage3DProxy, camera, _rttViewProjectionMatrix);
					item2 = item2.next;
				} while (item2 && item2.renderable.material == _activeMaterial);
				_activeMaterial.deactivateForDepth(_stage3DProxy);
			}
			item = item2;
		}
	}
}
