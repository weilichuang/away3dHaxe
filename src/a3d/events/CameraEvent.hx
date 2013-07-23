package a3d.events;

import a3d.entities.Camera3D;
import flash.events.Event;


class CameraEvent extends Event
{
	public static inline var LENS_CHANGED:String = "lensChanged";

	private var _camera:Camera3D;

	public function new(type:String, camera:Camera3D, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
		_camera = camera;
	}

	public var camera(get,null):Camera3D;
	private function get_camera():Camera3D
	{
		return _camera;
	}

	override public function clone():Event
	{
		return new CameraEvent(type, _camera, bubbles, cancelable);
	}
}
