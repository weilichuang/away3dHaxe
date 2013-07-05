package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.BlendMode;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;
import flash.errors.Error;



class LightMapMethod extends EffectMethodBase
{
	public static inline var MULTIPLY:String = "multiply";
	public static inline var ADD:String = "add";

	private var _texture:Texture2DBase;

	private var _blendMode:BlendMode;
	private var _useSecondaryUV:Bool;

	public function new(texture:Texture2DBase, blendMode:BlendMode = null, useSecondaryUV:Bool = false)
	{
		super();
		_useSecondaryUV = useSecondaryUV;
		_texture = texture;
		if (blendMode == null)
		{
			this.blendMode = BlendMode.MULTIPLY;
		}
		else
		{
			this.blendMode = blendMode;
		}
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsUV = !_useSecondaryUV;
		vo.needsSecondaryUV = _useSecondaryUV;
	}

	public var blendMode(get,set):BlendMode;
	private function get_blendMode():BlendMode
	{
		return _blendMode;
	}

	private function set_blendMode(value:BlendMode):BlendMode
	{
		if (value != BlendMode.ADD && value != BlendMode.MULTIPLY)
			throw new Error("Unknown blendmode!");
		if (_blendMode == value)
			return _blendMode;
		_blendMode = value;
		invalidateShaderProgram();
		return _blendMode;
	}

	public var texture(get,set):Texture2DBase;
	private function get_texture():Texture2DBase
	{
		return _texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		if (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)
			invalidateShaderProgram();
		_texture = value;
		return _texture;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		super.activate(vo, stage3DProxy);
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String;
		var lightMapReg:ShaderRegisterElement = regCache.getFreeTextureReg();
		var temp:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
		vo.texturesIndex = lightMapReg.index;

		code = getTex2DSampleCode(vo, temp, lightMapReg, _texture, _useSecondaryUV ? _sharedRegisters.secondaryUVVarying : _sharedRegisters.uvVarying);

		if(_blendMode == BlendMode.MULTIPLY)
			code += "mul " + targetReg + ", " + targetReg + ", " + temp + "\n";
		else if(_blendMode == BlendMode.ADD)
			code += "add " + targetReg + ", " + targetReg + ", " + temp + "\n";


		return code;
	}
}
