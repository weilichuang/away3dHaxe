package away3d.io.library.assets
{
	import flash.events.IEventDispatcher;

	import away3d.utils.IDispose;

	public interface IAsset extends IEventDispatcher, IDispose
	{
		function get name():String;
		function set name(val:String):void;
		function get id():String;
		function set id(val:String):void;
		function get assetNamespace():String;
		function get assetType():String;
		function get assetFullPath():Array;

		function assetPathEquals(name:String, ns:String):Boolean;
		function resetAssetPath(name:String, ns:String = null, overrideOriginal:Boolean = true):void;
	}
}
