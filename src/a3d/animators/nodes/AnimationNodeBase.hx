package a3d.animators.nodes;

import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;

/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
class AnimationNodeBase extends NamedAssetBase implements IAsset
{
	private var _stateClass:Class;

	private inline function get_stateClass():Class
	{
		return _stateClass;
	}

	/**
	 * Creates a new <code>AnimationNodeBase</code> object.
	 */
	public function AnimationNodeBase()
	{
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
	private inline function get_assetType():String
	{
		return AssetType.ANIMATION_NODE;
	}
}
