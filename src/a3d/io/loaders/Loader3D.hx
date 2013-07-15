package a3d.io.loaders;

import a3d.entities.Camera3D;
import a3d.entities.primitives.SkyBox;
import a3d.entities.SegmentSet;
import a3d.entities.TextureProjector;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.URLRequest;
import flash.Vector;


import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.events.AssetEvent;
import a3d.events.LoaderEvent;
import a3d.events.ParserEvent;
import a3d.io.library.AssetLibraryBundle;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.LightBase;
import a3d.io.loaders.misc.AssetLoaderContext;
import a3d.io.loaders.misc.AssetLoaderToken;
import a3d.io.loaders.misc.SingleFileLoader;
import a3d.io.loaders.parsers.ParserBase;



/**
 * Dispatched when a full resource (including dependencies) finishes loading.
 *
 * @eventType a3d.events.LoaderEvent
 */
@:meta(Eventname = "resourceComplete", type = "a3d.events.LoaderEvent")

/**
 * Dispatched when a single dependency (which may be the main file of a resource)
 * finishes loading.
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
 * Loader3D can load any file format that Away3D supports (or for which a third-party parser
 * has been plugged in) and be added directly to the scene. As assets are encountered
 * they are added to the Loader3D container. Assets that can not be displayed in the scene
 * graph (e.g. unused bitmaps/materials, skeletons et c) will be ignored.
 *
 * This provides a fast and easy way to load models (no need for event listeners) but is not
 * very versatile since many types of assets are ignored.
 *
 * Loader3D by default uses the AssetLibrary to load all assets, which means that they also
 * ends up in the library. To circumvent this, Loader3D can be configured to not use the
 * AssetLibrary in which case it will use the AssetLoader directly.
 *
 * @see a3d.loaders.AssetLoader
 * @see a3d.library.AssetLibrary
 */
class Loader3D extends ObjectContainer3D
{
	private var _loadingSessions:Vector<AssetLoader>;
	private var _useAssetLib:Bool;
	private var _assetLibId:String;

	public function new(useAssetLibrary:Bool = true, assetLibraryId:String = null)
	{
		super();

		_loadingSessions = new Vector<AssetLoader>();
		_useAssetLib = useAssetLibrary;
		_assetLibId = assetLibraryId;
	}

	/**
	 * Loads a file and (optionally) all of its dependencies.
	 *
	 * @param req The URLRequest object containing the URL of the file to be loaded.
	 * @param context An optional context object providing additional parameters for loading
	 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
	 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function load(req:URLRequest, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var token:AssetLoaderToken;

		if (_useAssetLib)
		{
			var lib:AssetLibraryBundle;
			lib = AssetLibraryBundle.getInstance(_assetLibId);
			token = lib.load(req, context, ns, parser);
		}
		else
		{
			var loader:AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			token = loader.load(req, context, ns, parser);
		}

		token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		token.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);

		// Error are handled separately (see documentation for addErrorHandler)
		token.loader.addErrorHandler(onLoadError);

		return token;
	}

	/**
	 * Loads a resource from already loaded data.
	 *
	 * @param data The data object containing all resource information.
	 * @param context An optional context object providing additional parameters for loading
	 * @param ns An optional namespace string under which the file is to be loaded, allowing the differentiation of two resources with identical assets
	 * @param parser An optional parser object for translating the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.
	 */
	public function loadData(data:Dynamic, context:AssetLoaderContext = null, ns:String = null, parser:ParserBase = null):AssetLoaderToken
	{
		var token:AssetLoaderToken;

		if (_useAssetLib)
		{
			var lib:AssetLibraryBundle;
			lib = AssetLibraryBundle.getInstance(_assetLibId);
			token = lib.loadData(data, context, ns, parser);
		}
		else
		{
			var loader:AssetLoader = new AssetLoader();
			_loadingSessions.push(loader);
			token = loader.loadData(data, '', context, ns, parser);
		}

		token.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		token.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
		token.addEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);

		// Error are handled separately (see documentation for addErrorHandler)
		token.loader.addErrorHandler(onLoadError);

		return token;
	}


	public static function enableParser(parserClass:Class<ParserBase>):Void
	{
		SingleFileLoader.enableParser(parserClass);
	}


	public static function enableParsers(parserClasses:Vector<Class<ParserBase>>):Void
	{
		SingleFileLoader.enableParsers(parserClasses);
	}



	private function removeListeners(dispatcher:EventDispatcher):Void
	{
		dispatcher.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		dispatcher.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadError);
		dispatcher.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.ANIMATION_SET_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.ANIMATION_STATE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.ANIMATION_NODE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.STATE_TRANSITION_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.TEXTURE_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.CONTAINER_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.GEOMETRY_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.MATERIAL_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.MESH_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.ENTITY_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.SKELETON_COMPLETE, onAssetComplete);
		dispatcher.removeEventListener(AssetEvent.SKELETON_POSE_COMPLETE, onAssetComplete);
	}



	private function onAssetComplete(ev:AssetEvent):Void
	{
		if (ev.type == AssetEvent.ASSET_COMPLETE)
		{
			// TODO: not used
			// var type : String = ev.asset.assetType;
			var obj:ObjectContainer3D = null;
			switch (ev.asset.assetType)
			{
				case AssetType.LIGHT:
					obj = Std.instance(ev.asset,LightBase);
				case AssetType.CONTAINER:
					obj = Std.instance(ev.asset,ObjectContainer3D);
				case AssetType.MESH:
					obj = Std.instance(ev.asset, Mesh);
				case AssetType.SKYBOX:
					obj = Std.instance(ev.asset,SkyBox);
				case AssetType.TEXTURE_PROJECTOR:
					obj = Std.instance(ev.asset,TextureProjector);
				case AssetType.CAMERA:
					obj = Std.instance(ev.asset,Camera3D);
				case AssetType.SEGMENT_SET:
					obj = Std.instance(ev.asset,SegmentSet);
			}

			// If asset was of fitting type, and doesn't
			// already have a parent, add to loader container
			if (obj != null && obj.parent == null)
			{
				addChild(obj);
			}
		}

		this.dispatchEvent(ev.clone());
	}

	private function onParseError(ev:ParserEvent):Bool
	{
		if (hasEventListener(ParserEvent.PARSE_ERROR))
		{
			dispatchEvent(ev);
			return true;
		}
		else
		{
			return false;
		}
	}

	public function stopLoad():Void
	{
		if (_useAssetLib)
		{
			var lib:AssetLibraryBundle;
			lib = AssetLibraryBundle.getInstance(_assetLibId);
			lib.stopAllLoadingSessions();
			_loadingSessions = null;
			return;
		}
		
		var length:Int = _loadingSessions.length;
		for (i  in 0...length)
		{
			removeListeners(_loadingSessions[i]);
			_loadingSessions[i].stop();
			_loadingSessions[i] = null;
		}
		_loadingSessions = null;
	}

	private function onLoadError(ev:LoaderEvent):Bool
	{
		if (hasEventListener(LoaderEvent.LOAD_ERROR))
		{
			dispatchEvent(ev);
			return true;
		}
		else
		{
			return false;
		}
	}

	private function onResourceComplete(ev:Event):Void
	{
		removeListeners(Std.instance(ev.currentTarget,EventDispatcher));
		this.dispatchEvent(ev.clone());
	}
}
