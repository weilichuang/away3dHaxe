package a3d.filters;

import flash.display3D.textures.Texture;
import flash.geom.Vector3D;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.ObjectContainer3D;
import a3d.filters.tasks.Filter3DHDepthOfFFieldTask;
import a3d.filters.tasks.Filter3DVDepthOfFFieldTask;

class DepthOfFieldFilter3D extends Filter3DBase
{
	private var _focusTarget:ObjectContainer3D;
	private var _hDofTask:Filter3DHDepthOfFFieldTask;
	private var _vDofTask:Filter3DVDepthOfFFieldTask;

	/**
	 * Creates a new DepthOfFieldFilter3D object.
	 * @param blurX The maximum amount of horizontal blur to apply
	 * @param blurY The maximum amount of vertical blur to apply
	 * @param stepSize The distance between samples. Set to -1 to auto-detect with acceptable quality.
	 */
	public function new(maxBlurX:UInt = 3, maxBlurY:UInt = 3, stepSize:Int = -1)
	{
		super();
		_hDofTask = new Filter3DHDepthOfFFieldTask(maxBlurX, stepSize);
		_vDofTask = new Filter3DVDepthOfFFieldTask(maxBlurY, stepSize);
		addTask(_hDofTask);
		addTask(_vDofTask);
	}


	/**
	 * The amount of pixels between each sample.
	 */
	private function get_stepSize():Int
	{
		return _hDofTask.stepSize;
	}

	private function set_stepSize(value:Int):Void
	{
		_vDofTask.stepSize = _hDofTask.stepSize = value;
	}

	/**
	 * An optional target ObjectContainer3D that will be used to auto-focus on.
	 */
	private function get_focusTarget():ObjectContainer3D
	{
		return _focusTarget;
	}

	private function set_focusTarget(value:ObjectContainer3D):Void
	{
		_focusTarget = value;
	}

	/**
	 * The distance from the camera to the point that is in focus.
	 */
	private function get_focusDistance():Float
	{
		return _hDofTask.focusDistance;
	}

	private function set_focusDistance(value:Float):Void
	{
		_hDofTask.focusDistance = _vDofTask.focusDistance = value;
	}

	/**
	 * The distance between the focus point and the maximum amount of blur.
	 */
	private function get_range():Float
	{
		return _hDofTask.range;
	}

	private function set_range(value:Float):Void
	{
		_vDofTask.range = _hDofTask.range = value;
	}

	/**
	 * The maximum amount of horizontal blur.
	 */
	private function get_maxBlurX():UInt
	{
		return _hDofTask.maxBlur;
	}

	private function set_maxBlurX(value:UInt):Void
	{
		_hDofTask.maxBlur = value;
	}

	/**
	 * The maximum amount of vertical blur.
	 */
	private function get_maxBlurY():UInt
	{
		return _vDofTask.maxBlur;
	}

	private function set_maxBlurY(value:UInt):Void
	{
		_vDofTask.maxBlur = value;
	}

	override public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{
		if (_focusTarget != null)
			updateFocus(camera);
	}

	private function updateFocus(camera:Camera3D):Void
	{
		var target:Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
		_hDofTask.focusDistance = _vDofTask.focusDistance = target.z;
	}

	override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		super.setRenderTargets(mainTarget, stage3DProxy);
		_hDofTask.target = _vDofTask.getMainInputTexture(stage3DProxy);
	}
}
