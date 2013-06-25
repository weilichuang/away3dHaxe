package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



class BasicNormalMethod extends ShadingMethodBase
{
	private var _texture:Texture2DBase;
	private var _useTexture:Bool;
	private var _normalTextureRegister:ShaderRegisterElement;

	public function new()
	{
		super();
	}


	override public function initVO(vo:MethodVO):Void
	{
		vo.needsUV = Bool(_texture);
	}

	private inline function get_tangentSpace():Bool
	{
		return true;
	}

	/**
	 * Override this is normal method output is not based on a texture (if not, it will usually always return true)
	 */
	private inline function get_hasOutput():Bool
	{
		return _useTexture;
	}

	override public function copyFrom(method:ShadingMethodBase):Void
	{
		normalMap = BasicNormalMethod(method).normalMap;
	}

	private inline function get_normalMap():Texture2DBase
	{
		return _texture;
	}

	private inline function set_normalMap(value:Texture2DBase):Void
	{
		if (Bool(value) != _useTexture ||
			(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
			invalidateShaderProgram();
		_useTexture = Bool(value);
		_texture = value;
	}

	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_normalTextureRegister = null;
	}

	override public function dispose():Void
	{
		if (_texture)
			_texture = null;
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		if (vo.texturesIndex >= 0)
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
	}

	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		_normalTextureRegister = regCache.getFreeTextureReg();
		vo.texturesIndex = _normalTextureRegister.index;
		return getTex2DSampleCode(vo, targetReg, _normalTextureRegister, _texture) +
			"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
			"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
	}
}
