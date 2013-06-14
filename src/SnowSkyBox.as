package  
{
	import away3d.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;
	
	/**
	 * ...
	 * @author 
	 */
	public class SnowSkyBox extends SkyBox 
	{
		public var cubeTexture:BitmapCubeTexture; 
		// Environment map.
		[Embed(source = "/../embeds/skybox/snow_positive_x.jpg")]
		private var EnvPosX:Class;
		[Embed(source = "/../embeds/skybox/snow_positive_y.jpg")]
		private var EnvPosY:Class;
		[Embed(source = "/../embeds/skybox/snow_positive_z.jpg")]
		private var EnvPosZ:Class;
		[Embed(source = "/../embeds/skybox/snow_negative_x.jpg")]
		private var EnvNegX:Class;
		[Embed(source = "/../embeds/skybox/snow_negative_y.jpg")]
		private var EnvNegY:Class;
		[Embed(source = "/../embeds/skybox/snow_negative_z.jpg")]
		private var EnvNegZ:Class;
		
		public function SnowSkyBox() 
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));

			super(cubeTexture);
		}
		
	}

}