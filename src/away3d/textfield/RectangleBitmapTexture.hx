package away3d.textfield;

import away3d.core.managers.Context3DProxy;
import away3d.textures.Texture2DBase;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.RectangleTexture;
import flash.display3D.textures.TextureBase;

#if flash11_8
class RectangleBitmapTexture extends Texture2DBase {
	private var _bitmapData:BitmapData;

	public function new(bitmapData:BitmapData) {
		super();
		this.bitmapData = bitmapData;
	}
	
	public var bitmapData(get, set):BitmapData;
	private function get_bitmapData():BitmapData {
		return _bitmapData;
	}

	private function set_bitmapData(value:BitmapData):BitmapData {
		if (value == _bitmapData)
			return value;

		invalidateContent();
		setSize(value.width, value.height);

		_bitmapData = value;
		return value;
	}
	
	override private function uploadContent(texture:TextureBase):Void {
		cast(texture, RectangleTexture).uploadFromBitmapData(_bitmapData);
	}
	
	override private function createTexture(context:Context3DProxy):TextureBase {
		return context.createRectangleTexture(_width, _height, Context3DTextureFormat.BGRA_PACKED, false);
	}
}
#end
