package example
{
	import flash.geom.Vector3D;

	import a3d.core.pick.PickingColliderType;
	import a3d.entities.Mesh;
	import a3d.events.MouseEvent3D;
	import a3d.materials.TextureMaterial;
	import a3d.entities.primitives.CubeGeometry;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.utils.Cast;

	import caurina.transitions.Tweener;
	import caurina.transitions.properties.CurveModifiers;

	class Basic_Tweening3D extends BasicApplication
	{
		//plane texture
		[Embed(source = "../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//cube texture jpg
		[Embed(source = "../embeds/trinket_diffuse.jpg")]
		public static var TrinketDiffuse:Class;

		//scene objects
		private var _plane:Mesh;
		private var _cube:Mesh;

		/**
		 * Constructor
		 */
		public function Basic_Tweening3D()
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

		/**
		 * view setup
		 */
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
			_cube = new Mesh(new CubeGeometry(100, 100, 100, 1, 1, 1, false), new TextureMaterial(Cast.bitmapTexture(TrinketDiffuse)));
			_cube.y = 50;
			view.scene.addChild(_cube);

			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			_plane.pickingCollider = PickingColliderType.AS3_FIRST_ENCOUNTERED;
			_plane.mouseEnabled = true;
			view.scene.addChild(_plane);

			//add mouse listener
			_plane.addEventListener(MouseEvent3D.MOUSE_UP, _onMouseUp);

			//initialize Tweener curve modifiers
			CurveModifiers.init();
		}

		/**
		 * mesh listener for mouse up interaction
		 */
		private function _onMouseUp(ev:MouseEvent3D):Void
		{
			Tweener.addTween(_cube, {time: 0.5, x: ev.scenePosition.x, z: ev.scenePosition.z, _bezier: {x: _cube.x, z: ev.scenePosition.z}});
		}
	}
}
