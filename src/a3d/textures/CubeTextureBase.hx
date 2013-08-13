package a3d.textures;

import a3d.core.managers.Context3DProxy;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

class CubeTextureBase extends TextureProxyBase
{
	public var size(get, set):Int;
	
	public function new()
	{
		super();
	}

	
	private function get_size():Int
	{
		return _width;
	}
	
	private function set_size(value:Int):Int
	{
		return _width = value;
	}

	override private function createTexture(context:Context3DProxy):TextureBase
	{
		return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
	}
}
