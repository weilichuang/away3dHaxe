package a3d.textures;

import flash.display3D.Context3D;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.TextureBase;
import flash.Lib;
import flash.utils.ByteArray;

class ATFCubeTexture extends CubeTextureBase
{
	private var _atfData:ATFData;

	public function new(byteArray:ByteArray)
	{
		super();
		atfData = new ATFData(byteArray);
		if (atfData.type != ATFData.TYPE_CUBE)
		{
			throw new Error("ATF isn't cubetexture");
		}
		_format = atfData.format;
		_hasMipmaps = _atfData.numTextures > 1;
	}

	public var atfData(get, set):ATFData;
	private function get_atfData():ATFData
	{
		return _atfData;
	}

	private function set_atfData(value:ATFData):ATFData
	{
		_atfData = value;

		invalidateContent();

		setSize(value.width, value.height);
		
		return _atfData;
	}

	override private function uploadContent(texture:TextureBase):Void
	{
		Lib.as(texture,CubeTexture).uploadCompressedTextureFromByteArray(_atfData.data, 0, false);
	}

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createCubeTexture(_atfData.width, _atfData.format, false);
	}
}
