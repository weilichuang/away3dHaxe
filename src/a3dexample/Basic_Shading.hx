package a3dexample;

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.Lib;

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
	static function main()
	{
		Lib.current.addChild(new Basic_Shading());
	}
	
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
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;

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

		view.camera.z = -1000;
		view.camera.y = 800;
		view.camera.lookAt(new Vector3D());
		//setup controller to be used on the camera
		//cameraController = new HoverController(camera);
		//cameraController.distance = 1000;
		//cameraController.minTiltAngle = 0;
		//cameraController.maxTiltAngle = 90;
		//cameraController.panAngle = 45;
		//cameraController.tiltAngle = 20;
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		planeMaterial = new TextureMaterial(createBitmapTexture(FloorDiffuse));
		planeMaterial.specularMap = createBitmapTexture(FloorSpecular);
		planeMaterial.normalMap = createBitmapTexture(FloorNormals);
		planeMaterial.lightPicker = lightPicker;
		planeMaterial.repeat = true;
		planeMaterial.mipmap = false;

		sphereMaterial = new TextureMaterial(createBitmapTexture(BeachBallDiffuse));
		sphereMaterial.specularMap = createBitmapTexture(BeachBallSpecular);
		sphereMaterial.lightPicker = lightPicker;

		cubeMaterial = new TextureMaterial(createBitmapTexture(TrinketDiffuse));
		cubeMaterial.specularMap = createBitmapTexture(TrinketSpecular);
		cubeMaterial.normalMap = createBitmapTexture(TrinketNormals);
		cubeMaterial.lightPicker = lightPicker;
		cubeMaterial.mipmap = false;

		var weaveDiffuseTexture:BitmapTexture = createBitmapTexture(WeaveDiffuse);
		torusMaterial = new TextureMaterial(weaveDiffuseTexture);
		torusMaterial.specularMap = weaveDiffuseTexture;
		torusMaterial.normalMap = createBitmapTexture(WeaveNormals);
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

		light1.direction = new Vector3D(Math.sin(Lib.getTimer() / 10000) * 150000, 
										1000, 
										Math.cos(Lib.getTimer() / 10000) * 150000);

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

//cube textures
@:bitmap("embeds/trinket_diffuse.jpg") class TrinketDiffuse extends flash.display.BitmapData { }
@:bitmap("embeds/trinket_specular.jpg") class TrinketSpecular extends flash.display.BitmapData { }
@:bitmap("embeds/trinket_normal.jpg") class TrinketNormals extends flash.display.BitmapData { }

//sphere textures
@:bitmap("embeds/beachball_diffuse.jpg") class BeachBallDiffuse extends flash.display.BitmapData { }
@:bitmap("embeds/beachball_specular.jpg") class BeachBallSpecular extends flash.display.BitmapData { }

//torus textures
@:bitmap("embeds/weave_diffuse.jpg") class WeaveDiffuse extends flash.display.BitmapData { }
@:bitmap("embeds/weave_normal.jpg") class WeaveNormals extends flash.display.BitmapData { }

@:bitmap("embeds/floor_diffuse.jpg") class FloorDiffuse extends flash.display.BitmapData { }
@:bitmap("embeds/floor_specular.jpg") class FloorSpecular extends flash.display.BitmapData { }
@:bitmap("embeds/floor_normal.jpg") class FloorNormals extends flash.display.BitmapData { }