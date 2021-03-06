package a3d.audio;

import flash.events.Event;
import flash.geom.Vector3D;
import flash.Lib;
import flash.media.Sound;

import a3d.audio.drivers.ISound3DDriver;
import a3d.audio.drivers.SimplePanVolumeDriver;
import a3d.entities.ObjectContainer3D;
import a3d.events.Object3DEvent;

/**
 * Dispatched when end of sound stream is reached (bubbled from the internal sound object).
 */
@:meta(Event(name = "soundComplete", type = "flash.events.Event"))

/**
 * <p>A sound source/emitter object that can be positioned in 3D space, and from which all audio
 * playback will be transformed to simulate orientation.</p>
 *
 * <p>The Sound3D object works much in the same fashion as primitives, lights and cameras, in that
 * it can be added to a scene and positioned therein. It is the main object, in the 3D sound API,
 * which the programmer will interact with.</p>
 *
 * <p>Actual sound transformation is performed by a driver object, which is defined at the time of
 * creation by the driver ini variable, the default being a simple pan/volume driver.</p>
 *
 * @see SimplePanVolumeDriver
*/
class Sound3D extends ObjectContainer3D
{
	/**
	 * Defines the overall (master) volume of the 3D sound, after any
	 * positional adjustments to volume have been applied. This value can
	 * equally well be cotrolled by modifying the volume property on the
	 * driver used by this Sound3D instance.
	 *
	 * @see ISound3DDriver.volume
	*/
	public var volume(get, set):Float;
	/**
	 * Defines a scale value used by the driver when adjusting sound
	 * intensity to simulate distance. The default number of 1000 means
	 * that sound volume will near the hearing threshold as the distance
	 * between listener and sound source approaches 1000 a3d units.
	 *
	 * @see ISound3DDriver.scale
	*/
	public var scaleDistance(get, set):Float;
	/**
	 * Returns a Bool indicating whether or not the sound is currently
	 * playing.
	*/
	public var playing(get, null):Float;
	/**
	 * Returns a Bool indicating whether or not playback is currently
	 * paused.
	*/
	public var paused(get, null):Float;
	
	private var _refv:Vector3D;
	private var _driver:ISound3DDriver;
	private var _reference:ObjectContainer3D;
	private var _sound:Sound;

	private var _paused:Bool;
	private var _playing:Bool;



	/**
	 * Create a Sound3D object, representing the sound source used for playback of a flash Sound object.
	 *
	 * @param sound 		The flash Sound object that is played back from this Sound3D object's position.
	 * For realistic results, this should be a <em>mono</em> (single-channel, non-stereo) sound stream.
	 * @param reference 	The reference, or "listener" object, typically a camera.
	 * @param driver		Sound3D driver to use when applying simulation effects. Defaults to SimplePanVolumeDriver.
	 * @param init 			[optional] An initialisation object for specifying default instance properties.
	*/
	public function new(sound:Sound, reference:ObjectContainer3D, driver:ISound3DDriver = null, volume:Float = 1, scale:Float = 1000)
	{
		super();

		_sound = sound;
		_reference = reference;
		if (driver == null)
			driver = new SimplePanVolumeDriver();
		_driver = driver; 
		_driver.sourceSound = _sound;
		_driver.volume = volume;
		_driver.scale = scale;
		_driver.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);

		addEventListener(Object3DEvent.SCENE_CHANGED, onSceneChanged);
		addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onSceneTransformChanged);
		_reference.addEventListener(Object3DEvent.SCENETRANSFORM_CHANGED, onSceneTransformChanged);
	}

	
	private function get_volume():Float
	{
		return _driver.volume;
	}

	private function set_volume(val:Float):Float
	{
		return _driver.volume = val;
	}



	
	private function get_scaleDistance():Float
	{
		return _driver.scale;
	}

	private function set_scaleDistance(val:Float):Float
	{
		return _driver.scale = val;
	}


	
	private function get_playing():Bool
	{
		return _playing;
	}


	
	private function get_paused():Bool
	{
		return _paused;
	}


	/**
	 * Start (or resume, if paused) playback.
	*/
	public function play():Void
	{
		_playing = true;
		_paused = false;
		_driver.play();
	}


	/**
	 * Pause playback. Resume using play().
	*/
	public function pause():Void
	{
		_playing = false;
		_paused = true;
		_driver.pause();
	}


	/**
	 * Stop and rewind sound file. Replay (from the beginning) using play().
	 * To temporarily pause playback, allowing you to resume from the same point,
	 * use pause() instead.
	 *
	 * @see pause()
	*/
	public function stop():Void
	{
		_playing = false;
		_paused = false;
		_driver.stop();
	}



	/**
	 * Alternate between pausing and resuming playback of this sound. If called
	 * while sound is paused (or stopped), this will resume playback. When
	 * called during playback, it will pause it.
	*/
	public function togglePlayPause():Void
	{
		if (_playing)
			this.pause();
		else
			this.play();
	}




	/**
	 * @internal
	 * When scene changes, mute if object was removed from scene.
	*/
	private function onSceneChanged(ev:Object3DEvent):Void
	{
		Lib.trace('scene changed');
		// mute driver if there is no scene available, i.e. when the
		// sound3d object has been removed from the scene
		_driver.mute = (_scene == null);

		// Force update
		update();

		// Re-update reference vector to force changes to take effect
		_driver.updateReferenceVector(_refv);
	}

	/**
	 * @internal
	 * When scene transform changes, calculate the relative vector between the listener/reference object
	 * and the position of this sound source, and update the driver to use
	 * this as the reference vector.
	 */
	private function update():Void
	{
		// Transform sound position into local space of the reference object ("listener").
		_refv = _reference.inverseSceneTransform.transformVector(sceneTransform.position);
		_driver.updateReferenceVector(_refv);
	}

	private function onSceneTransformChanged(ev:Object3DEvent):Void
	{
		update();
	}


	private function onSoundComplete(ev:Event):Void
	{
		dispatchEvent(ev.clone());
	}
}
