package a3d.textures
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	

	

	class CubeTextureBase extends TextureProxyBase
	{
		public function CubeTextureBase()
		{
			super();
		}

		private inline function get_size():Int
		{
			return _width;
		}

		override private function createTexture(context:Context3D):TextureBase
		{
			return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
		}
	}
}
