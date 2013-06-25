package example
{
	import flash.events.Event;
	import flash.events.MouseEvent;

	import a3d.animators.VertexAnimationSet;
	import a3d.animators.VertexAnimator;
	import a3d.controllers.HoverController;
	import a3d.entities.Mesh;
	import a3d.entities.lights.DirectionalLight;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.events.AssetEvent;
	import a3d.io.library.AssetLibrary;
	import a3d.io.library.assets.AssetType;
	import a3d.io.loaders.misc.AssetLoaderContext;
	import a3d.io.loaders.parsers.MD2Parser;
	import a3d.materials.TextureMaterial;
	import a3d.materials.lightpickers.StaticLightPicker;
	import a3d.materials.methods.FilteredShadowMapMethod;
	import a3d.utils.Cast;

	class Basic_LoadMD2 extends BasicApplication
	{
		//plane textures
		[Embed(source = "../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//ogre diffuse texture
		[Embed(source = "../embeds/ogre/ogre_diffuse.jpg")]
		public static var OgreDiffuse:Class;

		//ogre normal map texture
		[Embed(source = "../embeds/ogre/ogre_normals.png")]
		public static var OgreNormals:Class;

		//ogre specular map texture
		[Embed(source = "../embeds/ogre/ogre_specular.jpg")]
		public static var OgreSpecular:Class;

		//solider ant model
		[Embed(source = "../embeds/ogre/ogre.md2", mimeType = "application/octet-stream")]
		public static var OgreModel:Class;

		//pre-cached names of the states we want to use
		public static var stateNames:Array = ["stand", "sniffsniff", "deathc", "attack", "crattack", "run", "paina", "cwalk", "crpain", "cstand", "deathb", "salute_alt", "painc", "painb", "flip", "jump"];

		//engine variables
		private var _cameraController:HoverController;

		//light objects
		private var _light:DirectionalLight;
		private var _lightPicker:StaticLightPicker;

		//material objects
		private var _floorMaterial:TextureMaterial;
		private var _shadowMapMethod:FilteredShadowMapMethod;

		//scene objects
		private var _floor:Mesh;
		private var _mesh:Mesh;

		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Float;
		private var _lastTiltAngle:Float;
		private var _lastMouseX:Float;
		private var _lastMouseY:Float;
		private var _animationSet:VertexAnimationSet;

		/**
		 * Constructor
		 */
		public function Basic_LoadMD2()
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
			_light = new DirectionalLight(0, -1, -1);
			_lightPicker = new StaticLightPicker([_light]);
			view.scene.addChild(_light);

			//setup the url map for textures in the 3ds file
			var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
			assetLoaderContext.mapUrlToData("igdosh.jpg", new OgreDiffuse());

			//setup parser to be used on AssetLibrary
			AssetLibrary.loadData(new OgreModel(), assetLoaderContext, null, new MD2Parser());
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);

			//setup materials
			_shadowMapMethod = new FilteredShadowMapMethod(_light);
			_floorMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			_floorMaterial.lightPicker = _lightPicker;
			_floorMaterial.specular = 0;
			_floorMaterial.shadowMethod = _shadowMapMethod;
			_floor = new Mesh(new PlaneGeometry(1000, 1000), _floorMaterial);

			//setup the scene
			view.scene.addChild(_floor);
		}

		/**
		 * Initialise the engine
		 */
		override private function initEngine():Void
		{
			super.initEngine();

			//setup controller to be used on the camera
			_cameraController = new HoverController(view.camera, null, 45, 20, 1000, -90);
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

			super.render();
		}

		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):Void
		{
			if (event.asset.assetType == AssetType.MESH)
			{
				_mesh = Std.instance(event.asset,Mesh);

				//adjust the ogre material
				var material:TextureMaterial = Std.instance(_mesh.material,TextureMaterial);
				material.specularMap = Cast.bitmapTexture(OgreSpecular);
				material.normalMap = Cast.bitmapTexture(OgreNormals);
				material.lightPicker = _lightPicker;
				material.gloss = 30;
				material.specular = 1;
				material.ambientColor = 0x303040;
				material.ambient = 1;
				material.shadowMethod = _shadowMapMethod;

				//adjust the ogre mesh
				_mesh.y = 120;
				_mesh.scale(5);


				//create 16 different clones of the ogre
				var numWide:Float = 4;
				var numDeep:Float = 4;
				var k:uint = 0;
				for (var i:uint = 0; i < numWide; i++)
				{
					for (var j:uint = 0; j < numDeep; j++)
					{
						//clone mesh
						var clone:Mesh = Std.instance(_mesh.clone(),Mesh);
						clone.x = (i - (numWide - 1) / 2) * 1000 / numWide;
						clone.z = (j - (numDeep - 1) / 2) * 1000 / numDeep;
						clone.castsShadows = true;

						view.scene.addChild(clone);

						//create animator
						var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);

						//play specified state
						vertexAnimator.play(stateNames[i * numDeep + j]);
						clone.animator = vertexAnimator;
						k++;
					}
				}
			}
			else if (event.asset.assetType == AssetType.ANIMATION_SET)
			{
				_animationSet = Std.instance(event.asset,VertexAnimationSet);
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
