﻿package a3d.io.loaders.misc;

import a3d.io.library.assets.IAsset;
import a3d.io.loaders.parsers.ParserBase;
import flash.net.URLRequest;
import flash.Vector;





/**
 * ResourceDependency represents the data required to load, parse and resolve additional files ("dependencies")
 * required by a parser, used by ResourceLoadSession.
 *
 */
class ResourceDependency
{
	public var id(get, null):String;
	public var assets(get, null):Vector<IAsset>;
	public var dependencies(get, null):Vector<ResourceDependency>;
	public var request(get, null):URLRequest;
	public var retrieveAsRawData(get, null):Bool;
	public var suppresAssetEvents(get, null):Bool;
	/**
	 * The data containing the dependency to be parsed, if the resource was already loaded.
	 */
	public var data(get, null):Dynamic;
	/**
	 * The parser which is dependent on this ResourceDependency object.
	 */
	public var parentParser(get, null):ParserBase;
	
	public var loader:SingleFileLoader;
	public var success:Bool;
	
	private var _id:String;
	private var _req:URLRequest;
	private var _assets:Vector<IAsset>;
	private var _parentParser:ParserBase;
	private var _data:Dynamic;
	private var _retrieveAsRawData:Bool;
	private var _suppressAssetEvents:Bool;
	private var _dependencies:Vector<ResourceDependency>;


	public function new(id:String, req:URLRequest, data:Dynamic, parentParser:ParserBase, retrieveAsRawData:Bool = false, suppressAssetEvents:Bool = false)
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


	
	private function get_id():String
	{
		return _id;
	}

	
	private function get_assets():Vector<IAsset>
	{
		return _assets;
	}

	
	private function get_dependencies():Vector<ResourceDependency>
	{
		return _dependencies;
	}

	
	private function get_request():URLRequest
	{
		return _req;
	}

	
	private function get_retrieveAsRawData():Bool
	{
		return _retrieveAsRawData;
	}

	
	private function get_suppresAssetEvents():Bool
	{
		return _suppressAssetEvents;
	}


	
	private function get_data():Dynamic
	{
		return _data;
	}


	/**
	 * @private
	 * Method to set data after having already created the dependency object, e.g. after load.
	*/
	public function setData(data:Dynamic):Void
	{
		_data = data;
	}

	
	private function get_parentParser():ParserBase
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
		if (_parentParser != null)
			_parentParser.resolveDependency(this);
	}

	/**
	 * Resolve a dependency failure. For example, map loading failure from a 3d file
	 */
	public function resolveFailure():Void
	{
		if (_parentParser != null)
			_parentParser.resolveDependencyFailure(this);
	}

	/**
	 * Resolve the dependencies name
	 */
	public function resolveName(asset:IAsset):String
	{
		if (_parentParser != null)
			return _parentParser.resolveDependencyName(this, asset);
		return asset.name;
	}

}
