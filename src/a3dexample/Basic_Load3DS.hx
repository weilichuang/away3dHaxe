package example
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	import a3d.entities.View3D;
	import a3d.controllers.HoverController;
	import a3d.utils.AwayStats;
	import a3d.entities.Mesh;
	import a3d.events.AssetEvent;
	import a3d.io.library.assets.AssetType;
	import a3d.entities.lights.DirectionalLight;
	import a3d.io.loaders.Loader3D;
	import a3d.io.loaders.misc.AssetLoaderContext;
	import a3d.io.loaders.parsers.Parsers;
	import a3d.materials.TextureMaterial;
	import a3d.materials.lightpickers.StaticLightPicker;
	import a3d.materials.methods.FilteredShadowMapMethod;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.utils.Cast;

	class Basic_Load3DS extends BasicApplication
	{
		//solider ant texture
		[Embed(source = "../embeds/soldier_ant.jpg")]
		public static var AntTexture:Class;

		//solider ant model
		[Embed(source = "../embeds/soldier_ant.3ds", mimeType = "application/octet-stream")]
		public static var AntModel:Class;

		//ground texture
		[Embed(source = "../embeds/CoarseRedSand.jpg")]
		public static var SandTexture:Class;

		//engine variables
		private var _cameraController:HoverController;

		//light objects
		private var _light:DirectionalLight;
		private var _lightPicker:StaticLightPicker;
		private var _direction:Vector3D;

		//material objects
		private var _groundMaterial:TextureMaterial;

		//scene objects
		private var _loader:Loader3D;
		private var _ground:Mesh;

		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Float;
		private var _lastTiltAngle:Float;
		private var _lastMouseX:Float;
		private var _lastMouseY:Float;

		/**
		 * Constructor
		 */
		public function Basic_Load3DS()
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
		 * Initialise the scene objects
		 */
		private function initObjects():Void
		{
			//setup the lights for the scene
			_light = new DirectionalLight(-1, -1, 1);
			_direction = new Vector3D(-1, -1, 1);
			_lightPicker = new StaticLightPicker([_light]);
			view.scene.addChild(_light);

			//setup parser to be used on Loader3D
			Parsers.enableAllBundled();

			//setup the url map for textures in the 3ds file
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
			assetLoaderContext.mapUrlToData("texture.jpg", new AntTexture());

			//setup materials
			_groundMaterial = new TextureMaterial(Cast.bitmapTexture(SandTexture));
			_groundMaterial.shadowMethod = new FilteredShadowMapMethod(_light);
			_groundMaterial.lightPicker = _lightPicker;
			_groundMaterial.specular = 0;
			_ground = new Mesh(new PlaneGeometry(1000, 1000), _groundMaterial);
			view.scene.addChild(_ground);

			//setup the scene
			_loader = new Loader3D();
			_loader.scale(300);
			_loader.z = -200;
			_loader.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			_loader.loadData(new AntModel(), assetLoaderContext);
			view.scene.addChild(_loader);
		}

		/**
		 * Initialise the engine
		 */
		override private function initEngine():Void
		{
			super.initEngine();

			//setup the camera for optimal shadow rendering
			view.camera.lens.far = 2100;

			//setup controller to be used on the camera
			_cameraController = new HoverController(view.camera, null, 45, 20, 1000, 10);

		}

		/**
		 * Navigation and render loop
		 */
		override private function render():Void
		{
			if (_move)
			{
				_cameraController.panAngle = 0.3 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
				_cameraController.tiltAngle = 0.3 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
			}

			_direction.x = -Math.sin(getTimer() / 4000);
			_direction.z = -Math.cos(getTimer() / 4000);
			_light.direction = _direction;

			super.render();
		}

		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):Void
		{
			if (event.asset.assetType == AssetType.MESH)
			{
				var mesh:Mesh = event.asset as Mesh;
				mesh.castsShadows = true;
			}
			else if (event.asset.assetType == AssetType.MATERIAL)
			{
				var material:TextureMaterial = event.asset as TextureMaterial;
				material.shadowMethod = new FilteredShadowMapMethod(_light);
				material.lightPicker = _lightPicker;
				material.gloss = 30;
				material.specular = 1;
				material.ambientColor = 0x303040;
				material.ambient = 1;
			}
		}

		/**
		 * Mouse down listener for navigation
		 */
		override private function onMouseDown(event:MouseEvent):Void
		{
			_lastPanAngle = _cameraController.panAngle;
			_lastTiltAngle = _cameraController.tiltAngle;
			_lastMouseX = stage.mouseX;
			_lastMouseY = stage.mouseY;
			_move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		override private function onMouseUp(event:MouseEvent):Void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):Void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}
