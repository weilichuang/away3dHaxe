package a3d.animators.nodes;

import a3d.animators.IAnimator;
import a3d.animators.states.SkeletonNaryLERPState;
import flash.Vector;



/**
 * A skeleton animation node that uses an n-dimensional array of animation node inputs to blend a lineraly interpolated output of a skeleton pose.
 */
class SkeletonNaryLERPNode extends AnimationNodeBase
{
	private var _inputs:Vector<AnimationNodeBase>;
	private var _numInputs:Int;

	public var inputs(get,set):Vector<AnimationNodeBase>;
	

	public var numInputs(get,null):Int;
	
	/**
	 * Creates a new <code>SkeletonNaryLERPNode</code> object.
	 */
	public function new()
	{
		super();
		_stateClass = SkeletonNaryLERPState;
		_inputs = new Vector<AnimationNodeBase>();
	}
	
	private function get_inputs():Vector<AnimationNodeBase>
	{
		return _inputs;
	}

	private function set_inputs(value:Vector<AnimationNodeBase>):Vector<AnimationNodeBase>
	{
		return _inputs = value;
	}
	
	private function get_numInputs():Int
	{
		return _numInputs;
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
	public function getInputAt(index:Int):AnimationNodeBase
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
		return Std.instance(animator.getAnimationState(this),SkeletonNaryLERPState);
	}
}
