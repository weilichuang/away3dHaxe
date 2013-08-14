package a3d.materials.methods;


import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.CubeTextureBase;
import a3d.textures.Texture2DBase;
import flash.Vector;



/**
 * FresnelEnvMapMethod provides a method to add fresnel-based reflectivity to an object using cube maps, which gets
 * stronger as the viewing angle becomes more grazing.
 */
class FresnelEnvMapMethod extends EffectMethodBase
{
	/**
	 * An optional texture to modulate the reflectivity of the surface.
	 */
	public var mask(get,set):Texture2DBase;
	/**
	 * The power used in the Fresnel equation. Higher values make the fresnel effect more pronounced. Defaults to 5.
	 */
	public var fresnelPower(get,set):Float;
	/**
	 * The cubic environment map containing the reflected scene.
	 */
	public var envMap(get,set):CubeTextureBase;
	/**
	 * The reflectivity of the surface.
	 */
	public var alpha(get,set):Float;
	/**
	 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
	 */
	public var normalReflectance(get, set):Float;
	
	private var _cubeTexture:CubeTextureBase;
	private var _fresnelPower:Float = 5;
	private var _normalReflectance:Float = 0;
	private var _alpha:Float;
	private var _mask:Texture2DBase;

	/**
	 * Creates an FresnelEnvMapMethod object.
	 * @param envMap The environment map containing the reflected scene.
	 * @param alpha The reflectivity of the material.
	 */
	public function new(envMap:CubeTextureBase, alpha:Float = 1)
	{
		super();
		_cubeTexture = envMap;
		_alpha = alpha;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
		vo.needsView = true;
		vo.needsUV = _mask != null;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
	}

	
	private function get_mask():Texture2DBase
	{
		return _mask;
	}

	private function set_mask(value:Texture2DBase):Texture2DBase
	{
		if ((value != null) != (_mask != null) ||
			(value != null && _mask != null && 
			(value.hasMipMaps != _mask.hasMipMaps || value.format != _mask.format)))
			invalidateShaderProgram();
		_mask = value;
		return _mask;
	}

	
	private function get_fresnelPower():Float
	{
		return _fresnelPower;
	}

	private function set_fresnelPower(value:Float):Float
	{
		return _fresnelPower = value;
	}

	
	private function get_envMap():CubeTextureBase
	{
		return _cubeTexture;
	}

	private function set_envMap(value:CubeTextureBase):CubeTextureBase
	{
		return _cubeTexture = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
	}

	
	private function get_alpha():Float
	{
		return _alpha;
	}

	private function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	
	private function get_normalReflectance():Float
	{
		return _normalReflectance;
	}

	private function set_normalReflectance(value:Float):Float
	{
		return _normalReflectance = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;
		var context:Context3DProxy = stage3DProxy.context3D;
		data[index] = _alpha;
		data[index + 1] = _normalReflectance;
		data[index + 2] = _fresnelPower;
		context.setTextureAt(vo.texturesIndex, _cubeTexture.getTextureForStage3D(stage3DProxy));
		if (_mask != null)
			context.setTextureAt(vo.texturesIndex + 1, _mask.getTextureForStage3D(stage3DProxy));
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var dataRegister:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var code:String = "";
		var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
		var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;

		vo.texturesIndex = cubeMapReg.index;
		vo.fragmentConstantsIndex = dataRegister.index * 4;

		regCache.addFragmentTempUsages(temp, 1);
		var temp2:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

		// r = V - 2(V.N)*N
		code += "dp3 " + temp + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz		\n" +
				"add " + temp + ".w, " + temp + ".w, " + temp + ".w											\n" +
				"mul " + temp + ".xyz, " + normalReg + ".xyz, " + temp + ".w						\n" +
				"sub " + temp + ".xyz, " + temp + ".xyz, " + viewDirReg + ".xyz					\n" +
				getTexCubeSampleCode(vo, temp, cubeMapReg, _cubeTexture, temp) +
				"sub " + temp2 + ".w, " + temp + ".w, fc0.x									\n" + // -.5
				"kil " + temp2 + ".w\n" + // used for real time reflection mapping - if alpha is not 1 (mock texture) kil output
				"sub " + temp + ", " + temp + ", " + targetReg + "											\n";

		// calculate fresnel term
		code += "dp3 " + viewDirReg + ".w, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" + // dot(V, H)
				"sub " + viewDirReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" + // base = 1-dot(V, H)

				"pow " + viewDirReg + ".w, " + viewDirReg + ".w, " + dataRegister + ".z\n" + // exp = pow(base, 5)

				"sub " + normalReg + ".w, " + dataRegister + ".w, " + viewDirReg + ".w\n" + // 1 - exp
				"mul " + normalReg + ".w, " + dataRegister + ".y, " + normalReg + ".w\n" + // f0*(1 - exp)
				"add " + viewDirReg + ".w, " + viewDirReg + ".w, " + normalReg + ".w\n" + // exp + f0*(1 - exp)

				// total alpha
				"mul " + viewDirReg + ".w, " + dataRegister + ".x, " + viewDirReg + ".w\n";

		if (_mask != null)
		{
			var maskReg:ShaderRegisterElement = regCache.getFreeTextureReg();
			code += getTex2DSampleCode(vo, temp2, maskReg, _mask, _sharedRegisters.uvVarying) +
					"mul " + viewDirReg + ".w, " + temp2 + ".x, " + viewDirReg + ".w\n";
		}

		// blend
		code += "mul " + temp + ", " + temp + ", " + viewDirReg + ".w						\n" +
				"add " + targetReg + ", " + targetReg + ", " + temp + "						\n";

		regCache.removeFragmentTempUsage(temp);

		return code;
	}
}
