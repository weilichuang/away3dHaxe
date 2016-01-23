package away3d.animators.nodes;

import away3d.animators.states.IAnimationState;
import away3d.library.assets.AssetType;
import away3d.library.assets.IAsset;
import away3d.library.assets.NamedAssetBase;

/**
 * Provides an abstract base class for nodes in an animation blend tree.
 */
class AnimationNodeBase extends NamedAssetBase implements IAsset
{
	/**
	 * @inheritDoc
	 */
	public var assetType(get, null):String;
	
	public var stateClass(get, null):Class<IAnimationState>;
	
	private var _stateClass:Class<IAnimationState>;
	

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

	private inline function get_stateClass():Class<IAnimationState>
	{
		return _stateClass;
	}
	
	private function get_assetType():String
	{
		return AssetType.ANIMATION_NODE;
	}
}
