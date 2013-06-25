package a3d.animators.nodes;

import flash.geom.ColorTransform;


import a3d.animators.ParticleAnimationSet;
import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.states.ParticleInitialColorState;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;




class ParticleInitialColorNode extends ParticleNodeBase
{
	/** @private */
	public static inline var MULTIPLIER_INDEX:UInt = 0;
	/** @private */
	public static inline var OFFSET_INDEX:UInt = 1;

	//default values used when creating states
	/** @private */
	public var usesMultiplier:Bool;
	/** @private */
	public var usesOffset:Bool;
	/** @private */
	public var initialColor:ColorTransform;

	/**
	 * Reference for color node properties on a single particle (when in local property mode).
	 * Expects a <code>ColorTransform</code> object representing the color transform applied to the particle.
	 */
	public static inline var COLOR_INITIAL_COLORTRANSFORM:String = "ColorInitialColorTransform";

	public function new(mode:UInt, usesMultiplier:Bool = true, usesOffset:Bool = false, initialColor:ColorTransform = null)
	{
		_stateClass = ParticleInitialColorState;

		this.usesMultiplier = usesMultiplier;
		this.usesOffset = usesOffset;
		this.initialColor = initialColor || new ColorTransform();
		super("ParticleInitialColor", mode, (usesMultiplier && usesOffset) ? 8 : 4, ParticleAnimationSet.COLOR_PRIORITY);
	}

	/**
	 * @inheritDoc
	 */
	override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		pass = pass;

		var code:String = "";
		if (animationRegisterCache.needFragmentAnimation)
		{

			if (usesMultiplier)
			{
				var multiplierValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, MULTIPLIER_INDEX, multiplierValue.index);

				code += "mul " + animationRegisterCache.colorMulTarget + "," + multiplierValue + "," + animationRegisterCache.colorMulTarget + "\n";
			}

			if (usesOffset)
			{
				var offsetValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.LOCAL_STATIC) ? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, OFFSET_INDEX, offsetValue.index);

				code += "add " + animationRegisterCache.colorAddTarget + "," + offsetValue + "," + animationRegisterCache.colorAddTarget + "\n";
			}
		}

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
		if (usesMultiplier)
			particleAnimationSet.hasColorMulNode = true;
		if (usesOffset)
			particleAnimationSet.hasColorAddNode = true;
	}

	/**
	 * @inheritDoc
	 */
	override public function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
		var initialColor:ColorTransform = param[COLOR_INITIAL_COLORTRANSFORM];
		if (initialColor == null)
			throw(new Error("there is no " + COLOR_INITIAL_COLORTRANSFORM + " in param!"));

		var i:UInt;

		//multiplier
		if (usesMultiplier)
		{
			_oneData[i++] = initialColor.redMultiplier;
			_oneData[i++] = initialColor.greenMultiplier;
			_oneData[i++] = initialColor.blueMultiplier;
			_oneData[i++] = initialColor.alphaMultiplier;
		}
		//offset
		if (usesOffset)
		{
			_oneData[i++] = initialColor.redOffset / 255;
			_oneData[i++] = initialColor.greenOffset / 255;
			_oneData[i++] = initialColor.blueOffset / 255;
			_oneData[i++] = initialColor.alphaOffset / 255;
		}

	}

}
