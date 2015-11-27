package away3d.materials.methods;


import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;


/**
 * BasicNormalMethod is the default method for standard tangent-space normal mapping.
 */
class BasicNormalMethod extends ShadingMethodBase
{
	/**
	 * Indicates whether or not this method outputs normals in tangent space. Override for object-space normals.
	 */
	public var tangentSpace(get, null):Bool;
	/**
	 * Indicates if the normal method output is not based on a texture (if not, it will usually always return true)
	 * Override if subclasses are different.
	 */
	public var hasOutput(get, null):Bool;
	/**
	 * The texture containing the normals per pixel.
	 */
	public var normalMap(get, set):Texture2DBase;
	
	private var _texture:Texture2DBase;
	private var _useTexture:Bool;
	private var _normalTextureRegister:ShaderRegisterElement;

	/**
	 * Creates a new BasicNormalMethod object.
	 */
	public function new()
	{
		super();
	}


	override public function initVO(vo:MethodVO):Void
	{
		vo.needsUV = (_texture != null);
	}

	
	private function get_tangentSpace():Bool
	{
		return true;
	}

	
	private function get_hasOutput():Bool
	{
		return _useTexture;
	}

	override public function copyFrom(method:ShadingMethodBase):Void
	{
		normalMap = Std.instance(method,BasicNormalMethod).normalMap;
	}

	
	private function get_normalMap():Texture2DBase
	{
		return _texture;
	}

	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		if ((value != null) != _useTexture ||
			(value != null && _texture != null && 
			(value.hasMipMaps != _texture.hasMipMaps || 
			value.format != _texture.format)))
			invalidateShaderProgram();
			
		_useTexture = (value != null);
		_texture = value;
		
		return _texture;
	}

	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_normalTextureRegister = null;
	}

	override public function dispose():Void
	{
		if (_texture != null)
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
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz\n";
	}
} 
