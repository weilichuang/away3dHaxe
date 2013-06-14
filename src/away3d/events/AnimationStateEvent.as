package away3d.events
{
	import flash.events.Event;
	
	import away3d.animators.IAnimator;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.animators.states.IAnimationState;

	/**
	 * Dispatched to notify changes in an animation state's state.
	 */
	public class AnimationStateEvent extends Event
	{
		/**
		 * Dispatched when a non-looping clip node inside an animation state reaches the end of its timeline.
		 */
		public static const PLAYBACK_COMPLETE:String = "playbackComplete";

		public static const TRANSITION_COMPLETE:String = "transitionComplete";

		private var _animator:IAnimator;
		private var _animationState:IAnimationState;
		private var _animationNode:AnimationNodeBase;

		/**
		 * Create a new <code>AnimatonStateEvent</code>
		 *
		 * @param type The event type.
		 * @param animator The animation state object that is the subject of this event.
		 * @param animationNode The animation node inside the animation state from which the event originated.
		 */
		public function AnimationStateEvent(type:String, animator:IAnimator, animationState:IAnimationState, animationNode:AnimationNodeBase):void
		{
			super(type, false, false);

			_animator = animator;
			_animationState = animationState;
			_animationNode = animationNode;
		}

		/**
		 * The animator object that is the subject of this event.
		 */
		public function get animator():IAnimator
		{
			return _animator;
		}

		/**
		 * The animation state object that is the subject of this event.
		 */
		public function get animationState():IAnimationState
		{
			return _animationState;
		}

		/**
		 * The animation node inside the animation state from which the event originated.
		 */
		public function get animationNode():AnimationNodeBase
		{
			return _animationNode;
		}

		/**
		 * Clones the event.
		 *
		 * @return An exact duplicate of the current object.
		 */
		override public function clone():Event
		{
			return new AnimationStateEvent(type, _animator, _animationState, _animationNode);
		}
	}
}
