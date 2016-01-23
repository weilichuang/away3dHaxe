/*

Real time environment map reflections

Demonstrates:

How to use the CubeReflectionTexture to dynamically render environment maps.
How to use EnvMapMethod to apply the dynamic environment map to a material.
How to use the Elevation extrusions class to create a terrain from a heightmap.

Code by David Lenaerts & Rob Bateman
david.lenaerts@gmail.com
http://www.derschmale.com
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

package example;


import away3d.controllers.HoverController;
import away3d.entities.extrusions.Elevation;
import away3d.lights.DirectionalLight;
import away3d.entities.Mesh;
import away3d.events.AssetEvent;
import away3d.library.AssetLibrary;
import away3d.library.assets.AssetType;
import away3d.loaders.parsers.OBJParser;
import away3d.materials.ColorMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.EnvMapMethod;
import away3d.materials.methods.FogMethod;
import away3d.materials.methods.FresnelEnvMapMethod;
import away3d.materials.TextureMaterial;
import away3d.textures.CubeReflectionTexture;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Vector3D;
import flash.Lib;
import flash.text.AntiAliasType;
import flash.text.GridFitType;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;


class Intermediate_RealTimeEnvMap extends BasicApplication
{
	public static function main()
	{
		Lib.current.addChild(new Intermediate_RealTimeEnvMap());
	}
	
	//constants for R2D2 movement
	public static inline var MAX_SPEED:Float = 1;
	public static inline var MAX_ROTATION_SPEED:Float = 10;
	public static inline var DRAG:Float = .95;
	public static inline var ACCELERATION:Float = .5;
	public static inline var ROTATION:Float = .5;

	//engine variables
	private var cameraController:HoverController;

	//material objects
	private var reflectionTexture:CubeReflectionTexture;
	//private var floorMaterial : TextureMaterial;
	private var desertMaterial:TextureMaterial;
	private var reflectiveMaterial:ColorMaterial;
	private var r2d2Material:TextureMaterial;
	private var lightPicker:StaticLightPicker;
	private var fogMethod:FogMethod;

	//scene objects
	private var light:DirectionalLight;
	private var head:Mesh;
	private var r2d2:Mesh;

	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;

	//R2D2 motion variables
	//private var _drag : Number = 0.95;
	private var _acceleration:Float = 0;
	//private var _rotationDrag : Number = 0.95;
	private var _rotationAccel:Float = 0;
	private var _speed:Float = 0;
	private var _rotationSpeed:Float = 0;

	/**
	 * Constructor
	 */
	public function new()
	{
		super();
	}

	/**
	 * Global initialise function
	 */
	override private function init():Void
	{
		initEngine();
		initText();
		initLights();
		initReflectionCube();
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

		view.camera.lens.far = 4000;

		//setup controller to be used on the camera
		cameraController = new HoverController(view.camera, null, 90, 10, 600, 2, 90);
		cameraController.lookAtPosition = new Vector3D(0, 120, 0);
		cameraController.wrapPanAngle = true;
	}

	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		var text:TextField = new TextField();
		text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.ADVANCED;
		text.gridFitType = GridFitType.PIXEL;
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Cursor keys / WSAD - Move R2D2\n";
		text.appendText("Click+drag: Move camera\n");
		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights in a scene
	 */
	private function initLights():Void
	{
		//create global light
		light = new DirectionalLight(-1, -2, 1);
		light.color = 0xeedddd;
		light.ambient = 1;
		light.ambientColor = 0x808090;
		view.scene.addChild(light);

		//create global lightpicker
		lightPicker = new StaticLightPicker([light]);

		//create global fog method
		fogMethod = new FogMethod(500, 2000, 0x5f5e6e);
	}

	/**
	 * Initialized the ReflectionCubeTexture that will contain the environment map render
	 */
	private function initReflectionCube():Void
	{
	}


	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//create the skybox
		var skyBox:SnowSkyBox = new SnowSkyBox();

		view.scene.addChild(skyBox);
		
		// create reflection texture with a dimension of 256x256x256
		reflectionTexture = new CubeReflectionTexture(256);
		reflectionTexture.farPlaneDistance = 3000;
		reflectionTexture.nearPlaneDistance = 50;

		// center the reflection at (0, 100, 0) where our reflective object will be
		reflectionTexture.position = new Vector3D(0, 100, 0);

		// setup desert floor material
		desertMaterial = new TextureMaterial(createBitmapTexture(DesertTexture));
		desertMaterial.lightPicker = lightPicker;
		desertMaterial.addMethod(fogMethod);
		desertMaterial.repeat = true;
		desertMaterial.gloss = 5;
		desertMaterial.specular = .1;

		//setup R2D2 material
		r2d2Material = new TextureMaterial(createBitmapTexture(R2D2Texture));
		r2d2Material.lightPicker = lightPicker;
		r2d2Material.addMethod(fogMethod);
		r2d2Material.addMethod(new EnvMapMethod(skyBox.cubeTexture, .2));

		// setup fresnel method using our reflective texture in the place of a static environment map
		var fresnelMethod:FresnelEnvMapMethod = new FresnelEnvMapMethod(reflectionTexture);
		fresnelMethod.normalReflectance = .6;
		fresnelMethod.fresnelPower = 2;

		//setup the reflective material
		reflectiveMaterial = new ColorMaterial(0x000000);
		reflectiveMaterial.addMethod(fresnelMethod);
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		

		//create the desert ground
		var desert:Elevation = new Elevation(desertMaterial, new DesertHeightMap(0,0), 5000, 300, 5000, 250, 250);
		desert.y = -3;
		desert.geometry.scaleUV(25, 25);
		view.scene.addChild(desert);

		//enabled the obj parser
		AssetLibrary.enableParser(OBJParser);

		// load model data
		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.loadData(new HeadModel());
		AssetLibrary.loadData(new R2D2Model());
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

		if (r2d2 != null)
		{
			//drag
			_speed *= DRAG;

			//acceleration
			_speed += _acceleration;

			//speed bounds
			if (_speed > MAX_SPEED)
				_speed = MAX_SPEED;
			else if (_speed < -MAX_SPEED)
				_speed = -MAX_SPEED;

			//rotational drag
			_rotationSpeed *= DRAG;

			//rotational acceleration
			_rotationSpeed += _rotationAccel;

			//rotational speed bounds
			if (_rotationSpeed > MAX_ROTATION_SPEED)
				_rotationSpeed = MAX_ROTATION_SPEED;
			else if (_rotationSpeed < -MAX_ROTATION_SPEED)
				_rotationSpeed = -MAX_ROTATION_SPEED;

			//apply motion to R2D2
			r2d2.moveForward(_speed);
			r2d2.rotationY += _rotationSpeed;

			//keep R2D2 within max and min radius
			var radius:Float = Math.sqrt(r2d2.x * r2d2.x + r2d2.z * r2d2.z);
			if (radius < 200)
			{
				r2d2.x = 200 * r2d2.x / radius;
				r2d2.z = 200 * r2d2.z / radius;
			}
			else if (radius > 500)
			{
				r2d2.x = 500 * r2d2.x / radius;
				r2d2.z = 500 * r2d2.z / radius;
			}

			//pan angle overridden by R2D2 position
			cameraController.panAngle = 90 - 180 * Math.atan2(r2d2.z, r2d2.x) / Math.PI;
		}

		// render the view's scene to the reflection texture (view is required to use the correct stage3DProxy)
		reflectionTexture.render(view);
		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			if (event.asset.name == "g0")
			{ // Head
				head = Std.instance(event.asset,Mesh);
				head.scale(60);
				head.y = 180;
				head.rotationY = -90;
				head.material = reflectiveMaterial;
				view.scene.addChild(head);
			}
			else
			{ // R2D2
				r2d2 = Std.instance(event.asset, Mesh);
				r2d2.scale(5);
				r2d2.material = r2d2Material;
				r2d2.x = 200;
				r2d2.y = 30;
				r2d2.z = 0;
				view.scene.addChild(r2d2);
			}
		}
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

	/**
	 * Listener for keyboard down events
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.W,Keyboard.UP:
				_acceleration = ACCELERATION;
			case Keyboard.S,Keyboard.DOWN:
				_acceleration = -ACCELERATION;
			case Keyboard.A,Keyboard.LEFT:
				_rotationAccel = -ROTATION;
			case Keyboard.D,Keyboard.RIGHT:
				_rotationAccel = ROTATION;
		}
	}

	/**
	 * Listener for keyboard up events
	 */
	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.W,Keyboard.S,Keyboard.UP,Keyboard.DOWN:
				_acceleration = 0;
			case Keyboard.A,Keyboard.D,Keyboard.LEFT,Keyboard.RIGHT:
				_rotationAccel = 0;
		}
	}
}

// R2D2 Model
@:file("embeds/R2D2.obj") class R2D2Model extends flash.utils.ByteArray {}

// R2D2 Texture
@:bitmap("embeds/r2d2_diffuse.jpg") class R2D2Texture extends flash.display.BitmapData {}

// desert texture
@:bitmap("embeds/arid.jpg") class DesertTexture extends flash.display.BitmapData {}

//desert height map
@:bitmap("embeds/desertHeightMap.jpg") class DesertHeightMap extends flash.display.BitmapData {}

// head Model
@:file("embeds/head.obj") class HeadModel extends flash.utils.ByteArray {}