package a3d.materials.utils;

import flash.display.Sprite;
import flash.media.SoundTransform;

interface IVideoPlayer
{

	/**
	 * The source, url, to the video file
	 */
	function get_source():String;
	function set_source(src:String):Void;

	/**
	 * Indicates whether the player should loop when video finishes
	 */
	function get_loop():Bool;
	function set_loop(val:Bool):Void;

	/**
	 * Master volume/gain
	 */
	function get_volume():Float;
	function set_volume(val:Float):Void;

	/**
	 * Panning
	 */
	function get_pan():Float;
	function set_pan(val:Float):Void;

	/**
	 * Mutes/unmutes the video's audio.
	 */
	function get_mute():Bool;
	function set_mute(val:Bool):Void;

	/**
	 * Provides access to the SoundTransform of the video stream
	 */
	function get_soundTransform():SoundTransform;
	function set_soundTransform(val:SoundTransform):Void;

	/**
	 * Get/Set access to the with of the video object
	 */
	function get_width():Int;
	function set_width(val:Int):Void;

	/**
	 * Get/Set access to the height of the video object
	 */
	function get_height():Int;
	function set_height(val:Int):Void;

	/**
	 * Provides access to the Video Object
	 */
	function get_container():Sprite;

	/**
	 * Indicates whether the video is playing
	 */
	function get_playing():Bool;

	/**
	 * Indicates whether the video is paused
	 */
	function get_paused():Bool;

	/**
	 * Returns the actual time of the netStream
	 */
	function get_time():Float;

	/**
	 * Start playing (or resume if paused) the video.
	 */
	function play():Void;

	/**
	 * Temporarily pause playback. Resume using play().
	 */
	function pause():Void;

	/**
	 *  Seeks to a given time in the video, specified in seconds, with a precision of three decimal places (milliseconds).
	 */
	function seek(val:Float):Void;

	/**
	 * Stop playback and reset playhead.
	 */
	function stop():Void;

	/**
	 * Called if the player is no longer needed
	 */
	function dispose():Void;


}
