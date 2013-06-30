package a3d.filters;

import a3d.filters.tasks.Filter3DHBlurTask;

class HBlurFilter3D extends Filter3DBase
{
	private var _blurTask:Filter3DHBlurTask;

	/**
	 * Creates a new HBlurFilter3D object
	 * @param amount The amount of blur in pixels
	 * @param stepSize The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 */
	public function new(amount:UInt, stepSize:Int = -1)
	{
		super();
		_blurTask = new Filter3DHBlurTask(amount, stepSize);
		addTask(_blurTask);
	}

	private function get_amount():UInt
	{
		return _blurTask.amount;
	}

	private function set_amount(value:UInt):Void
	{
		_blurTask.amount = value;
	}

	/**
	 * The distance between two blur samples. Set to -1 to autodetect with acceptable quality (default value).
	 * Higher values provide better performance at the cost of reduces quality.
	 */
	private function get_stepSize():Int
	{
		return _blurTask.stepSize;
	}

	private function set_stepSize(value:Int):Void
	{
		_blurTask.stepSize = value;
	}
}
