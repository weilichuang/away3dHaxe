package away3d.textures;

import away3d.Away3D;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import away3d.io.library.assets.AssetType;
import away3d.io.library.assets.IAsset;
import away3d.io.library.assets.NamedAssetBase;
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

	private var _texture:TextureBase;
	private var _dirtyContext:Context3DProxy;

	private var _width:Int;
	private var _height:Int;

	public function new()
	{
		super();
		
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
		var tex:TextureBase = _texture;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (tex == null || _dirtyContext != context)
		{
			_texture = tex = createTexture(context);
			_dirtyContext = context;
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
		_dirtyContext = null;
	}

	private function invalidateSize():Void
	{
		if (_texture != null)
		{
			_texture.dispose();
			_texture = null;
			_dirtyContext = null;
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
		if (_texture != null)
			_texture.dispose();
	}
}
