package a3d.materials.methods
{
	
	import a3d.core.managers.Stage3DProxy;
	import a3d.materials.compilation.ShaderRegisterCache;
	import a3d.materials.compilation.ShaderRegisterElement;

	

	class RimLightMethod extends EffectMethodBase
	{
		public static inline var ADD:String = "add";
		public static inline var MULTIPLY:String = "multiply";
		public static inline var MIX:String = "mix";

		private var _color:UInt;
		private var _blend:String;
		private var _colorR:Float;
		private var _colorG:Float;
		private var _colorB:Float;
		private var _strength:Float;
		private var _power:Float;

		public function RimLightMethod(color:UInt = 0xffffff, strength:Float = .4, power:Float = 2, blend:String = "mix")
		{
			super();
			_blend = blend;
			_strength = strength;
			_power = power;
			this.color = color;
		}


		override public function initConstants(vo:MethodVO):Void
		{
			vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
		}

		override public function initVO(vo:MethodVO):Void
		{
			vo.needsNormals = true;
			vo.needsView = true;
		}

		private inline function get_color():UInt
		{
			return _color;
		}

		private inline function set_color(value:UInt):Void
		{
			_color = value;
			_colorR = ((value >> 16) & 0xff) / 0xff;
			_colorG = ((value >> 8) & 0xff) / 0xff;
			_colorB = (value & 0xff) / 0xff;
		}

		private inline function get_strength():Float
		{
			return _strength;
		}

		private inline function set_strength(value:Float):Void
		{
			_strength = value;
		}

		private inline function get_power():Float
		{
			return _power;
		}

		private inline function set_power(value:Float):Void
		{
			_power = value;
		}

		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			var index:Int = vo.fragmentConstantsIndex;
			var data:Vector<Float> = vo.fragmentData;
			data[index] = _colorR;
			data[index + 1] = _colorG;
			data[index + 2] = _colorB;
			data[index + 4] = _strength;
			data[index + 5] = _power;
		}

		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var dataRegister2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var code:String = "";

			vo.fragmentConstantsIndex = dataRegister.index * 4;

			code += "dp3 " + temp + ".x, " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.normalFragment + ".xyz	\n" +
				"sat " + temp + ".x, " + temp + ".x														\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"pow " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".y							\n" +
				"mul " + temp + ".x, " + temp + ".x, " + dataRegister2 + ".x							\n" +
				"sub " + temp + ".x, " + dataRegister + ".w, " + temp + ".x								\n" +
				"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".x						\n" +
				"sub " + temp + ".w, " + dataRegister + ".w, " + temp + ".x								\n";


			if (_blend == ADD)
			{
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			}
			else if (_blend == MULTIPLY)
			{
				code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
			}
			else
			{
				code += "sub " + temp + ".xyz, " + dataRegister + ".xyz, " + targetReg + ".xyz				\n" +
					"mul " + temp + ".xyz, " + temp + ".xyz, " + temp + ".w								\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz					\n";
			}

			return code;
		}
	}
}
