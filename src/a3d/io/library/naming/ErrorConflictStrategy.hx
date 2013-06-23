package a3d.io.library.naming;

import a3d.io.library.assets.IAsset;

class ErrorConflictStrategy extends ConflictStrategyBase
{
	public function new()
	{
		super();
	}

	override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, precedence:String):Void
	{
		throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
	}


	override public function create():ConflictStrategyBase
	{
		return new ErrorConflictStrategy();
	}
}
