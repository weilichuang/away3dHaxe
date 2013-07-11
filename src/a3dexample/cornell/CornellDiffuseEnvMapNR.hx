package a3dexample.cornell;

import a3d.textures.BitmapCubeTexture;

import flash.display.BitmapData;

class CornellDiffuseEnvMapNR extends BitmapCubeTexture
{
	private var _posX:BitmapData;
	private var _negX:BitmapData;
	private var _posY:BitmapData;
	private var _negY:BitmapData;
	private var _posZ:BitmapData;
	private var _negZ:BitmapData;

	public function new()
	{
		super(_posX = new NRPosX(0,0), _negX = new NRNegX(0,0),
			_posY = new NRPosY(0,0), _negY = new NRNegY(0,0),
			_posZ = new NRPosZ(0,0), _negZ = new NRNegZ(0,0)
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
@:bitmap("embeds/cornellEnvMap/posXnegZ/posX.jpg") class NRPosX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXnegZ/negX.jpg") class NRNegX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXnegZ/posY.jpg") class NRPosY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXnegZ/negY.jpg") class NRNegY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXnegZ/posZ.jpg") class NRPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/posXnegZ/negZ.jpg") class NRNegZ extends flash.display.BitmapData { }
