package a3d.io.library.assets;

import flash.events.IEventDispatcher;

import a3d.utils.IDispose;

interface IAsset extends IEventDispatcher, IDispose
{
	var name(get,set):String;
	var id(get,set):String;
	var assetNamespace(get,null):String;
	var assetType(get,null):String;
	var assetFullPath(get,null):Array<String>;

	function assetPathEquals(name:String, ns:String):Bool;
	function resetAssetPath(name:String, ns:String = null, overrideOriginal:Bool = true):Void;
}

