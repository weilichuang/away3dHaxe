package a3d.io.library.naming;

import a3d.io.library.assets.IAsset;
import haxe.ds.StringMap;

class IgnoreConflictStrategy extends ConflictStrategyBase
{
	public function new()
	{
		super();
	}


	override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, 
								assetsDictionary:StringMap<IAsset>, precedence:String):Void
	{
		// Do nothing, ignore the fact that there is a conflict.
		return;
	}


	override public function create():ConflictStrategyBase
	{
		return new IgnoreConflictStrategy();
	}
}
