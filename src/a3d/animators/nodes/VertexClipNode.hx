package a3d.animators.nodes;

import flash.geom.Vector3D;

import a3d.animators.states.VertexClipState;
import a3d.core.base.Geometry;


/**
 * A vertex animation node containing time-based animation data as individual geometry obejcts.
 */
class VertexClipNode extends AnimationClipNodeBase
{
	private var _frames:Vector<Geometry> = new Vector<Geometry>();
	private var _translations:Vector<Vector3D> = new Vector<Vector3D>();


	/**
	 * Returns a vector of geometry frames representing the vertex values of each animation frame in the clip.
	 */
	private inline function get_frames():Vector<Geometry>
	{
		return _frames;
	}

	/**
	 * Creates a new <code>VertexClipNode</code> object.
	 */
	public function VertexClipNode()
	{
		_stateClass = VertexClipState;
	}


	/**
	 * Adds a geometry object to the internal timeline of the animation node.
	 *
	 * @param geometry The geometry object to add to the timeline of the node.
	 * @param duration The specified duration of the frame in milliseconds.
	 * @param translation The absolute translation of the frame, used in root delta calculations for mesh movement.
	 */
	public function addFrame(geometry:Geometry, duration:UInt, translation:Vector3D = null):Void
	{
		_frames.push(geometry);
		_durations.push(duration);
		_translations.push(translation || new Vector3D());

		_numFrames = _durations.length;

		_stitchDirty = true;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateStitch():Void
	{
		super.updateStitch();

		var i:UInt = _numFrames - 1;
		var p1:Vector3D, p2:Vector3D, delta:Vector3D;
		while (i--)
		{
			_totalDuration += _durations[i];
			p1 = _translations[i];
			p2 = _translations[i + 1];
			delta = p2.subtract(p1);
			_totalDelta.x += delta.x;
			_totalDelta.y += delta.y;
			_totalDelta.z += delta.z;
		}

		if (_numFrames > 1 && (_stitchFinalFrame || !_looping))
		{
			_totalDuration += _durations[_numFrames - 1];
			p1 = _translations[0];
			p2 = _translations[1];
			delta = p2.subtract(p1);
			_totalDelta.x += delta.x;
			_totalDelta.y += delta.y;
			_totalDelta.z += delta.z;
		}
	}
}