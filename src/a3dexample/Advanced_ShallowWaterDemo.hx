/*

Interactive pool using the Shallow Water Equations

Demonstrates:

How to create and deform a surface
How to apply an enviroment map to a material.
How to use 3D mouse events to return the local coordinate of a surface.
How to use the Shallow Water Equations to produce a convincing water effect.

Code by Rob Bateman, David Lenaerts & Alejadro Santander
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com
Alejandro Santander
http://www.lidev.com.ar/

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

package a3dexample;

import a3d.controllers.HoverController;
import a3d.core.base.SubGeometry;
import a3d.core.pick.PickingColliderType;
import a3d.entities.lights.PointLight;
import a3d.entities.Mesh;
import a3d.entities.primitives.CubeGeometry;
import a3d.entities.primitives.PlaneGeometry;
import a3d.events.MouseEvent3D;
import a3d.materials.ColorMaterial;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.EnvMapMethod;
import a3d.materials.methods.FogMethod;
import a3d.materials.TextureMaterial;
import a3d.textures.BitmapTexture;
import a3dexample.shallowwater.DisturbanceBrush;
import a3dexample.shallowwater.FluidDisturb;
import a3dexample.shallowwater.ShallowFluid;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.ColorTransform;
import flash.Lib;
import flash.ui.Keyboard;
import flash.utils.Timer;
import uk.co.soulwire.gui.SimpleGUI;




class Advanced_ShallowWaterDemo extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Advanced_ShallowWaterDemo());
	}
	
	/**
	 * GUI property for controlling the active displacement brush on the mouse
	 */
	public var activeMouseBrushClip(get,set):Sprite;
	/**
	 * GUI property for controlling the rate of rain
	 */
	public var rainTime(get,set):Int;
	/**
	 * GUI property for toggling shading on the water plane
	 */
	public var toggleShading(get,set):Bool;
	/**
	 * GUI property for toggling a3d text image
	 */
	public var toggleLiquidImage(get,set):Bool;
	/**
	 * GUI property for toggling Winston Churchill image
	 */
	public var toggleLiquidImage1(get, set):Bool;
	
	/**
	 * GUI property for toggling Mustang image
	 */
	public var toggleLiquidImage2(get,set):Bool;
	/**
	 * GUI property for toggling rain
	 */
	public var toggleRain(get,set):Bool;

	//engine variables
	private var cameraController:HoverController;

	//light objects
	private var skyLight:PointLight;
	private var lightPicker:StaticLightPicker;
	private var fogMethod:FogMethod;

	//material objects
	private var colorMaterial:ColorMaterial;
	private var liquidMaterial:ColorMaterial;
	private var poolMaterial:TextureMaterial;

	//fluid simulation variables
	private var gridDimension:UInt = 200;
	private var gridSpacing:UInt = 2;
	private var planeSize:Float;


	//scene objects
	public var fluid:ShallowFluid;
	private var plane:Mesh;
	private var fluidDisturb:FluidDisturb;
	private var gui:SimpleGUI;

	//gui variables

	private var rainBrush:DisturbanceBrush;
	private var imageBrush:DisturbanceBrush;
	private var mouseBrush:DisturbanceBrush;
	private var showingLiquidImage:Bool;
	private var showingLiquidImage1:Bool;
	private var showingLiquidImage2:Bool;
	private var aMouseBrushClip:Sprite;


	//interaction variables
	private var dropTmr:Timer;
	private var rain:Bool;
	private var liquidShading:Bool = true;
	private var planeDisturb:Bool = false;
	private var planeX:Float;
	private var planeY:Float;

	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var tiltSpeed:Float = 2;
	private var panSpeed:Float = 2;
	private var distanceSpeed:Float = 2;
	private var tiltIncrement:Float = 0;
	private var panIncrement:Float = 0;
	private var distanceIncrement:Float = 0;

	/**
	 * GUI property for controlling the strength of the displacement brush on the mouse
	 */
	public var mouseBrushStrength:Float = 5;

	/**
	 * GUI property for controlling the life of the displacement brush on the mouse
	 */
	public var mouseBrushLife:UInt = 0;

	/**
	 * GUI property for controlling the strength of the displacement brush on the rain
	 */
	public var rainBrushStrength:Float = 10;

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
		initLights();
		initMaterials();
		initObjects();
		initFluid();
		initGUI();
		initListeners();
	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 180, 20, 320, 5);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		skyLight = new PointLight();
		skyLight.color = 0x0000FF;
		skyLight.specular = 0.5;
		skyLight.diffuse = 2;
		scene.addChild(skyLight);

		lightPicker = new StaticLightPicker([skyLight]);

		//create a global fog method
		fogMethod = new FogMethod(0, 2500, 0x000000);
	}

	/**
	 * Initialise the material
	 */
	private function initMaterials():Void
	{
		//create skybox.
		var skyBox:SnowSkyBox = new SnowSkyBox();
		scene.addChild(skyBox);
		
		liquidMaterial = new ColorMaterial(0xFFFFFF);
		liquidMaterial.specular = 0.5;
		liquidMaterial.ambient = 0.25;
		liquidMaterial.ambientColor = 0x111199;
		liquidMaterial.ambient = 1;
		liquidMaterial.addMethod(new EnvMapMethod(skyBox.cubeTexture, 1));
		liquidMaterial.lightPicker = lightPicker;

		colorMaterial = new ColorMaterial(liquidMaterial.color);
		colorMaterial.specular = 0.5;
		colorMaterial.ambient = 0.25;
		colorMaterial.ambientColor = 0x555555;
		colorMaterial.ambient = 1;
		colorMaterial.diffuseMethod = new BasicDiffuseMethod();
		colorMaterial.lightPicker = lightPicker;

		var tex:BitmapData = new BitmapData(512, 512, false, 0);
		tex.perlinNoise(25, 25, 8, 1, false, true, 7, true);
		tex.colorTransform(tex.rect, new ColorTransform(0.1, 0.1, 0.1, 1, 0, 0, 0, 0));
		poolMaterial = new TextureMaterial(new BitmapTexture(tex));
		poolMaterial.addMethod(fogMethod);

	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create water plane.
		var planeSegments:UInt = (gridDimension - 1);
		planeSize = planeSegments * gridSpacing;
		plane = new Mesh(new PlaneGeometry(planeSize, planeSize, planeSegments, planeSegments), liquidMaterial);
		plane.rotationX = 90;
		plane.x -= planeSize / 2;
		plane.z -= planeSize / 2;
		plane.mouseEnabled = true;
		plane.pickingCollider = PickingColliderType.BOUNDS_ONLY;
		plane.geometry.convertToSeparateBuffers();
		plane.geometry.subGeometries[0].autoDeriveVertexNormals = false;
		plane.geometry.subGeometries[0].autoDeriveVertexTangents = false;
		scene.addChild(plane);

		//create pool
		var poolHeight:Float = 500000;
		var poolThickness:Float = 5;
		var poolVOffset:Float = 5 - poolHeight / 2;
		var poolHOffset:Float = planeSize / 2 + poolThickness / 2;

		var left:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness * 2), poolMaterial);
		left.x = -poolHOffset;
		left.y = poolVOffset;
		scene.addChild(left);

		var right:Mesh = new Mesh(new CubeGeometry(poolThickness, poolHeight, planeSize + poolThickness * 2), poolMaterial);
		right.x = poolHOffset;
		right.y = poolVOffset;
		scene.addChild(right);

		var back:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
		back.z = poolHOffset;
		back.y = poolVOffset;
		scene.addChild(back);

		var front:Mesh = new Mesh(new CubeGeometry(planeSize, poolHeight, poolThickness), poolMaterial);
		front.z = -poolHOffset;
		front.y = poolVOffset;
		scene.addChild(front);
	}

	/**
	 * Initialise the fluid
	 */
	private function initFluid():Void
	{
		// Fluid.
		var dt:Float = 1 / stage.frameRate;
		var viscosity:Float = 0.3;
		var waveVelocity:Float = 0.99; // < 1 or the sim will collapse.
		fluid = new ShallowFluid(gridDimension, gridDimension, gridSpacing, dt, waveVelocity, viscosity);

		// Disturbance util.
		fluidDisturb = new FluidDisturb(fluid);

	}

	/**
	 * Initialise the GUI
	 */
	private function initGUI():Void
	{
		// Init brush clips.
		var drop:Sprite = cast(new Brush3(),Sprite);

		var brushClips:Array<Dynamic> = [
			{label: "drop", data: drop},
			{label: "star", data: new Brush1()},
			{label: "box", data: new Brush2()},
			{label: "triangle", data: new Brush4()},
			{label: "stamp", data: new Brush5()},
			{label: "butter", data: new Brush6()}
			];

		aMouseBrushClip = drop;

		// Init brushes.
		rainBrush = new DisturbanceBrush();
		rainBrush.fromSprite(drop);
		mouseBrush = new DisturbanceBrush();
		mouseBrush.fromSprite(aMouseBrushClip);
		imageBrush = new DisturbanceBrush();
		imageBrush.fromSprite(cast(new ImageClip(),Sprite));

		// Rain.
		dropTmr = new Timer(50);
		dropTmr.addEventListener(TimerEvent.TIMER, onRainTimer);

		gui = new SimpleGUI(this, "");

		gui.addColumn("Instructions");
		var instr:String = "Click and drag on the stage to rotate camera.\n";
		instr += "Click on the fluid to disturb it.\n";
		instr += "Keyboard arrows and WASD also rotate camera.\n";
		instr += "Keyboard Z and X zoom camera.\n";
		gui.addLabel(instr);

		gui.addColumn("Simulation");
		gui.addSlider("fluid.speed", 0.0, 0.95, {label: "speed", tick: 0.01});
		gui.addSlider("fluid.viscosity", 0.0, 1.7, {label: "viscosity", tick: 0.01});
		gui.addToggle("toggleShading", {label: "reflective shading"});


		gui.addColumn("Rain");
		gui.addToggle("toggleRain", {label: "enabled"});
		gui.addSlider("rainTime", 10, 1000, {label: "speed", tick: 10});
		gui.addSlider("rainBrushStrength", 1, 50, {label: "strength", tick: 0.01});

		gui.addColumn("Mouse Brush");
		gui.addComboBox("activeMouseBrushClip", brushClips, {label: "brush"});
		gui.addSlider("mouseBrushStrength", -10, 10, {label: "strength", tick: 0.01});
		gui.addSlider("mouseBrushLife", 0, 10000, {label: "life", tick: 10});

		gui.addColumn("Liquid Image");
		gui.addToggle("toggleLiquidImage", {label: "away"});
		gui.addToggle("toggleLiquidImage2", {label: "mustang"});
		gui.addToggle("toggleLiquidImage1", {label: "winston"});
		gui.show();
	}

	/**
	 * Initialise the listeners
	 */
	override private function initListeners():Void
	{
		super.initListeners();

		plane.addEventListener(MouseEvent3D.MOUSE_MOVE, onPlaneMouseMove);
		plane.addEventListener(MouseEvent3D.MOUSE_DOWN, onPlaneMouseDown);
	}

	private function updatePlaneCoords(x:Float, y:Float):Void
	{
		planeX = x / planeSize;
		planeY = y / planeSize;
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		// Update fluid.
		fluid.evaluate();

		// Update memory disturbances.
		fluidDisturb.updateMemoryDisturbances();

		// Update plane to fluid.
		var subGeometry:SubGeometry = Std.instance(plane.geometry.subGeometries[0],SubGeometry);
		subGeometry.updateVertexData(fluid.points);
		subGeometry.updateVertexNormalData(fluid.normals);
		subGeometry.updateVertexTangentData(fluid.tangents);

		if (planeDisturb)
		{
			if (mouseBrushLife == 0)
				fluidDisturb.disturbBitmapInstant(planeX, planeY, -mouseBrushStrength, mouseBrush.bitmapData);
			else
				fluidDisturb.disturbBitmapMemory(planeX, planeY, -5 * mouseBrushStrength, mouseBrush.bitmapData, mouseBrushLife, 0.2);
		}
		else if (move)
		{
			cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
		}

		cameraController.panAngle += panIncrement;
		cameraController.tiltAngle += tiltIncrement;
		cameraController.distance += distanceIncrement;

		// Update light.
		skyLight.transform = camera.transform.clone();

		super.render();
	}

	/**
	 * Key down listener for camera control
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W:
				tiltIncrement = tiltSpeed;
			case Keyboard.DOWN,Keyboard.S:
				tiltIncrement = -tiltSpeed;
			case Keyboard.LEFT,Keyboard.A:
				panIncrement = panSpeed;
			case Keyboard.RIGHT,Keyboard.D:
				panIncrement = -panSpeed;
			case Keyboard.Z:
				distanceIncrement = distanceSpeed;
			case Keyboard.X:
				distanceIncrement = -distanceSpeed;
		}
	}

	/**
	 * Key up listener for camera control
	 */
	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W,Keyboard.DOWN,Keyboard.S:
				tiltIncrement = 0;
			case Keyboard.LEFT,Keyboard.A,Keyboard.RIGHT,Keyboard.D:
				panIncrement = 0;
			case Keyboard.Z,Keyboard.X:
				distanceIncrement = 0;
		}
	}

	/**
	 * mesh listener for fluid interaction with the mouse
	 */
	private function onPlaneMouseMove(event:MouseEvent3D):Void
	{
		if (planeDisturb)
			updatePlaneCoords(event.localPosition.x, event.localPosition.y);
	}

	/**
	 * mesh listener for fluid interaction with the mouse
	 */
	private function onPlaneMouseDown(event:MouseEvent3D):Void
	{
		planeDisturb = true;
		updatePlaneCoords(event.localPosition.x, event.localPosition.y);
	}

	/**
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
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
	override private function onMouseUp(event:MouseEvent):Void
	{
		move = false;
		planeDisturb = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		move = false;
		planeDisturb = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Timer listener for simulating rain
	 */
	private function onRainTimer(event:TimerEvent):Void
	{
		fluidDisturb.disturbBitmapInstant(0.8 * Math.random() + 0.1, 0.8 * Math.random() + 0.1, rainBrushStrength, rainBrush.bitmapData);
	}
	
	
	private function set_activeMouseBrushClip(value:Sprite):Sprite
	{
		aMouseBrushClip = value;
		mouseBrush.fromSprite(aMouseBrushClip, 2);
		return aMouseBrushClip;
	}

	private function get_activeMouseBrushClip():Sprite
	{
		return aMouseBrushClip;
	}

	
	private function set_rainTime(delay:Int):Int
	{
		dropTmr.delay = delay;
		return rainTime;
	}

	private function get_rainTime():Int
	{
		return Std.int(dropTmr.delay);
	}

	
	private function set_toggleShading(value:Bool):Bool
	{
		liquidShading = value;
		if (liquidShading)
			plane.material = liquidMaterial;
		else
			plane.material = colorMaterial;
		return liquidShading;
	}

	private function get_toggleShading():Bool
	{
		return liquidShading;
	}

	
	private function set_toggleLiquidImage(value:Bool):Bool
	{
		showingLiquidImage = value;
		if (showingLiquidImage)
		{
			imageBrush.fromSprite(cast(new ImageClip(),Sprite));
			fluidDisturb.disturbBitmapMemory(0.5, 0.5, -10, imageBrush.bitmapData, -1, 0.01);
		}
		else
			fluidDisturb.releaseMemoryDisturbances();
		return showingLiquidImage;
	}

	private function get_toggleLiquidImage():Bool
	{
		return showingLiquidImage;
	}

	
	private function set_toggleLiquidImage1(value:Bool):Bool
	{
		showingLiquidImage1 = value;
		if (showingLiquidImage1)
		{
			imageBrush.fromSprite(cast(new ImageClip1(),Sprite));
			fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, imageBrush.bitmapData, -1, 0.01);
		}
		else
			fluidDisturb.releaseMemoryDisturbances();
		return showingLiquidImage1;
	}

	private function get_toggleLiquidImage1():Bool
	{
		return showingLiquidImage1;
	}

	
	private function set_toggleLiquidImage2(value:Bool):Bool
	{
		showingLiquidImage2 = value;
		if (showingLiquidImage2)
		{
			imageBrush.fromSprite(cast(new ImageClip2(),Sprite));
			fluidDisturb.disturbBitmapMemory(0.5, 0.5, -15, imageBrush.bitmapData, -1, 0.01);
		}
		else
		{
			fluidDisturb.releaseMemoryDisturbances();
		}
		return showingLiquidImage2;
	}

	private function get_toggleLiquidImage2():Bool
	{
		return showingLiquidImage2;
	}

	
	private function set_toggleRain(value:Bool):Bool
	{
		rain = value;
		if (rain)
			dropTmr.start();
		else
			dropTmr.stop();
		return rain;
	}

	private function get_toggleRain():Bool
	{
		return rain;
	}
}