package away3d.textures
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	

	

	public class CubeTextureBase extends TextureProxyBase
	{
		public function CubeTextureBase()
		{
			super();
		}

		public function get size():int
		{
			return _width;
		}

		override protected function createTexture(context:Context3D):TextureBase
		{
			return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
		}
	}
}
