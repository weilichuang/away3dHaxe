package a3d.io.library.assets;

import flash.display.BitmapData;

/**
 * BitmapDataResource is a wrapper for loaded BitmapData, allowing it to be used uniformly as a resource when
 * loading, parsing, and listing/resolving dependencies.
 */
class BitmapDataAsset extends NamedAssetBase implements IAsset
{
	private var _bitmapData:BitmapData;

	/**
	 * Creates a new BitmapDataResource object.
	 * @param bitmapData An optional BitmapData object to use as the resource data.
	 */
	public function new(bitmapData:BitmapData = null)
	{
		_bitmapData = bitmapData;
	}

	/**
	 * The bitmapData to be treated as a resource.
	 */
	public var bitmapData(get, set):BitmapData;
	private function get_bitmapData():BitmapData
	{
		return _bitmapData;
	}

	private function set_bitmapData(value:BitmapData):BitmapData
	{
		return _bitmapData = value;
	}

	public var assetType(get, null):String;
	private function get_assetType():String
	{
		return AssetType.TEXTURE;
	}

	/**
	 * Cleans up any resources used by the current object.
	 */
	public function dispose():Void
	{
		_bitmapData.dispose();
	}
}
