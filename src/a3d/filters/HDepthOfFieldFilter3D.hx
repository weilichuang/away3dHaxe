package a3d.filters;

import flash.geom.Vector3D;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.ObjectContainer3D;
import a3d.filters.tasks.Filter3DHDepthOfFFieldTask;

class HDepthOfFieldFilter3D extends Filter3DBase
{
	private var _dofTask:Filter3DHDepthOfFFieldTask;
	private var _focusTarget:ObjectContainer3D;

	/**
	 * Creates a new HDepthOfFieldFilter3D object
	 * @param amount The amount of blur to apply in pixels
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(maxBlur:UInt = 3, stepSize:Int = -1)
	{
		super();
		_dofTask = new Filter3DHDepthOfFFieldTask(maxBlur, stepSize);
		addTask(_dofTask);
	}

	private inline function get_focusTarget():ObjectContainer3D
	{
		return _focusTarget;
	}

	private inline function set_focusTarget(value:ObjectContainer3D):Void
	{
		_focusTarget = value;
	}

	private inline function get_focusDistance():Float
	{
		return _dofTask.focusDistance;
	}

	private inline function set_focusDistance(value:Float):Void
	{
		_dofTask.focusDistance = value;
	}

	private inline function get_range():Float
	{
		return _dofTask.range;
	}

	private inline function set_range(value:Float):Void
	{
		_dofTask.range = value;
	}

	private inline function get_maxBlur():UInt
	{
		return _dofTask.maxBlur;
	}

	private inline function set_maxBlur(value:UInt):Void
	{
		_dofTask.maxBlur = value;
	}

	override public function update(stage:Stage3DProxy, camera:Camera3D):Void
	{
		if (_focusTarget)
			updateFocus(camera);
	}

	private function updateFocus(camera:Camera3D):Void
	{
		var target:Vector3D = camera.inverseSceneTransform.transformVector(_focusTarget.scenePosition);
		_dofTask.focusDistance = target.z;
	}
}
