package a3d.animators.states;

import a3d.animators.data.Skeleton;
import a3d.animators.data.SkeletonPose;

interface ISkeletonAnimationState extends IAnimationState
{
	/**
	 * Returns the output skeleton pose of the animation node.
	 */
	function getSkeletonPose(skeleton:Skeleton):SkeletonPose;
}
