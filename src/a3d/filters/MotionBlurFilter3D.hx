package a3d.filters;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.filters.tasks.Filter3DDoubleBufferCopyTask;
import a3d.filters.tasks.Filter3DXFadeCompositeTask;

class MotionBlurFilter3D extends Filter3DBase
{
	public var strength(get, set):Float;
	
	private var _compositeTask:Filter3DXFadeCompositeTask;
	private var _copyTask:Filter3DDoubleBufferCopyTask;

	public function new(strength:Float = .65)
	{
		super();
		_compositeTask = new Filter3DXFadeCompositeTask(strength);
		_copyTask = new Filter3DDoubleBufferCopyTask();

		addTask(_compositeTask);
		addTask(_copyTask);
	}

	
	private function get_strength():Float
	{
		return _compositeTask.amount;
	}

	private function set_strength(value:Float):Float
	{
		return _compositeTask.amount = value;
	}

	override public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{
		_compositeTask.overlayTexture = _copyTask.getMainInputTexture(stage);
		_compositeTask.target = _copyTask.secondaryInputTexture;
	}
}
