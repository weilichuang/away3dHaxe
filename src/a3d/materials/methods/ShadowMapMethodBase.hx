package a3d.materials.methods;


import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.shadowmaps.ShadowMapperBase;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;



class ShadowMapMethodBase extends ShadingMethodBase implements IAsset
{
	private var _castingLight:LightBase;
	private var _shadowMapper:ShadowMapperBase;

	private var _epsilon:Float = .02;
	private var _alpha:Float = 1;


	public function new(castingLight:LightBase)
	{
		super();
		_castingLight = castingLight;
		castingLight.castsShadows = true;
		_shadowMapper = castingLight.shadowMapper;
	}

	public var assetType(get, null):String;
	private inline function get_assetType():String
	{
		return AssetType.SHADOW_MAP_METHOD;
	}

	public var alpha(get,set):Float;
	private inline function get_alpha():Float
	{
		return _alpha;
	}

	private inline function set_alpha(value:Float):Float
	{
		return _alpha = value;
	}

	public var castingLight(get,null):LightBase;
	private inline function get_castingLight():LightBase
	{
		return _castingLight;
	}

	public var epsilon(get,set):Float;
	private inline function get_epsilon():Float
	{
		return _epsilon;
	}

	private inline function set_epsilon(value:Float):Float
	{
		return _epsilon = value;
	}

	public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		throw new AbstractMethodError();
		return null;
	}
}
