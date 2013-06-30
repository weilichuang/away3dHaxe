package a3d.io.library.naming;

import a3d.errors.AbstractMethodError;
import a3d.events.AssetEvent;
import a3d.io.library.assets.IAsset;
import haxe.ds.StringMap;
import haxe.ds.StringMap.StringMap;

/**
 * Abstract base class for naming conflict resolution classes. Extend this to create a
 * strategy class which the asset library can use to resolve asset naming conflicts, or
 * use one of the bundled concrete strategy classes:
 *
 * <ul>
 *   <li>IgnoreConflictStrategy (ConflictStrategy.IGNORE)</li>
 *   <li>ErrorConflictStrategy (ConflictStrategy.THROW_ERROR)</li>
 *   <li>NumSuffixConflictStrategy (ConflictStrategy.APPEND_NUM_SUFFIX)</li>
 * </ul>
 *
 * @see a3d.library.AssetLibrary.conflictStrategy
 * @see a3d.library.naming.ConflictStrategy
 * @see a3d.library.naming.IgnoreConflictStrategy
 * @see a3d.library.naming.ErrorConflictStrategy
 * @see a3d.library.naming.NumSuffixConflictStrategy
*/
class ConflictStrategyBase
{

	public function new()
	{
	}


	/**
	 * Resolve a naming conflict between two assets. Must be implemented by concrete strategy
	 * classes.
	*/
	public function resolveConflict(changedAsset:IAsset, oldAsset:IAsset, assetsDictionary: StringMap<IAsset>, precedence:String):Void
	{
		throw new AbstractMethodError();
	}


	/**
	 * Create instance of this conflict strategy. Used internally by the AssetLibrary to
	 * make sure the same strategy instance is not used in all AssetLibrary instances, which
	 * would break any state caching that happens inside the strategy class.
	*/
	public function create():ConflictStrategyBase
	{
		throw new AbstractMethodError();
	}


	/**
	 * Provided as a convenience method for all conflict strategy classes, as a way to finalize
	 * the conflict resolution by applying the new names and dispatching the correct events.
	*/
	private function updateNames(ns:String, nonConflictingName:String, oldAsset:IAsset, newAsset:IAsset, assetsDictionary:StringMap<IAsset>, precedence:String):Void
	{
		var loser_prev_name:String;
		var winner:IAsset, loser:IAsset;

		winner = (precedence == ConflictPrecedence.FAVOR_NEW) ? newAsset : oldAsset;
		loser = (precedence == ConflictPrecedence.FAVOR_NEW) ? oldAsset : newAsset;

		loser_prev_name = loser.name;

		assetsDictionary.set(winner.name,winner);
		assetsDictionary.set(nonConflictingName,loser);
		loser.resetAssetPath(nonConflictingName, ns, false);

		loser.dispatchEvent(new AssetEvent(AssetEvent.ASSET_CONFLICT_RESOLVED, loser, loser_prev_name));
	}
}
