package a3d.events;

import flash.events.Event;

import a3d.animators.IAnimator;
import a3d.animators.nodes.AnimationNodeBase;
import a3d.animators.states.IAnimationState;

/**
 * Dispatched to notify changes in an animation state's state.
 */
class AnimationStateEvent extends Event
{
	/**
	 * Dispatched when a non-looping clip node inside an animation state reaches the end of its timeline.
	 */
	public static inline var PLAYBACK_COMPLETE:String = "playbackComplete";

	public static inline var TRANSITION_COMPLETE:String = "transitionComplete";

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
	public function new(type:String, animator:IAnimator, animationState:IAnimationState, animationNode:AnimationNodeBase):Void
	{
		super(type, false, false);

		_animator = animator;
		_animationState = animationState;
		_animationNode = animationNode;
	}

	/**
	 * The animator object that is the subject of this event.
	 */
	public var animator(get,null):IAnimator;
	private function get_animator():IAnimator
	{
		return _animator;
	}

	/**
	 * The animation state object that is the subject of this event.
	 */
	public var animationState(get,null):IAnimationState;
	private function get_animationState():IAnimationState
	{
		return _animationState;
	}

	/**
	 * The animation node inside the animation state from which the event originated.
	 */
	public var animationNode(get,null):AnimationNodeBase;
	private function get_animationNode():AnimationNodeBase
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
