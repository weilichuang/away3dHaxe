package a3d.materials.methods
{
	
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.compilation.ShaderRegisterCache;
	import a3d.materials.compilation.ShaderRegisterElement;
	import a3d.textures.PlanarReflectionTexture;

	

	/**
	 * Allows the use of an additional texture to specify the alpha value of the material. When used with the secondary uv
	 * set, it allows for a tiled main texture with independently varying alpha (useful for water etc).
	 */
	class FresnelPlanarReflectionMethod extends EffectMethodBase
	{
		private var _texture:PlanarReflectionTexture;
		private var _alpha:Float = 1;
		private var _normalDisplacement:Float = 0;
		private var _normalReflectance:Float = 0;
		private var _fresnelPower:Float = 5;

		public function FresnelPlanarReflectionMethod(texture:PlanarReflectionTexture, alpha:Float = 1)
		{
			super();
			_texture = texture;
			_alpha = alpha;
		}

		private inline function get_alpha():Float
		{
			return _alpha;
		}

		private inline function set_alpha(value:Float):Void
		{
			_alpha = value;
		}

		private inline function get_fresnelPower():Float
		{
			return _fresnelPower;
		}

		private inline function set_fresnelPower(value:Float):Void
		{
			_fresnelPower = value;
		}

		/**
		 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
		 */
		private inline function get_normalReflectance():Float
		{
			return _normalReflectance;
		}

		private inline function set_normalReflectance(value:Float):Void
		{
			_normalReflectance = value;
		}

		override public function initVO(vo:MethodVO):Void
		{
			vo.needsProjection = true;
			vo.needsNormals = true;
			vo.needsView = true;
		}

		private inline function get_texture():PlanarReflectionTexture
		{
			return _texture;
		}

		private inline function set_texture(value:PlanarReflectionTexture):Void
		{
			_texture = value;
		}

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
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
			vo.fragmentData[vo.fragmentConstantsIndex] = _texture.textureRatioX * .5;
			vo.fragmentData[vo.fragmentConstantsIndex + 1] = _texture.textureRatioY * .5;
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = _alpha;
			vo.fragmentData[vo.fragmentConstantsIndex + 4] = _normalReflectance;
			vo.fragmentData[vo.fragmentConstantsIndex + 5] = _fresnelPower;
			if (_normalDisplacement > 0)
			{
				vo.fragmentData[vo.fragmentConstantsIndex + 2] = _normalDisplacement;
				vo.fragmentData[vo.fragmentConstantsIndex + 6] = .5 + _texture.textureRatioX * .5 - 1 / _texture.width;
				vo.fragmentData[vo.fragmentConstantsIndex + 7] = .5 - _texture.textureRatioX * .5 + 1 / _texture.width;
			}
		}

		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var textureReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();

			var filter:String = vo.useSmoothTextures ? "linear" : "nearest";
			var code:String;
			vo.texturesIndex = textureReg.index;
			vo.fragmentConstantsIndex = dataReg.index * 4;
			// fc0.x = .5

			var projectionReg:ShaderRegisterElement = _sharedRegisters.projectionFragment;
			var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
			var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;

			code = "div " + temp + ", " + projectionReg + ", " + projectionReg + ".w\n" +
				"mul " + temp + ", " + temp + ", " + dataReg + ".xyww\n" +
				"add " + temp + ".xy, " + temp + ".xy, fc0.xx\n";

			if (_normalDisplacement > 0)
			{
				code += "add " + temp + ".w, " + projectionReg + ".w, " + "fc0.w\n" +
					"sub " + temp + ".z, fc0.w, " + normalReg + ".y\n" +
					"div " + temp + ".z, " + temp + ".z, " + temp + ".w\n" +
					"mul " + temp + ".z, " + dataReg + ".z, " + temp + ".z\n" +
					"add " + temp + ".x, " + temp + ".x, " + temp + ".z\n" +
					"min " + temp + ".x, " + temp + ".x, " + dataReg2 + ".z\n" +
					"max " + temp + ".x, " + temp + ".x, " + dataReg2 + ".w\n";
			}

			code += "tex " + temp + ", " + temp + ", " + textureReg + " <2d," + filter + ">\n" +
				"sub " + viewDirReg + ".w, " + temp + ".w,  fc0.x\n" +
				"kil " + viewDirReg + ".w\n";

			// calculate fresnel term
			code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" + // dot(V, H)
				"sub " + viewDirReg + ".w, fc0.w, " + viewDirReg + ".w\n" + // base = 1-dot(V, H)

				"pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataReg2 + ".y\n" + // exp = pow(base, 5)

				"sub " + normalReg + ".w, fc0.w, " + viewDirReg + ".w\n" + // 1 - exp
				"mul " + normalReg + ".w, " + dataReg2 + ".x, " + normalReg + ".w\n" + // f0*(1 - exp)
				"add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" + // exp + f0*(1 - exp)

				// total alpha
				"mul " + viewDirReg + ".w, " + dataReg + ".w, " + viewDirReg + ".w\n" +

				"sub " + temp + ", " + temp + ", " + targetReg + "\n" +
				"mul " + temp + ", " + temp + ", " + viewDirReg + ".w\n" +

				"add " + targetReg + ", " + targetReg + ", " + temp + "\n";

			return code;
		}
	}
}
