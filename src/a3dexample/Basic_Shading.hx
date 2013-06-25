package example
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	import a3d.entities.Camera3D;
	import a3d.entities.Scene3D;
	import a3d.controllers.HoverController;
	import a3d.entities.Mesh;
	import a3d.entities.lights.DirectionalLight;
	import a3d.materials.TextureMaterial;
	import a3d.materials.lightpickers.StaticLightPicker;
	import a3d.entities.primitives.CubeGeometry;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.entities.primitives.SphereGeometry;
	import a3d.entities.primitives.TorusGeometry;
	import a3d.textures.BitmapTexture;
	import a3d.utils.Cast;


	class Basic_Shading extends BasicApplication
	{
		//cube textures
		[Embed(source = "../embeds/trinket_diffuse.jpg")]
		public static var TrinketDiffuse:Class;
		[Embed(source = "../embeds/trinket_specular.jpg")]
		public static var TrinketSpecular:Class;
		[Embed(source = "../embeds/trinket_normal.jpg")]
		public static var TrinketNormals:Class;

		//sphere textures
		[Embed(source = "../embeds/beachball_diffuse.jpg")]
		public static var BeachBallDiffuse:Class;
		[Embed(source = "../embeds/beachball_specular.jpg")]
		public static var BeachBallSpecular:Class;

		//torus textures
		[Embed(source = "../embeds/weave_diffuse.jpg")]
		public static var WeaveDiffuse:Class;
		[Embed(source = "../embeds/weave_normal.jpg")]
		public static var WeaveNormals:Class;

		//plane textures
		[Embed(source = "../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;
		[Embed(source = "../embeds/floor_specular.jpg")]
		public static var FloorSpecular:Class;
		[Embed(source = "../embeds/floor_normal.jpg")]
		public static var FloorNormals:Class;

		//engine variables
		private var cameraController:HoverController;

		//material objects
		private var planeMaterial:TextureMaterial;
		private var sphereMaterial:TextureMaterial;
		private var cubeMaterial:TextureMaterial;
		private var torusMaterial:TextureMaterial;

		//light objects
		private var light1:DirectionalLight;
		private var light2:DirectionalLight;
		private var lightPicker:StaticLightPicker;

		//scene objects
		private var plane:Mesh;
		private var sphere:Mesh;
		private var cube:Mesh;
		private var torus:Mesh;

		//navigation variables
		private var move:Boolean = false;
		private var lastPanAngle:Float;
		private var lastTiltAngle:Float;
		private var lastMouseX:Float;
		private var lastMouseY:Float;

		/**
		 * Constructor
		 */
		public function Basic_Shading()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():Void
		{
			initEngine();
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		override private function initEngine():Void
		{
			super.initEngine();

			scene = new Scene3D();

			camera = new Camera3D();

			view.antiAlias = 4;
			view.scene = scene;
			view.camera = camera;

			//setup controller to be used on the camera
			cameraController = new HoverController(camera);
			cameraController.distance = 1000;
			cameraController.minTiltAngle = 0;
			cameraController.maxTiltAngle = 90;
			cameraController.panAngle = 45;
			cameraController.tiltAngle = 20;
		}

		/**
		 * Initialise the materials
		 */
		private function initMaterials():Void
		{
			planeMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			planeMaterial.specularMap = Cast.bitmapTexture(FloorSpecular);
			planeMaterial.normalMap = Cast.bitmapTexture(FloorNormals);
			planeMaterial.lightPicker = lightPicker;
			planeMaterial.repeat = true;
			planeMaterial.mipmap = false;

			sphereMaterial = new TextureMaterial(Cast.bitmapTexture(BeachBallDiffuse));
			sphereMaterial.specularMap = Cast.bitmapTexture(BeachBallSpecular);
			sphereMaterial.lightPicker = lightPicker;

			cubeMaterial = new TextureMaterial(Cast.bitmapTexture(TrinketDiffuse));
			cubeMaterial.specularMap = Cast.bitmapTexture(TrinketSpecular);
			cubeMaterial.normalMap = Cast.bitmapTexture(TrinketNormals);
			cubeMaterial.lightPicker = lightPicker;
			cubeMaterial.mipmap = false;

			var weaveDiffuseTexture:BitmapTexture = Cast.bitmapTexture(WeaveDiffuse);
			torusMaterial = new TextureMaterial(weaveDiffuseTexture);
			torusMaterial.specularMap = weaveDiffuseTexture;
			torusMaterial.normalMap = Cast.bitmapTexture(WeaveNormals);
			torusMaterial.lightPicker = lightPicker;
			torusMaterial.repeat = true;
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():Void
		{
			light1 = new DirectionalLight();
			light1.direction = new Vector3D(0, -1, 0);
			light1.ambient = 0.1;
			light1.diffuse = 0.7;

			scene.addChild(light1);

			light2 = new DirectionalLight();
			light2.direction = new Vector3D(0, -1, 0);
			light2.color = 0x00FFFF;
			light2.ambient = 0.1;
			light2.diffuse = 0.7;

			scene.addChild(light2);

			lightPicker = new StaticLightPicker([light1, light2]);
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():Void
		{
			plane = new Mesh(new PlaneGeometry(1000, 1000), planeMaterial);
			plane.geometry.scaleUV(2, 2);
			plane.y = -20;

			scene.addChild(plane);

			sphere = new Mesh(new SphereGeometry(150, 40, 20), sphereMaterial);
			sphere.x = 300;
			sphere.y = 160;
			sphere.z = 300;

			scene.addChild(sphere);

			cube = new Mesh(new CubeGeometry(200, 200, 200, 1, 1, 1, false), cubeMaterial);
			cube.x = 300;
			cube.y = 160;
			cube.z = -250;

			scene.addChild(cube);

			torus = new Mesh(new TorusGeometry(150, 60, 40, 20), torusMaterial);
			torus.geometry.scaleUV(10, 5);
			torus.x = -250;
			torus.y = 160;
			torus.z = -250;

			scene.addChild(torus);
		}

		/**
		 * Navigation and render loop
		 */
		override private function render():Void
		{
			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}

			light1.direction = new Vector3D(Math.sin(getTimer() / 10000) * 150000, 1000, Math.cos(getTimer() / 10000) * 150000);

			super.render();
		}

		/**
		 * Mouse down listener for navigation
		 */
		override private function onMouseDown(event:MouseEvent):Void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		override private function onMouseUp(event:MouseEvent):Void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):Void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}
