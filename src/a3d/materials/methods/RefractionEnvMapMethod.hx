package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.CubeTextureBase;
import flash.Vector;



class RefractionEnvMapMethod extends EffectMethodBase
{
	private var _envMap:CubeTextureBase;

	private var _dispersionR:Float = 0;
	private var _dispersionG:Float = 0;
	private var _dispersionB:Float = 0;
	private var _useDispersion:Bool;
	private var _refractionIndex:Float;
	private var _alpha:Float = 1;

	// example values for dispersion: dispersionR : Number = -0.03, dispersionG : Number = -0.01, dispersionB : Number = .0015
	public function new(envMap:CubeTextureBase, refractionIndex:Float = .1, dispersionR:Float = 0, dispersionG:Float = 0, dispersionB:Float = 0)
	{
		super();
		_envMap = envMap;
		_dispersionR = dispersionR;
		_dispersionG = dispersionG;
		_dispersionB = dispersionB;
		_useDispersion = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		_refractionIndex = refractionIndex;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index + 4] = 1;
		data[index + 5] = 0;
		data[index + 7] = 1;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
		vo.needsView = true;
	}

	/**
	 * The cube environment map to use for the refraction.
	 */
	public var envMap(get,set):CubeTextureBase;
	private inline function get_envMap():CubeTextureBase
	{
		return _envMap;
	}

	private inline function set_envMap(value:CubeTextureBase):CubeTextureBase
	{
		return _envMap = value;
	}

	public var refractionIndex(get,set):Float;
	private inline function get_refractionIndex():Float
	{
		return _refractionIndex;
	}

	private inline function set_refractionIndex(value:Float):Float
	{
		return _refractionIndex = value;
	}

	public var dispersionR(get,set):Float;
	private inline function get_dispersionR():Float
	{
		return _dispersionR;
	}

	private inline function set_dispersionR(value:Float):Float
	{
		_dispersionR = value;

		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion)
		{
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		return _dispersionR;
	}

	public var dispersionG(get,set):Float;
	private inline function get_dispersionG():Float
	{
		return _dispersionG;
	}

	private inline function set_dispersionG(value:Float):Float
	{
		_dispersionG = value;

		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion)
		{
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		
		return _dispersionG;
	}

	public var dispersionR(get,set):Float;
	private inline function get_dispersionB():Float
	{
		return _dispersionB;
	}

	private inline function set_dispersionB(value:Float):Float
	{
		_dispersionB = value;

		var useDispersion:Bool = !(_dispersionR == _dispersionB && _dispersionR == _dispersionG);
		if (_useDispersion != useDispersion)
		{
			invalidateShaderProgram();
			_useDispersion = useDispersion;
		}
		return _dispersionB;
	}

	public var alpha(get,set):Float;
	private inline function get_alpha():Float
	{
		return _alpha;
	}

	private inline function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = _dispersionR + _refractionIndex;
		if (_useDispersion)
		{
			data[index + 1] = _dispersionG + _refractionIndex;
			data[index + 2] = _dispersionB + _refractionIndex;
		}
		data[index + 3] = _alpha;
		stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _envMap.getTextureForStage3D(stage3DProxy));
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		// todo: data2.x could use common reg, so only 1 reg is used
		var data:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var data2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var code:String = "";
		var cubeMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var refractionDir:ShaderRegisterElement;
		var refractionColor:ShaderRegisterElement;
		var temp:ShaderRegisterElement;

		vo.texturesIndex = cubeMapReg.index;
		vo.fragmentConstantsIndex = data.index * 4;

		refractionDir = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(refractionDir, 1);
		refractionColor = regCache.getFreeFragmentVectorTemp();
		regCache.addFragmentTempUsages(refractionColor, 1);

		temp = regCache.getFreeFragmentVectorTemp();

		var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
		var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;

		code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";

		code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
			"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
			"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
			"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
			"mul " + temp + ".w, " + data + ".x, " + temp + ".w\n" +
			"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
			"sqt " + temp + ".y, " + temp + ".w\n" +

			"mul " + temp + ".x, " + data + ".x, " + temp + ".x\n" +
			"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
			"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +

			"mul " + refractionDir + ", " + data + ".x, " + viewDirReg + "\n" +
			"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
			"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";


		code += getTexCubeSampleCode(vo, refractionColor, cubeMapReg, _envMap, refractionDir) +
			"sub " + refractionColor + ".w, " + refractionColor + ".w, fc0.x	\n" +
			"kil " + refractionColor + ".w\n";

		if (_useDispersion)
		{
			// GREEN

			code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
				"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".y, " + temp + ".w\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"sqt " + temp + ".y, " + temp + ".w\n" +

				"mul " + temp + ".x, " + data + ".y, " + temp + ".x\n" +
				"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
				"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +

				"mul " + refractionDir + ", " + data + ".y, " + viewDirReg + "\n" +
				"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
				"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";
			//
			code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
				"mov " + refractionColor + ".y, " + temp + ".y\n";



			// BLUE

			code += "dp3 " + temp + ".x, " + viewDirReg + ".xyz, " + normalReg + ".xyz\n" +
				"mul " + temp + ".w, " + temp + ".x, " + temp + ".x\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
				"mul " + temp + ".w, " + data + ".z, " + temp + ".w\n" +
				"sub " + temp + ".w, " + data2 + ".x, " + temp + ".w\n" +
				"sqt " + temp + ".y, " + temp + ".w\n" +

				"mul " + temp + ".x, " + data + ".z, " + temp + ".x\n" +
				"add " + temp + ".x, " + temp + ".x, " + temp + ".y\n" +
				"mul " + temp + ".xyz, " + temp + ".x, " + normalReg + ".xyz\n" +

				"mul " + refractionDir + ", " + data + ".z, " + viewDirReg + "\n" +
				"sub " + refractionDir + ".xyz, " + refractionDir + ".xyz, " + temp + ".xyz\n" +
				"nrm " + refractionDir + ".xyz, " + refractionDir + ".xyz\n";

			code += getTexCubeSampleCode(vo, temp, cubeMapReg, _envMap, refractionDir) +
				"mov " + refractionColor + ".z, " + temp + ".z\n";
		}

		regCache.removeFragmentTempUsage(refractionDir);

		code += "sub " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + targetReg + ".xyz\n" +
			"mul " + refractionColor + ".xyz, " + refractionColor + ".xyz, " + data + ".w\n" +
			"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + refractionColor + ".xyz\n";
		regCache.removeFragmentTempUsage(refractionColor);

		// restore
		code += "neg " + viewDirReg + ".xyz, " + viewDirReg + ".xyz\n";

		return code;
	}
}
