package a3dexample;

import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.nodes.ParticleBillboardNode;
import a3d.animators.nodes.ParticleColorNode;
import a3d.animators.nodes.ParticleScaleNode;
import a3d.animators.nodes.ParticleVelocityNode;
import a3d.animators.ParticleAnimationSet;
import a3d.animators.ParticleAnimator;
import a3d.controllers.HoverController;
import a3d.core.base.Geometry;
import a3d.core.base.ParticleGeometry;
import a3d.entities.Camera3D;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.PointLight;
import a3d.entities.Mesh;
import a3d.entities.primitives.PlaneGeometry;
import a3d.entities.Scene3D;
import a3d.materials.BlendMode;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.TextureMaterial;
import a3d.materials.TextureMultiPassMaterial;
import a3d.tools.helpers.ParticleGeometryHelper;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.ColorTransform;
import flash.geom.Vector3D;
import flash.Lib;
import flash.utils.Timer;
import flash.Vector;




class Basic_Fire extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_Fire());
	}
	
	private static inline var NUM_FIRES:Int = 10;

	//engine variables
	private var cameraController:HoverController;

	//material objects
	private var planeMaterial:TextureMultiPassMaterial;
	private var particleMaterial:TextureMaterial;

	//light objects
	private var directionalLight:DirectionalLight;
	private var lightPicker:StaticLightPicker;

	//particle objects
	private var fireAnimationSet:ParticleAnimationSet;
	private var particleGeometry:ParticleGeometry;
	private var timer:Timer;

	//scene objects
	private var plane:Mesh;
	private var fireObjects:Vector<FireVO>;

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
		initParticles();
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
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		directionalLight = new DirectionalLight(0, -1, 0);
		directionalLight.castsShadows = false;
		directionalLight.color = 0xeedddd;
		directionalLight.diffuse = .5;
		directionalLight.ambient = .5;
		directionalLight.specular = 0;
		directionalLight.ambientColor = 0x808090;
		view.scene.addChild(directionalLight);

		lightPicker = new StaticLightPicker([directionalLight]);
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		planeMaterial = new TextureMultiPassMaterial(createBitmapTexture(FloorDiffuse));
		planeMaterial.specularMap = createBitmapTexture(FloorSpecular);
		planeMaterial.normalMap = createBitmapTexture(FloorNormals);
		planeMaterial.lightPicker = lightPicker;
		planeMaterial.repeat = true;
		planeMaterial.mipmap = false;
		planeMaterial.specular = 10;

		particleMaterial = new TextureMaterial(createBitmapTexture(FireTexture));
		particleMaterial.blendMode = BlendMode.ADD;
	}

	/**
	 * Initialise the particles
	 */
	private function initParticles():Void
	{

		//create the particle animation set
		fireAnimationSet = new ParticleAnimationSet(true, true);

		//add some animations which can control the particles:
		//the global animations can be set directly, because they influence all the particles with the same factor
		fireAnimationSet.addAnimation(new ParticleBillboardNode());
		fireAnimationSet.addAnimation(new ParticleScaleNode(ParticlePropertiesMode.GLOBAL, false, false, 2.5, 0.5));
		fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.GLOBAL, new Vector3D(0, 80, 0)));
		fireAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, true, false, false, new ColorTransform(0, 0, 0, 1, 0xFF, 0x33, 0x01), new ColorTransform(0, 0, 0, 1,
			0x99)));

		//no need to set the local animations here, because they influence all the particle with different factors.
		fireAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));

		//set the initParticleFunc. It will be invoked for the local static property initialization of every particle
		fireAnimationSet.initParticleFunc = initParticleFunc;

		//create the original particle geometry
		var particle:Geometry = new PlaneGeometry(10, 10, 1, 1, false);

		//combine them into a list
		var geometrySet:Vector<Geometry> = new Vector<Geometry>();
		for (i in 0...500)
			geometrySet.push(particle);

		particleGeometry = ParticleGeometryHelper.generateGeometry(geometrySet);
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		view.scene.addChild(new SnowSkyBox());
		
		fireObjects = new Vector<FireVO>();
		
		plane = new Mesh(new PlaneGeometry(1000, 1000), planeMaterial);
		plane.geometry.scaleUV(2, 2);
		plane.y = -20;

		scene.addChild(plane);

		//create fire object meshes from geomtry and material, and apply particle animators to each
		for (i in 0...NUM_FIRES)
		{
			var particleMesh:Mesh = new Mesh(particleGeometry, particleMaterial);
			var animator:ParticleAnimator = new ParticleAnimator(fireAnimationSet);
			particleMesh.animator = animator;

			//position the mesh
			var degree:Float = i / NUM_FIRES * Math.PI * 2;
			particleMesh.x = Math.sin(degree) * 400;
			particleMesh.z = Math.cos(degree) * 400;
			particleMesh.y = 5;

			//create a fire object and add it to the fire object vector
			fireObjects.push(new FireVO(particleMesh, animator));
			view.scene.addChild(particleMesh);
		}

		//setup timer for triggering each particle aniamtor
		timer = new Timer(1000, fireObjects.length);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();
	}

	/**
	 * Initialiser function for particle properties
	 */
	private function initParticleFunc(prop:ParticleProperties):Void
	{
		prop.startTime = Math.random() * 5;
		prop.duration = Math.random() * 4 + 0.1;

		var degree1:Float = Math.random() * Math.PI * 2;
		var degree2:Float = Math.random() * Math.PI * 2;
		var r:Float = 15;
		untyped prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
	}

	/**
	 * Returns an array of active lights in the scene
	 */
	private function getAllLights():Array<LightBase>
	{
		var lights:Array<LightBase> = [];

		lights.push(directionalLight);

		for (fireVO in fireObjects)
			if (fireVO.light != null)
				lights.push(fireVO.light);

		return lights;
	}

	/**
	 * Timer event handler
	 */
	private function onTimer(e:TimerEvent):Void
	{
		var fireObject:FireVO = fireObjects[timer.currentCount - 1];

		//start the animator
		fireObject.animator.start();

		//create the lightsource
		var light:PointLight = new PointLight();
		light.color = 0xFF3301;
		light.diffuse = 0;
		light.specular = 0;
		light.position = fireObject.mesh.position;

		//add the lightsource to the fire object
		fireObject.light = light;

		//update the lightpicker
		lightPicker.lights = getAllLights();
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

		//animate lights
		var fireVO:FireVO;
		for (fireVO in fireObjects)
		{
			//update flame light
			var light:PointLight = fireVO.light;

			if (light == null)
				continue;

			if (fireVO.strength < 1)
				fireVO.strength += 0.1;

			light.fallOff = 380 + Math.random() * 20;
			light.radius = 200 + Math.random() * 30;
			light.diffuse = light.specular = fireVO.strength + Math.random() * .2;
		}

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


/**
 * Data class for the fire objects
 */
class FireVO
{
	public var mesh:Mesh;
	public var animator:ParticleAnimator;
	public var light:PointLight;
	public var strength:Float = 0;

	public function new(mesh:Mesh, animator:ParticleAnimator)
	{
		this.mesh = mesh;
		this.animator = animator;
	}
}

//fire texture
@:bitmap("embeds/blue.png") class FireTexture extends flash.display.BitmapData { }
//plane textures
@:bitmap("embeds/floor_diffuse.jpg") class FloorDiffuse extends flash.display.BitmapData { }
@:bitmap("embeds/floor_specular.jpg") class FloorSpecular extends flash.display.BitmapData { }
@:bitmap("embeds/floor_normal.jpg") class FloorNormals extends flash.display.BitmapData { }
