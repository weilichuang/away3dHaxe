package example;

import away3d.entities.primitives.SkyBox;
import away3d.textures.BitmapCubeTexture;
import away3d.utils.Cast;

/**
 * ...
 * @author
 */
class SnowSkyBox extends SkyBox
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
@:bitmap("embeds/skybox/snow_positive_x.jpg") class EnvPosX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/snow_positive_y.jpg") class EnvPosY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/snow_positive_z.jpg") class EnvPosZ extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/snow_negative_x.jpg") class EnvNegX extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/snow_negative_y.jpg") class EnvNegY extends flash.display.BitmapData { }
@:bitmap("embeds/skybox/snow_negative_z.jpg") class EnvNegZ extends flash.display.BitmapData { }