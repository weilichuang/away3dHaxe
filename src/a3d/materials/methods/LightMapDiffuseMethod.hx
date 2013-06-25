package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



class LightMapDiffuseMethod extends CompositeDiffuseMethod
{
	public static inline var MULTIPLY:String = "multiply";
	public static inline var ADD:String = "add";

	private var _texture:Texture2DBase;
	private var _blendMode:String;
	private var _useSecondaryUV:Bool;

	public function new(lightMap:Texture2DBase, blendMode:String = "multiply", useSecondaryUV:Bool = false, baseMethod:BasicDiffuseMethod = null)
	{
		super(null, baseMethod);
		_useSecondaryUV = useSecondaryUV;
		_texture = lightMap;
		this.blendMode = blendMode;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsSecondaryUV = _useSecondaryUV;
		vo.needsUV = !_useSecondaryUV;
	}

	private inline function get_blendMode():String
	{
		return _blendMode;
	}

	private inline function set_blendMode(value:String):Void
	{
		if (value != ADD && value != MULTIPLY)
			throw new Error("Unknown blendmode!");
		if (_blendMode == value)
			return;
		_blendMode = value;
		invalidateShaderProgram();
	}

	private inline function get_lightMapTexture():Texture2DBase
	{
		return _texture;
	}

	private inline function set_lightMapTexture(value:Texture2DBase):Void
	{
		_texture = value;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(vo.secondaryTexturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		super.activate(vo, stage3DProxy);
	}

	override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String;
		var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		vo.secondaryTexturesIndex = lightMapReg.index;

		code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _sharedRegisters.secondaryUVVarying);

		switch (_blendMode)
		{
			case MULTIPLY:
				code += "mul " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
			
			case ADD:
				code += "add " + _totalLightColorReg + ", " + _totalLightColorReg + ", " + temp + "\n";
			
		}

		code += super.getFragmentPostLightingCode(vo, regCache, targetReg);

		return code;
	}
}
