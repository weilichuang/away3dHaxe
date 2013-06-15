/*

Vertex animation example in Away3d using the MD2 format

Demonstrates:

How to use the AssetLibrary class to load an embedded internal md2 model.
How to clone an asset from the AssetLibrary and apply different mateirals.
How to load animations into an animation set and apply to individual meshes.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

Perelith Knight, by James Green (no email given)

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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Vector3D;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	import away3d.animators.VertexAnimationSet;
	import away3d.animators.VertexAnimator;
	import away3d.controllers.HoverController;
	import away3d.utils.AwayStats;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.events.LoaderEvent;
	import away3d.io.library.AssetLibrary;
	import away3d.io.library.assets.AssetType;
	import away3d.entities.lights.DirectionalLight;
	import away3d.io.loaders.parsers.MD2Parser;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.FilteredShadowMapMethod;
	import away3d.entities.primitives.PlaneGeometry;
	import away3d.utils.Cast;

	import example.utils.BitmapFilterEffects;

	public class Intermediate_PerelithKnightMD2 extends BasicApplication
	{
		//plane textures
		[Embed(source = "/../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//Perelith Knight diffuse texture 1
		[Embed(source = "/../embeds/pknight/pknight1.png")]
		public static var PKnightTexture1:Class;

		//Perelith Knight diffuse texture 2
		[Embed(source = "/../embeds/pknight/pknight2.png")]
		public static var PKnightTexture2:Class;

		//Perelith Knight diffuse texture 3
		[Embed(source = "/../embeds/pknight/pknight3.png")]
		public static var PKnightTexture3:Class;

		//Perelith Knight diffuse texture 4
		[Embed(source = "/../embeds/pknight/pknight4.png")]
		public static var PKnightTexture4:Class;

		//Perelith Knight model
		[Embed(source = "/../embeds/pknight/pknight.md2", mimeType = "application/octet-stream")]
		public static var PKnightModel:Class;

		//array of textures for random sampling
		private var _pKnightTextures:Vector.<Bitmap> = Vector.<Bitmap>([new PKnightTexture1(), new PKnightTexture2(), new PKnightTexture3(), new PKnightTexture4()]);
		private var _pKnightMaterials:Vector.<TextureMaterial> = new Vector.<TextureMaterial>();

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
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;
		private var _keyUp:Boolean;
		private var _keyDown:Boolean;
		private var _keyLeft:Boolean;
		private var _keyRight:Boolean;
		private var _lookAtPosition:Vector3D = new Vector3D();
		private var _animationSet:VertexAnimationSet;

		/**
		 * Constructor
		 */
		public function Intermediate_PerelithKnightMD2()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}

		override protected function initEngine():void
		{
			super.initEngine();

			//setup the camera for optimal rendering
			view.camera.lens.far = 5000;

			//setup controller to be used on the camera
			_cameraController = new HoverController(view.camera, null, 45, 20, 2000, 5);
		}

		override protected function initListeners():void
		{
			super.initListeners();
			stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		private function initObjects():void
		{
			//setup the help text
			var text:TextField = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.embedFonts = true;
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.gridFitType = GridFitType.PIXEL;
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Click and drag - rotate\n" +
				"Cursor keys / WSAD / ZSQD - move\n" +
				"Scroll wheel - zoom";

			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

			addChild(text);

			//setup the floor
			_floor = new Mesh(new PlaneGeometry(5000, 5000), _floorMaterial);
			_floor.geometry.scaleUV(5, 5);

			//setup the scene
			view.scene.addChild(_floor);

			//setup parser to be used on AssetLibrary
			AssetLibrary.loadData(new PKnightModel(), null, null, new MD2Parser());
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
			AssetLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		}

		private function initMaterials():void
		{
			//create a global shadow map method
			_shadowMapMethod = new FilteredShadowMapMethod(_light);

			//setup floor material
			_floorMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
			_floorMaterial.lightPicker = _lightPicker;
			_floorMaterial.specular = 0;
			_floorMaterial.ambient = 1;
			_floorMaterial.shadowMethod = _shadowMapMethod;
			_floorMaterial.repeat = true;

			//setup Perelith Knight materials
			for (var i:uint = 0; i < _pKnightTextures.length; i++)
			{
				var bitmapData:BitmapData = _pKnightTextures[i].bitmapData;
				var knightMaterial:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(bitmapData));
				knightMaterial.normalMap = Cast.bitmapTexture(BitmapFilterEffects.normalMap(bitmapData));
				knightMaterial.specularMap = Cast.bitmapTexture(BitmapFilterEffects.outline(bitmapData));
				knightMaterial.lightPicker = _lightPicker;
				knightMaterial.gloss = 30;
				knightMaterial.specular = 1;
				knightMaterial.ambient = 1;
				knightMaterial.shadowMethod = _shadowMapMethod;
				_pKnightMaterials.push(knightMaterial);
			}
		}

		private function initLights():void
		{
			//setup the lights for the scene
			_light = new DirectionalLight(-0.5, -1, -1);
			_light.ambient = 0.4;
			_lightPicker = new StaticLightPicker([_light]);
			view.scene.addChild(_light);
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

			if (_keyUp)
				_lookAtPosition.x -= 10;
			if (_keyDown)
				_lookAtPosition.x += 10;
			if (_keyLeft)
				_lookAtPosition.z -= 10;
			if (_keyRight)
				_lookAtPosition.z += 10;

			_cameraController.lookAtPosition = _lookAtPosition;

			super.render();
		}

		/**
		 * Listener function for asset complete event on loader
		 */
		private function onAssetComplete(event:AssetEvent):void
		{
			if (event.asset.assetType == AssetType.MESH)
			{
				_mesh = event.asset as Mesh;

				//adjust the ogre mesh
				_mesh.y = 120;
				_mesh.scale(5);

			}
			else if (event.asset.assetType == AssetType.ANIMATION_SET)
			{
				_animationSet = event.asset as VertexAnimationSet;
			}
		}

		/**
		 * Listener function for resource complete event on loader
		 */
		private function onResourceComplete(event:LoaderEvent):void
		{
			//create 20 x 20 different clones of the ogre
			var numWide:Number = 20;
			var numDeep:Number = 20;
			var k:uint = 0;
			for (var i:uint = 0; i < numWide; i++)
			{
				for (var j:uint = 0; j < numDeep; j++)
				{
					//clone mesh
					var clone:Mesh = _mesh.clone() as Mesh;
					clone.x = (i - (numWide - 1) / 2) * 5000 / numWide;
					clone.z = (j - (numDeep - 1) / 2) * 5000 / numDeep;
					clone.castsShadows = true;
					clone.material = _pKnightMaterials[uint(Math.random() * _pKnightMaterials.length)];
					view.scene.addChild(clone);

					//create animator
					var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);

					//play specified state
					vertexAnimator.play(_animationSet.animationNames[int(Math.random() * _animationSet.animationNames.length)], null, Math.random() * 1000);
					clone.animator = vertexAnimator;
					k++;
				}
			}
		}

		/**
		 * Key down listener for animation
		 */
		override protected function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.Z: //fr
					_keyUp = true;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					_keyDown = true;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.Q: //fr
					_keyLeft = true;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					_keyRight = true;
					break;
			}
		}

		/**
		 * Key up listener
		 */
		override protected function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.Z: //fr
					_keyUp = false;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					_keyDown = false;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.Q: //fr
					_keyLeft = false;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					_keyRight = false;
					break;
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
		}

		/**
		 * Mouse up listener for navigation
		 */
		override protected function onMouseUp(event:MouseEvent):void
		{
			_move = false;
		}

		/**
		 * Mouse wheel listener for navigation
		 */
		private function onMouseWheel(ev:MouseEvent):void
		{
			_cameraController.distance -= ev.delta * 5;

			if (_cameraController.distance < 100)
				_cameraController.distance = 100;
			else if (_cameraController.distance > 2000)
				_cameraController.distance = 2000;
		}
	}
}
