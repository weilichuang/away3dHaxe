package a3d.animators.nodes;

import flash.geom.Vector3D;


import a3d.animators.IAnimator;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleVelocityState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;



/**
 * A particle animation node used to set the starting velocity of a particle.
 */
class ParticleVelocityNode extends ParticleNodeBase
{
	/** @private */
	public static inline var VELOCITY_INDEX:Int = 0;

	/** @private */
	public var velocity:Vector3D;

	/**
	 * Reference for velocity node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> object representing the direction of movement on the particle.
	 */
	public static inline var VELOCITY_VECTOR3D:String = "VelocityVector3D";

	/**
	 * Creates a new <code>ParticleVelocityNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] velocity        Defines the default velocity vector of the node, used when in global mode.
	 */
	public function new(mode:UInt, velocity:Vector3D = null)
	{
		super("ParticleVelocity", mode, 3);

		_stateClass = ParticleVelocityState;

		this.velocity = velocity || new Vector3D();
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;
		var velocityValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, VELOCITY_INDEX, velocityValue.index);

		var distance:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var code:String = "";
		code += "mul " + distance + "," + animationRegisterCache.vertexTime + "," + velocityValue + "\n";
		code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + "," + animationRegisterCache.positionTarget + ".xyz\n";

		if (animationRegisterCache.needVelocity)
			code += "add " + animationRegisterCache.velocityTarget + ".xyz," + velocityValue + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleVelocityState
	{
		return Std.instance(animator.getAnimationState(this),ParticleVelocityState);
	}

	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var _tempVelocity:Vector3D = param[VELOCITY_VECTOR3D];
		if (_tempVelocity == null)
			throw new Error("there is no " + VELOCITY_VECTOR3D + " in param!");

		_oneData[0] = _tempVelocity.x;
		_oneData[1] = _tempVelocity.y;
		_oneData[2] = _tempVelocity.z;
	}
}
