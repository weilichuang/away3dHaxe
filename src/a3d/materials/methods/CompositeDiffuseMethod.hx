package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.events.ShadingMethodEvent;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.textures.Texture2DBase;



/**
 * CompositeDiffuseMethod provides a base class for diffuse methods that wrap a diffuse method to alter the
 * calculated diffuse reflection strength.
 */
class CompositeDiffuseMethod extends BasicDiffuseMethod
{
	private var _baseMethod:BasicDiffuseMethod;

	/**
	 * The base diffuse method on which this method's shading is based.
	 */
	public var baseMethod(get, set):BasicDiffuseMethod;
	

	/**
	 * Creates a new WrapDiffuseMethod object.
	 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature clampDiffuse(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the diffuse strength.
	 * @param baseDiffuseMethod The base diffuse method on which this method's shading is based.
	 */
	public function new(modulateMethod:Dynamic = null, baseDiffuseMethod:BasicDiffuseMethod = null)
	{
		super();
		
		_baseMethod = baseDiffuseMethod != null ? baseDiffuseMethod : new BasicDiffuseMethod();
		_baseMethod.modulateMethod = modulateMethod;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}
	
	private function get_baseMethod():BasicDiffuseMethod
	{
		return _baseMethod;
	}

	private function set_baseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		if (_baseMethod == value)
			return _baseMethod;
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod = value;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		invalidateShaderProgram();
		
		return _baseMethod;
	}

	override public function initVO(vo:MethodVO):Void
	{
		_baseMethod.initVO(vo);
	}

	override public function initConstants(vo:MethodVO):Void
	{
		_baseMethod.initConstants(vo);
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod.dispose();
	}

	override private function get_alphaThreshold():Float
	{
		return _baseMethod.alphaThreshold;
	}

	override private function set_alphaThreshold(value:Float):Float
	{
		return _baseMethod.alphaThreshold = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_texture():Texture2DBase
	{
		return _baseMethod.texture;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_texture(value:Texture2DBase):Texture2DBase
	{
		return _baseMethod.texture = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_diffuseAlpha():Float
	{
		return _baseMethod.diffuseAlpha;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_diffuseColor():UInt
	{
		return _baseMethod.diffuseColor;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_diffuseColor(diffuseColor:UInt):UInt
	{
		return _baseMethod.diffuseColor = diffuseColor;
	}

	/**
	 * @inheritDoc
	 */
	override private function set_diffuseAlpha(value:Float):Float
	{
		return _baseMethod.diffuseAlpha = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentPreLightingCode(vo, regCache);
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		var code:String = _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
		_totalLightColorReg = _baseMethod._totalLightColorReg;
		return code;
	}


	/**
	 * @inheritDoc
	 */
	override public function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		var code:String = _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
		_totalLightColorReg = _baseMethod._totalLightColorReg;
		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.activate(vo, stage3DProxy);
	}

	override public function deactivate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		_baseMethod.deactivate(vo, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	override public function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getVertexCode(vo, regCache);
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return _baseMethod.getFragmentPostLightingCode(vo, regCache, targetReg);
	}

	/**
	 * @inheritDoc
	 */
	override public function reset():Void
	{
		_baseMethod.reset();
	}


	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_baseMethod.cleanCompilationData();
	}

	/**
	 * @inheritDoc
	 */
	override private function set_sharedRegisters(value:ShaderRegisterData):ShaderRegisterData
	{
		return super.sharedRegisters = _baseMethod.sharedRegisters = value;
	}

	override private function set_shadowRegister(value:ShaderRegisterElement):ShaderRegisterElement
	{
		_baseMethod.shadowRegister = value;
		return super.shadowRegister = value;
	}

	/**
	 * Called when the base method's shader code is invalidated.
	 */
	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}
}
