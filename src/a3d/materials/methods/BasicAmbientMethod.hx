package a3d.materials.methods;


import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



/**
 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
 */


class BasicAmbientMethod extends ShadingMethodBase
{
	private var _useTexture:Bool;
	private var _texture:Texture2DBase;

	private var _ambientInputRegister:ShaderRegisterElement;

	private var _ambientColor:UInt;
	private var _ambientR:Float; 
	private var _ambientG:Float; 
	private var _ambientB:Float;
	private var _ambient:Float;
	public var lightAmbientR:Float;
	public var lightAmbientG:Float;
	public var lightAmbientB:Float;


	/**
	 * Creates a new BasicAmbientMethod object.
	 */
	public function new()
	{
		super();
		
		_ambientColor = 0xffffff;
		_ambientR = 0; 
		_ambientG = 0; 
		_ambientB = 0;
		_ambient = 1;
		lightAmbientR = 0;
		lightAmbientG = 0;
		lightAmbientB = 0;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsUV = _useTexture;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		vo.fragmentData[vo.fragmentConstantsIndex + 3] = 1;
	}

	/**
	 * The strength of the ambient reflection of the surface.
	 */
	private inline function get_ambient():Float
	{
		return _ambient;
	}

	private inline function set_ambient(value:Float):Void
	{
		_ambient = value;
	}

	/**
	 * The colour of the ambient reflection of the surface.
	 */
	private inline function get_ambientColor():UInt
	{
		return _ambientColor;
	}

	private inline function set_ambientColor(value:UInt):Void
	{
		_ambientColor = value;
	}

	/**
	 * The bitmapData to use to define the diffuse reflection color per texel.
	 */
	private inline function get_texture():Texture2DBase
	{
		return _texture;
	}

	private inline function set_texture(value:Texture2DBase):Void
	{
		if (Bool(value) != _useTexture ||
			(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
			invalidateShaderProgram();
		_useTexture = Bool(value);
		_texture = value;
	}

	/**
	 * Copies the state from a BasicAmbientMethod object into the current object.
	 */
	override public function copyFrom(method:ShadingMethodBase):Void
	{
		var diff:BasicAmbientMethod = BasicAmbientMethod(method);
		ambient = diff.ambient;
		ambientColor = diff.ambientColor;
	}

	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_ambientInputRegister = null;
	}

	/**
	 * @inheritDoc
	 */
	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";

		if (_useTexture)
		{
			_ambientInputRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _ambientInputRegister.index;
			code += getTex2DSampleCode(vo, targetReg, _ambientInputRegister, _texture) +
				// apparently, still needs to un-premultiply :s
				"div " + targetReg + ".xyz, " + targetReg + ".xyz, " + targetReg + ".w\n";
		}
		else
		{
			_ambientInputRegister = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = _ambientInputRegister.index * 4;
			code += "mov " + targetReg + ", " + _ambientInputRegister + "\n";
		}

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		if (_useTexture)
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
	}

	/**
	 * Updates the ambient color data used by the render state.
	 */
	private function updateAmbient():Void
	{
		_ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient * lightAmbientR;
		_ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient * lightAmbientG;
		_ambientB = (_ambientColor & 0xff) / 0xff * _ambient * lightAmbientB;
	}


	override public function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		updateAmbient();

		if (!_useTexture)
		{
			var index:Int = vo.fragmentConstantsIndex;
			var data:Vector<Float> = vo.fragmentData;
			data[index] = _ambientR;
			data[index + 1] = _ambientG;
			data[index + 2] = _ambientB;
		}
	}
}
