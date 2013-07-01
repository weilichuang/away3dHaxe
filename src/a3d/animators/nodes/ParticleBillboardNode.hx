package a3d.animators.nodes;

import flash.geom.Vector3D;


import a3d.animators.IAnimator;
import a3d.animators.ParticleAnimationSet;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleBillboardState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;



/**
 * A particle animation node that controls the rotation of a particle to always face the camera.
 */
class ParticleBillboardNode extends ParticleNodeBase
{
	/** @private */
	public static inline var MATRIX_INDEX:Int = 0;

	/** @private */
	public var billboardAxis:Vector3D;

	/**
	 * Creates a new <code>ParticleBillboardNode</code>
	 */
	public function new(billboardAxis:Vector3D = null)
	{
		super("ParticleBillboard", ParticlePropertiesMode.GLOBAL, 0, 4);

		_stateClass = ParticleBillboardState;

		this.billboardAxis = billboardAxis;
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
		animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.getFreeVertexConstant();
		animationRegisterCache.getFreeVertexConstant();

		var code:String = "m33 " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + rotationMatrixRegister + "\n";

		var shaderRegisterElement:ShaderRegisterElement;
		for (shaderRegisterElement in animationRegisterCache.rotationRegisters)
			code += "m33 " + shaderRegisterElement.regName + shaderRegisterElement.index + ".xyz," + shaderRegisterElement + "," + rotationMatrixRegister + "\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleBillboardState
	{
		return Std.instance(animator.getAnimationState(this),ParticleBillboardState);
	}

	/**
	 * @inheritDoc
	 */
	override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		particleAnimationSet.hasBillboard = true;
	}
}
