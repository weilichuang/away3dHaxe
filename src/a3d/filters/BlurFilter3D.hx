package a3d.filters;

import flash.display3D.textures.Texture;

import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DHBlurTask;
import a3d.filters.tasks.Filter3DVBlurTask;

class BlurFilter3D extends Filter3DBase
{
	private var _hBlurTask:Filter3DHBlurTask;
	private var _vBlurTask:Filter3DVBlurTask;

	/**
	 * Creates a new BlurFilter3D object
	 * @param blurX The amount of horizontal blur to apply
	 * @param blurY The amount of vertical blur to apply
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(blurX:UInt = 3, blurY:UInt = 3, stepSize:Int = -1)
	{
		super();
		addTask(_hBlurTask = new Filter3DHBlurTask(blurX, stepSize));
		addTask(_vBlurTask = new Filter3DVBlurTask(blurY, stepSize));
	}

	private inline function get_blurX():UInt
	{
		return _hBlurTask.amount;
	}

	private inline function set_blurX(value:UInt):Void
	{
		_hBlurTask.amount = value;
	}

	private inline function get_blurY():UInt
	{
		return _vBlurTask.amount;
	}

	private inline function set_blurY(value:UInt):Void
	{
		_vBlurTask.amount = value;
	}

	/**
	 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 * Higher values provide better performance at the cost of reduces quality.
	 */
	private inline function get_stepSize():Int
	{
		return _hBlurTask.stepSize;
	}

	private inline function set_stepSize(value:Int):Void
	{
		_hBlurTask.stepSize = value;
		_vBlurTask.stepSize = value;
	}


	override public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void
	{
		_hBlurTask.target = _vBlurTask.getMainInputTexture(stage3DProxy);
		super.setRenderTargets(mainTarget, stage3DProxy);
	}
}
