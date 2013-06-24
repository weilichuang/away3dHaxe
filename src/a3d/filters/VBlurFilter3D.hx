package a3d.filters;

import a3d.filters.tasks.Filter3DVBlurTask;

class VBlurFilter3D extends Filter3DBase
{
	private var _blurTask:Filter3DVBlurTask;

	/**
	 * Creates a new VBlurFilter3D object
	 * @param amount The amount of blur in pixels
	 * @param stepSize The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 */
	public function VBlurFilter3D(amount:UInt, stepSize:Int = -1)
	{
		super();
		_blurTask = new Filter3DVBlurTask(amount, stepSize);
		addTask(_blurTask);
	}

	private inline function get_amount():UInt
	{
		return _blurTask.amount;
	}

	private inline function set_amount(value:UInt):Void
	{
		_blurTask.amount = value;
	}

	/**
	 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 * Higher values provide better performance at the cost of reduces quality.
	 */
	private inline function get_stepSize():Int
	{
		return _blurTask.stepSize;
	}

	private inline function set_stepSize(value:Int):Void
	{
		_blurTask.stepSize = value;
	}
}
