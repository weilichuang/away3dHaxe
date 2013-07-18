package a3d.io.loaders.misc;

import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.Vector;


import a3d.events.AssetEvent;
import a3d.events.LoaderEvent;
import a3d.events.ParserEvent;
import a3d.io.loaders.parsers.ImageParser;
import a3d.io.loaders.parsers.ParserBase;
import a3d.io.loaders.parsers.ParserDataFormat;



/**
 * Dispatched when the dependency that this single-file loader was loading complets.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "dependencyComplete", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when an error occurs during loading.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "loadError", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when any asset finishes parsing. Also see specific events for each
 * individual asset type (meshes, materials et c.)
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "assetComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a geometry asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "geometryComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a skeleton asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a skeleton pose asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "skeletonPoseComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a container asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "containerComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation set has been constructed from a group of animation state resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationSetComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation state has been constructed from a group of animation node resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationStateComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation node has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animationNodeComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an animation state transition has been constructed from a group of animation node resources.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "stateTransitionComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a texture asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "textureComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a material asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "materialComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when a animator asset has been constructed from a resource.
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "animatorComplete", type = "a3d.events.AssetEvent")

/**
 * Dispatched when an image assets dimensions are not a power of 2
 *
 * @eventType a3d.events.AssetEvent
 */
@:meta(Eventname = "textureSizeError", type = "a3d.events.AssetEvent")


/**
 * The SingleFileLoader is used to load a single file, as part of a resource.
 *
 * While SingleFileLoader can be used directly, e.g. to create a third-party asset
 * management system, it's recommended to use any of the classes Loader3D, AssetLoader
 * and AssetLibrary instead in most cases.
 *
 * @see a3d.loading.Loader3D
 * @see a3d.loading.AssetLoader
 * @see a3d.loading.AssetLibrary
 */
class SingleFileLoader extends EventDispatcher
{
	private var _parser:ParserBase;
	private var _req:URLRequest;
	private var _fileExtension:String;
	private var _fileName:String;
	private var _loadAsRawData:Bool;
	private var _materialMode:Int;
	private var _data:Dynamic;

	// Image parser only parser that is added by default, to save file size.
	private static var _parsers:Vector<Class<ParserBase>> = Vector.convert(Vector.ofArray([ImageParser]));


	/**
	 * Creates a new SingleFileLoader object.
	 */
	public function new(materialMode:Int = 0)
	{
		super();
		_materialMode = materialMode;
	}

	public var url(get, null):String;
	private function get_url():String
	{
		return _req != null ? _req.url : '';
	}


	public var data(get, null):Dynamic;
	private function get_data():Dynamic
	{
		return _data;
	}


	public var loadAsRawData(get, null):Dynamic;
	private function get_loadAsRawData():Bool
	{
		return _loadAsRawData;
	}


	public static function enableParser(parser:Class<ParserBase>):Void
	{
		if (_parsers.indexOf(parser) < 0)
			_parsers.push(parser);
	}


	public static function enableParsers(parsers:Array<Class<ParserBase>>):Void
	{
		var pc:Class<ParserBase>;
		for (pc in parsers)
		{
			enableParser(pc);
		}
	}


	/**
	 * Load a resource from a file.
	 *
	 * @param urlRequest The URLRequest object containing the URL of the object to be loaded.
	 * @param parser An optional parser object that will translate the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function load(urlRequest:URLRequest, parser:ParserBase = null, loadAsRawData:Bool = false):Void
	{
		var urlLoader:URLLoader;
		var dataFormat:URLLoaderDataFormat = URLLoaderDataFormat.BINARY;

		_loadAsRawData = loadAsRawData;
		_req = urlRequest;
		decomposeFilename(_req.url);

		if (_loadAsRawData)
		{
			// Always use binary for raw data loading
			dataFormat = URLLoaderDataFormat.BINARY;
		}
		else
		{
			if (parser != null)
				_parser = parser;

			if (_parser == null)
				_parser = getParserFromSuffix();

			if (_parser != null)
			{
				switch (_parser.dataFormat)
				{
					case ParserDataFormat.BINARY:
						dataFormat = URLLoaderDataFormat.BINARY;
					case ParserDataFormat.PLAIN_TEXT:
						dataFormat = URLLoaderDataFormat.TEXT;
				}

			}
			else
			{
				// Always use BINARY for unknown file formats. The thorough
				// file type check will determine format after load, and if
				// binary, a text load will have broken the file data.
				dataFormat = URLLoaderDataFormat.BINARY;
			}
		}

		urlLoader = new URLLoader();
		urlLoader.dataFormat = dataFormat;
		urlLoader.addEventListener(Event.COMPLETE, handleUrlLoaderComplete);
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
		urlLoader.load(urlRequest);
	}

	/**
	 * Loads a resource from already loaded data.
	 * @param data The data to be parsed. Depending on the parser type, this can be a ByteArray, String or XML.
	 * @param uri The identifier (url or id) of the object to be loaded, mainly used for resource management.
	 * @param parser An optional parser object that will translate the data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function parseData(data:Dynamic, parser:ParserBase = null, req:URLRequest = null):Void
	{
		if (Std.is(data,Class))
			data = Type.createInstance(data,[]);

		if (parser != null)
			_parser = parser;

		_req = req;

		parse(data);
	}

	/**
	 * A reference to the parser that will translate the loaded data into a usable resource.
	 */
	public var parser(get, null):ParserBase;
	private function get_parser():ParserBase
	{
		return _parser;
	}

	/**
	 * A list of dependencies that need to be loaded and resolved for the loaded object.
	 */
	public var dependencies(get, null):Vector<ResourceDependency>;
	private function get_dependencies():Vector<ResourceDependency>
	{
		if (_parser != null)
		{
			return _parser.dependencies;
		}
		else
		{
			return new Vector<ResourceDependency>();
		}
	}

	/**
	 * Splits a url string into base and extension.
	 * @param url The url to be decomposed.
	 */
	private function decomposeFilename(url:String):Void
	{

		// Get rid of query string if any and extract suffix
		var base:String = (url.indexOf('?') > 0) ? url.split('?')[0] : url;
		var i:Int = base.lastIndexOf('.');
		_fileExtension = base.substr(i + 1).toLowerCase();
		_fileName = base.substr(0, i);
	}

	/**
	 * Guesses the parser to be used based on the file extension.
	 * @return An instance of the guessed parser.
	 */
	private function getParserFromSuffix():ParserBase
	{
		var len:Int = _parsers.length;

		// go in reverse order to allow application override of default parser added in a3d proper
		var i:Int = len - 1;
		while (i >= 0)
		{
			if (untyped _parsers[i].supportsType(_fileExtension))
			{
				return Type.createInstance(_parsers[i],[]);
			}
			i--;
		}

		return null;
	}

	/**
	 * Guesses the parser to be used based on the file contents.
	 * @param data The data to be parsed.
	 * @param uri The url or id of the object to be parsed.
	 * @return An instance of the guessed parser.
	 */
	private function getParserFromData(data:Dynamic):ParserBase
	{
		var len:Int = _parsers.length;

		// go in reverse order to allow application override of default parser added in a3d proper
		var i:Int = len - 1;
		while (i >= 0)
		{
			if (untyped _parsers[i].supportsData(data))
			{
				return Type.createInstance(_parsers[i],[]);
			}
			i--;
		}

		return null;
	}

	/**
	 * Cleanups
	 */
	private function removeListeners(urlLoader:URLLoader):Void
	{
		urlLoader.removeEventListener(Event.COMPLETE, handleUrlLoaderComplete);
		urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);
	}

	/**
	 * Called when loading of a file has failed
	 */
	private function handleUrlLoaderError(event:IOErrorEvent):Void
	{
		var urlLoader:URLLoader = Std.instance(event.currentTarget,URLLoader);
		removeListeners(urlLoader);

		if (hasEventListener(LoaderEvent.LOAD_ERROR))
			dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, _req.url, true, event.text));
	}

	/**
	 * Called when loading of a file is complete
	 */
	private function handleUrlLoaderComplete(event:Event):Void
	{
		var urlLoader:URLLoader = Std.instance(event.currentTarget,URLLoader);
		removeListeners(urlLoader);

		_data = urlLoader.data;

		if (_loadAsRawData)
		{
			// No need to parse this data, which should be returned as is
			dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE));
		}
		else
		{
			parse(_data);
		}
	}

	/**
	 * Initiates parsing of the loaded data.
	 * @param data The data to be parsed.
	 */
	private function parse(data:Dynamic):Void
	{
		// If no parser has been defined, try to find one by letting
		// all plugged in parsers inspect the actual data.
		if (_parser == null)
		{
			_parser = getParserFromData(data);
		}

		if (_parser != null)
		{
			_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.addEventListener(ParserEvent.PARSE_ERROR, onParseError);
			_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.addEventListener(AssetEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
			_parser.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
			_parser.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);

			if (_req != null && _req.url != null)
				_parser.fileName = _req.url;
			_parser.materialMode = _materialMode;
			_parser.parseAsync(data);
		}
		else
		{
			var msg:String = "No parser defined. To enable all parsers for auto-detection, use Parsers.enableAllBundled()";
			if (hasEventListener(LoaderEvent.LOAD_ERROR))
			{
				this.dispatchEvent(new LoaderEvent(LoaderEvent.LOAD_ERROR, "", true, msg));
			}
			else
			{
				throw new Error(msg);
			}
		}
	}

	private function onParseError(event:ParserEvent):Void
	{
		if (hasEventListener(ParserEvent.PARSE_ERROR))
			dispatchEvent(event.clone());
	}

	private function onReadyForDependencies(event:ParserEvent):Void
	{
		dispatchEvent(event.clone());
	}

	private function onAssetComplete(event:AssetEvent):Void
	{
		this.dispatchEvent(event.clone());
	}

	private function onTextureSizeError(event:AssetEvent):Void
	{
		this.dispatchEvent(event.clone());
	}

	/**
	 * Called when parsing is complete.
	 */
	private function onParseComplete(event:ParserEvent):Void
	{
		this.dispatchEvent(new LoaderEvent(LoaderEvent.DEPENDENCY_COMPLETE, this.url)); //dispatch in front of removing listeners to allow any remaining asset events to propagate

		_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
		_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
		_parser.removeEventListener(ParserEvent.PARSE_ERROR, onParseError);
		_parser.removeEventListener(AssetEvent.TEXTURE_SIZE_ERROR, onTextureSizeError);
		_parser.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
		_parser.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
	}
}

