package away3d.animators.nodes
{
	import flash.geom.ColorTransform;

	
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.states.ParticleInitialColorState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;

	


	public class ParticleInitialColorNode extends ParticleNodeBase
	{
		/** @private */
		public static const MULTIPLIER_INDEX:uint = 0;
		/** @private */
		public static const OFFSET_INDEX:uint = 1;

		//default values used when creating states
		/** @private */
		public var _usesMultiplier:Boolean;
		/** @private */
		public var _usesOffset:Boolean;
		/** @private */
		public var _initialColor:ColorTransform;

		/**
		 * Reference for color node properties on a single particle (when in local property mode).
		 * Expects a <code>ColorTransform</code> object representing the color transform applied to the particle.
		 */
		public static const COLOR_INITIAL_COLORTRANSFORM:String = "ColorInitialColorTransform";

		public function ParticleInitialColorNode(mode:uint, usesMultiplier:Boolean = true, usesOffset:Boolean = false, initialColor:ColorTransform = null)
		{
			_stateClass = ParticleInitialColorState;

			_usesMultiplier = usesMultiplier;
			_usesOffset = usesOffset;
			_initialColor = initialColor || new ColorTransform();
			super("ParticleInitialColor", mode, (_usesMultiplier && _usesOffset) ? 8 : 4, ParticleAnimationSet.COLOR_PRIORITY);
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

				if (_usesMultiplier)
				{
					var multiplierValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
					animationRegisterCache.setRegisterIndex(this, MULTIPLIER_INDEX, multiplierValue.index);

					code += "mul " + animationRegisterCache.colorMulTarget + "," + multiplierValue + "," + animationRegisterCache.colorMulTarget + "\n";
				}

				if (_usesOffset)
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
		override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			if (_usesMultiplier)
				particleAnimationSet.hasColorMulNode = true;
			if (_usesOffset)
				particleAnimationSet.hasColorAddNode = true;
		}

		/**
		 * @inheritDoc
		 */
		override public function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			var initialColor:ColorTransform = param[COLOR_INITIAL_COLORTRANSFORM];
			if (!initialColor)
				throw(new Error("there is no " + COLOR_INITIAL_COLORTRANSFORM + " in param!"));

			var i:uint;

			//multiplier
			if (_usesMultiplier)
			{
				_oneData[i++] = initialColor.redMultiplier;
				_oneData[i++] = initialColor.greenMultiplier;
				_oneData[i++] = initialColor.blueMultiplier;
				_oneData[i++] = initialColor.alphaMultiplier;
			}
			//offset
			if (_usesOffset)
			{
				_oneData[i++] = initialColor.redOffset / 255;
				_oneData[i++] = initialColor.greenOffset / 255;
				_oneData[i++] = initialColor.blueOffset / 255;
				_oneData[i++] = initialColor.alphaOffset / 255;
			}

		}

	}

}
