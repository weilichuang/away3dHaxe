package a3d.stereo;


import a3d.entities.Camera3D;
import a3d.entities.Scene3D;
import a3d.entities.View3D;
import a3d.core.render.RendererBase;
import a3d.stereo.methods.StereoRenderMethodBase;

import flash.display3D.textures.Texture;



class StereoView3D extends View3D
{
	private var _stereoCam:StereoCamera3D;
	private var _stereoRenderer:StereoRenderer;

	private var _stereoEnabled:Bool;


	public function new(scene:Scene3D = null, camera:Camera3D = null, renderer:RendererBase = null, stereoRenderMethod:StereoRenderMethodBase = null)
	{
		super(scene, camera, renderer);

		this.camera = camera;

		_stereoRenderer = new StereoRenderer(stereoRenderMethod);
	}


	private function get_stereoRenderMethod():StereoRenderMethodBase
	{
		return _stereoRenderer.renderMethod;
	}

	private function set_stereoRenderMethod(value:StereoRenderMethodBase):Void
	{
		_stereoRenderer.renderMethod = value;
	}


	override private function get_camera():Camera3D
	{
		return _stereoCam;
	}

	override private function set_camera(value:Camera3D):Void
	{
		if (value == _stereoCam)
			return;

		if (Std.is(value,StereoCamera3D))
		{
			_stereoCam = StereoCamera3D(value);
		}
		else
		{
			throw new Error('StereoView3D must be used with StereoCamera3D');
		}
	}


	private function get_stereoEnabled():Bool
	{
		return _stereoEnabled;
	}

	private function set_stereoEnabled(val:Bool):Void
	{
		_stereoEnabled = val;
	}



	override public function render():Void
	{
		if (_stereoEnabled)
		{
			// reset or update render settings
			if (_backBufferInvalid)
				updateBackBuffer();

			if (!_parentIsStage)
				updateGlobalPos();

			updateTime();

			renderWithCamera(_stereoCam.leftCamera, _stereoRenderer.getLeftInputTexture(_stage3DProxy), true);
			renderWithCamera(_stereoCam.rightCamera, _stereoRenderer.getRightInputTexture(_stage3DProxy), false);

			_stereoRenderer.render(_stage3DProxy);

			if (!_shareContext)
				_stage3DProxy.context3D.present();

			// fire collected mouse events
			_mouse3DManager.fireMouseEvents();
		}
		else
		{
			_camera = _stereoCam;
			super.render();
		}
	}



	private function renderWithCamera(cam:Camera3D, texture:Texture, doMouse:Bool):Void
	{
		_entityCollector.clear();

		_camera = cam;
		_camera.lens.aspectRatio = _aspectRatio;
		_entityCollector.camera = _camera;

		updateViewSizeData();

		// Always use RTT for stereo rendering
		_renderer.textureRatioX = _rttBufferManager.textureRatioX;
		_renderer.textureRatioY = _rttBufferManager.textureRatioY;

		// collect stuff to render
		_scene.traversePartitions(_entityCollector);

		// update picking
		if (doMouse)
			_mouse3DManager.updateCollider(this);

		//			updateLights(_entityCollector);

		if (_requireDepthRender)
			renderDepthPrepass(_entityCollector);

		if (_filter3DRenderer && _stage3DProxy.context3D)
		{
			_renderer.render(_entityCollector, _filter3DRenderer.getMainInputTexture(_stage3DProxy), _rttBufferManager.renderToTextureRect);
			_filter3DRenderer.render(_stage3DProxy, camera, _depthRender);
			if (!_shareContext)
				_stage3DProxy.context3D.present();
		}
		else
		{
			_renderer.shareContext = _shareContext;
			if (_shareContext)
			{
				_renderer.render(_entityCollector, texture, _scissorRect);
			}
			else
			{
				_renderer.render(_entityCollector, texture, _rttBufferManager.renderToTextureRect);
			}

		}

		// clean up data for this render
		_entityCollector.cleanUp();
	}
}
