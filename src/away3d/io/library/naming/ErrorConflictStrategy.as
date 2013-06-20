package away3d.io.library.naming
{
	import away3d.io.library.assets.IAsset;

	public class ErrorConflictStrategy extends ConflictStrategyBase
	{
		public function ErrorConflictStrategy()
		{
			super();
		}

		override public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary:Object, precedence:String):void
		{
			throw new Error('Asset name collision while AssetLibrary.namingStrategy set to AssetLibrary.THROW_ERROR. Asset path: ' + changedAsset.assetFullPath);
		}


		override public function create():ConflictStrategyBase
		{
			return new ErrorConflictStrategy();
		}
	}
}
