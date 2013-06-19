package away3d.materials.methods
{
	
	import away3d.errors.AbstractMethodError;
	import away3d.io.library.assets.AssetType;
	import away3d.io.library.assets.IAsset;
	import away3d.entities.lights.LightBase;
	import away3d.entities.lights.shadowmaps.ShadowMapperBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;

	

	public class ShadowMapMethodBase extends ShadingMethodBase implements IAsset
	{
		protected var _castingLight:LightBase;
		protected var _shadowMapper:ShadowMapperBase;

		protected var _epsilon:Number = .02;
		protected var _alpha:Number = 1;


		public function ShadowMapMethodBase(castingLight:LightBase)
		{
			super();
			_castingLight = castingLight;
			castingLight.castsShadows = true;
			_shadowMapper = castingLight.shadowMapper;
		}

		public function get assetType():String
		{
			return AssetType.SHADOW_MAP_METHOD;
		}

		public function get alpha():Number
		{
			return _alpha;
		}

		public function set alpha(value:Number):void
		{
			_alpha = value;
		}

		public function get castingLight():LightBase
		{
			return _castingLight;
		}

		public function get epsilon():Number
		{
			return _epsilon;
		}

		public function set epsilon(value:Number):void
		{
			_epsilon = value;
		}

		public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			throw new AbstractMethodError();
			return null;
		}
	}
}
