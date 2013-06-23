package a3d.animators.states
{
	import a3d.animators.data.SpriteSheetAnimationFrame;

	/**
	 * Provides an interface for animation node classes that hold animation data for use in the SpriteSheetAnimator class.
	 *
	 * @see a3d.animators.SpriteSheetAnimator
	 */
	interface ISpriteSheetAnimationState extends IAnimationState
	{
		/**
		 * Returns the current SpriteSheetAnimationFrame of animation in the clip based on the internal playhead position.
		 */
		function get_currentFrameData():SpriteSheetAnimationFrame;

		/**
		 * Returns the current frame number.
		 */
		function get_currentFrameNumber():UInt;

	}
}
