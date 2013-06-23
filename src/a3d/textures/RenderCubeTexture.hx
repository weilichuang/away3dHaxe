package a3d.textures
{
	
	import a3d.materials.utils.MipmapGenerator;
	import a3d.tools.utils.TextureUtils;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;

	

	class RenderCubeTexture extends CubeTextureBase
	{
		public function RenderCubeTexture(size:Float)
		{
			super();
			setSize(size, size);
		}

		private inline function set_size(value:Int):Void
		{
			if (value == _width)
				return;

			if (!TextureUtils.isDimensionValid(value))
				throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

			invalidateContent();
			setSize(value, value);
		}

		override private function uploadContent(texture:TextureBase):Void
		{
			// fake data, to complete texture for sampling
			var bmd:BitmapData = new BitmapData(_width, _height, false, 0);
			for (var i:Int = 0; i < 6; ++i)
				MipmapGenerator.generateMipMaps(bmd, texture, null, false, i);
			bmd.dispose();
		}

		override private function createTexture(context:Context3D):TextureBase
		{
			return context.createCubeTexture(_width, Context3DTextureFormat.BGRA, true);
		}
	}
}
