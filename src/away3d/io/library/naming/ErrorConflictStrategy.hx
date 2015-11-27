package away3d.io.library.naming;

import away3d.io.library.assets.IAsset;
import flash.errors.Error;
import haxe.ds.StringMap;

class ErrorConflictStrategy extends ConflictStrategyBase
{
	public function new()
	{
		super();
	}

	override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:StringMap<IAsset>, precedence:String):Void
	{
		throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
	}


	override public function create():ConflictStrategyBase
	{
		return new ErrorConflictStrategy();
	}
}
