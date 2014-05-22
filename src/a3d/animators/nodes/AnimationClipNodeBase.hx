package a3d.animators.nodes;

import flash.geom.Vector3D;
import flash.Vector;

/**
 * Provides an abstract base class for nodes with time-based animation data in an animation blend tree.
 */
class AnimationClipNodeBase extends AnimationNodeBase
{
	/**
	 * Determines whether the contents of the animation node have looping characteristics enabled.
	 */
	public var looping(get, set):Bool;
	/**
	 * Defines if looping content blends the final frame of animation data with the first (true) or works on the
	 * assumption that both first and last frames are identical (false). Defaults to false.
	 */
	public var stitchFinalFrame(get, set):Bool;
	public var totalDuration(get, null):Int;
	public var totalDelta(get, null):Vector3D;
	public var lastFrame(get, null):Int;
	/**
	 * Returns a vector of time values representing the duration (in milliseconds) of each animation frame in the clip.
	 */
	public var durations(get, null):Vector<UInt>;
	
	private var _looping:Bool = true;
	private var _totalDuration:Int = 0;
	private var _lastFrame:Int;

	private var _stitchDirty:Bool = true;
	private var _stitchFinalFrame:Bool = false;
	private var _numFrames:Int = 0;

	private var _durations:Vector<UInt>;
	private var _totalDelta:Vector3D;

	public var fixedFrameRate:Bool = true;

	

	/**
	 * Creates a new <code>AnimationClipNodeBase</code> object.
	 */
	public function new()
	{
		super();
		_durations = new Vector<UInt>();
		_totalDelta = new Vector3D();
	}
	
	
	private function get_looping():Bool
	{
		return _looping;
	}

	private function set_looping(value:Bool):Bool
	{
		if (_looping == value)
			return _looping;

		_looping = value;

		_stitchDirty = true;
		
		return _looping;
	}

	
	private function get_stitchFinalFrame():Bool
	{
		return _stitchFinalFrame;
	}

	private function set_stitchFinalFrame(value:Bool):Bool
	{
		if (_stitchFinalFrame == value)
			return _stitchFinalFrame;

		_stitchFinalFrame = value;

		_stitchDirty = true;
		
		return _stitchFinalFrame;
	}

	
	private function get_totalDuration():Int
	{
		if (_stitchDirty)
			updateStitch();

		return _totalDuration;
	}

	
	private function get_totalDelta():Vector3D
	{
		if (_stitchDirty)
			updateStitch();

		return _totalDelta;
	}

	
	private function get_lastFrame():Int
	{
		if (_stitchDirty)
			updateStitch();

		return _lastFrame;
	}

	
	private function get_durations():Vector<UInt>
	{
		return _durations;
	}

	/**
	 * Updates the node's final frame stitch state.
	 *
	 * @see #stitchFinalFrame
	 */
	private function updateStitch():Void
	{
		_stitchDirty = false;

		_lastFrame = (_looping && _stitchFinalFrame) ? _numFrames : _numFrames - 1;

		_totalDuration = 0;
		_totalDelta.x = 0;
		_totalDelta.y = 0;
		_totalDelta.z = 0;
	}
}
