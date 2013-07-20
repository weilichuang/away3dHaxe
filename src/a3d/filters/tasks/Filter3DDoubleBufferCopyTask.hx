package a3d.filters.tasks;

import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import flash.display.BitmapData;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;





class Filter3DDoubleBufferCopyTask extends Filter3DTaskBase
{
	public var secondaryInputTexture(get, null):Texture;
	
	private var _secondaryInputTexture:Texture;

	public function new()
	{
		super();
	}

	
	private function get_secondaryInputTexture():Texture
	{
		return _secondaryInputTexture;
	}

	override private function getFragmentCode():String
	{
		return "tex oc, v0, fs0 <2d,nearest,clamp>\n";
	}

	override private function updateTextures(stage:Stage3DProxy):Void
	{
		super.updateTextures(stage);

		if (_secondaryInputTexture != null)
			_secondaryInputTexture.dispose();

		_secondaryInputTexture = stage.context3D.createTexture(_textureWidth >> _textureScale, _textureHeight >> _textureScale, Context3DTextureFormat.BGRA, true);

		var dummy:BitmapData = new BitmapData(_textureWidth >> _textureScale, _textureHeight >> _textureScale, false, 0);
		_mainInputTexture.uploadFromBitmapData(dummy);
		_secondaryInputTexture.uploadFromBitmapData(dummy);
		dummy.dispose();
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void
	{
		swap();
		super.activate(stage3DProxy, camera, depthTexture);
	}

	private function swap():Void
	{
		var tmp:Texture = _secondaryInputTexture;
		_secondaryInputTexture = _mainInputTexture;
		_mainInputTexture = tmp;
	}
}
