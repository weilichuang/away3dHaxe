package a3d.textures
{
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;

	
	import a3d.materials.utils.MipmapGenerator;
	import a3d.tools.utils.TextureUtils;

	

	class BitmapTexture extends Texture2DBase
	{
		private static var _mipMaps:Array = [];
		private static var _mipMapUses:Array = [];

		private var _bitmapData:BitmapData;
		private var _mipMapHolder:BitmapData;
		private var _generateMipmaps:Bool;

		public function BitmapTexture(bitmapData:BitmapData, generateMipmaps:Bool = true)
		{
			super();

			this.bitmapData = bitmapData;
			_generateMipmaps = generateMipmaps;
		}

		private inline function get_bitmapData():BitmapData
		{
			return _bitmapData;
		}

		private inline function set_bitmapData(value:BitmapData):Void
		{
			if (value == _bitmapData)
				return;

			if (!TextureUtils.isBitmapDataValid(value))
				throw new Error("Invalid bitmapData: Width and height must be power of 2 and cannot exceed 2048");

			invalidateContent();
			setSize(value.width, value.height);

			_bitmapData = value;

			if (_generateMipmaps)
				getMipMapHolder();
		}

		override private function uploadContent(texture:TextureBase):Void
		{
			if (_generateMipmaps)
				MipmapGenerator.generateMipMaps(_bitmapData, texture, _mipMapHolder, true);
			else
				Texture(texture).uploadFromBitmapData(_bitmapData, 0);
		}

		private function getMipMapHolder():Void
		{
			var newW:UInt, newH:UInt;

			newW = _bitmapData.width;
			newH = _bitmapData.height;

			if (_mipMapHolder)
			{
				if (_mipMapHolder.width == newW && _bitmapData.height == newH)
					return;

				freeMipMapHolder();
			}

			if (_mipMaps[newW] == null)
			{
				_mipMaps[newW] = [];
				_mipMapUses[newW] = [];
			}
			if (_mipMaps[newW][newH] == null)
			{
				_mipMapHolder = _mipMaps[newW][newH] = new BitmapData(newW, newH, true);
				_mipMapUses[newW][newH] = 1;
			}
			else
			{
				_mipMapUses[newW][newH] = _mipMapUses[newW][newH] + 1;
				_mipMapHolder = _mipMaps[newW][newH];
			}
		}

		private function freeMipMapHolder():Void
		{
			var holderWidth:UInt = _mipMapHolder.width;
			var holderHeight:UInt = _mipMapHolder.height;

			if (--_mipMapUses[holderWidth][holderHeight] == 0)
			{
				_mipMaps[holderWidth][holderHeight].dispose();
				_mipMaps[holderWidth][holderHeight] = null;
			}
		}

		override public function dispose():Void
		{
			super.dispose();

			if (_mipMapHolder)
				freeMipMapHolder();
		}
	}
}
