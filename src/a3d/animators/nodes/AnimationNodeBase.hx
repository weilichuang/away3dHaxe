package a3d.animators.nodes;

import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;

/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
class AnimationNodeBase extends NamedAssetBase implements IAsset
{
	public var stateClass(get, null):Class<Dynamic>;
	
	private var _stateClass:Class<Dynamic>;
	private function get_stateClass():Class<Dynamic>
	{
		return _stateClass;
	}

	/**
	 * Creates a new <code>AnimationNodeBase</code> object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
	}

	/**
	 * @inheritDoc
	 */
	public var assetType(get, null):String;
	private function get_assetType():String
	{
		return AssetType.ANIMATION_NODE;
	}
}
