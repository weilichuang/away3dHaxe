package a3d.animators;

import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.AnimationSubGeometry;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleNodeBase;
import a3d.animators.states.ParticleStateBase;
import a3d.core.base.IRenderable;
import a3d.core.base.ISubGeometry;
import a3d.core.base.SubMesh;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.materials.passes.MaterialPassBase;
import flash.display3D.Context3DProgramType;
import flash.errors.Error;
import flash.Vector;
import haxe.ds.WeakMap;




/**
 * Provides an interface for assigning paricle-based animation data sets to mesh-based entity objects
 * and controlling the various available states of animation through an interative playhead that can be
 * automatically updated or manually triggered.
 *
 * Requires that the containing geometry of the parent mesh is particle geometry
 *
 * @see a3d.core.base.ParticleGeometry
 */
class ParticleAnimator extends AnimatorBase implements IAnimator
{

	private var _particleAnimationSet:ParticleAnimationSet;
	private var _animationParticleStates:Vector<ParticleStateBase>;
	private var _animatorParticleStates:Vector<ParticleStateBase>;
	private var _timeParticleStates:Vector<ParticleStateBase>;
	private var _totalLenOfOneVertex:Int = 0;
	private var _animatorSubGeometries:WeakMap<ISubGeometry,AnimationSubGeometry>;

	/**
	 * Creates a new <code>ParticleAnimator</code> object.
	 *
	 * @param particleAnimationSet The animation data set containing the particle animations used by the animator.
	 */
	public function new(particleAnimationSet:ParticleAnimationSet)
	{
		super(particleAnimationSet);
		
		_animationParticleStates = new Vector<ParticleStateBase>();
		_animatorParticleStates = new Vector<ParticleStateBase>();
		_timeParticleStates = new Vector<ParticleStateBase>();
		_animatorSubGeometries = new WeakMap<ISubGeometry,AnimationSubGeometry>();
	
		_particleAnimationSet = particleAnimationSet;

		var state:ParticleStateBase;
		var node:ParticleNodeBase;
		for (node in _particleAnimationSet.particleNodes)
		{
			state = Std.instance(getAnimationState(node),ParticleStateBase);
			if (node.mode == ParticlePropertiesMode.LOCAL_DYNAMIC)
			{
				_animatorParticleStates.push(state);
				node.dataOffset = _totalLenOfOneVertex;
				_totalLenOfOneVertex += node.dataLength;
			}
			else
			{
				_animationParticleStates.push(state);
			}
			if (state.needUpdateTime)
				_timeParticleStates.push(state);
		}
	}

	/**
	 * @inheritDoc
	 */
	public function clone():IAnimator
	{
		return new ParticleAnimator(_particleAnimationSet);
	}

	/**
	 * @inheritDoc
	 */
	public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:Int, vertexStreamOffset:Int, camera:Camera3D):Void
	{
		var animationRegisterCache:AnimationRegisterCache = _particleAnimationSet.animationRegisterCache;

		var subMesh:SubMesh = Std.instance(renderable,SubMesh);
		var state:ParticleStateBase;

		if (subMesh == null)
			throw new Error("Must be subMesh") ;

		//process animation sub geometries
		if (subMesh.animationSubGeometry == null)
			_particleAnimationSet.generateAnimationSubGeometries(subMesh.parentMesh);

		var animationSubGeometry:AnimationSubGeometry = subMesh.animationSubGeometry;

		for (state in _animationParticleStates)
			state.setRenderState(stage3DProxy, renderable, animationSubGeometry, animationRegisterCache, camera);

		//process animator subgeometries
		if (subMesh.animatorSubGeometry == null && _animatorParticleStates.length != 0)
			generateAnimatorSubGeometry(subMesh);

		var animatorSubGeometry:AnimationSubGeometry = subMesh.animatorSubGeometry;

		for (state in _animatorParticleStates)
			state.setRenderState(stage3DProxy, renderable, animatorSubGeometry, animationRegisterCache, camera);

		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegisterCache.vertexConstantOffset, animationRegisterCache.vertexConstantData, animationRegisterCache.numVertexConstant);

		if (animationRegisterCache.numFragmentConstant > 0)
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegisterCache.fragmentConstantOffset, animationRegisterCache.fragmentConstantData, animationRegisterCache.numFragmentConstant);
	}

	/**
	 * @inheritDoc
	 */
	public function testGPUCompatibility(pass:MaterialPassBase):Void
	{

	}

	/**
	 * @inheritDoc
	 */
	override public function start():Void
	{
		super.start();
		for (state in _timeParticleStates)
		{
			state.offset(Std.int(_absoluteTime));
		}
	}

	/**
	 * @inheritDoc
	 */
	override private function updateDeltaTime(dt:Float):Void
	{
		_absoluteTime += dt;

		for(state in _timeParticleStates)
		{
			state.update(Std.int(_absoluteTime));
		}
	}

	/**
	 * @inheritDoc
	 */
	public function resetTime(offset:Int = 0):Void
	{
		for (state in _timeParticleStates)
		{
			state.offset(Std.int(_absoluteTime + offset));
		}
		update(time);
	}

	override public function dispose():Void
	{
		var subGeometry:AnimationSubGeometry;
		for (subGeometry in _animatorSubGeometries)
		{
			subGeometry.dispose();
		}
	}

	private function generateAnimatorSubGeometry(subMesh:SubMesh):Void
	{
		var subGeometry:ISubGeometry = subMesh.subGeometry;
		
		var animatorSubGeometry:AnimationSubGeometry = new AnimationSubGeometry();
		_animatorSubGeometries.set(subGeometry,animatorSubGeometry);
		subMesh.animatorSubGeometry = animatorSubGeometry;

		//create the vertexData vector that will be used for local state data
		animatorSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);

		//pass the particles data to the animator subGeometry
		animatorSubGeometry.animationParticles = subMesh.animationSubGeometry.animationParticles;
	}
}
