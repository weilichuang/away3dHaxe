package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;



/**
 * FresnelSpecularMethod provides a specular shading method that is stronger on shallow view angles.
 */
class FresnelSpecularMethod extends CompositeSpecularMethod
{
	private var _dataReg:ShaderRegisterElement;
	private var _incidentLight:Bool;
	private var _fresnelPower:Float = 5;
	private var _normalReflectance:Float = .028; // default value for skin

	/**
	 * Creates a new FresnelSpecularMethod object.
	 * @param basedOnSurface Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
	 * @param baseSpecularMethod
	 */
	public function new(basedOnSurface:Bool = true, baseSpecularMethod:BasicSpecularMethod = null)
	{
		// may want to offer diff speculars
		super(modulateSpecular, baseSpecularMethod);
		_incidentLight = !basedOnSurface;
	}

	override public function initConstants(vo:MethodVO):Void
	{
		var index:Int = vo.secondaryFragmentConstantsIndex;
		vo.fragmentData[index + 2] = 1;
		vo.fragmentData[index + 3] = 0;
	}

	/**
	 * Defines whether the fresnel effect should be based on the view angle on the surface (if true), or on the angle between the light and the view.
	 */
	public var basedOnSurface(get,set):Bool;
	private function get_basedOnSurface():Bool
	{
		return !_incidentLight;
	}

	private function set_basedOnSurface(value:Bool):Bool
	{
		if (_incidentLight != value)
			return basedOnSurface;

		_incidentLight = !value;

		invalidateShaderProgram();
		
		return basedOnSurface;
	}

	public var fresnelPower(get,set):Float;
	private function get_fresnelPower():Float
	{
		return _fresnelPower;
	}

	private function set_fresnelPower(value:Float):Float
	{
		return _fresnelPower = value;
	}

	override public function cleanCompilationData():Void
	{
		super.cleanCompilationData();
		_dataReg = null;
	}

	/**
	 * The minimum amount of reflectance, ie the reflectance when the view direction is normal to the surface or light direction.
	 */
	public var normalReflectance(get,set):Float;
	private function get_normalReflectance():Float
	{
		return _normalReflectance;
	}

	private function set_normalReflectance(value:Float):Float
	{
		return _normalReflectance = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		super.activate(vo, stage3DProxy);
		var fragmentData:Vector<Float> = vo.fragmentData;
		var index:Int = vo.secondaryFragmentConstantsIndex;
		fragmentData[index] = _normalReflectance;
		fragmentData[index + 1] = _fresnelPower;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		_dataReg = regCache.getFreeFragmentConstant();
		vo.secondaryFragmentConstantsIndex = _dataReg.index * 4;
		return super.getFragmentPreLightingCode(vo, regCache);
	}

	/**
	 * Applies the fresnel effect to the specular strength.
	 *
	 * @param target The register containing the specular strength in the "w" component, and the half-vector/reflection vector in "xyz".
	 * @param regCache The register cache used for the shader compilation.
	 * @return The AGAL fragment code for the method.
	 */
	private function modulateSpecular(vo:MethodVO, target:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		vo = vo;
		regCache = regCache;

		var code:String;

		code = "dp3 " + target + ".y, " + sharedRegisters.viewDirFragment + ".xyz, " + (_incidentLight ? target + ".xyz\n" : sharedRegisters.normalFragment + ".xyz\n") + // dot(V, H)
			"sub " + target + ".y, " + _dataReg + ".z, " + target + ".y\n" + // base = 1-dot(V, H)
			"pow " + target + ".x, " + target + ".y, " + _dataReg + ".y\n" + // exp = pow(base, 5)
			"sub " + target + ".y, " + _dataReg + ".z, " + target + ".y\n" + // 1 - exp
			"mul " + target + ".y, " + _dataReg + ".x, " + target + ".y\n" + // f0*(1 - exp)
			"add " + target + ".y, " + target + ".x, " + target + ".y\n" + // exp + f0*(1 - exp)
			"mul " + target + ".w, " + target + ".w, " + target + ".y\n";

		return code;
	}

}
