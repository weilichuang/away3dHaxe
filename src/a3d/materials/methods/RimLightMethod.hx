package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.BlendMode;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;


/**
 * RimLightMethod provides a method to add rim lighting to a material. This adds a glow-like effect to edges of objects.
 */
class RimLightMethod extends EffectMethodBase
{
	/**
	 * The blend mode with which to add the light to the object.
	 *
	 * RimLightMethod.MULTIPLY multiplies the rim light with the material's colour.
	 * RimLightMethod.ADD adds the rim light with the material's colour.
	 * RimLightMethod.MIX provides normal alpha blending.
	 */
	public var blendMode(get, set) : BlendMode;
	
	public var color(get, set):UInt;
	
	/**
	 * The strength of the rim light.
	 */
	public var strength(get, set):Float;
	
	public var power(get, set):Float;
	
	private var _color:UInt;
	private var _blendMode:BlendMode;
	private var _colorR:Float;
	private var _colorG:Float;
	private var _colorB:Float;
	private var _strength:Float;
	private var _power:Float;

	/**
	 * Creates a new RimLightMethod.
	 * @param color The colour of the rim light.
	 * @param strength The strength of the rim light.
	 * @param power The power of the rim light. Higher values will result in a higher edge fall-off.
	 * @param blend The blend mode with which to add the light to the object.
	 */
	public function new(color:UInt = 0xffffff, strength:Float = .4, power:Float = 2, blendMode:BlendMode=null)
	{
		super();
		_blendMode = blendMode != null ? blendMode : BlendMode.MIX;
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
	
	
	private function get_blendMode() : BlendMode
	{
		return _blendMode;
	}

	private function set_blendMode(value : BlendMode) : BlendMode
	{
		if (_blendMode == value) 
			return _blendMode;
			
		_blendMode = value;
		invalidateShaderProgram();
		
		return _blendMode;
	}

	
	private function get_color():UInt
	{
		return _color;
	}

	private function set_color(value:UInt):UInt
	{
		_color = value;
		_colorR = ((value >> 16) & 0xff) / 0xff;
		_colorG = ((value >> 8) & 0xff) / 0xff;
		_colorB = (value & 0xff) / 0xff;
		return _color;
	}

	
	private function get_strength():Float
	{
		return _strength;
	}

	private function set_strength(value:Float):Float
	{
		return _strength = value;
	}

	
	private function get_power():Float
	{
		return _power;
	}

	private function set_power(value:Float):Float
	{
		return _power = value;
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


		if (_blendMode == BlendMode.ADD)
		{
			code += "mul " + temp + ".xyz, " + temp + ".w, " + dataRegister + ".xyz							\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + temp + ".xyz						\n";
		}
		else if (_blendMode == BlendMode.MULTIPLY)
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
