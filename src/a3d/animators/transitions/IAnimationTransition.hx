package a3d.animators.transitions;

import a3d.animators.IAnimator;
import a3d.animators.nodes.AnimationNodeBase;

interface IAnimationTransition
{
	function getAnimationNode(animator:IAnimator, startNode:AnimationNodeBase, endNode:AnimationNodeBase, startTime:Int):AnimationNodeBase
}

