package example.cornell;

import away3d.textures.BitmapCubeTexture;

import flash.display.BitmapData;

class CornellDiffuseEnvMapNL extends BitmapCubeTexture
{
	private var _posX:BitmapData;
	private var _negX:BitmapData;
	private var _posY:BitmapData;
	private var _negY:BitmapData;
	private var _posZ:BitmapData;
	private var _negZ:BitmapData;

	public function new()
	{
		super(_posX = new NLPosX(0,0), _negX = new NLNegX(0,0),
			_posY = new NLPosY(0,0), _negY = new NLNegY(0,0),
			_posZ = new NLPosZ(0,0), _negZ = new NLNegZ(0,0)
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

@:bitmap("embeds/cornellEnvMap/negXnegZ/posX.jpg") class NLPosX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXnegZ/negX.jpg") class NLNegX extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXnegZ/posY.jpg") class NLPosY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXnegZ/negY.jpg") class NLNegY extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXnegZ/posZ.jpg") class NLPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/cornellEnvMap/negXnegZ/negZ.jpg") class NLNegZ extends flash.display.BitmapData { }
