package a3d.io.loaders.parsers;

import a3d.events.AssetEvent;
import a3d.events.ParserEvent;
import a3d.io.library.assets.IAsset;
import a3d.io.loaders.misc.ResourceDependency;



/**
 * The AWDParser class is a wrapper for both AWD1Parser and AWD2Parser, and will
 * find the right concrete parser for an AWD file.
*/
class AWDParser extends ParserBase
{
	private var _parser:ParserBase;

	public function AWDParser()
	{
		super(ParserDataFormat.BINARY);
	}


	public static function supportsType(suffix:String):Bool
	{
		return (suffix.toLowerCase() == 'awd');
	}


	public static function supportsData(data:*):Bool
	{
		return (AWD1Parser.supportsData(data) || AWD2Parser.supportsData(data));
	}



	/**
	 * @inheritDoc
	*/
	override public function get dependencies():Vector<ResourceDependency>
	{
		return _parser ? _parser.dependencies : super.dependencies;
	}


	/**
	 * @inheritDoc
	*/
	override public function get parsingComplete():Bool
	{
		return _parser ? _parser.parsingComplete : false;
	}


	/**
	 * @inheritDoc
	*/
	override public function get parsingPaused():Bool
	{
		return _parser ? _parser.parsingPaused : false;
	}


	/**
	 * @private
	 * Delegate to the concrete parser.
	*/
	override public function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (_parser)
			_parser.resolveDependency(resourceDependency);
	}


	/**
	 * @private
	 * Delegate to the concrete parser.
	*/
	override public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		if (_parser)
			_parser.resolveDependencyFailure(resourceDependency);
	}

	/**
	 * @private
	 * Delagate to the concrete parser.
	 */
	override public function resolveDependencyName(resourceDependency:ResourceDependency, asset:IAsset):String
	{
		if (_parser)
			return _parser.resolveDependencyName(resourceDependency, asset);
		return asset.name;
	}

	override public function resumeParsingAfterDependencies():Void
	{
		if (_parser)
			_parser.resumeParsingAfterDependencies();
	}


	/**
	 * Find the right conrete parser (AWD1Parser or AWD2Parser) and delegate actual
	 * parsing to it.
	*/
	override protected function proceedParsing():Bool
	{
		if (!_parser)
		{
			// Inspect data to find correct parser. AWD2 parser
			// file inspection is the most reliable
			if (AWD2Parser.supportsData(_data))
				_parser = new AWD2Parser();
			else
				_parser = new AWD1Parser();
			_parser.materialMode = materialMode;
			// Listen for events that need to be bubbled
			_parser.addEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
			_parser.addEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
			_parser.addEventListener(ParserEvent.PARSE_ERROR, onParseError);
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

			_parser.parseAsync(_data);
		}

		// Return MORE_TO_PARSE while delegate parser is working. Once the delegate
		// finishes parsing, this dummy parser instance will be stopped as well as
		// a result of the delegate's PARSE_COMPLETE event (onParseComplete).
		return MORE_TO_PARSE;
	}



	/**
	 * @private
	 * Just bubble events from concrete parser.
	*/
	private function onParseError(ev:ParserEvent):Void
	{
		dispatchEvent(ev.clone());
	}

	/**
	 * @private
	 * Just bubble events from concrete parser.
	*/
	private function onReadyForDependencies(ev:ParserEvent):Void
	{
		dispatchEvent(ev.clone());
	}


	/**
	 * @private
	 * Just bubble events from concrete parser.
	*/
	private function onAssetComplete(ev:AssetEvent):Void
	{
		dispatchEvent(ev.clone());
	}

	/**
	 * @private
	 * Just bubble events from concrete parser.
	*/
	private function onParseComplete(ev:ParserEvent):Void
	{
		_parser.removeEventListener(ParserEvent.READY_FOR_DEPENDENCIES, onReadyForDependencies);
		_parser.removeEventListener(ParserEvent.PARSE_COMPLETE, onParseComplete);
		_parser.removeEventListener(ParserEvent.PARSE_ERROR, onParseError);
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

		finishParsing();
	}
}
