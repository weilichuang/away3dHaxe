package example.cornell;

import away3d.textures.BitmapCubeTexture;

import flash.display.BitmapData;

class CornellDiffuseEnvMapFL extends BitmapCubeTexture
{
	private var _posX:BitmapData;
	private var _negX:BitmapData;
	private var _posY:BitmapData;
	private var _negY:BitmapData;
	private var _posZ:BitmapData;
	private var _negZ:BitmapData;

	public function new()
	{
		super(_posX = new FLPosX(0,0), _negX = new FLNegX(0,0),
			_posY = new FLPosY(0,0), _negY = new FLNegY(0,0),
			_posZ = new FLPosZ(0,0), _negZ = new FLNegZ(0,0)
			);
	}


	override public function dispose():Void
	{
		super.dispose();
		_posX.dispose();
		_negX.dispose();
		_posY.dispose();
		_negY.dispose();
		_posZ.dispose();
		_negZ.dispose();
	}
}
	
@:bitmap("embeds/cornellEnvMap/negXposZ/posX.jpg") class FLPosX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negX.jpg") class FLNegX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/posY.jpg") class FLPosY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negY.jpg") class FLNegY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/posZ.jpg") class FLPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negZ.jpg") class FLNegZ extends flash.display.BitmapData { }
