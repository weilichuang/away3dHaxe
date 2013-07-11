package a3d.animators.transitions;

import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonBinaryLERPState;
import a3d.events.AnimationStateEvent;

/**
 *
 */
class CrossfadeTransitionState extends SkeletonBinaryLERPState
{
	private var _crossfadeTransitionNode:CrossfadeTransitionNode;
	private var _animationStateTransitionComplete:AnimationStateEvent;

	public function new(animator:IAnimator, skeletonAnimationNode:CrossfadeTransitionNode)
	{
		super(animator, skeletonAnimationNode);

		_crossfadeTransitionNode = skeletonAnimationNode;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		blendWeight = Math.abs(time - _crossfadeTransitionNode.startBlend) / (1000 * _crossfadeTransitionNode.blendSpeed);

		if (blendWeight >= 1)
		{
			blendWeight = 1;
			if (_animationStateTransitionComplete == null)
				_animationStateTransitionComplete = new AnimationStateEvent(AnimationStateEvent.TRANSITION_COMPLETE, _animator, this, _skeletonAnimationNode);
			_crossfadeTransitionNode.dispatchEvent(_animationStateTransitionComplete);
		}

		super.updateTime(time);
	}
}
