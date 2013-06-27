package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.events.ShadingMethodEvent;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.passes.MaterialPassBase;
import a3d.textures.Texture2DBase;
import flash.Vector;



/**
 * CompositeSpecularMethod provides a base class for specular methods that wrap a specular method to alter the strength
 * of its calculated strength.
 */
class CompositeSpecularMethod extends BasicSpecularMethod
{
	private var _baseMethod:BasicSpecularMethod;

	/**
	 * Creates a new WrapSpecularMethod object.
	 * @param modulateMethod The method which will add the code to alter the base method's strength. It needs to have the signature modSpecular(t : ShaderRegisterElement, regCache : ShaderRegisterCache) : String, in which t.w will contain the specular strength and t.xyz will contain the half-vector or the reflection vector.
	 * @param baseSpecularMethod The base specular method on which this method's shading is based.
	 */
	public function new(modulateMethod:Function, baseSpecularMethod:BasicSpecularMethod = null)
	{
		super();
		_baseMethod = baseSpecularMethod || new BasicSpecularMethod();
		_baseMethod.modulateMethod = modulateMethod;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
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
	 * The base specular method on which this method's shading is based.
	 */
	private inline function get_baseMethod():BasicSpecularMethod
	{
		return _baseMethod;
	}

	private inline function set_baseMethod(value:BasicSpecularMethod):Void
	{
		if (_baseMethod == value)
			return;
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod = value;
		_baseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated, false, 0, true);
		invalidateShaderProgram();
	}

	/**
	 * @inheritDoc
	 */
	override private function get_gloss():Float
	{
		return _baseMethod.gloss;
	}

	override private function set_gloss(value:Float):Void
	{
		_baseMethod.gloss = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_specular():Float
	{
		return _baseMethod.specular;
	}

	override private function set_specular(value:Float):Void
	{
		_baseMethod.specular = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_passes():Vector<MaterialPassBase>
	{
		return _baseMethod.passes;
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		_baseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_baseMethod.dispose();
	}

	/**
	 * @inheritDoc
	 */
	override private function get_texture():Texture2DBase
	{
		return _baseMethod.texture;
	}

	override private function set_texture(value:Texture2DBase):Void
	{
		_baseMethod.texture = value;
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
	override private function set_sharedRegisters(value:ShaderRegisterData):Void
	{
		super.sharedRegisters = _baseMethod.sharedRegisters = value;
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
	override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentPreLightingCode(vo, regCache);
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentCodePerLight(vo, lightDirReg, lightColReg, regCache);
	}

	/**
	 * @inheritDoc
	 * @return
	 */
	override public function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		return _baseMethod.getFragmentCodePerProbe(vo, cubeMapReg, weightRegister, regCache);
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

	override private function set_shadowRegister(value:ShaderRegisterElement):Void
	{
		super.shadowRegister = value;
		_baseMethod.shadowRegister = value;
	}

	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}
}
