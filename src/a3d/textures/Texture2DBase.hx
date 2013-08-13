package a3d.textures;

import a3d.core.managers.Context3DProxy;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;

class Texture2DBase extends TextureProxyBase
{
	public function new()
	{
		super();
	}

	override private function createTexture(context:Context3DProxy):TextureBase
	{
		return context.createTexture(_width, _height, Context3DTextureFormat.BGRA, false);
	}
}
