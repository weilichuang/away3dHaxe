package a3d.animators.states
{
	import a3d.animators.data.UVAnimationFrame;

	/**
	 * Provides an interface for animation node classes that hold animation data for use in the UV animator class.
	 *
	 * @see a3d.animators.UVAnimator
	 */
	interface IUVAnimationState extends IAnimationState
	{
		/**
		 * Returns the current UV frame of animation in the clip based on the internal playhead position.
		 */
		function get_currentUVFrame():UVAnimationFrame;

		/**
		 * Returns the next UV frame of animation in the clip based on the internal playhead position.
		 */
		function get_nextUVFrame():UVAnimationFrame;

		/**
		 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
		 * between the current uv frame (0) and next uv frame (1) of the animation.
		 */
		function get_blendWeight():Float;
	}
}
