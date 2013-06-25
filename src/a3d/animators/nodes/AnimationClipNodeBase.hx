package a3d.animators.nodes;

import flash.geom.Vector3D;

/**
 * Provides an abstract base class for nodes with time-based animation data in an animation blend tree.
 */
class AnimationClipNodeBase extends AnimationNodeBase
{
	private var _looping:Bool = true;
	private var _totalDuration:UInt = 0;
	private var _lastFrame:UInt;

	private var _stitchDirty:Bool = true;
	private var _stitchFinalFrame:Bool = false;
	private var _numFrames:UInt = 0;

	private var _durations:Vector<UInt> = new Vector<UInt>();
	private var _totalDelta:Vector3D = new Vector3D();

	public var fixedFrameRate:Bool = true;

	/**
	 * Determines whether the contents of the animation node have looping characteristics enabled.
	 */
	private inline function get_looping():Bool
	{
		return _looping;
	}

	private inline function set_looping(value:Bool):Void
	{
		if (_looping == value)
			return;

		_looping = value;

		_stitchDirty = true;
	}

	/**
	 * Defines if looping content blends the final frame of animation data with the first (true) or works on the
	 * assumption that both first and last frames are identical (false). Defaults to false.
	 */
	private inline function get_stitchFinalFrame():Bool
	{
		return _stitchFinalFrame;
	}

	private inline function set_stitchFinalFrame(value:Bool):Void
	{
		if (_stitchFinalFrame == value)
			return;

		_stitchFinalFrame = value;

		_stitchDirty = true;
	}

	private inline function get_totalDuration():UInt
	{
		if (_stitchDirty)
			updateStitch();

		return _totalDuration;
	}

	private inline function get_totalDelta():Vector3D
	{
		if (_stitchDirty)
			updateStitch();

		return _totalDelta;
	}

	private inline function get_lastFrame():UInt
	{
		if (_stitchDirty)
			updateStitch();

		return _lastFrame;
	}

	/**
	 * Returns a vector of time values representing the duration (in milliseconds) of each animation frame in the clip.
	 */
	private inline function get_durations():Vector<UInt>
	{
		return _durations;
	}

	/**
	 * Creates a new <code>AnimationClipNodeBase</code> object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * Updates the node's final frame stitch state.
	 *
	 * @see #stitchFinalFrame
	 */
	private function updateStitch():Void
	{
		_stitchDirty = false;

		_lastFrame = (_stitchFinalFrame) ? _numFrames : _numFrames - 1;

		_totalDuration = 0;
		_totalDelta.x = 0;
		_totalDelta.y = 0;
		_totalDelta.z = 0;
	}
}
