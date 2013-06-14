/*

3ds file loading example in Away3d

Demonstrates:

How to use the Loader3D object to load an embedded internal 3ds model.
How to map an external asset reference inside a file to an internal embedded asset.
How to extract material data and use it to set custom material properties on a model.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package example
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.library.assets.AssetType;
	import away3d.lights.DirectionalLight;
	import away3d.loaders.Loader3D;
	import away3d.loaders.misc.AssetLoaderContext;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.primitives.PlaneGeometry;
	import away3d.utils.Cast;

	public class Basic_Load3DS extends BasicApplication
	{
		//solider ant texture
		[Embed(source = "/../embeds/soldier_ant.jpg")]
		public static var AntTexture:Class;

		//solider ant model
		[Embed(source = "/../embeds/soldier_ant.3ds", mimeType = "application/octet-stream")]
		public static var AntModel:Class;

		//ground texture
		[Embed(source = "/../embeds/CoarseRedSand.jpg")]
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
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;

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
		private function init():void
		{
			initEngine();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
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
		override protected function initEngine():void
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
		override protected function render():void
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
		private function onAssetComplete(event:AssetEvent):void
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
		override protected function onMouseDown(event:MouseEvent):void
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
		override protected function onMouseUp(event:MouseEvent):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}
