package a3dexample.cornell;

import a3d.textures.BitmapCubeTexture;

import flash.display.BitmapData;

class CornellDiffuseEnvMapFL extends BitmapCubeTexture
{
	private var _posX:BitmapData;
	private var _negX:BitmapData;
	private var _posY:BitmapData;
	private var _negY:BitmapData;
	private var _posZ:BitmapData;
	private var _negZ:BitmapData;

	public function CornellDiffuseEnvMapFL()
	{
		super(_posX = new PosX(0,0), _negX = new NegX(0,0),
			_posY = new PosY(0,0), _negY = new NegY(0,0),
			_posZ = new PosZ(0,0), _negZ = new NegZ(0,0)
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
	
@:bitmap("embeds/cornellEnvMap/negXposZ/posX.png") class PosX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negX.png") class NegX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/posY.png") class PosY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negY.png") class NegY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/posZ.png") class PosZ extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXposZ/negZ.png") class NegZ extends flash.display.BitmapData { }
