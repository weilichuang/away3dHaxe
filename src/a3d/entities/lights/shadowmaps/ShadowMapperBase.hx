package a3d.entities.lights.shadowmaps
{
	import flash.display3D.textures.TextureBase;

	import a3d.core.managers.Stage3DProxy;
	import a3d.core.render.DepthRenderer;
	import a3d.core.traverse.EntityCollector;
	import a3d.core.traverse.ShadowCasterCollector;
	import a3d.entities.Camera3D;
	import a3d.entities.Scene3D;
	import a3d.entities.lights.LightBase;
	import a3d.errors.AbstractMethodError;
	import a3d.textures.RenderTexture;
	import a3d.textures.TextureProxyBase;



	class ShadowMapperBase
	{
		private var _casterCollector:ShadowCasterCollector;

		private var _depthMap:TextureProxyBase;
		private var _depthMapSize:UInt = 2048;
		private var _light:LightBase;
		private var _explicitDepthMap:Bool;
		private var _autoUpdateShadows:Bool = true;
		private var _shadowsInvalid:Bool;

		private inline function get_shadowsInvalid():Bool
		{
			return _shadowsInvalid;
		}

//		private inline function set_shadowsInvalid(value:Bool):Void
//		{
//			_shadowsInvalid = value;
//		}

		public function ShadowMapperBase()
		{
			_casterCollector = createCasterCollector();
		}

		private function createCasterCollector():ShadowCasterCollector
		{
			return new ShadowCasterCollector();
		}

		private inline function get_autoUpdateShadows():Bool
		{
			return _autoUpdateShadows;
		}

		private inline function set_autoUpdateShadows(value:Bool):Void
		{
			_autoUpdateShadows = value;
		}

		public function updateShadows():Void
		{
			_shadowsInvalid = true;
		}

		/**
		 * This is used by renderers that can support depth maps to be shared across instances
		 * @param depthMap
		 */
		public function setDepthMap(depthMap:TextureProxyBase):Void
		{
			if (_depthMap == depthMap)
				return;
			if (_depthMap && !_explicitDepthMap)
				_depthMap.dispose();
			_depthMap = depthMap;
			if (_depthMap)
			{
				_explicitDepthMap = true;
				_depthMapSize = _depthMap.width;
			}
			else
				_explicitDepthMap = false;
		}

		private inline function get_light():LightBase
		{
			return _light;
		}

		private inline function set_light(value:LightBase):Void
		{
			_light = value;
		}

		private inline function get_depthMap():TextureProxyBase
		{
			if (_depthMap == null)
				_depthMap = createDepthTexture();
			return _depthMap;
		}

		private inline function get_depthMapSize():UInt
		{
			return _depthMapSize;
		}

		private inline function set_depthMapSize(value:UInt):Void
		{
			if (value == _depthMapSize)
				return;
			_depthMapSize = value;

			if (_explicitDepthMap)
			{
				throw Error("Cannot set depth map size for the current renderer.");
			}
			else if (_depthMap)
			{
				_depthMap.dispose();
				_depthMap = null;
			}
		}

		public function dispose():Void
		{
			_casterCollector = null;
			if (_depthMap && !_explicitDepthMap)
				_depthMap.dispose();
			_depthMap = null;
		}


		private function createDepthTexture():TextureProxyBase
		{
			return new RenderTexture(_depthMapSize, _depthMapSize);
		}


		/**
		 * Renders the depth map for this light.
		 * @param entityCollector The EntityCollector that contains the original scene data.
		 * @param renderer The DepthRenderer to render the depth map.
		 */
		public function renderDepthMap(stage3DProxy:Stage3DProxy, entityCollector:EntityCollector, renderer:DepthRenderer):Void
		{
			_shadowsInvalid = false;
			updateDepthProjection(entityCollector.camera);
			if (_depthMap == null)
				_depthMap = createDepthTexture();
			drawDepthMap(_depthMap.getTextureForStage3D(stage3DProxy), entityCollector.scene, renderer);
		}

		private function updateDepthProjection(viewCamera:Camera3D):Void
		{
			throw new AbstractMethodError();
		}

		private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
		{
			throw new AbstractMethodError();
		}
	}
}
