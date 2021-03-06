package a3d.materials.methods;


import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;



/**
 * EffectMethodBase forms an abstract base class for shader methods that are not dependent on light sources,
 * and are in essence post-process effects on the materials.
 */
class EffectMethodBase extends ShadingMethodBase implements IAsset
{
	public var assetType(get, null):String;
	
	public function new()
	{
		super();
	}

	
	private function get_assetType():String
	{
		return AssetType.EFFECTS_METHOD;
	}

	/**
	 * Get the fragment shader code that should be added after all per-light code. Usually composits everything to the target register.
	 * @param vo The MethodVO object containing the method data for the currently compiled material pass.
	 * @param regCache The register cache used during the compilation.
	 * @param targetReg The register that will be containing the method's output.
	 * @private
	 */
	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return "";
	}
}
