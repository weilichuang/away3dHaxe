package a3d.events;

import flash.events.Event;

import a3d.entities.lenses.LensBase;

class LensEvent extends Event
{
	public static inline var MATRIX_CHANGED:String = "matrixChanged";

	private var _lens:LensBase;

	public function new(type:String, lens:LensBase, bubbles:Bool = false, cancelable:Bool = false)
	{
		super(type, bubbles, cancelable);
		_lens = lens;
	}

	public var lens(get,null):LensBase;
	private inline function get_lens():LensBase
	{
		return _lens;
	}

	override public function clone():Event
	{
		return new LensEvent(type, _lens, bubbles, cancelable);
	}
}
