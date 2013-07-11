package a3dexample.cornell;

import a3d.textures.BitmapCubeTexture;
import flash.display.BitmapData;

class CornellDiffuseEnvMapFR extends BitmapCubeTexture
{
	private var _posX:BitmapData;
	private var _negX:BitmapData;
	private var _posY:BitmapData;
	private var _negY:BitmapData;
	private var _posZ:BitmapData;
	private var _negZ:BitmapData;

	public function new()
	{
		super(_posX = new FRPosX(0,0), _negX = new FRNegX(0,0),
			_posY = new FRPosY(0,0), _negY = new FRNegY(0,0),
			_posZ = new FRPosZ(0,0), _negZ = new FRNegZ(0,0)
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

@:bitmap("embeds/cornellEnvMap/posXposZ/posX.jpg") class FRPosX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXposZ/negX.jpg") class FRNegX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXposZ/posY.jpg") class FRPosY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXposZ/negY.jpg") class FRNegY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXposZ/posZ.jpg") class FRPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXposZ/negZ.jpg") class FRNegZ extends flash.display.BitmapData { }
