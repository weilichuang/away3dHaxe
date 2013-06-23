package a3d.materials.methods
{
	
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.compilation.ShaderRegisterCache;
	import a3d.materials.compilation.ShaderRegisterElement;
	import a3d.textures.PlanarReflectionTexture;

	

	/**
	 * PlanarReflectionMethod is a material method that adds reflections from a PlanarReflectionTexture object.
	 *
	 * @see a3d.textures.PlanarReflectionTexture
	 */
	class PlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture:PlanarReflectionTexture;
		private var _alpha:Float = 1;
		private var _normalDisplacement:Float = 0;

		/**
		 * Creates a new PlanarReflectionMethod
		 * @param texture The PlanarReflectionTexture used to render the reflected view.
		 * @param alpha The reflectiveness of the surface.
		 */
		public function PlanarReflectionMethod(texture:PlanarReflectionTexture, alpha:Float = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}

		/**
		 * @inheritDoc
		 */
		override public function initVO(vo:MethodVO):Void
		{
			vo.needsProjection = true;
			vo.needsNormals = _normalDisplacement > 0;
		}

		/**
		 * The reflectiveness of the surface.
		 */
		private inline function get_alpha():Float
		{
			return _alpha;
		}

		private inline function set_alpha(value:Float):Void
		{
			_alpha = value;
		}

		/**
		 * The PlanarReflectionTexture used to render the reflected view.
		 */
		private inline function get_texture():PlanarReflectionTexture
		{
			return _texture;
		}

		private inline function set_texture(value:PlanarReflectionTexture):Void
		{
			_texture = value;
		}

		/**
		 * The amount of displacement on the surface, for use with water waves.
		 */
		private inline function get_normalDisplacement():Float
		{
			return _normalDisplacement;
		}

		private inline function set_normalDisplacement(value:Float):Void
		{
			if (_normalDisplacement == value)
				return;
			if (_normalDisplacement == 0 || value == 0)
				invalidateShaderProgram();
			_normalDisplacement = value;
		}

		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			var index:Int = vo.fragmentConstantsIndex;
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			vo.fragmentData[index] = _texture.textureRatioX * .5;
			vo.fragmentData[uint(index + 1)] = _texture.textureRatioY * .5;
			vo.fragmentData[uint(index + 3)] = _alpha;
			if (_normalDisplacement > 0)
			{
				vo.fragmentData[uint(index + 2)] = _normalDisplacement;
				vo.fragmentData[uint(index + 4)] = .5 + _texture.textureRatioX * .5 - 1 / _texture.width;
				vo.fragmentData[uint(index + 5)] = .5 + _texture.textureRatioY * .5 - 1 / _texture.height;
				vo.fragmentData[uint(index + 6)] = .5 - _texture.textureRatioX * .5 + 1 / _texture.width;
				vo.fragmentData[uint(index + 7)] = .5 - _texture.textureRatioY * .5 + 1 / _texture.height;
			}
		}

		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();

			var filter:String = vo.useSmoothTextures ? "linear" : "nearest";
			var code:String;
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataReg.index * 4;
			// fc0.x = .5

			var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;

			regCache.addFragmentTempUsages(temp, 1);

			code = "div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + "\n" +
				"add " + temp + ", " + temp + ", fc0.xx\n";

			if (_normalDisplacement > 0)
			{
				var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
				code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" +
					"sub " + temp + ".z, fc0.w, " + _sharedRegisters.normalFragment + ".y\n" +
					"div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" +
					"mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" +
					"min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".x\n" +
					"max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n";
			}

			var temp2:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
			code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d," + filter + ">\n" +
				"sub " + temp2 + ", " + temp + ".w,  fc0.x\n" +
				"kil " + temp2 + "\n" +
				"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + ".w\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "\n";

			regCache.removeFragmentTempUsage(temp);

			return code;
		}
	}
}
