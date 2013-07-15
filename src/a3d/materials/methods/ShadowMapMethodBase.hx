package a3d.materials.methods;


import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.shadowmaps.ShadowMapperBase;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;


/**
 * ShadowMapMethodBase provides an abstract base method for shadow map methods.
 */
class ShadowMapMethodBase extends ShadingMethodBase implements IAsset
{
	private var _castingLight:LightBase;
	private var _shadowMapper:ShadowMapperBase;

	private var _epsilon:Float = .02;
	private var _alpha:Float = 1;

	/**
	 * Creates a new ShadowMapMethodBase object.
	 * @param castingLight The light used to cast shadows.
	 */
	public function new(castingLight:LightBase)
	{
		super();
		_castingLight = castingLight;
		castingLight.castsShadows = true;
		_shadowMapper = castingLight.shadowMapper;
	}

	public var assetType(get, null):String;
	private function get_assetType():String
	{
		return AssetType.SHADOW_MAP_METHOD;
	}

	/**
	 * The "transparency" of the shadows. This allows making shadows less strong.
	 */
	public var alpha(get,set):Float;
	private function get_alpha():Float
	{
		return _alpha;
	}

	private function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	/**
	 * The light casting the shadows.
	 */
	public var castingLight(get,null):LightBase;
	private function get_castingLight():LightBase
	{
		return _castingLight;
	}

	/**
	 * A small value to counter floating point precision errors when comparing values in the shadow map with the
	 * calculated depth value. Increase this if shadow banding occurs, decrease it if the shadow seems to be too detached.
	 */
	public var epsilon(get,set):Float;
	private function get_epsilon():Float
	{
		return _epsilon;
	}

	private function set_epsilon(value:Float):Float
	{
		return _epsilon = value;
	}

	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return null;
	}
}
