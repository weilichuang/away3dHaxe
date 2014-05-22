package a3d.io.library.assets;

import a3d.events.AssetEvent;
import flash.events.EventDispatcher;

class NamedAssetBase extends EventDispatcher
{
	public static inline var DEFAULT_NAMESPACE:String = 'default';

	/**
	 * The original name used for this asset in the resource (e.g. file) in which
	 * it was found. This may not be the same as <code>name</code>, which may
	 * have changed due to of a name conflict.
	*/
	public var originalName(get, null):String;
	public var id(get, set):String;
	public var name(get, set):String;
	public var assetNamespace(get, null):String;
	public var assetFullPath(get, null):Array<String>;
	
	private var _originalName:String;
	private var _namespace:String;
	private var _name:String;
	private var _id:String;
	private var _full_path:Array<String>;
	
	public function new(name:String = null)
	{
		super();
		
		if (name == null)
			name = 'null';

		_name = name;
		_originalName = name;

		updateFullPath();
	}


	
	private function get_originalName():String
	{
		return _originalName;
	}

	
	private function get_id():String
	{
		return _id;
	}

	private function set_id(newID:String):String
	{
		return _id = newID;
	}

	
	private function get_name():String
	{
		return _name;
	}

	private function set_name(val:String):String
	{
		var prev:String;

		prev = _name;
		_name = val;
		if (_name == null)
			_name = 'null';

		updateFullPath();

		if (hasEventListener(AssetEvent.ASSET_RENAME))
			dispatchEvent(new AssetEvent(AssetEvent.ASSET_RENAME, cast(this, IAsset), prev));
		
		return _name;
	}

	
	private function get_assetNamespace():String
	{
		return _namespace;
	}

	
	private function get_assetFullPath():Array<String>
	{
		return _full_path;
	}


	public function assetPathEquals(name:String, ns:String):Bool
	{
		return (_name == name && (ns != null || _namespace == ns));
	}


	public function resetAssetPath(name:String, ns:String = null, overrideOriginal:Bool = true):Void
	{
		_name = name != null ? name : 'null';
		_namespace = ns != null ? ns : DEFAULT_NAMESPACE;
		if (overrideOriginal)
			_originalName = _name;

		updateFullPath();
	}


	private function updateFullPath():Void
	{
		_full_path = [_namespace, _name];
	}
}
