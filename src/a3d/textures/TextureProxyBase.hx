package a3d.textures;

import a3d.A3d;
import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.Vector;





class TextureProxyBase extends NamedAssetBase implements IAsset
{
	public var hasMipMaps(get, null):Bool;
	public var format(get, null):Context3DTextureFormat;
	public var assetType(get, null):String;
	public var width(get, set):Int;
	public var height(get, set):Int;
	
	private var _format:Context3DTextureFormat;
	private var _hasMipmaps:Bool;

	private var _textures:Vector<TextureBase>;
	private var _dirty:Vector<Context3DProxy>;

	private var _width:Int;
	private var _height:Int;

	public function new()
	{
		super();
		
		_textures = new Vector<TextureBase>(A3d.MAX_NUM_STAGE3D);
		_dirty = new Vector<Context3DProxy>(A3d.MAX_NUM_STAGE3D);
		
		_format = Context3DTextureFormat.BGRA;
		_hasMipmaps = true;
	}

	
	private function get_hasMipMaps():Bool
	{
		return _hasMipmaps;
	}

	
	private function get_format():Context3DTextureFormat
	{
		return _format;
	}

	
	private function get_assetType():String
	{
		return AssetType.TEXTURE;
	}

	
	private function get_width():Int
	{
		return _width;
	}
	
	private function set_width(value:Int):Int
	{
		return _width = value;
	}

	
	private function get_height():Int
	{
		return _height;
	}
	
	private function set_height(value:Int):Int
	{
		return _height = value;
	}

	public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var tex:TextureBase = _textures[contextIndex];
		var context:Context3DProxy = stage3DProxy.context3D;

		if (tex == null || _dirty[contextIndex] != context)
		{
			_textures[contextIndex] = tex = createTexture(context);
			_dirty[contextIndex] = context;
			uploadContent(tex);
		}

		return tex;
	}

	private function uploadContent(texture:TextureBase):Void
	{
		throw new AbstractMethodError();
	}

	private function setSize(width:Int, height:Int):Void
	{
		if (_width != width || _height != height)
			invalidateSize();

		_width = width;
		_height = height;
	}

	public function invalidateContent():Void
	{
		for (i in 0...A3d.MAX_NUM_STAGE3D)
		{
			_dirty[i] = null;
		}
	}

	private function invalidateSize():Void
	{
		var tex:TextureBase;
		for (i in 0...A3d.MAX_NUM_STAGE3D)
		{
			tex = _textures[i];
			if (tex != null)
			{
				tex.dispose();
				_textures[i] = null;
				_dirty[i] = null;
			}
		}
	}

	private function createTexture(context:Context3DProxy):TextureBase
	{
		throw new AbstractMethodError();
	}

	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
		for (i in 0...A3d.MAX_NUM_STAGE3D)
		{
			if (_textures[i] != null)
				_textures[i].dispose();
		}
	}
}
