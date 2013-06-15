﻿/*

Terrain creation using height maps and splat maps

Demonstrates:

How to create a 3D terrain out of a hieght map
How to enhance the detail of a material close-up by applying splat maps.
How to create a realistic lake effect.
How to create first-person camera motion using the FirstPersonController.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

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
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	import away3d.controllers.FirstPersonController;
	import away3d.entities.Mesh;
	import away3d.entities.extrusions.Elevation;
	import away3d.entities.lights.DirectionalLight;
	import away3d.entities.primitives.PlaneGeometry;
	import away3d.filters.BloomFilter3D;
	import away3d.materials.TextureMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.materials.methods.FogMethod;
	import away3d.materials.methods.FresnelSpecularMethod;
	import away3d.materials.methods.SimpleWaterNormalMethod;
	import away3d.materials.methods.TerrainDiffuseMethod;
	import away3d.textures.BitmapTexture;
	import away3d.utils.Cast;

	public class Advanced_TerrainDemo extends BasicApplication
	{
		//water normal map
		[Embed(source = "/../embeds/water_normals.jpg")]
		private var WaterNormals:Class;

		// terrain height map
		[Embed(source = "/../embeds/terrain/terrain_heights.jpg")]
		private var HeightMap:Class;

		// terrain texture map
		[Embed(source = "/../embeds/terrain/terrain_diffuse.jpg")]
		private var Albedo:Class;

		// terrain normal map
		[Embed(source = "/../embeds/terrain/terrain_normals.jpg")]
		private var Normals:Class;

		//splat texture maps
		[Embed(source = "/../embeds/terrain/grass.jpg")]
		private var Grass:Class;
		[Embed(source = "/../embeds/terrain/rock.jpg")]
		private var Rock:Class;
		[Embed(source = "/../embeds/terrain/beach.jpg")]
		private var Beach:Class;

		//splat blend map
		[Embed(source = "/../embeds/terrain/terrain_splats.png")]
		private var Blend:Class;

		//engine variables
		private var cameraController:FirstPersonController;

		//light objects
		private var sunLight:DirectionalLight;
		private var lightPicker:StaticLightPicker;
		private var fogMethod:FogMethod;

		//material objects
		private var terrainMethod:TerrainDiffuseMethod;
		private var waterMethod:SimpleWaterNormalMethod;
		private var fresnelMethod:FresnelSpecularMethod;
		private var terrainMaterial:TextureMaterial;
		private var waterMaterial:TextureMaterial;

		//scene objects
		private var text:TextField;
		private var terrain:Elevation;
		private var plane:Mesh;

		//rotation variables
		private var move:Boolean = false;
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;

		//movement variables
		private var drag:Number = 0.5;
		private var walkIncrement:Number = 2;
		private var strafeIncrement:Number = 2;
		private var walkSpeed:Number = 0;
		private var strafeSpeed:Number = 0;
		private var walkAcceleration:Number = 0;
		private var strafeAcceleration:Number = 0;

		/**
		 * Constructor
		 */
		public function Advanced_TerrainDemo()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():void
		{
			initEngine();
			initText();
			initLights();
			initMaterials();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the engine
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			camera.lens.far = 4000;
			camera.lens.near = 1;
			camera.y = 300;

			//setup controller to be used on the camera
			cameraController = new FirstPersonController(camera, 180, 0, -80, 80);

//			view.filters3d = [new BloomFilter3D(200, 200, .85, 15, 3)];
		}

		/**
		 * Create an instructions overlay
		 */
		private function initText():void
		{
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 240;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.text = "Mouse click and drag - rotate\n" +
				"Cursor keys / WSAD - move\n";

			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

			addChild(text);
		}

		/**
		 * Initialise the lights
		 */
		private function initLights():void
		{
			sunLight = new DirectionalLight(-300, -300, -5000);
			sunLight.color = 0xfffdc5;
			sunLight.ambient = 1;
			scene.addChild(sunLight);

			lightPicker = new StaticLightPicker([sunLight]);

			//create a global fog method
			fogMethod = new FogMethod(0, 8000, 0xcfd9de);
		}

		/**
		 * Initialise the material
		 */
		private var skyBox:SnowSkyBox;

		private function initMaterials():void
		{
			terrainMethod = new TerrainDiffuseMethod([Cast.bitmapTexture(Beach), Cast.bitmapTexture(Grass), Cast.bitmapTexture(Rock)], Cast.bitmapTexture(Blend), [1, 50, 150, 100]);

			terrainMaterial = new TextureMaterial(Cast.bitmapTexture(Albedo));
			terrainMaterial.diffuseMethod = terrainMethod;
			terrainMaterial.normalMap = Cast.bitmapTexture(Normals);
			terrainMaterial.lightPicker = lightPicker;
			terrainMaterial.ambientColor = 0x303040;
			terrainMaterial.ambient = 1;
			terrainMaterial.specular = .2;
			terrainMaterial.addMethod(fogMethod);

			waterMethod = new SimpleWaterNormalMethod(Cast.bitmapTexture(WaterNormals), Cast.bitmapTexture(WaterNormals));
			fresnelMethod = new FresnelSpecularMethod();
			fresnelMethod.normalReflectance = .3;

			skyBox = new SnowSkyBox();
			//create skybox.
			scene.addChild(skyBox);

			waterMaterial = new TextureMaterial(new BitmapTexture(new BitmapData(512, 512, true, 0xaa404070)));
			waterMaterial.alphaBlending = true;
			waterMaterial.lightPicker = lightPicker;
			waterMaterial.repeat = true;
			waterMaterial.normalMethod = waterMethod;
			waterMaterial.addMethod(new EnvMapMethod(skyBox.cubeTexture));
			waterMaterial.specularMethod = fresnelMethod;
			waterMaterial.gloss = 100;
			waterMaterial.specular = 1;
		}


		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//create mountain like terrain
			terrain = new Elevation(terrainMaterial, Cast.bitmapData(HeightMap), 5000, 1300, 5000, 250, 250);
			scene.addChild(terrain);

			//create water
			plane = new Mesh(new PlaneGeometry(5000, 5000), waterMaterial);
			plane.geometry.scaleUV(50, 50);
			plane.y = 285;
			scene.addChild(plane);
		}

		/**
		 * Navigation and render loop
		 */
		override protected function render():void
		{
			//set the camera height based on the terrain (with smoothing)
			camera.y += 0.2 * (terrain.getHeightAt(camera.x, camera.z) + 20 - camera.y);

			if (move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;

			}

			if (walkSpeed || walkAcceleration)
			{
				walkSpeed = (walkSpeed + walkAcceleration) * drag;
				if (Math.abs(walkSpeed) < 0.01)
					walkSpeed = 0;
				cameraController.incrementWalk(walkSpeed);
			}

			if (strafeSpeed || strafeAcceleration)
			{
				strafeSpeed = (strafeSpeed + strafeAcceleration) * drag;
				if (Math.abs(strafeSpeed) < 0.01)
					strafeSpeed = 0;
				cameraController.incrementStrafe(strafeSpeed);
			}

			//animate our lake material
			waterMethod.water1OffsetX += .005;
			waterMethod.water1OffsetY += .007;
			waterMethod.water2OffsetX += .003;
			waterMethod.water2OffsetY += .004;

			super.render();
		}

		/**
		 * Key down listener for camera control
		 */
		override protected function onKeyDown(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
					walkAcceleration = walkIncrement;
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = -walkIncrement;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					strafeAcceleration = -strafeIncrement;
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = strafeIncrement;
					break;
			}
		}

		/**
		 * Key up listener for camera control
		 */
		override protected function onKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.DOWN:
				case Keyboard.S:
					walkAcceleration = 0;
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.RIGHT:
				case Keyboard.D:
					strafeAcceleration = 0;
					break;
			}
		}

		/**
		 * Mouse down listener for navigation
		 */
		override protected function onMouseDown(event:MouseEvent):void
		{
			move = true;
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse up listener for navigation
		 */
		override protected function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}
