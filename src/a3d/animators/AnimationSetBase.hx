package a3d.animators;

import flash.utils.Dictionary;
import flash.Vector;

import a3d.animators.nodes.AnimationNodeBase;
import a3d.errors.AnimationSetError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;
import haxe.ds.WeakMap;
/**
 * Provides an abstract base class for data set classes that hold animation data for use in animator classes.
 *
 * @see a3d.animators.AnimatorBase
 */
class AnimationSetBase extends NamedAssetBase implements IAsset
{
	/**
	 * Indicates whether the properties of the animation data contained within the set combined with
	 * the vertex registers aslready in use on shading materials allows the animation data to utilise
	 * GPU calls.
	 */
	public var usesCPU(get, null):Bool;
	/**
	 * @inheritDoc
	 */
	public var assetType(get, null):String;
	/**
	 * Returns a vector of animation state objects that make up the contents of the animation data set.
	 */
	public var animations(get, null):Vector<AnimationNodeBase>;
	/**
	 * Returns a vector of animation state objects that make up the contents of the animation data set.
	 */
	public var animationNames(get, null):Vector<String>;
	
	private var _usesCPU:Bool;
	private var _animations:Vector<AnimationNodeBase>;
	private var _animationNames:Vector<String>;
	private var _animationDictionary:WeakMap<String,AnimationNodeBase>;

	public function new()
	{
		super();
		_animations = new Vector<AnimationNodeBase>();
		_animationNames = new Vector<String>();
		_animationDictionary = new WeakMap<String,AnimationNodeBase>();
	}

	/**
	 * Retrieves a temporary GPU register that's still free.
	 *
	 * @param exclude An array of non-free temporary registers.
	 * @param excludeAnother An additional register that's not free.
	 * @return A temporary register that can be used.
	 */
	private function findTempReg(exclude:Vector<String>, excludeAnother:String = null):String
	{
		var i:Int = 0;
		var reg:String;

		while (true)
		{
			reg = "vt" + i;
			if (exclude.indexOf(reg) == -1 && excludeAnother != reg)
				return reg;
			++i;
		}

		// can't be reached
		return null;
	}

	
	private function get_usesCPU():Bool
	{
		return _usesCPU;
	}

	/**
	 * Called by the material to reset the GPU indicator before testing whether register space in the shader
	 * is available for running GPU-based animation code.
	 *
	 * @private
	 */
	public function resetGPUCompatibility():Void
	{
		_usesCPU = false;
	}

	public function cancelGPUCompatibility():Void
	{
		_usesCPU = true;
	}

	
	private function get_assetType():String
	{
		return AssetType.ANIMATION_SET;
	}

	
	private function get_animations():Vector<AnimationNodeBase>
	{
		return _animations;
	}

	
	private function get_animationNames():Vector<String>
	{
		return _animationNames;
	}

	/**
	 * Check to determine whether a state is registered in the animation set under the given name.
	 *
	 * @param stateName The name of the animation state object to be checked.
	 */
	public function hasAnimation(name:String):Bool
	{
		return _animationDictionary.exists(name);
	}

	/**
	 * Retrieves the animation state object registered in the animation data set under the given name.
	 *
	 * @param stateName The name of the animation state object to be retrieved.
	 */
	public function getAnimation(name:String):AnimationNodeBase
	{
		return _animationDictionary.get(name);
	}


	/**
	 * Adds an animation state object to the aniamtion data set under the given name.
	 *
	 * @param stateName The name under which the animation state object will be stored.
	 * @param animationState The animation state object to be staored in the set.
	 */
	public function addAnimation(node:AnimationNodeBase):Void
	{
		if (_animationDictionary.exists(node.name))
			throw new AnimationSetError("root node name '" + node.name + "' already exists in the set");

		_animationDictionary.set(node.name,node);

		_animations.push(node);

		_animationNames.push(node.name);
	}

	/**
	 * Cleans up any resources used by the current object.
	 */
	public function dispose():Void
	{
	}
}
