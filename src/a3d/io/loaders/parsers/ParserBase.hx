package a3d.io.loaders.parsers;

import a3d.errors.AbstractMethodError;
import a3d.events.AssetEvent;
import a3d.events.ParserEvent;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.loaders.misc.ResourceDependency;
import a3d.io.loaders.parsers.utils.ParserUtil;
import a3d.tools.utils.TextureUtils;
import flash.display.BitmapData;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.getTimer;
import flash.utils.Timer;



/**
 * Dispatched when the parsing finishes.
 *
 * @eventType away3d.events.ParserEvent
 */
@:meta(Eventname = "parseComplete", type = "a3d.events.ParserEvent"))

/**
 * Dispatched when parser pauses to wait for dependencies, used internally to trigger
 * loading of dependencies which are then returned to the parser through it's interface
 * in the arcane namespace.
 *
 * @eventType away3d.events.ParserEvent
 */
@:meta(Eventname = "readyForDependencies", type = "a3d.events.ParserEvent"))

/**
 * Dispatched if an error was caught during parsing.
 *
 * @eventType away3d.events.ParserEvent
 */
@:meta(Eventname = "parseError", type = "a3d.events.ParserEvent"))

/**
 * Dispatched when any asset finishes parsing. Also see specific events for each
 * individual asset type (meshes, materials et c.)
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "assetComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a geometry asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "geometryComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a skeleton asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a skeleton pose asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonPoseComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a container asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "containerComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when an animation set has been constructed from a group of animation state resources.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "animationSetComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when an animation state has been constructed from a group of animation node resources.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "animationStateComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when an animation node has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "animationNodeComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "stateTransitionComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a texture asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "textureComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a material asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "materialComplete", type = "a3d.events.AssetEvent"))

/**
 * Dispatched when a animator asset has been constructed from a resource.
 *
 * @eventType away3d.events.AssetEvent
 */
@:meta(Eventname = "animatorComplete", type = "a3d.events.AssetEvent"))



/**
 * <code>ParserBase</code> provides an abstract base class for objects that convert blocks of data to data structures
 * supported by Away3D.
 *
 * If used by <code>AssetLoader</code> to automatically determine the parser type, two static public methods should
 * be implemented, with the following signatures:
 *
 * <code>public static function supportsType(extension : String) : Boolean</code>
 * Indicates whether or not a given file extension is supported by the parser.
 *
 * <code>public static function supportsData(data : *) : Boolean</code>
 * Tests whether a data block can be parsed by the parser.
 *
 * Furthermore, for any concrete subtype, the method <code>initHandle</code> should be overridden to immediately
 * create the object that will contain the parsed data. This allows <code>ResourceManager</code> to return an object
 * handle regardless of whether the object was loaded or not.
 *
 * @see away3d.loading.parsers.AssetLoader
 * @see away3d.loading.ResourceManager
 */
class ParserBase extends EventDispatcher
{
	public var fileName:String;
	protected var _dataFormat:String;
	protected var _data:*;
	protected var _frameLimit:Float;
	protected var _lastFrameTime:Float;

	protected function getTextData():String
	{
		return ParserUtil.toString(_data);
	}

	protected function getByteData():ByteArray
	{
		return ParserUtil.toByteArray(_data);
	}

	private var _dependencies:Vector<ResourceDependency>;
	private var _parsingPaused:Bool;
	private var _parsingComplete:Bool;
	private var _parsingFailure:Bool;
	private var _timer:Timer;
	private var _materialMode:UInt;

	/**
	 * Returned by <code>proceedParsing</code> to indicate no more parsing is needed.
	 */
	protected static const PARSING_DONE:Bool = true;

	/**
	 * Returned by <code>proceedParsing</code> to indicate more parsing is needed, allowing asynchronous parsing.
	 */
	protected static const MORE_TO_PARSE:Bool = false;


	/**
	 * Creates a new ParserBase object
	 * @param format The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>, and should be provided by the concrete subtype.
	 *
	 * @see away3d.loading.parsers.ParserDataFormat
	 */
	public function ParserBase(format:String)
	{
		_materialMode = 0;
		_dataFormat = format;
		_dependencies = new Vector<ResourceDependency>();
	}

	/**
	 * Validates a bitmapData loaded before assigning to a default BitmapMaterial
	 */
	public function isBitmapDataValid(bitmapData:BitmapData):Bool
	{
		var isValid:Bool = TextureUtils.isBitmapDataValid(bitmapData);
		if (!isValid)
			trace(">> Bitmap loaded is not having power of 2 dimensions or is higher than 2048");

		return isValid;
	}

	public function set parsingFailure(b:Bool):Void
	{
		_parsingFailure = b;
	}

	public function get parsingFailure():Bool
	{
		return _parsingFailure;
	}


	public function get parsingPaused():Bool
	{
		return _parsingPaused;
	}


	public function get parsingComplete():Bool
	{
		return _parsingComplete;
	}

	public function set materialMode(newMaterialMode:UInt):Void
	{
		_materialMode = newMaterialMode;
	}

	public function get materialMode():UInt
	{
		return _materialMode;
	}

	/**
	 * The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>.
	 */
	public function get dataFormat():String
	{
		return _dataFormat;
	}

	/**
	 * Parse data (possibly containing bytearry, plain text or BitmapAsset) asynchronously, meaning that
	 * the parser will periodically stop parsing so that the AVM may proceed to the
	 * next frame.
	 *
	 * @param data The untyped data object in which the loaded data resides.
	 * @param frameLimit number of milliseconds of parsing allowed per frame. The
	 * actual time spent on a frame can exceed this number since time-checks can
	 * only be performed between logical sections of the parsing procedure.
	 */
	public function parseAsync(data:*, frameLimit:Float = 30):Void
	{
		_data = data;
		startParsing(frameLimit);
	}

	/**
	 * A list of dependencies that need to be loaded and resolved for the object being parsed.
	 */
	public function get dependencies():Vector<ResourceDependency>
	{
		return _dependencies;
	}

	/**
	 * Resolve a dependency when it's loaded. For example, a dependency containing an ImageResource would be assigned
	 * to a Mesh instance as a BitmapMaterial, a scene graph object would be added to its intended parent. The
	 * dependency should be a member of the dependencies property.
	 *
	 * @param resourceDependency The dependency to be resolved.
	 */
	public function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * Resolve a dependency loading failure. Used by parser to eventually provide a default map
	 *
	 * @param resourceDependency The dependency to be resolved.
	 */
	public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		throw new AbstractMethodError();
	}

	/**
	 * Resolve a dependency name
	 *
	 * @param resourceDependency The dependency to be resolved.
	 */
	public function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
	{
		return asset.name;
	}

	public function resumeParsingAfterDependencies():Void
	{
		_parsingPaused = false;
		if (_timer)
		{
			_timer.start();
		}
	}



	protected function finalizeAsset(asset:IAsset, name:String = null):Void
	{
		var type_event:String;
		var type_name:String;

		if (name != null)
			asset.name = name;

		switch (asset.assetType)
		{
			case AssetType.LIGHT_PICKER:
				type_name = 'lightPicker';
				type_event = AssetEvent.LIGHTPICKER_COMPLETE;
				break;
			case AssetType.LIGHT:
				type_name = 'light';
				type_event = AssetEvent.LIGHT_COMPLETE;
				break;
			case AssetType.ANIMATOR:
				type_name = 'animator';
				type_event = AssetEvent.ANIMATOR_COMPLETE;
				break;
			case AssetType.ANIMATION_SET:
				type_name = 'animationSet';
				type_event = AssetEvent.ANIMATION_SET_COMPLETE;
				break;
			case AssetType.ANIMATION_STATE:
				type_name = 'animationState';
				type_event = AssetEvent.ANIMATION_STATE_COMPLETE;
				break;
			case AssetType.ANIMATION_NODE:
				type_name = 'animationNode';
				type_event = AssetEvent.ANIMATION_NODE_COMPLETE;
				break;
			case AssetType.STATE_TRANSITION:
				type_name = 'stateTransition';
				type_event = AssetEvent.STATE_TRANSITION_COMPLETE;
				break;
			case AssetType.TEXTURE:
				type_name = 'texture';
				type_event = AssetEvent.TEXTURE_COMPLETE;
				break;
			case AssetType.TEXTURE_PROJECTOR:
				type_name = 'textureProjector';
				type_event = AssetEvent.TEXTURE_PROJECTOR_COMPLETE;
				break;
			case AssetType.CONTAINER:
				type_name = 'container';
				type_event = AssetEvent.CONTAINER_COMPLETE;
				break;
			case AssetType.GEOMETRY:
				type_name = 'geometry';
				type_event = AssetEvent.GEOMETRY_COMPLETE;
				break;
			case AssetType.MATERIAL:
				type_name = 'material';
				type_event = AssetEvent.MATERIAL_COMPLETE;
				break;
			case AssetType.MESH:
				type_name = 'mesh';
				type_event = AssetEvent.MESH_COMPLETE;
				break;
			case AssetType.SKELETON:
				type_name = 'skeleton';
				type_event = AssetEvent.SKELETON_COMPLETE;
				break;
			case AssetType.SKELETON_POSE:
				type_name = 'skelpose';
				type_event = AssetEvent.SKELETON_POSE_COMPLETE;
				break;
			case AssetType.ENTITY:
				type_name = 'entity';
				type_event = AssetEvent.ENTITY_COMPLETE;
				break;
			case AssetType.SKYBOX:
				type_name = 'skybox';
				type_event = AssetEvent.SKYBOX_COMPLETE;
				break;
			case AssetType.CAMERA:
				type_name = 'camera';
				type_event = AssetEvent.CAMERA_COMPLETE;
				break;
			case AssetType.SEGMENT_SET:
				type_name = 'segmentSet';
				type_event = AssetEvent.SEGMENT_SET_COMPLETE;
				break;
			case AssetType.EFFECTS_METHOD:
				type_name = 'effectsMethod';
				type_event = AssetEvent.EFFECTMETHOD_COMPLETE;
				break;
			case AssetType.SHADOW_MAP_METHOD:
				type_name = 'effectsMethod';
				type_event = AssetEvent.SHADOWMAPMETHOD_COMPLETE;
				break;
			default:
				throw new Error('Unhandled asset type ' + asset.assetType + '. Report as bug!');
				break;
		}
		;

		// If the asset has no name, give it
		// a per-type default name.
		if (!asset.name)
			asset.name = type_name;

		dispatchEvent(new AssetEvent(AssetEvent.ASSET_COMPLETE, asset));
		dispatchEvent(new AssetEvent(type_event, asset));
	}

	/**
	 * Parse the next block of data.
	 * @return Whether or not more data needs to be parsed. Can be <code>ParserBase.PARSING_DONE</code> or
	 * <code>ParserBase.MORE_TO_PARSE</code>.
	 */
	protected function proceedParsing():Bool
	{
		throw new AbstractMethodError();
		return true;
	}

	protected function dieWithError(message:String = 'Unknown parsing error'):Void
	{
		if (_timer)
		{
			_timer.removeEventListener(TimerEvent.TIMER, onInterval);
			_timer.stop();
			_timer = null;
		}
		dispatchEvent(new ParserEvent(ParserEvent.PARSE_ERROR, message));
	}


	protected function addDependency(id:String, req:URLRequest, retrieveAsRawData:Bool = false, data:* = null, suppressErrorEvents:Bool = false):Void
	{
		_dependencies.push(new ResourceDependency(id, req, data, this, retrieveAsRawData, suppressErrorEvents));
	}


	protected function pauseAndRetrieveDependencies():Void
	{
		if (_timer)
			_timer.stop();
		_parsingPaused = true;
		dispatchEvent(new ParserEvent(ParserEvent.READY_FOR_DEPENDENCIES));
	}


	/**
	 * Tests whether or not there is still time left for parsing within the maximum allowed time frame per session.
	 * @return True if there is still time left, false if the maximum allotted time was exceeded and parsing should be interrupted.
	 */
	protected function hasTime():Bool
	{
		return ((getTimer() - _lastFrameTime) < _frameLimit);
	}

	/**
	 * Called when the parsing pause interval has passed and parsing can proceed.
	 */
	protected function onInterval(event:TimerEvent = null):Void
	{
		_lastFrameTime = getTimer();
		if (proceedParsing() && !_parsingFailure)
			finishParsing();
	}

	/**
	 * Initializes the parsing of data.
	 * @param frameLimit The maximum duration of a parsing session.
	 */
	private function startParsing(frameLimit:Float):Void
	{
		_frameLimit = frameLimit;
		_timer = new Timer(_frameLimit, 0);
		_timer.addEventListener(TimerEvent.TIMER, onInterval);
		_timer.start();
	}


	/**
	 * Finish parsing the data.
	 */
	protected function finishParsing():Void
	{
		if (_timer)
		{
			_timer.removeEventListener(TimerEvent.TIMER, onInterval);
			_timer.stop();
		}
		_timer = null;
		_parsingComplete = true;
		dispatchEvent(new ParserEvent(ParserEvent.PARSE_COMPLETE));
	}
}

