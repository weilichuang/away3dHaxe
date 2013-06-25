package a3d.filters;

import a3d.filters.tasks.Filter3DHueSaturationTask;

class HueSaturationFilter3D extends Filter3DBase
{
	private var _hslTask:Filter3DHueSaturationTask;

	public function new(saturation:Float = 1, r:Float = 1, g:Float = 1, b:Float = 1)
	{
		super();

		_hslTask = new Filter3DHueSaturationTask();
		this.saturation = saturation;
		this.r = r;
		this.g = g;
		this.b = b;
		addTask(_hslTask);
	}

	private inline function get_saturation():Float
	{
		return _hslTask.saturation;
	}

	private inline function set_saturation(value:Float):Void
	{
		if (_hslTask.saturation == value)
			return;
		_hslTask.saturation = value;
	}

	private inline function get_r():Float
	{
		return _hslTask.r;
	}

	private inline function set_r(value:Float):Void
	{
		if (_hslTask.r == value)
			return;
		_hslTask.r = value;
	}

	private inline function get_b():Float
	{
		return _hslTask.b;
	}

	private inline function set_b(value:Float):Void
	{
		if (_hslTask.b == value)
			return;
		_hslTask.b = value;
	}

	private inline function get_g():Float
	{
		return _hslTask.g;
	}

	private inline function set_g(value:Float):Void
	{
		if (_hslTask.g == value)
			return;
		_hslTask.g = value;
	}
}
