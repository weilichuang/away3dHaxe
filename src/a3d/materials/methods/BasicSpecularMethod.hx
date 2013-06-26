package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



/**
 * BasicSpecularMethod provides the default shading method for Blinn-Phong specular highlights.
 */
class BasicSpecularMethod extends LightingMethodBase
{
	private var _useTexture:Bool;
	private var _totalLightColorReg:ShaderRegisterElement;
	private var _specularTextureRegister:ShaderRegisterElement;
	private var _specularTexData:ShaderRegisterElement;
	private var _specularDataRegister:ShaderRegisterElement;

	private var _texture:Texture2DBase;

	private var _gloss:Int = 50;
	private var _specular:Float = 1;
	private var _specularColor:UInt = 0xffffff;
	public var specularR:Float = 1; 
	public var specularG:Float = 1; 
	public var specularB:Float = 1;
	private var _shadowRegister:ShaderRegisterElement;
	private var _isFirstLight:Bool;


	/**
	 * Creates a new BasicSpecularMethod object.
	 */
	public function new()
	{
		super();
		_gloss = 50;
	_specular:Float = 1;
	_specularColor:UInt = 0xffffff;
	specularR:Float = 1; 
	specularG:Float = 1; 
	specularB:Float = 1;
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsUV = _useTexture;
		vo.needsNormals = vo.numLights > 0;
		vo.needsView = vo.numLights > 0;
	}

	/**
	 * The sharpness of the specular highlight.
	 */
	private inline function get_gloss():Float
	{
		return _gloss;
	}

	private inline function set_gloss(value:Float):Void
	{
		_gloss = value;
	}

	/**
	 * The overall strength of the specular highlights.
	 */
	private inline function get_specular():Float
	{
		return _specular;
	}

	private inline function set_specular(value:Float):Void
	{
		if (value == _specular)
			return;

		_specular = value;
		updateSpecular();
	}

	/**
	 * The colour of the specular reflection of the surface.
	 */
	private inline function get_specularColor():UInt
	{
		return _specularColor;
	}

	private inline function set_specularColor(value:UInt):Void
	{
		if (_specularColor == value)
			return;

		// specular is now either enabled or disabled
		if (_specularColor == 0 || value == 0)
			invalidateShaderProgram();
		_specularColor = value;
		updateSpecular();
	}

	/**
	 * The bitmapData that encodes the specular highlight strength per texel in the red channel, and the sharpness
	 * in the green channel. You can use SpecularBitmapTexture if you want to easily set specular and gloss maps
	 * from greyscale images, but prepared images are preffered.
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
	 * Copies the state from a BasicSpecularMethod object into the current object.
	 */
	override public function copyFrom(method:ShadingMethodBase):Void
	{
		var spec:BasicSpecularMethod = BasicSpecularMethod(method);
		texture = spec.texture;
		specular = spec.specular;
		specularColor = spec.specularColor;
		gloss = spec.gloss;
	}

	/**
	 * @inheritDoc
	 */
	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_shadowRegister = null;
		_totalLightColorReg = null;
		_specularTextureRegister = null;
		_specularTexData = null;
		_specularDataRegister = null;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		var code:String = "";

		_isFirstLight = true;

		if (vo.numLights > 0)
		{
			_specularDataRegister = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = _specularDataRegister.index * 4;

			if (_useTexture)
			{
				_specularTexData = regCache.getFreeFragmentVectorTemp();
				regCache.addFragmentTempUsages(_specularTexData, 1);
				_specularTextureRegister = regCache.getFreeTextureReg();
				vo.texturesIndex = _specularTextureRegister.index;
				code = getTex2DSampleCode(vo, _specularTexData, _specularTextureRegister, _texture);
			}
			else
				_specularTextureRegister = null;

			_totalLightColorReg = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(_totalLightColorReg, 1);
		}

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		var code:String = "";
		var t:ShaderRegisterElement;

		if (_isFirstLight)
			t = _totalLightColorReg;
		else
		{
			t = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(t, 1);
		}

		var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
		var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;

		// blinn-phong half vector model
		code += "add " + t + ", " + lightDirReg + ", " + viewDirReg + "\n" +
			"nrm " + t + ".xyz, " + t + "\n" +
			"dp3 " + t + ".w, " + normalReg + ", " + t + "\n" +
			"sat " + t + ".w, " + t + ".w\n";


		if (_useTexture)
		{
			// apply gloss modulation from texture
			code += "mul " + _specularTexData + ".w, " + _specularTexData + ".y, " + _specularDataRegister + ".w\n" +
				"pow " + t + ".w, " + t + ".w, " + _specularTexData + ".w\n";
		}
		else
			code += "pow " + t + ".w, " + t + ".w, " + _specularDataRegister + ".w\n";

		// attenuate
		if (vo.useLightFallOff)
			code += "mul " + t + ".w, " + t + ".w, " + lightDirReg + ".w\n";

		if (modulateMethod != null)
			code += modulateMethod(vo, t, regCache, _sharedRegisters);

		code += "mul " + t + ".xyz, " + lightColReg + ", " + t + ".w\n";

		if (!_isFirstLight)
		{
			code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
			regCache.removeFragmentTempUsage(t);
		}

		_isFirstLight = false;

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		var code:String = "";
		var t:ShaderRegisterElement;

		// write in temporary if not first light, so we can add to total diffuse colour
		if (_isFirstLight)
			t = _totalLightColorReg;
		else
		{
			t = regCache.getFreeFragmentVectorTemp();
			regCache.addFragmentTempUsages(t, 1);
		}

		var normalReg:ShaderRegisterElement = _sharedRegisters.normalFragment;
		var viewDirReg:ShaderRegisterElement = _sharedRegisters.viewDirFragment;
		code += "dp3 " + t + ".w, " + normalReg + ", " + viewDirReg + "\n" +
			"add " + t + ".w, " + t + ".w, " + t + ".w\n" +
			"mul " + t + ", " + t + ".w, " + normalReg + "\n" +
			"sub " + t + ", " + t + ", " + viewDirReg + "\n" +
			"tex " + t + ", " + t + ", " + cubeMapReg + " <cube," + (vo.useSmoothTextures ? "linear" : "nearest") + ",miplinear>\n" +
			"mul " + t + ".xyz, " + t + ", " + weightRegister + "\n";

		if (modulateMethod != null)
			code += modulateMethod(vo, t, regCache, _sharedRegisters);

		if (!_isFirstLight)
		{
			code += "add " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + t + "\n";
			regCache.removeFragmentTempUsage(t);
		}

		_isFirstLight = false;

		return code;
	}


	/**
	 * @inheritDoc
	 */
	override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";

		if (vo.numLights == 0)
			return code;

		if (_shadowRegister)
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _shadowRegister + ".w\n";

		if (_useTexture)
		{
			// apply strength modulation from texture
			code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularTexData + ".x\n";
			regCache.removeFragmentTempUsage(_specularTexData);
		}

		// apply material's specular reflection
		code += "mul " + _totalLightColorReg + ".xyz, " + _totalLightColorReg + ", " + _specularDataRegister + "\n" +
			"add " + targetReg + ".xyz, " + targetReg + ", " + _totalLightColorReg + "\n";
		regCache.removeFragmentTempUsage(_totalLightColorReg);

		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		//var context : Context3D = stage3DProxy._context3D;

		if (vo.numLights == 0)
			return;

		if (_useTexture)
			stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = specularR;
		data[index + 1] = specularG;
		data[index + 2] = specularB;
		data[index + 3] = _gloss;
	}

	/**
	 * Updates the specular color data used by the render state.
	 */
	private function updateSpecular():Void
	{
		specularR = ((_specularColor >> 16) & 0xff) / 0xff * _specular;
		specularG = ((_specularColor >> 8) & 0xff) / 0xff * _specular;
		specularB = (_specularColor & 0xff) / 0xff * _specular;
	}

	private inline function set_shadowRegister(shadowReg:ShaderRegisterElement):Void
	{
		_shadowRegister = shadowReg;
	}
}
