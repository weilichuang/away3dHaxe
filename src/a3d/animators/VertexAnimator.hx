package a3d.animators;

import flash.display3D.Context3DProgramType;
import flash.errors.Error;
import flash.Vector;


import a3d.animators.data.VertexAnimationMode;
import a3d.animators.states.IVertexAnimationState;
import a3d.animators.transitions.IAnimationTransition;
import a3d.entities.Camera3D;
import a3d.core.base.Geometry;
import a3d.core.base.IRenderable;
import a3d.core.base.ISubGeometry;
import a3d.core.base.SubMesh;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.passes.MaterialPassBase;



/**
 * Provides an interface for assigning vertex-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 */
class VertexAnimator extends AnimatorBase implements IAnimator
{
	private var _vertexAnimationSet:VertexAnimationSet;
	private var _poses:Vector<Geometry>;
	private var _weights:Vector<Float>;
	private var _numPoses:Int;
	private var _blendMode:String;
	private var _activeVertexState:IVertexAnimationState;

	/**
	 * Creates a new <code>VertexAnimator</code> object.
	 *
	 * @param vertexAnimationSet The animation data set containing the vertex animations used by the animator.
	 */
	public function new(vertexAnimationSet:VertexAnimationSet)
	{
		super(vertexAnimationSet);

		_vertexAnimationSet = vertexAnimationSet;
		_numPoses = vertexAnimationSet.numPoses;
		_blendMode = vertexAnimationSet.blendMode;
		
		_poses = new Vector<Geometry>();
		_weights = Vector.ofArray([1., 0, 0, 0]);
	}

	/**
	 * @inheritDoc
	 */
	public function clone():IAnimator
	{
		return new VertexAnimator(_vertexAnimationSet);
	}

	/**
	 * Plays a sequence with a given name. If the sequence is not found, it may not be loaded yet, and it will retry every frame.
	 * @param sequenceName The name of the clip to be played.
	 */
	public function play(name:String, transition:IAnimationTransition = null, offset:Float = null):Void
	{
		if (_activeAnimationName == name)
			return;

		_activeAnimationName = name;

		//TODO: implement transitions in vertex animator

		if (!_animationSet.hasAnimation(name))
			throw new Error("Animation root node " + name + " not found!");

		_activeNode = _animationSet.getAnimation(name);

		_activeState = getAnimationState(_activeNode);

		if (updatePosition)
		{
			//update straight away to reset position deltas
			_activeState.update(Std.int(_absoluteTime));
			_activeState.positionDelta;
		}

		_activeVertexState = Std.instance(_activeState,IVertexAnimationState);

		start();

		//apply a time offset if specified
		if (!Math.isNaN(offset))
			reset(name, offset);
	}

	/**
	 * @inheritDoc
	 */
	override private function updateDeltaTime(dt:Float):Void
	{
		super.updateDeltaTime(dt);

		_poses[0] = _activeVertexState.currentGeometry;
		_poses[1] = _activeVertexState.nextGeometry;
		_weights[0] = 1 - (_weights[1] = _activeVertexState.blendWeight);
	}


	/**
	 * @inheritDoc
	 */
	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
	{
		// todo: add code for when running on cpu

		// if no poses defined, set temp data
		if (_poses.length == 0)
		{
			setNullPose(stage3DProxy, renderable, vertexConstantOffset, vertexStreamOffset);
			return;
		}

		// this type of animation can only be SubMesh
		var subMesh:SubMesh = Std.instance(renderable,SubMesh);
		var subGeom:ISubGeometry;

		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

		var s:UInt;
		if (_blendMode == VertexAnimationMode.ABSOLUTE)
		{
			s = 1;
			subGeom = _poses[0].subGeometries[subMesh.index];
			// set the base sub-geometry so the material can simply pick up on this data
			if (subGeom != null)
				subMesh.subGeometry = subGeom;
		}
		else
			s = 0;

		for (i in s..._numPoses)
		{
			if (_poses[i].subGeometries[subMesh.index] != null)
			{
				subGeom = _poses[i].subGeometries[subMesh.index];
			}
			else 
			{
				subGeom =  subMesh.subGeometry;
			}

			subGeom.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);

			if (_vertexAnimationSet.useNormals)
				subGeom.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);

		}
	}

	private function setNullPose(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int):Void
	{
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _weights, 1);

		if (_blendMode == VertexAnimationMode.ABSOLUTE)
		{
			var len:UInt = _numPoses;
			for (i in 1...len)
			{
				renderable.activateVertexBuffer(vertexStreamOffset++, stage3DProxy);

				if (_vertexAnimationSet.useNormals)
					renderable.activateVertexNormalBuffer(vertexStreamOffset++, stage3DProxy);
			}
		}
		// todo: set temp data for additive?
	}


	/**
	 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
	 * Needs to be called if gpu code is potentially required.
	 */
	public function testGPUCompatibility(pass:MaterialPassBase):Void
	{
	}
}
