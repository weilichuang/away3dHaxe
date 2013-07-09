package a3d.animators.nodes;

import a3d.math.MathUtil;
import flash.errors.Error;
import flash.geom.Vector3D;


import a3d.animators.IAnimator;
import a3d.animators.ParticleAnimationSet;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleSpriteSheetState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;

using Reflect;

/**
 * A particle animation node used when a spritesheet texture is required to animate the particle.
 * NB: to enable use of this node, the <code>repeat</code> property on the material has to be set to true.
 */
class ParticleSpriteSheetNode extends ParticleNodeBase
{
	/** @private */
	public static inline var UV_INDEX_0:UInt = 0;

	/** @private */
	public static inline var UV_INDEX_1:UInt = 1;

	/** @private */
	public var usesCycle:Bool;

	/** @private */
	public var usesPhase:Bool;

	/** @private */
	private var _totalFrames:Int;
	/** @private */
	public var numColumns:Int;
	/** @private */
	public var numRows:Int;
	/** @private */
	public var cycleDuration:Float;
	/** @private */
	public var cyclePhase:Float;

	/**
	 * Reference for spritesheet node properties on a single particle (when in local property mode).
	 * Expects a <code>Vector3D</code> representing the cycleDuration (x), optional phaseTime (y).
	 */
	public static inline var UV_VECTOR3D:String = "UVVector3D";

	/**
	 * Defines the number of columns in the spritesheet, when in global mode. Defaults to 1. Read only.
	 */
	private function get_numColumns():Float
	{
		return numColumns;
	}

	/**
	 * Defines the number of rows in the spritesheet, when in global mode. Defaults to 1. Read only.
	 */
	private function get_numRows():Float
	{
		return numRows;
	}

	/**
	 * Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows. Read only.
	 */
	private function get_totalFrames():Float
	{
		return _totalFrames;
	}

	/**
	 * Creates a new <code>ParticleSpriteSheetNode</code>
	 *
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param    [optional] numColumns      Defines the number of columns in the spritesheet, when in global mode. Defaults to 1.
	 * @param    [optional] numRows         Defines the number of rows in the spritesheet, when in global mode. Defaults to 1.
	 * @param    [optional] cycleDuration   Defines the default cycle duration in seconds, when in global mode. Defaults to 1.
	 * @param    [optional] cyclePhase      Defines the default cycle phase, when in global mode. Defaults to 0.
	 * @param    [optional] totalFrames     Defines the total number of frames used by the spritesheet, when in global mode. Defaults to the number defined by numColumns and numRows.
	 * @param    [optional] looping         Defines whether the spritesheet animation is set to loop indefinitely. Defaults to true.
	 */
	public function new(mode:UInt, usesCycle:Bool, usesPhase:Bool, numColumns:Int = 1, numRows:UInt = 1, cycleDuration:Float = 1, cyclePhase:Float = 0, totalFrames:Int = 2147483647)
	{
		var len:Int;
		if (usesCycle)
		{
			len = 2;
			if (usesPhase)
				len++;
		}
		super("ParticleSpriteSheet", mode, len, ParticleAnimationSet.POST_PRIORITY + 1);

		_stateClass = ParticleSpriteSheetState;

		this.usesCycle = usesCycle;
		this.usesPhase = usesPhase;

		this.numColumns = numColumns;
		this.numRows = numRows;
		this.cyclePhase = cyclePhase;
		this.cycleDuration = cycleDuration;
		this._totalFrames = MathUtil.min(totalFrames, numColumns * numRows);
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		//get 2 vc
		var uvParamConst1:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
		var uvParamConst2:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
		animationRegisterCache.setRegisterIndex(this, UV_INDEX_0, uvParamConst1.index);
		animationRegisterCache.setRegisterIndex(this, UV_INDEX_1, uvParamConst2.index);

		var uTotal:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 0);
		var uStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 1);
		var vStep:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst1.regName, uvParamConst1.index, 2);

		var uSpeed:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 0);
		var cycle:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 1);
		var phaseTime:ShaderRegisterElement = new ShaderRegisterElement(uvParamConst2.regName, uvParamConst2.index, 2);


		var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
		var time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
		var vOffset:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
		temp = new ShaderRegisterElement(temp.regName, temp.index, 2);
		var temp2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 3);


		var u:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 0);
		var v:ShaderRegisterElement = new ShaderRegisterElement(animationRegisterCache.uvTarget.regName, animationRegisterCache.uvTarget.index, 1);

		var code:String = "";
		//scale uv
		code += "mul " + u + "," + u + "," + uStep + "\n";
		if (numRows > 1)
			code += "mul " + v + "," + v + "," + vStep + "\n";

		if (usesCycle)
		{
			if (usesPhase)
				code += "add " + time + "," + animationRegisterCache.vertexTime + "," + phaseTime + "\n";
			else
				code += "mov " + time + "," + animationRegisterCache.vertexTime + "\n";
			code += "div " + time + "," + time + "," + cycle + "\n";
			code += "frc " + time + "," + time + "\n";
			code += "mul " + time + "," + time + "," + cycle + "\n";
			code += "mul " + temp + "," + time + "," + uSpeed + "\n";
		}
		else
		{
			code += "mul " + temp.toString() + "," + animationRegisterCache.vertexLife + "," + uTotal + "\n";
		}



		if (numRows > 1)
		{
			code += "frc " + temp2 + "," + temp + "\n";
			code += "sub " + vOffset + "," + temp + "," + temp2 + "\n";
			code += "mul " + vOffset + "," + vOffset + "," + vStep + "\n";
			code += "add " + v + "," + v + "," + vOffset + "\n";
		}

		code += "div " + temp2 + "," + temp + "," + uStep + "\n";
		code += "frc " + temp + "," + temp2 + "\n";
		code += "sub " + temp2 + "," + temp2 + "," + temp + "\n";
		code += "mul " + temp + "," + temp2 + "," + uStep + "\n";

		if (numRows > 1)
			code += "frc " + temp + "," + temp + "\n";
		code += "add " + u + "," + u + "," + temp + "\n";

		return code;
	}

	/**
	 * @inheritDoc
	 */
	public function getAnimationState(animator:IAnimator):ParticleSpriteSheetState
	{
		return Std.instance(animator.getAnimationState(this),ParticleSpriteSheetState);
	}

	/**
	 * @inheritDoc
	 */
	override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		particleAnimationSet.hasUVNode = true;
	}

	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		if (usesCycle)
		{
			var uvCycle:Vector3D = param.field(UV_VECTOR3D);
			if (uvCycle == null)
				throw new Error("there is no " + UV_VECTOR3D + " in param!");
			if (uvCycle.x <= 0)
				throw new Error("the cycle duration must be greater than zero");
				
			var uTotal:Float = _totalFrames / numColumns;
			_oneData[0] = uTotal / uvCycle.x;
			_oneData[1] = uvCycle.x;
			if (usesPhase)
				_oneData[2] = uvCycle.y;
		}
	}
}
