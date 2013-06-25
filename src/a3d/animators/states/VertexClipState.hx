package a3d.animators.states;

import a3d.animators.IAnimator;
import a3d.animators.VertexAnimator;
import a3d.animators.nodes.VertexClipNode;
import a3d.core.base.Geometry;

/**
 *
 */
class VertexClipState extends AnimationClipState implements IVertexAnimationState
{
	private var _frames:Vector<Geometry>;
	private var _vertexClipNode:VertexClipNode;
	private var _currentGeometry:Geometry;
	private var _nextGeometry:Geometry;

	/**
	 * @inheritDoc
	 */
	private inline function get_currentGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();

		return _currentGeometry;
	}

	/**
	 * @inheritDoc
	 */
	private inline function get_nextGeometry():Geometry
	{
		if (_framesDirty)
			updateFrames();

		return _nextGeometry;
	}

	public function new(animator:IAnimator, vertexClipNode:VertexClipNode)
	{
		super(animator, vertexClipNode);

		_vertexClipNode = vertexClipNode;
		_frames = _vertexClipNode.frames;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateFrames():Void
	{
		super.updateFrames();

		_currentGeometry = _frames[_currentFrame];

		if (_vertexClipNode.looping && _nextFrame >= _vertexClipNode.lastFrame)
		{
			_nextGeometry = _frames[0];
			VertexAnimator(_animator).dispatchCycleEvent();
		}
		else
		{
			_nextGeometry = _frames[_nextFrame];
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		//TODO:implement positiondelta functionality for vertex animations
	}
}
