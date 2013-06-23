package a3d.textures
{
	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;

	

	

	class ATFTexture extends Texture2DBase
	{
		private var _atfData:ATFData;

		public function ATFTexture(byteArray:ByteArray)
		{
			super();

			atfData = new ATFData(byteArray);
			_format = atfData.format;
			_hasMipmaps = _atfData.numTextures > 1;
		}

		private inline function get_atfData():ATFData
		{
			return _atfData;
		}

		private inline function set_atfData(value:ATFData):Void
		{
			_atfData = value;

			invalidateContent();

			setSize(value.width, value.height);
		}

		override private function uploadContent(texture:TextureBase):Void
		{
			Texture(texture).uploadCompressedTextureFromByteArray(_atfData.data, 0, false);
		}

		override private function createTexture(context:Context3D):TextureBase
		{
			return context.createTexture(_width, _height, atfData.format, false);
		}
	}
}
