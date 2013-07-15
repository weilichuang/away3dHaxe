package a3d.io.library.assets;

import flash.events.IEventDispatcher;

import a3d.utils.IDispose;

interface IAsset extends IEventDispatcher extends IDispose
{
	/**
	 * The name of the asset.
	 */
	var name(get, set):String;
	/**
	 * The id of the asset.
	 */
	var id(get, set):String;
	/**
	 * The namespace of the asset. This allows several assets with the same name to coexist in different contexts.
	 */
	var assetNamespace(get, null):String;
	/**
	 * The type of the asset.
	 */
	var assetType(get, null):String;
	/**
	 * The full path of the asset.
	 */
	var assetFullPath(get,null):Array<String>;

	function assetPathEquals(name:String, ns:String):Bool;
	function resetAssetPath(name:String, ns:String = null, overrideOriginal:Bool = true):Void;
}

