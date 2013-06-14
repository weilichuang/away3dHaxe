package
{
	import flash.geom.Vector3D;

	import away3d.core.pick.PickingColliderType;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.CubeGeometry;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;

	import caurina.transitions.Tweener;
	import caurina.transitions.properties.CurveModifiers;

	public class Basic_Tweening3D extends BasicApplication
	{
		//plane texture
		[Embed(source = "/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//cube texture jpg
		[Embed(source = "/../embeds/trinket_diffuse.jpg")]
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
		private function init():void
		{
			initEngine();
			initObjects();
			initListeners();
		}

		/**
		 * view setup
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			//setup the camera
			view.camera.z = -600;
			view.camera.y = 500;
			view.camera.lookAt(new Vector3D());
		}


		private function initObjects():void
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
		private function _onMouseUp(ev:MouseEvent3D):void
		{
			Tweener.addTween(_cube, {time: 0.5, x: ev.scenePosition.x, z: ev.scenePosition.z, _bezier: {x: _cube.x, z: ev.scenePosition.z}});
		}
	}
}
