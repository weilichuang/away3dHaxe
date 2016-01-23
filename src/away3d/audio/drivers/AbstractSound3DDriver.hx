package away3d.audio.drivers;

import flash.events.EventDispatcher;
import flash.geom.Vector3D;
import flash.media.Sound;

class AbstractSound3DDriver extends EventDispatcher
{
	public var sourceSound(get, set):Sound;

	public var volume(get, set):Float;

	public var scale(get, set):Float;
	
	public var mute(get, set):Bool;
	
	private var _ref_v:Vector3D;
	private var _src:Sound;
	private var _volume:Float;
	private var _scale:Float;

	private var _mute:Bool;
	private var _paused:Bool;
	private var _playing:Bool;


	public function new()
	{
		super();
		_volume = 1;
		_scale = 1000;
		_playing = false;
	}

	
	private function get_sourceSound():Sound
	{
		return _src;
	}

	private function set_sourceSound(val:Sound):Sound
	{
		if (_src == val)
			return _src;

		return _src = val;
	}


	
	private function get_volume():Float
	{
		return _volume;
	}

	private function set_volume(val:Float):Float
	{
		return _volume = val;
	}
	
	
	private function get_scale():Float
	{
		return _scale;
	}

	private function set_scale(val:Float):Float
	{
		return _scale = val;
	}

	
	private function get_mute():Bool
	{
		return _mute;
	}

	private function set_mute(val:Bool):Bool
	{
		if (_mute == val)
			return val;

		return _mute = val;
	}



	public function updateReferenceVector(v:Vector3D):Void
	{
		this._ref_v = v;
	}
}
