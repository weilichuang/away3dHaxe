package a3d.animators.nodes;

import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonBinaryLERPState;

/**
 * A skeleton animation node that uses two animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class SkeletonBinaryLERPNode extends AnimationNodeBase
{
	/**
	 * Defines input node A to use for the blended output.
	 */
	public var inputA:AnimationNodeBase;

	/**
	 * Defines input node B to use for the blended output.
	 */
	public var inputB:AnimationNodeBase;

	/**
	 * Creates a new <code>SkeletonBinaryLERPNode</code> object.
	 */
	public function new()
	{
		_stateClass = SkeletonBinaryLERPState;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonBinaryLERPState
	{
		return animator.getAnimationState(this) as SkeletonBinaryLERPState;
	}
}
