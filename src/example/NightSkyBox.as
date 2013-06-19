package example
{
	import away3d.entities.primitives.SkyBox;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;

	/**
	 * ...
	 * @author
	 */
	public class NightSkyBox extends SkyBox
	{
		//skybox
		[Embed(source = "../embeds/skybox/grimnight_posX.png")]
		private var EnvPosX:Class;
		[Embed(source = "../embeds/skybox/grimnight_posY.png")]
		private var EnvPosY:Class;
		[Embed(source = "../embeds/skybox/grimnight_posZ.png")]
		private var EnvPosZ:Class;
		[Embed(source = "../embeds/skybox/grimnight_negX.png")]
		private var EnvNegX:Class;
		[Embed(source = "../embeds/skybox/grimnight_negY.png")]
		private var EnvNegY:Class;
		[Embed(source = "../embeds/skybox/grimnight_negZ.png")]
		private var EnvNegZ:Class;

		public var cubeTexture:BitmapCubeTexture;

		public function NightSkyBox()
		{
			cubeTexture = new BitmapCubeTexture(Cast.bitmapData(EnvPosX), Cast.bitmapData(EnvNegX), Cast.bitmapData(EnvPosY), Cast.bitmapData(EnvNegY), Cast.bitmapData(EnvPosZ), Cast.bitmapData(EnvNegZ));

			super(cubeTexture);
		}

	}

}
