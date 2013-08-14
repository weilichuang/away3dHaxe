package a3d.textures;

import a3d.core.managers.Context3DProxy;
import a3d.materials.utils.MipmapGenerator;
import a3d.tools.utils.TextureUtils;
import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.errors.Error;




class RenderTexture extends Texture2DBase
{
	public function new(width:Int, height:Int)
	{
		super();
		setSize(width, height);
	}

	override private function set_width(value:Int):Int
	{
		if (value == _width)
			return _width;

		if (!TextureUtils.isDimensionValid(value))
			throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

		invalidateContent();
		setSize(value, _height);
		
		return _width;
	}

	override private function set_height(value:Int):Int
	{
		if (value == _height)
			return _height;

		if (!TextureUtils.isDimensionValid(value))
			throw new Error("Invalid size: Width and height must be power of 2 and cannot exceed 2048");

		invalidateContent();
		setSize(_width, value);
		
		return _height;
	}

	override private function uploadContent(texture:TextureBase):Void
	{
		// fake data, to complete texture for sampling
		var bmp:BitmapData = new BitmapData(width, height, false, 0xff0000);
		MipmapGenerator.generateMipMaps(bmp, texture);
		bmp.dispose();
	}

	override private function createTexture(context:Context3DProxy):TextureBase
	{
		return context.createTexture(width, height, Context3DTextureFormat.BGRA, true);
	}
}
