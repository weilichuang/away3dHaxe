package a3d.textures;

import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

class CubeTextureBase extends TextureProxyBase
{
	public function new()
	{
		super();
	}

	public var size(get, set):Int;
	private inline function get_size():Int
	{
		return _width;
	}
	
	private function set_size(value:Int):Int
	{
		return _width = value;
	}

	override private function createTexture(context:Context3D):TextureBase
	{
		return context.createCubeTexture(width, Context3DTextureFormat.BGRA, false);
	}
}
