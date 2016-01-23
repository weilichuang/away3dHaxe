package away3d.animators;

import away3d.animators.nodes.AnimationNodeBase;
import away3d.animators.states.AnimationStateBase;
import away3d.animators.states.IAnimationState;
import away3d.entities.Mesh;
import away3d.events.AnimatorEvent;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.Lib;
import flash.Vector;
import haxe.ds.WeakMap;





/**
 * Dispatched when playback of an animation inside the animator object starts.
 *
 * @eventType away3d.events.AnimatorEvent
 */
@:meta(Event(name = "start", type = "away3d.events.AnimatorEvent"))

/**
 * Dispatched when playback of an animation inside the animator object stops.
 *
 * @eventType away3d.events.AnimatorEvent
 */
@:meta(Event(name = "stop", type = "away3d.events.AnimatorEvent"))

/**
 * Dispatched when playback of an animation reaches the end of an animation.
 *
 * @eventType away3d.events.AnimatorEvent
 */
@:meta(Event(name = "cycle_complete", type = "away3d.events.AnimatorEvent"))

/**
 * Provides an abstract base class for animator classes that control animation output from a data set subtype of <code>AnimationSetBase</code>.
 *
 * @see away3d.animators.AnimationSetBase
 */
class AnimatorBase extends NamedAssetBase implements IAsset
{
	/**
	 * Returns the internal absolute time of the animator, calculated by the current time and the playback speed.
	 *
	 * @see #time
	 * @see #playbackSpeed
	 */
	public var absoluteTime(get, null):Float;
	/**
	 * Returns the animation data set in use by the animator.
	 */
	public var animationSet(get, null):IAnimationSet;
	/**
	 * Returns the current active animation state.
	 */
	public var activeState(get, null):IAnimationState;
	/**
	 * Returns the current active animation node.
	 */
	public var activeAnimation(get, null):AnimationNodeBase;
	/**
	 * Returns the current active animation node.
	 */
	public var activeAnimationName(get, null):String;
	/**
	 * Determines whether the animators internal update mechanisms are active. Used in cases
	 * where manual updates are required either via the <code>time</code> property or <code>update()</code> method.
	 * Defaults to true.
	 *
	 * @see #time
	 * @see #update()
	 */
	public var autoUpdate(get, set):Bool;
	/**
	 * Gets and sets the internal time clock of the animator.
	 */
	public var time(get, set):Int;
	
	/**
	 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
	 */
	public var playbackSpeed(get, set):Float;
	/**
	 * @inheritDoc
	 */
	public var assetType(get, null):String;
	
	private var _broadcaster:Sprite;
	private var _isPlaying:Bool;
	private var _autoUpdate:Bool = true;
	private var _startEvent:AnimatorEvent;
	private var _stopEvent:AnimatorEvent;
	private var _cycleEvent:AnimatorEvent;
	private var _time:Int;
	private var _playbackSpeed:Float = 1;

	private var _animationSet:IAnimationSet;
	private var _owners:Vector<Mesh>;
	private var _activeNode:AnimationNodeBase;
	private var _activeState:IAnimationState;
	private var _activeAnimationName:String;
	private var _absoluteTime:Float = 0;
	private var _animationStates:WeakMap<AnimationNodeBase,AnimationStateBase>;

	/**
	 * Enables translation of the animated mesh from data returned per frame via the positionDelta property of the active animation node. Defaults to true.
	 *
	 * @see away3d.animators.states.IAnimationState#positionDelta
	 */
	public var updatePosition:Bool = true;

	public function getAnimationState(node:AnimationNodeBase):AnimationStateBase
	{
		var className:Dynamic = node.stateClass;

		if (!_animationStates.exists(node))
			_animationStates.set(node,Std.instance(Type.createInstance(className, [this, node]),AnimationStateBase));
		return _animationStates.get(node);
	}

	public function getAnimationStateByName(name:String):AnimationStateBase
	{
		return getAnimationState(_animationSet.getAnimation(name));
	}

	
	private function get_absoluteTime():Float
	{
		return _absoluteTime;
	}

	
	private function get_animationSet():IAnimationSet
	{
		return _animationSet;
	}

	
	private function get_activeState():IAnimationState
	{
		return _activeState;
	}

	
	private function get_activeAnimation():AnimationNodeBase
	{
		return _animationSet.getAnimation(_activeAnimationName);
	}

	
	private function get_activeAnimationName():String
	{
		return _activeAnimationName;
	}

	
	private function get_autoUpdate():Bool
	{
		return _autoUpdate;
	}

	private function set_autoUpdate(value:Bool):Bool
	{
		if (_autoUpdate == value)
			return _autoUpdate;

		_autoUpdate = value;

		if (_autoUpdate)
			start();
		else
			stop();
			
		return _autoUpdate;
	}

	
	private function get_time():Int
	{
		return _time;
	}

	private function set_time(value:Int):Int
	{
		if (_time == value)
			return _time;

		update(value);
		
		return _time;
	}

	/**
	 * Sets the animation phase of the current active state's animation clip(s).
	 *
	 * @param value The phase value to use. 0 represents the beginning of an animation clip, 1 represents the end.
	 */
	public function phase(value:Float):Void
	{
		_activeState.phase(value);
	}

	/**
	 * Creates a new <code>AnimatorBase</code> object.
	 *
	 * @param animationSet The animation data set to be used by the animator object.
	 */
	public function new(animationSet:IAnimationSet)
	{
		super();
		_animationSet = animationSet;
		
		_owners = new Vector<Mesh>();
		_animationStates = new WeakMap<AnimationNodeBase,AnimationStateBase>();
		_broadcaster = new Sprite();
	}

	
	private function get_playbackSpeed():Float
	{
		return _playbackSpeed;
	}

	private function set_playbackSpeed(value:Float):Float
	{
		return _playbackSpeed = value;
	}

	/**
	 * Resumes the automatic playback clock controling the active state of the animator.
	 */
	public function start():Void
	{
		if (_isPlaying || !_autoUpdate)
			return;

		_time = Lib.getTimer();
		_absoluteTime = _time;

		_isPlaying = true;

		if (!_broadcaster.hasEventListener(Event.ENTER_FRAME))
			_broadcaster.addEventListener(Event.ENTER_FRAME, onEnterFrame);

		if (!hasEventListener(AnimatorEvent.START))
			return;

		if (_startEvent == null)
			_startEvent = new AnimatorEvent(AnimatorEvent.START, this);
		dispatchEvent(_startEvent);
	}

	/**
	 * Pauses the automatic playback clock of the animator, in case manual updates are required via the
	 * <code>time</code> property or <code>update()</code> method.
	 *
	 * @see #time
	 * @see #update()
	 */
	public function stop():Void
	{
		if (!_isPlaying)
			return;

		_isPlaying = false;

		if (_broadcaster.hasEventListener(Event.ENTER_FRAME))
			_broadcaster.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

		if (!hasEventListener(AnimatorEvent.STOP))
			return;

		if (_stopEvent == null)
			_stopEvent = new AnimatorEvent(AnimatorEvent.STOP, this);
		dispatchEvent(_stopEvent);
	}

	/**
	 * Provides a way to manually update the active state of the animator when automatic
	 * updates are disabled.
	 *
	 * @see #stop()
	 * @see #autoUpdate
	 */
	public function update(time:Int):Void
	{
		var dt:Float = (time - _time) * playbackSpeed;

		updateDeltaTime(dt);

		_time = time;
	}

	public function reset(name:String, offset:Float = 0):Void
	{
		getAnimationState(_animationSet.getAnimation(name)).offset(Std.int(offset + _absoluteTime));
	}

	/**
	 * Used by the mesh object to which the animator is applied, registers the owner for internal use.
	 *
	 * @private
	 */
	public function addOwner(mesh:Mesh):Void
	{
		_owners.push(mesh);
	}

	/**
	 * Used by the mesh object from which the animator is removed, unregisters the owner for internal use.
	 *
	 * @private
	 */
	public function removeOwner(mesh:Mesh):Void
	{
		_owners.splice(_owners.indexOf(mesh), 1);
	}

	/**
	 * Internal abstract method called when the time delta property of the animator's contents requires updating.
	 *
	 * @private
	 */
	private function updateDeltaTime(dt:Float):Void
	{
		_absoluteTime += dt;

		_activeState.update(Std.int(_absoluteTime));

		if (updatePosition)
			applyPositionDelta();
	}

	/**
	 * Enter frame event handler for automatically updating the active state of the animator.
	 */
	private function onEnterFrame(event:Event = null):Void
	{
		update(Lib.getTimer());
	}

	private function applyPositionDelta():Void
	{
		var delta:Vector3D = _activeState.positionDelta;
		var dist:Float = delta.length;
		var len:Int;
		if (dist > 0)
		{
			len = _owners.length;
			for (i in 0...len)
				_owners[i].translateLocal(delta, dist);
		}
	}

	/**
	 *  for internal use.
	 *
	 * @private
	 */
	public function dispatchCycleEvent():Void
	{
		if (hasEventListener(AnimatorEvent.CYCLE_COMPLETE))
		{
			if (_cycleEvent == null)
				_cycleEvent = new AnimatorEvent(AnimatorEvent.CYCLE_COMPLETE, this);
			dispatchEvent(_cycleEvent);
		}
	}

	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
	}

	
	private function get_assetType():String
	{
		return AssetType.ANIMATOR;
	}
}
