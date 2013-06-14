package away3d.materials.utils
{
	import flash.display.BitmapData;
	
	import away3d.core.base.IMaterialOwner;
	import away3d.materials.TextureMaterial;
	import away3d.textures.BitmapTexture;

	public class DefaultMaterialManager
	{
		private static var _defaultTextureBitmapData:BitmapData;
		private static var _defaultMaterial:TextureMaterial;
		private static var _defaultTexture:BitmapTexture;

		//private static var _defaultMaterialRenderables:Vector.<IMaterialOwner> = new Vector.<IMaterialOwner>();

		public static function getDefaultMaterial(renderable:IMaterialOwner = null):TextureMaterial
		{
			if (!_defaultTexture)
				createDefaultTexture();

			if (!_defaultMaterial)
				createDefaultMaterial();

			//_defaultMaterialRenderables.push(renderable);

			return _defaultMaterial;
		}

		public static function getDefaultTexture(renderable:IMaterialOwner = null):BitmapTexture
		{
			if (!_defaultTexture)
				createDefaultTexture();

			//_defaultMaterialRenderables.push(renderable);

			return _defaultTexture;
		}

		private static function createDefaultTexture():void
		{
			_defaultTextureBitmapData = new BitmapData(8, 8, false, 0x0);

			//create chekerboard
			var i:uint, j:uint;
			for (i = 0; i < 8; i++)
			{
				for (j = 0; j < 8; j++)
				{
					if ((j & 1) ^ (i & 1))
						_defaultTextureBitmapData.setPixel(i, j, 0XFFFFFF);
				}
			}

			_defaultTexture = new BitmapTexture(_defaultTextureBitmapData);
			_defaultTexture.name = "defaultTexture";
		}

		private static function createDefaultMaterial():void
		{
			_defaultMaterial = new TextureMaterial(_defaultTexture);
			_defaultMaterial.mipmap = false;
			_defaultMaterial.smooth = false;
			_defaultMaterial.name = "defaultMaterial";
		}
	}
}
