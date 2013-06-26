package a3d.materials.methods;


import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;



/**
 * LightingMethodBase provides an abstract base method for shading methods that uses lights.
 * Used for diffuse and specular shaders only.
 */
class LightingMethodBase extends ShadingMethodBase
{
	/**
	 * A method that is exposed to wrappers in case the strength needs to be controlled
	 */
	public var modulateMethod:Dynamic;

	public function new()
	{
		super();
	}

	/**
	 * Get the fragment shader code that will be needed before any per-light code is added.
	 * @param regCache The register cache used during the compilation.
	 * @private
	 */
	public function getFragmentPreLightingCode(vo:MethodVO, regCache:ShaderRegisterCache):String
	{
		vo = vo;
		regCache = regCache;
		return "";
	}

	/**
	 * Get the fragment shader code that will generate the code relevant to a single light.
	 */
	public function getFragmentCodePerLight(vo:MethodVO, lightDirReg:ShaderRegisterElement, lightColReg:ShaderRegisterElement, regCache:ShaderRegisterCache):String
	{
		vo = vo;
		lightDirReg = lightDirReg;
		lightColReg = lightColReg;
		regCache = regCache;
		return "";
	}

	/**
	 * Get the fragment shader code that will generate the code relevant to a single light probe object.
	 * @param cubeMapReg The register containing the cube map for the current probe
	 * @param weightRegister A string representation of the register + component containing the current weight
	 * @param regCache The register cache providing any necessary registers to the shader
	 */
	public function getFragmentCodePerProbe(vo:MethodVO, cubeMapReg:ShaderRegisterElement, weightRegister:String, regCache:ShaderRegisterCache):String
	{
		vo = vo;
		cubeMapReg = cubeMapReg;
		weightRegister = weightRegister;
		regCache = regCache;
		return "";
	}

	/**
	 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
	 * @param regCache The register cache used during the compilation.
	 * @private
	 */
	public function getFragmentPostLightingCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		vo = vo;
		regCache = regCache;
		targetReg = targetReg;
		return "";
	}
}
