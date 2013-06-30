package a3dexample;

import away3d.entities.primitives.SkyBox;
import away3d.textures.BitmapCubeTexture;

/**
 * ...
 * @author
 */
class NightSkyBox extends SkyBox
{
	public var cubeTexture:BitmapCubeTexture;

	public function new()
	{
		cubeTexture = new BitmapCubeTexture(new EnvPosX(0, 0), new EnvNegX(0, 0), 
											new EnvPosY(0, 0), new EnvNegY(0, 0), 
											new EnvPosZ(0, 0), new EnvNegZ(0, 0));
		super(cubeTexture);
	}

}
@:bitmap("embeds/skybox/grimnight_posX.png") class EnvPosX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/grimnight_posY.png") class EnvPosY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/grimnight_posZ.png") class EnvPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/grimnight_negX.png") class EnvNegX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/grimnight_negY.png") class EnvNegY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/grimnight_negZ.png") class EnvNegZ extends flash.display.BitmapData { }