package a3d.animators.nodes;

import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonNaryLERPState;



/**
 * A skeleton animation node that uses an n-dimensional array of animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class SkeletonNaryLERPNode extends AnimationNodeBase
{
	private var _inputs:Vector<AnimationNodeBase> = new Vector<AnimationNodeBase>();
	private var _numInputs:UInt;

	private inline function get_inputs():Vector<AnimationNodeBase>
	{
		return _inputs;
	}

	private inline function set_inputs(value:Vector<AnimationNodeBase>):Void
	{
		_inputs = value;
	}

	private inline function get_numInputs():UInt
	{
		return _numInputs;
	}

	/**
	 * Creates a new <code>SkeletonNaryLERPNode</code> object.
	 */
	public function SkeletonNaryLERPNode()
	{
		_stateClass = SkeletonNaryLERPState;
	}

	/**
	 * Returns an integer representing the input index of the given skeleton animation node.
	 *
	 * @param input The skeleton animation node for with the input index is requested.
	 */
	public function getInputIndex(input:AnimationNodeBase):Int
	{
		return _inputs.indexOf(input);
	}

	/**
	 * Returns the skeleton animation node object that resides at the given input index.
	 *
	 * @param index The input index for which the skeleton animation node is requested.
	 */
	public function getInputAt(index:UInt):AnimationNodeBase
	{
		return _inputs[index];
	}

	/**
	 * Adds a new skeleton animation node input to the animation node.
	 */
	public function addInput(input:AnimationNodeBase):Void
	{
		_inputs[_numInputs++] = input;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):SkeletonNaryLERPState
	{
		return animator.getAnimationState(this) as SkeletonNaryLERPState;
	}
}
