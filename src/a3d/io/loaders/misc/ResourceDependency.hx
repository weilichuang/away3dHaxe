package a3d.io.loaders.misc;

import flash.net.URLRequest;
import flash.Vector;


import a3d.io.library.assets.IAsset;
import a3d.io.loaders.parsers.ParserBase;



/**
 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
 * required by a parser, used by ResourceLoadSession.
 *
 */
class ResourceDependency
{
	private var _id:String;
	private var _req:URLRequest;
	private var _assets:Vector<IAsset>;
	private var _parentParser:ParserBase;
	private var _data:*;
	private var _retrieveAsRawData:Bool;
	private var _suppressAssetEvents:Bool;
	private var _dependencies:Vector<ResourceDependency>;

	public var loader:SingleFileLoader;
	public var success:Bool;


	public function new(id:String, req:URLRequest, data:*, parentParser:ParserBase, retrieveAsRawData:Bool = false, suppressAssetEvents:Bool = false)
	{
		_id = id;
		_req = req;
		_parentParser = parentParser;
		_data = data;
		_retrieveAsRawData = retrieveAsRawData;
		_suppressAssetEvents = suppressAssetEvents;

		_assets = new Vector<IAsset>();
		_dependencies = new Vector<ResourceDependency>();
	}


	public function get id():String
	{
		return _id;
	}


	public function get assets():Vector<IAsset>
	{
		return _assets;
	}


	public function get dependencies():Vector<ResourceDependency>
	{
		return _dependencies;
	}


	public function get request():URLRequest
	{
		return _req;
	}


	public function get retrieveAsRawData():Bool
	{
		return _retrieveAsRawData;
	}


	public function get suppresAssetEvents():Bool
	{
		return _suppressAssetEvents;
	}


	/**
	 * The data containing the dependency to be parsed, if the resource was already loaded.
	 */
	public function get data():*
	{
		return _data;
	}


	/**
	 * @private
	 * Method to set data after having already created the dependency object, e.g. after load.
	*/
	public function setData(data:*):Void
	{
		_data = data;
	}

	/**
	 * The parser which is dependent on this ResourceDependency object.
	 */
	public function get parentParser():ParserBase
	{
		return _parentParser;
	}

	/**
	 * Resolve the dependency when it's loaded with the parent parser. For example, a dependency containing an
	 * ImageResource would be assigned to a Mesh instance as a BitmapMaterial, a scene graph object would be added
	 * to its intended parent. The dependency should be a member of the dependencies property.
	 */
	public function resolve():Void
	{
		if (_parentParser)
			_parentParser.resolveDependency(this);
	}

	/**
	 * Resolve a dependency failure. For example, map loading failure from a 3d file
	 */
	public function resolveFailure():Void
	{
		if (_parentParser)
			_parentParser.resolveDependencyFailure(this);
	}

	/**
	 * Resolve the dependencies name
	 */
	public function resolveName(asset:IAsset):String
	{
		if (_parentParser)
			return _parentParser.resolveDependencyName(this, asset);
		return asset.name;
	}

}
