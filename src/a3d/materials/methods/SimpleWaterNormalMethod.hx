package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;
import flash.Vector;



class SimpleWaterNormalMethod extends BasicNormalMethod
{
	private var _texture2:Texture2DBase;
	private var _normalTextureRegister2:ShaderRegisterElement;
	private var _useSecondNormalMap:Bool;
	private var _water1OffsetX:Float = 0;
	private var _water1OffsetY:Float = 0;
	private var _water2OffsetX:Float = 0;
	private var _water2OffsetY:Float = 0;

	public function new(waveMap1:Texture2DBase, waveMap2:Texture2DBase)
	{
		super();
		normalMap = waveMap1;
		secondaryNormalMap = waveMap2;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		var index:Int = vo.fragmentConstantsIndex;
		vo.fragmentData[index] = .5;
		vo.fragmentData[index + 1] = 0;
		vo.fragmentData[index + 2] = 0;
		vo.fragmentData[index + 3] = 1;
	}

	override public function initVO(vo:MethodVO):Void
	{
		super.initVO(vo);

		_useSecondNormalMap = normalMap != secondaryNormalMap;
	}

	private inline function get_water1OffsetX():Float
	{
		return _water1OffsetX;
	}

	private inline function set_water1OffsetX(value:Float):Void
	{
		_water1OffsetX = value;
	}

	private inline function get_water1OffsetY():Float
	{
		return _water1OffsetY;
	}

	private inline function set_water1OffsetY(value:Float):Void
	{
		_water1OffsetY = value;
	}

	private inline function get_water2OffsetX():Float
	{
		return _water2OffsetX;
	}

	private inline function set_water2OffsetX(value:Float):Void
	{
		_water2OffsetX = value;
	}

	private inline function get_water2OffsetY():Float
	{
		return _water2OffsetY;
	}

	private inline function set_water2OffsetY(value:Float):Void
	{
		_water2OffsetY = value;
	}

	override private function set_normalMap(value:Texture2DBase):Void
	{
		if (!value)
			return;
		super.normalMap = value;
	}

	private inline function get_secondaryNormalMap():Texture2DBase
	{
		return _texture2;
	}

	private inline function set_secondaryNormalMap(value:Texture2DBase):Void
	{
		_texture2 = value;
	}

	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_normalTextureRegister2 = null;
	}

	override public function dispose():Void
	{
		super.dispose();
		_texture2 = null;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);

		var data:Vector<Float> = vo.fragmentData;
		var index:Int = vo.fragmentConstantsIndex;

		data[index + 4] = _water1OffsetX;
		data[index + 5] = _water1OffsetY;
		data[index + 6] = _water2OffsetX;
		data[index + 7] = _water2OffsetY;

		if (_useSecondNormalMap >= 0)
		{
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex + 1, _texture2.getTextureForStage3D(stage3DProxy));
		}
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		var dataReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var dataReg2:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		_normalTextureRegister = regCache.getFreeTextureReg();
		_normalTextureRegister2 = _useSecondNormalMap ? regCache.getFreeTextureReg() : _normalTextureRegister;
		vo.texturesIndex = _normalTextureRegister.index;

		vo.fragmentConstantsIndex = dataReg.index * 4;
		return "add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".xyxy\n" +
			getTex2DSampleCode(vo, targetReg, _normalTextureRegister, normalMap, temp) +
			"add " + temp + ", " + _sharedRegisters.uvVarying + ", " + dataReg2 + ".zwzw\n" +
			getTex2DSampleCode(vo, temp, _normalTextureRegister2, _texture2, temp) +
			"add " + targetReg + ", " + targetReg + ", " + temp + "		\n" +
			"mul " + targetReg + ", " + targetReg + ", " + dataReg + ".x	\n" +
			"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
			"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";

	}
}
