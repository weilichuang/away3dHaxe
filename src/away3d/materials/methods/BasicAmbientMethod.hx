package away3d.materials.methods;


import away3d.entities.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.compilation.ShaderRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.textures.Texture2DBase;
import flash.Vector;



/**
 * BasicAmbientMethod provides the default shading method for uniform ambient lighting.
 */


class BasicAmbientMethod extends ShadingMethodBase
{
	/**
	 * The strength of the ambient reflection of the surface.
	 */
	public var ambient(get, set):Float;
	/**
	 * The colour of the ambient reflection of the surface.
	 */
	public var ambientColor(get, set):UInt;
	/**
	 * The bitmapData to use to define the diffuse reflection color per texel.
	 */
	public var texture(get, set):Texture2DBase;
	
	public var lightAmbientR:Float;
	public var lightAmbientG:Float;
	public var lightAmbientB:Float;
	
	private var _useTexture:Bool;
	private var _texture:Texture2DBase;

	private var _ambientInputRegister:ShaderRegisterElement;

	private var _ambientColor:UInt;
	private var _ambientR:Float; 
	private var _ambientG:Float; 
	private var _ambientB:Float;
	private var _ambient:Float;
	
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

	
	private function get_ambient():Float
	{
		return _ambient;
	}

	private function set_ambient(value:Float):Float
	{
		return _ambient = value;
	}

	
	private function get_ambientColor():UInt
	{
		return _ambientColor;
	}

	private function set_ambientColor(value:UInt):UInt
	{
		return _ambientColor = value;
	}

	
	private function get_texture():Texture2DBase
	{
		return _texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		if ((value != null) != _useTexture ||
			(value != null && _texture != null && 
			(value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
			invalidateShaderProgram();
		_useTexture = value != null;
		_texture = value;
		
		return _texture;
	}

	/**
	 * Copies the state from a BasicAmbientMethod object into the current object.
	 */
	override public function copyFrom(method:ShadingMethodBase):Void
	{
		var diff:BasicAmbientMethod = Std.instance(method,BasicAmbientMethod);
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
