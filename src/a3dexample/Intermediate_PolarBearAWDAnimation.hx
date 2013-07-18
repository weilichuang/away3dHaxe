/*

Bones animation loading and interaction example in a3d

Demonstrates:

How to load an AWD file with bones animation from external resources.
How to map animation data after loading in order to playback an animation sequence.
How to control the movement of a game character using the mouse.
How to use a skybox with a fog method to create a seamless play area.
How to create a snow effect with the particle system.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

Model by Billy Allison
bli@blimation.com
http://www.blimation.com/

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

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Lib;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.Vector.Vector;

import a3d.animators.ParticleAnimationSet;
import a3d.animators.ParticleAnimator;
import a3d.animators.SkeletonAnimationSet;
import a3d.animators.SkeletonAnimator;
import a3d.animators.data.ParticleProperties;
import a3d.animators.data.ParticlePropertiesMode;
import a3d.animators.data.Skeleton;
import a3d.animators.nodes.ParticleOscillatorNode;
import a3d.animators.nodes.ParticlePositionNode;
import a3d.animators.nodes.ParticleRotationalVelocityNode;
import a3d.animators.nodes.ParticleVelocityNode;
import a3d.animators.nodes.SkeletonClipNode;
import a3d.animators.transitions.CrossfadeTransition;
import a3d.entities.Camera3D;
import a3d.entities.ObjectContainer3D;
import a3d.entities.Scene3D;
import a3d.controllers.LookAtController;
import a3d.core.base.Geometry;
import a3d.utils.AwayStats;
import a3d.entities.Mesh;
import a3d.events.AssetEvent;
import a3d.io.library.AssetLibrary;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.PointLight;
import a3d.entities.lights.shadowmaps.NearDirectionalShadowMapper;
import a3d.io.loaders.parsers.AWDParser;
import a3d.io.loaders.parsers.OBJParser;
import a3d.materials.ColorMaterial;
import a3d.materials.TextureMaterial;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.FogMethod;
import a3d.materials.methods.NearShadowMapMethod;
import a3d.materials.methods.SoftShadowMapMethod;
import a3d.entities.primitives.PlaneGeometry;
import a3d.entities.primitives.SkyBox;
import a3d.textures.BitmapCubeTexture;
import a3d.tools.helpers.ParticleGeometryHelper;
import a3d.tools.helpers.data.ParticleGeometryTransform;
import a3d.utils.Cast;

using Reflect;

class Intermediate_PolarBearAWDAnimation extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_PolarBearAWDAnimation());
	}
	//engine variables
	private var cameraController:LookAtController;

	//animation variables
	private var skeletonAnimator:SkeletonAnimator;
	private var skeletonAnimationSet:SkeletonAnimationSet;
	private var stateTransition:CrossfadeTransition;
	private var isRunning:Bool;
	private var isMoving:Bool;
	private var movementDirection:Float;
	private var currentAnim:String;
	private var currentRotationInc:Float = 0;

	//animation constants
	private var ANIM_BREATHE:String = "Breathe";
	private var ANIM_WALK:String = "Walk";
	private var ANIM_RUN:String = "Run";
	private var ROTATION_SPEED:Float = 3;
	private var RUN_SPEED:Float = 2;
	private var WALK_SPEED:Float = 1;
	private var BREATHE_SPEED:Float = 1;

	//light objects
	private var sunLight:DirectionalLight;
	private var skyLight:PointLight;
	private var lightPicker:StaticLightPicker;
	private var softShadowMapMethod:NearShadowMapMethod;
	private var fogMethod:FogMethod;

	//material objects
	private var bearMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;

	//scene objects
	private var text:TextField;
	private var polarBearMesh:Mesh;
	private var ground:Mesh;
	private var skyBox:SkyBox;
	private var particleMesh:Mesh;

	/**
	 * Constructor
	 */
	public function new()
	{
		stateTransition = new CrossfadeTransition(0.5);
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
		camera.lens.far = 5000;
		camera.lens.near = 20;
		camera.y = 500;
		camera.z = 0;
		camera.lookAt(new Vector3D(0, 0, 1000));

		view.scene = scene;
		view.camera = camera;

		//setup controller to be used on the camera
		var placeHolder:ObjectContainer3D = new ObjectContainer3D();
		placeHolder.z = 1000;
		cameraController = new LookAtController(camera, placeHolder);
	}

	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		text = new TextField();
		text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Cursor keys / WSAD - move\n";
		text.appendText("SHIFT - hold down to run\n");

		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a light for shadows that mimics the sun's position in the skybox
		sunLight = new DirectionalLight(-1, -0.4, 1);
		sunLight.shadowMapper = new NearDirectionalShadowMapper(0.5);
		sunLight.color = 0xFFFFFF;
		sunLight.castsShadows = true;
		sunLight.ambient = 1;
		sunLight.diffuse = 1;
		sunLight.specular = 1;
		scene.addChild(sunLight);

		//create a light for ambient effect that mimics the sky
		skyLight = new PointLight();
		skyLight.y = 500;
		skyLight.color = 0xFFFFFF;
		skyLight.diffuse = 1;
		skyLight.specular = 0.5;
		skyLight.radius = 2000;
		skyLight.fallOff = 2500;
		scene.addChild(skyLight);

		lightPicker = new StaticLightPicker([sunLight, skyLight]);

		//create a global shadow method
		softShadowMapMethod = new NearShadowMapMethod(new SoftShadowMapMethod(sunLight, 10, 4));

		//create a global fog method
		fogMethod = new FogMethod(0, 3000, 0x5f5e6e);
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		AssetLibrary.enableParser(AWDParser);
		AssetLibrary.enableParser(OBJParser);

		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.load(new URLRequest("assets/PolarBear.awd"));
		AssetLibrary.load(new URLRequest("assets/snow.obj"));

		//create a snowy ground plane
		groundMaterial = new TextureMaterial(createBitmapTexture(SnowDiffuse), true, true, true);
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.specularMap = createBitmapTexture(SnowSpecular);
		groundMaterial.normalMap = createBitmapTexture(SnowNormal);
		groundMaterial.shadowMethod = softShadowMapMethod;
		groundMaterial.addMethod(fogMethod);
		groundMaterial.ambient = 0.5;
		ground = new Mesh(new PlaneGeometry(50000, 50000), groundMaterial);
		ground.geometry.scaleUV(50, 50);
		ground.castsShadows = true;
		scene.addChild(ground);

		//create a skybox
		skyBox = new SnowSkyBox();
		scene.addChild(skyBox);
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		//update character animation
		if (polarBearMesh != null)
			polarBearMesh.rotationY += currentRotationInc;

		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.SKELETON)
		{
			//create a new skeleton animation set
			skeletonAnimationSet = new SkeletonAnimationSet(3);

			//wrap our skeleton animation set in an animator object and add our sequence objects
			skeletonAnimator = new SkeletonAnimator(skeletonAnimationSet, Std.instance(event.asset,Skeleton), false);

			//apply our animator to our mesh
			polarBearMesh.animator = skeletonAnimator;

			//register our mesh as the lookAt target
			cameraController.lookAtObject = polarBearMesh;

			//add key listeners
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		else if (event.asset.assetType == AssetType.ANIMATION_NODE)
		{
			//create animation objects for each animation node encountered
			var animationNode:SkeletonClipNode = Std.instance(event.asset,SkeletonClipNode);

			skeletonAnimationSet.addAnimation(animationNode);
			if (animationNode.name == ANIM_BREATHE)
				stop();
		}
		else if (event.asset.assetType == AssetType.MESH)
		{
			if (event.asset.name == "PolarBear")
			{
				//create material object and assign it to our mesh
				bearMaterial = new TextureMaterial(createBitmapTexture(BearDiffuse));
				bearMaterial.shadowMethod = softShadowMapMethod;
				bearMaterial.normalMap = Cast.bitmapTexture(BearNormal);
				bearMaterial.specularMap = Cast.bitmapTexture(BearSpecular);
				bearMaterial.addMethod(fogMethod);
				bearMaterial.lightPicker = lightPicker;
				bearMaterial.gloss = 50;
				bearMaterial.specular = 0.5;
				bearMaterial.ambientColor = 0xAAAAAA;
				bearMaterial.ambient = 0.5;

				//create mesh object and assign our animation object and material object
				polarBearMesh = Std.instance(event.asset,Mesh);
				polarBearMesh.material = bearMaterial;
				polarBearMesh.castsShadows = true;
				polarBearMesh.scale(1.5);
				polarBearMesh.z = 1000;
				polarBearMesh.rotationY = -45;
				scene.addChild(polarBearMesh);
			}
			else
			{
				//create particle system and add it to our scene
				var geometry:Geometry = Std.instance(event.asset,Mesh).geometry;
				var geometrySet:Vector<Geometry> = new Vector<Geometry>();
				var transforms:Vector<ParticleGeometryTransform> = new Vector<ParticleGeometryTransform>();
				var scale:Float;
				var vertexTransform:Matrix3D;
				var particleTransform:ParticleGeometryTransform;
				for (i in 0...3000)
				{
					geometrySet.push(geometry);
					particleTransform = new ParticleGeometryTransform();
					scale = Math.random() + 1;
					vertexTransform = new Matrix3D();
					vertexTransform.appendScale(scale, scale, scale);
					particleTransform.vertexTransform = vertexTransform;
					transforms.push(particleTransform);
				}

				var particleGeometry:Geometry = ParticleGeometryHelper.generateGeometry(geometrySet, transforms);


				var particleAnimationSet:ParticleAnimationSet = new ParticleAnimationSet(true, true);
				particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.GLOBAL, new Vector3D(0, -100, 0)));
				particleAnimationSet.addAnimation(new ParticlePositionNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.addAnimation(new ParticleOscillatorNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.addAnimation(new ParticleRotationalVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
				particleAnimationSet.initParticleFunc = initParticleFunc;

				var material:ColorMaterial = new ColorMaterial();
				material.lightPicker = lightPicker;
				particleMesh = new Mesh(particleGeometry, material);
				particleMesh.bounds.fromSphere(new Vector3D(), 2000);
				var particleAnimator:ParticleAnimator = new ParticleAnimator(particleAnimationSet);
				particleMesh.animator = particleAnimator;
				particleAnimator.start();
				particleAnimator.resetTime(-10000);
				scene.addChild(particleMesh);
			}

		}
	}

	private function initParticleFunc(param:ParticleProperties):Void
	{
		param.startTime = Math.random() * 20 - 10;
		param.duration = 20;
		param.setField(ParticleOscillatorNode.OSCILLATOR_VECTOR3D, new Vector3D(Math.random() * 100 - 50, 0, Math.random() * 100 - 50, Math.random() * 2 + 3));
		param.setField(ParticlePositionNode.POSITION_VECTOR3D, new Vector3D(Math.random() * 10000 - 5000, 1200, Math.random() * 10000 - 5000));
		param.setField(ParticleRotationalVelocityNode.ROTATIONALVELOCITY_VECTOR3D, new Vector3D(Math.random(), Math.random(), Math.random(), Math.random() * 2 + 2));
	}

	/**
	 * Key down listener for animation
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.SHIFT:
				isRunning = true;
				if (isMoving)
					updateMovement(movementDirection);
				
			case Keyboard.UP,Keyboard.W:
				updateMovement(movementDirection = 1);
				
			case Keyboard.DOWN,Keyboard.S:
				updateMovement(movementDirection = -1);
				
			case Keyboard.LEFT,Keyboard.A:
				currentRotationInc = -ROTATION_SPEED;
				
			case Keyboard.RIGHT,Keyboard.D:
				currentRotationInc = ROTATION_SPEED;
				
		}
	}

	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.SHIFT:
				isRunning = false;
				if (isMoving)
					updateMovement(movementDirection);
			case Keyboard.UP,Keyboard.W,Keyboard.DOWN,Keyboard.S:
				stop();
			case Keyboard.LEFT,Keyboard.A,Keyboard.RIGHT,Keyboard.D:
				currentRotationInc = 0;
		}
	}

	private function updateMovement(dir:Float):Void
	{
		isMoving = true;

		//update animator speed
		skeletonAnimator.playbackSpeed = dir * (isRunning ? RUN_SPEED : WALK_SPEED);

		//update animator sequence
		var anim:String = isRunning ? ANIM_RUN : ANIM_WALK;
		if (currentAnim == anim)
			return;

		currentAnim = anim;

		skeletonAnimator.play(currentAnim, stateTransition);
	}

	private function stop():Void
	{
		isMoving = false;

		//update animator speed
		skeletonAnimator.playbackSpeed = BREATHE_SPEED;

		//update animator sequence
		if (currentAnim == ANIM_BREATHE)
			return;

		currentAnim = ANIM_BREATHE;

		skeletonAnimator.play(currentAnim, stateTransition);
	}
}


//polar bear color map
@:bitmap("embeds/snow_diffuse.png") class SnowDiffuse extends BitmapData {}

//polar bear normal map
@:bitmap("embeds/snow_normals.png") class SnowNormal extends BitmapData {}

//polar bear specular map
@:bitmap("embeds/snow_specular.png") class SnowSpecular extends BitmapData {}

//snow color map
@:bitmap("embeds/polarbear_diffuse.jpg") class BearDiffuse extends BitmapData {}

//snow normal map
@:bitmap("embeds/polarbear_normals.jpg") class BearNormal extends BitmapData {}

//snow specular map
@:bitmap("embeds/polarbear_specular.jpg") class BearSpecular extends BitmapData {}