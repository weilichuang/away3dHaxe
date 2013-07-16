package a3dexample;

import a3d.controllers.HoverController;
import a3d.entities.Camera3D;
import a3d.entities.lights.PointLight;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.entities.primitives.SkyBox;
import a3d.entities.primitives.SphereGeometry;
import a3d.entities.Scene3D;
import a3d.entities.Sprite3D;
import a3d.io.loaders.parsers.Parsers;
import a3d.materials.BlendMode;
import a3d.materials.ColorMaterial;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterData;
import a3d.materials.compilation.ShaderRegisterElement;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.methods.CompositeDiffuseMethod;
import a3d.materials.methods.CompositeSpecularMethod;
import a3d.materials.methods.FresnelSpecularMethod;
import a3d.materials.methods.MethodVO;
import a3d.materials.methods.PhongSpecularMethod;
import a3d.materials.TextureMaterial;
import a3d.textures.BitmapCubeTexture;
import a3d.textures.BitmapTexture;
import a3d.utils.Cast;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.Lib;
import flash.text.AntiAliasType;
import flash.text.GridFitType;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.Vector.Vector;
import flash.display.Bitmap;

class Intermediate_Globe extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_Globe());
	}

	//engine variables
	private var cameraController:HoverController;

	//material objects
	private var sunMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var cloudMaterial:TextureMaterial;
	private var atmosphereMaterial:ColorMaterial;
	private var atmosphereDiffuseMethod:BasicDiffuseMethod;
	private var atmosphereSpecularMethod:BasicSpecularMethod;

	//scene objects
	private var sun:Sprite3D;
	private var earth:Mesh;
	private var clouds:Mesh;
	private var atmosphere:Mesh;
	private var tiltContainer:ObjectContainer3D;
	private var orbitContainer:ObjectContainer3D;
	private var skyBox:SkyBox;

	//light objects
	private var light:PointLight;
	private var lightPicker:StaticLightPicker;
	private var flares:Vector<FlareObject>;

	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var mouseLockX:Float = 0;
	private var mouseLockY:Float = 0;
	private var mouseLocked:Bool;
	private var flareVisible:Bool;

	/**
	 * Constructor
	 */
	public function new()
	{
		flares = new Vector<FlareObject>();
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
		initLensFlare();
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

		//setup camera for optimal skybox rendering
		camera = new Camera3D();
		camera.lens.far = 100000;

		view.scene = scene;
		view.camera = camera;

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 0, 0, 600, -90, 90);
		cameraController.yFactor = 1;

		//setup parser to be used on loader3D
		Parsers.enableAllBundled();
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
		text.text = "MOUSE:\n" +
			"\t windowed: click and drag - rotate\n" +
			"\t fullscreen: mouse move - rotate\n" +
			"SCROLL_WHEEL - zoom\n" +
			"SPACE - enables fullscreen mode";

		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		light = new PointLight();
		light.x = 10000;
		light.ambient = 1;
		light.diffuse = 2;

		lightPicker = new StaticLightPicker([light]);
	}

	private function initLensFlare():Void
	{
		flares.push(new FlareObject(new Flare10(0,0), 3.2, -0.01, 147.9));
		flares.push(new FlareObject(new Flare11(0,0), 6, 0, 30.6));
		flares.push(new FlareObject(new Flare7(0,0), 2, 0, 25.5));
		flares.push(new FlareObject(new Flare7(0,0), 4, 0, 17.85));
		flares.push(new FlareObject(new Flare12(0,0), 0.4, 0.32, 22.95));
		flares.push(new FlareObject(new Flare6(0,0), 1, 0.68, 20.4));
		flares.push(new FlareObject(new Flare2(0,0), 1.25, 1.1, 48.45));
		flares.push(new FlareObject(new Flare3(0,0), 1.75, 1.37, 7.65));
		flares.push(new FlareObject(new Flare4(0,0), 2.75, 1.85, 12.75));
		flares.push(new FlareObject(new Flare8(0,0), 0.5, 2.21, 33.15));
		flares.push(new FlareObject(new Flare6(0,0), 4, 2.5, 10.4));
		flares.push(new FlareObject(new Flare7(0,0), 10, 2.66, 50));
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//adjust specular map
		var specBitmap:BitmapData = Cast.bitmapData(EarthSpecular);
		specBitmap.colorTransform(specBitmap.rect, new ColorTransform(1, 1, 1, 1, 64, 64, 64));

		var specular:FresnelSpecularMethod = new FresnelSpecularMethod(true, new PhongSpecularMethod());
		specular.fresnelPower = 1;
		specular.normalReflectance = 0.1;

		sunMaterial = new TextureMaterial(Cast.bitmapTexture(Flare10));
		sunMaterial.blendMode = BlendMode.ADD;

		groundMaterial = new TextureMaterial(Cast.bitmapTexture(EarthDiffuse));
		groundMaterial.specularMethod = specular;
		groundMaterial.specularMap = new BitmapTexture(specBitmap);
		groundMaterial.normalMap = Cast.bitmapTexture(EarthNormals);
		groundMaterial.ambientTexture = Cast.bitmapTexture(EarthNight);
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.gloss = 5;
		groundMaterial.specular = 1;
		groundMaterial.ambientColor = 0xFFFFFF;
		groundMaterial.ambient = 1;

		var skyBitmap:BitmapData = new BitmapData(2048, 1024, true, 0xFFFFFFFF);
		skyBitmap.copyChannel(Cast.bitmapData(SkyDiffuse), skyBitmap.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);

		cloudMaterial = new TextureMaterial(new BitmapTexture(skyBitmap));
		cloudMaterial.alphaBlending = true;
		cloudMaterial.lightPicker = lightPicker;
		cloudMaterial.specular = 0;
		cloudMaterial.ambientColor = 0x1b2048;
		cloudMaterial.ambient = 1;

		atmosphereDiffuseMethod = new CompositeDiffuseMethod(modulateDiffuseMethod);
		atmosphereSpecularMethod = new CompositeSpecularMethod(modulateSpecularMethod, new PhongSpecularMethod());

		atmosphereMaterial = new ColorMaterial(0x1671cc);
		atmosphereMaterial.diffuseMethod = atmosphereDiffuseMethod;
		atmosphereMaterial.specularMethod = atmosphereSpecularMethod;
		atmosphereMaterial.blendMode = BlendMode.ADD;
		atmosphereMaterial.lightPicker = lightPicker;
		atmosphereMaterial.specular = 0.5;
		atmosphereMaterial.gloss = 5;
		atmosphereMaterial.ambientColor = 0x0;
		atmosphereMaterial.ambient = 1;
	}

	private function modulateDiffuseMethod(vo:MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
		var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;

		var code:String = "dp3 " + t + ".w, " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" +
			"mul " + t + ".w, " + t + ".w, " + t + ".w\n";

		return code;
	}

	private function modulateSpecularMethod(vo:MethodVO, t:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
	{
		var viewDirFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.viewDirFragment;
		var normalFragmentReg:ShaderRegisterElement = atmosphereDiffuseMethod.sharedRegisters.normalFragment;
		var temp:ShaderRegisterElement = regCache.getFreeFragmentSingleTemp();
		regCache.addFragmentTempUsages(temp, 1);

		var code:String = "dp3 " + temp + ", " + viewDirFragmentReg + ".xyz, " + normalFragmentReg + ".xyz\n" +
			"neg" + temp + ", " + temp + "\n" +
			"mul " + t + ".w, " + t + ".w, " + temp + "\n";

		regCache.removeFragmentTempUsage(temp);

		return code;
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		orbitContainer = new ObjectContainer3D();
		orbitContainer.addChild(light);
		scene.addChild(orbitContainer);

		sun = new Sprite3D(sunMaterial, 3000, 3000);
		sun.x = 10000;
		orbitContainer.addChild(sun);

		earth = new Mesh(new SphereGeometry(200, 200, 100), groundMaterial);

		clouds = new Mesh(new SphereGeometry(202, 200, 100), cloudMaterial);

		atmosphere = new Mesh(new SphereGeometry(210, 200, 100), atmosphereMaterial);
		atmosphere.scaleX = -1;

		tiltContainer = new ObjectContainer3D();
		tiltContainer.rotationX = -23;
		tiltContainer.addChild(earth);
		tiltContainer.addChild(clouds);
		tiltContainer.addChild(atmosphere);

		scene.addChild(tiltContainer);

		cameraController.lookAtObject = tiltContainer;

		//create a skybox
		scene.addChild(new SpaceSkyBox());
	}

	/**
	 * Initialise the listeners
	 */
	override private function initListeners():Void
	{
		super.initListeners();

		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		earth.rotationY += 0.2;
		clouds.rotationY += 0.21;
		orbitContainer.rotationY += 0.02;

		if (stage.mouseLock)
		{
			cameraController.panAngle = 0.3 * mouseLockX;
			cameraController.tiltAngle = 0.3 * mouseLockY;
		}
		else if (move)
		{
			cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
		}

		super.render();

		updateFlares();
	}

	private function updateFlares():Void
	{
		var flareVisibleOld:Bool = flareVisible;

		var sunScreenPosition:Vector3D = view.project(sun.scenePosition);
		var xOffset:Float = sunScreenPosition.x - stage.stageWidth / 2;
		var yOffset:Float = sunScreenPosition.y - stage.stageHeight / 2;

		var earthScreenPosition:Vector3D = view.project(earth.scenePosition);
		var earthRadius:Float = 190 * stage.stageHeight / earthScreenPosition.z;
		var flareObject:FlareObject;

		flareVisible = (sunScreenPosition.x > 0 && sunScreenPosition.x < stage.stageWidth && sunScreenPosition.y > 0 && sunScreenPosition.y < stage.stageHeight && sunScreenPosition.z > 0 && Math.sqrt(xOffset *
			xOffset + yOffset * yOffset) > earthRadius) ? true : false;

		//update flare visibility
		if (flareVisible != flareVisibleOld)
		{
			for (flareObject in flares)
			{
				if (flareVisible)
					addChild(flareObject.sprite);
				else
					removeChild(flareObject.sprite);
			}
		}

		//update flare position
		if (flareVisible)
		{
			var flareDirection:Point = new Point(xOffset, yOffset);
			for (flareObject in flares)
			{
				flareObject.sprite.x = sunScreenPosition.x - flareDirection.x * flareObject.position - flareObject.sprite.width / 2;
				flareObject.sprite.y = sunScreenPosition.y - flareDirection.y * flareObject.position - flareObject.sprite.height / 2;
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
	override private function onMouseUp(e:MouseEvent):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse move listener for mouseLock
	 */
	private function onMouseMove(e:MouseEvent):Void
	{
		if (stage.displayState == StageDisplayState.FULL_SCREEN)
		{

			if (mouseLocked && (lastMouseX != 0 || lastMouseY != 0))
			{
				e.movementX += lastMouseX;
				e.movementY += lastMouseY;
				lastMouseX = 0;
				lastMouseY = 0;
			}

			mouseLockX += e.movementX;
			mouseLockY += e.movementY;

			if (!stage.mouseLock)
			{
				stage.mouseLock = true;
				lastMouseX = stage.mouseX - stage.stageWidth / 2;
				lastMouseY = stage.mouseY - stage.stageHeight / 2;
			}
			else if (!mouseLocked)
			{
				mouseLocked = true;
			}

			//ensure bounds for tiltAngle are not eceeded
			if (mouseLockY > cameraController.maxTiltAngle / 0.3)
				mouseLockY = cameraController.maxTiltAngle / 0.3;
			else if (mouseLockY < cameraController.minTiltAngle / 0.3)
				mouseLockY = cameraController.minTiltAngle / 0.3;
		}
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
	 * Mouse wheel listener for navigation
	 */
	private function onMouseWheel(event:MouseEvent):Void
	{
		cameraController.distance -= event.delta * 5;

		if (cameraController.distance < 400)
			cameraController.distance = 400;
		else if (cameraController.distance > 10000)
			cameraController.distance = 10000;
	}

	/**
	 * Key down listener for fullscreen
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.SPACE:
				if (stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					stage.displayState = StageDisplayState.NORMAL;
				}
				else
				{
					stage.displayState = StageDisplayState.FULL_SCREEN;

					mouseLocked = false;
					mouseLockX = cameraController.panAngle / 0.3;
					mouseLockY = cameraController.tiltAngle / 0.3;
				}
		}
	}
}


class FlareObject
{
	private var flareSize:Float = 144;

	public var sprite:Bitmap;

	public var size:Float;

	public var position:Float;

	public var opacity:Float;

	/**
	* Constructor
	*/
	public function new(data:BitmapData, size:Float, position:Float, opacity:Float)
	{
		this.sprite = new Bitmap(new BitmapData(data.width, data.height, true, 0xFFFFFFFF));
		this.sprite.bitmapData.copyChannel(data, data.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		this.sprite.alpha = opacity / 100;
		this.sprite.smoothing = true;
		this.sprite.scaleX = this.sprite.scaleY = size * flareSize / sprite.width;
		this.size = size;
		this.position = position;
		this.opacity = opacity;
	}
}


//night map for globe
@:bitmap("embeds/globe/land_lights_16384.jpg") class EarthNight extends flash.display.BitmapData { }

//diffuse map for globe
@:bitmap("embeds/globe/land_ocean_ice_2048_match.jpg") class EarthDiffuse extends flash.display.BitmapData { }

//normal map for globe
@:bitmap("embeds/globe/EarthNormal.png") class EarthNormals extends flash.display.BitmapData { }

//specular map for globe
@:bitmap("embeds/globe/earth_specular_2048.jpg") class EarthSpecular extends flash.display.BitmapData { }

//diffuse map for globe
@:bitmap("embeds/globe/cloud_combined_2048.jpg") class SkyDiffuse extends flash.display.BitmapData { }

//lens flare
@:bitmap("embeds/lensflare/flare0.jpg") class Flare0 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare1.jpg") class Flare1 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare2.jpg") class Flare2 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare3.jpg") class Flare3 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare4.jpg") class Flare4 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare5.jpg") class Flare5 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare6.jpg") class Flare6 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare7.jpg") class Flare7 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare8.jpg") class Flare8 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare9.jpg") class Flare9 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare10.jpg") class Flare10 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare11.jpg") class Flare11 extends flash.display.BitmapData { }
@:bitmap("embeds/lensflare/flare12.jpg") class Flare12 extends flash.display.BitmapData { }