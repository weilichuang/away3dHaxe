package a3d.filters;

import flash.display3D.textures.Texture;

import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DHBlurTask;
import a3d.filters.tasks.Filter3DVBlurTask;

class BlurFilter3D extends Filter3DBase
{
	public var blurX(get, set):Int;
	public var blurY(get, set):Int;
	public var stepSize(get, set):Int;
	
	private var _hBlurTask:Filter3DHBlurTask;
	private var _vBlurTask:Filter3DVBlurTask;

	/**
	 * Creates a new BlurFilter3D object
	 * @param blurX The amount of horizontal blur to apply
	 * @param blurY The amount of vertical blur to apply
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(blurX:Int = 3, blurY:Int = 3, stepSize:Int = -1)
	{
		super();
		addTask(_hBlurTask = new Filter3DHBlurTask(blurX, stepSize));
		addTask(_vBlurTask = new Filter3DVBlurTask(blurY, stepSize));
	}

	private function get_blurX():Int
	{
		return _hBlurTask.amount;
	}

	private function set_blurX(value:Int):Int
	{
		return _hBlurTask.amount = value;
	}

	private function get_blurY():Int
	{
		return _vBlurTask.amount;
	}

	private function set_blurY(value:Int):Int
	{
		return _vBlurTask.amount = value;
	}

	/**
	 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 * Higher values provide better performance at the cost of reduces quality.
	 */
	private function get_stepSize():Int
	{
		return _hBlurTask.stepSize;
	}

	private function set_stepSize(value:Int):Int
	{
		_hBlurTask.stepSize = value;
		_vBlurTask.stepSize = value;
		return value;
	}


	override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
		super.setRenderTargets(mainTarget, stage3DProxy);
	}
}
