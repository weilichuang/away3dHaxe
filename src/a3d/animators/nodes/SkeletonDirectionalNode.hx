package a3d.animators.nodes;

import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonDirectionalState;

/**
 * A skeleton animation node that uses four directional input poses with an input direction to blend a linearly interpolated output of a skeleton pose.
 */
class SkeletonDirectionalNode extends AnimationNodeBase
{
	/**
	 * Defines the forward configured input node to use for the blended output.
	 */
	public var forward:AnimationNodeBase;

	/**
	 * Defines the backwards configured input node to use for the blended output.
	 */
	public var backward:AnimationNodeBase;

	/**
	 * Defines the left configured input node to use for the blended output.
	 */
	public var left:AnimationNodeBase;

	/**
	 * Defines the right configured input node to use for the blended output.
	 */
	public var right:AnimationNodeBase;

	public function new()
	{
		super();
		_stateClass = SkeletonDirectionalState;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonDirectionalState
	{
		return Std.instance(animator.getAnimationState(this),SkeletonDirectionalState);
	}

}
