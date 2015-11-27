package away3d.materials.utils;

import flash.display.Sprite;
import flash.media.SoundTransform;

interface IVideoPlayer
{

	/**
	 * The source, url, to the video file
	 */
	var source(get,set):String;

	/**
	 * Indicates whether the player should loop when video finishes
	 */
	var loop(get,set):Bool;

	/**
	 * Master volume/gain
	 */
	var volume(get,set):Float;

	/**
	 * Panning
	 */
	var pan(get,set):Float;

	/**
	 * Mutes/unmutes the video's audio.
	 */
	var mute(get,set):Bool;

	/**
	 * Provides access to the SoundTransform of the video stream
	 */
	var soundTransform(get,set):SoundTransform;

	/**
	 * Get/Set access to the with of the video object
	 */
	var width(get,set):Int;

	/**
	 * Get/Set access to the height of the video object
	 */
	var height(get,set):Int;

	/**
	 * Provides access to the Video Object
	 */
	var container(get,null):Sprite;

	/**
	 * Indicates whether the video is playing
	 */
	var playing(get,null):Bool;

	/**
	 * Indicates whether the video is paused
	 */
	var paused(get,null):Bool;

	/**
	 * Returns the actual time of the netStream
	 */
	var time(get,null):Float;

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
