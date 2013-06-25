package example
{
	import flash.geom.Vector3D;

	import a3d.entities.Mesh;
	import a3d.materials.TextureMaterial;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.utils.Cast;

	class Basic_View extends BasicApplication
	{
		//plane texture
		[Embed(source = "../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//scene objects
		private var _plane:Mesh;

		/**
		 * Constructor
		 */
		public function Basic_View()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():Void
		{
			initEngine();
			initObjects();
			initListeners();
		}

		override private function initEngine():Void
		{
			super.initEngine();

			//setup the camera
			view.camera.z = -600;
			view.camera.y = 500;
			view.camera.lookAt(new Vector3D());
		}

		private function initObjects():Void
		{
			//setup the scene
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			view.scene.addChild(_plane);
		}

		/**
		 * render loop
		 */
		override private function render():Void
		{
			_plane.rotationY += 1;

			super.render();
		}
	}
}
