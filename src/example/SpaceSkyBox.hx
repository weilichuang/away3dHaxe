package example;

import away3d.primitives.SkyBox;
import away3d.textures.BitmapCubeTexture;
import away3d.utils.Cast;

/**
 * ...
 * @author
 */
class SpaceSkyBox extends SkyBox
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


// Environment map.
@:bitmap("embeds/skybox/space_posX.jpg") class EnvPosX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/space_posY.jpg") class EnvPosY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/space_posZ.jpg") class EnvPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/space_negX.jpg") class EnvNegX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/space_negY.jpg") class EnvNegY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/space_negZ.jpg") class EnvNegZ extends flash.display.BitmapData { }