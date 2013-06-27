package a3d.textures;

import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.TextureBase;
import flash.Vector;


import a3d.core.managers.Stage3DProxy;
import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;



class TextureProxyBase extends NamedAssetBase implements IAsset
{
	private var _format:Context3DTextureFormat;
	private var _hasMipmaps:Bool;

	private var _textures:Vector<TextureBase>;
	private var _dirty:Vector<Context3D>;

	private var _width:Int;
	private var _height:Int;

	public function new()
	{
		super();
		
		_textures = new Vector<TextureBase>(8);
		_dirty = new Vector<Context3D>(8);
		
		_format = Context3DTextureFormat.BGRA;
		_hasMipmaps = true;
	}

	public var hasMipMaps(get, null):Bool;
	private inline function get_hasMipMaps():Bool
	{
		return _hasMipmaps;
	}

	public var format(get, null):Context3DTextureFormat;
	private inline function get_format():Context3DTextureFormat
	{
		return _format;
	}

	public var assetType(get, null):String;
	private inline function get_assetType():String
	{
		return AssetType.TEXTURE;
	}

	public var width(get, set):Int;
	private inline function get_width():Int
	{
		return _width;
	}
	
	private inline function set_width(value:Int):Int
	{
		return _width = value;
	}

	public var height(get, set):Int;
	private inline function get_height():Int
	{
		return _height;
	}
	
	private inline function set_height(value:Int):Int
	{
		return _height = value;
	}

	public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var tex:TextureBase = _textures[contextIndex];
		var context:Context3D = stage3DProxy.context3D;

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
		for (i in 0...8)
		{
			_dirty[i] = null;
		}
	}

	private function invalidateSize():Void
	{
		var tex:TextureBase;
		for (i in 0...8)
		{
			tex = _textures[i];
			if (tex)
			{
				tex.dispose();
				_textures[i] = null;
				_dirty[i] = null;
			}
		}
	}



	private function createTexture(context:Context3D):TextureBase
	{
		throw new AbstractMethodError();
	}

	/**
	 * @inheritDoc
	 */
	public function dispose():Void
	{
		for (i in 0...8)
			if (_textures[i] != null)
				_textures[i].dispose();
	}
}
