/*

 MD5 animation loading and interaction example in a3d

 Demonstrates:

 How to load MD5 mesh and anim files with bones animation from embedded resources.
 How to map animation data after loading in order to playback an animation sequence.
 How to control the movement of a game character using keys.

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

package a3dexample;

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.filters.DropShadowFilter;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

import a3d.animators.SkeletonAnimationSet;
import a3d.animators.SkeletonAnimator;
import a3d.animators.data.Skeleton;
import a3d.animators.nodes.SkeletonClipNode;
import a3d.animators.transitions.CrossfadeTransition;
import a3d.entities.Camera3D;
import a3d.entities.ObjectContainer3D;
import a3d.entities.Scene3D;
import a3d.entities.View3D;
import a3d.controllers.LookAtController;
import a3d.utils.AwayStats;
import a3d.entities.Mesh;
import a3d.entities.Sprite3D;
import a3d.events.AnimationStateEvent;
import a3d.events.AssetEvent;
import a3d.io.library.AssetLibrary;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.PointLight;
import a3d.entities.lights.shadowmaps.NearDirectionalShadowMapper;
import a3d.io.loaders.parsers.MD5AnimParser;
import a3d.io.loaders.parsers.MD5MeshParser;
import a3d.materials.TextureMaterial;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.FilteredShadowMapMethod;
import a3d.materials.methods.FogMethod;
import a3d.materials.methods.NearShadowMapMethod;
import a3d.entities.primitives.PlaneGeometry;
import a3d.entities.primitives.SkyBox;
import a3d.textures.BitmapCubeTexture;
import a3d.utils.Cast;

class Intermediate_MD5Animation extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_MD5Animation());
	}
	
	//engine variables
	private var cameraController:LookAtController;

	//animation variables
	private var animator:SkeletonAnimator;
	private var animationSet:SkeletonAnimationSet;
	private var stateTransition:CrossfadeTransition;
	private var skeleton:Skeleton;
	private var isRunning:Bool;
	private var isMoving:Bool;
	private var movementDirection:Float;
	private var onceAnim:String;
	private var currentAnim:String;
	private var currentRotationInc:Float = 0;

	//animation constants
	private static var IDLE_NAME:String = "idle2";
	private static var WALK_NAME:String = "walk7";
	private static var ANIM_NAMES:Array<String> = [IDLE_NAME, WALK_NAME, "attack3", "turret_attack", "attack2", "chest", "roar1", "leftslash", "headpain", "pain1", "pain_luparm", "range_attack2"];
	private static var ANIM_CLASSES:Array<Class<ByteArray>> = [HellKnight_Idle2, HellKnight_Walk7, HellKnight_Attack3, HellKnight_TurretAttack, HellKnight_Attack2, HellKnight_Chest, HellKnight_Roar1, HellKnight_LeftSlash,
		HellKnight_HeadPain, HellKnight_Pain1, HellKnight_PainLUPArm, HellKnight_RangeAttack2];
	
	private var ROTATION_SPEED:Float = 3;
	private var RUN_SPEED:Float = 2;
	private var WALK_SPEED:Float = 1;
	private var IDLE_SPEED:Float = 1;
	private var ACTION_SPEED:Float = 1;

	//light objects
	private var redLight:PointLight;
	private var blueLight:PointLight;
	private var whiteLight:DirectionalLight;
	private var lightPicker:StaticLightPicker;
	private var shadowMapMethod:NearShadowMapMethod;
	private var fogMethod:FogMethod;
	private var count:Float = 0;

	//material objects
	private var redLightMaterial:TextureMaterial;
	private var blueLightMaterial:TextureMaterial;
	private var groundMaterial:TextureMaterial;
	private var bodyMaterial:TextureMaterial;
	private var cubeTexture:BitmapCubeTexture;

	//scene objects
	private var text:TextField;
	private var placeHolder:ObjectContainer3D;
	private var mesh:Mesh;
	private var ground:Mesh;
	private var skyBox:SkyBox;

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

		camera.lens.far = 5000;
		camera.z = -200;
		camera.y = 160;

		//setup controller to be used on the camera
		placeHolder = new ObjectContainer3D();
		placeHolder.y = 50;
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
		text.appendText("Numbers 1-9 - Attack\n");
		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a light for shadows that mimics the sun's position in the skybox
		redLight = new PointLight();
		redLight.x = -1000;
		redLight.y = 200;
		redLight.z = -1400;
		redLight.color = 0xff1111;
		scene.addChild(redLight);

		blueLight = new PointLight();
		blueLight.x = 1000;
		blueLight.y = 200;
		blueLight.z = 1400;
		blueLight.color = 0x1111ff;
		scene.addChild(blueLight);

		whiteLight = new DirectionalLight(-50, -20, 10);
		whiteLight.color = 0xffffee;
		whiteLight.castsShadows = true;
		whiteLight.ambient = 1;
		whiteLight.ambientColor = 0x303040;
		whiteLight.shadowMapper = new NearDirectionalShadowMapper(.2);
		scene.addChild(whiteLight);

		lightPicker = new StaticLightPicker([redLight, blueLight, whiteLight]);


		//create a global shadow method
		shadowMapMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(whiteLight));
		shadowMapMethod.epsilon = .1;

		//create a global fog method
		fogMethod = new FogMethod(0, camera.lens.far * 0.5, 0x000000);
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//red light material
		redLightMaterial = new TextureMaterial(Cast.bitmapTexture(RedLight));
		redLightMaterial.alphaBlending = true;
		redLightMaterial.addMethod(fogMethod);

		//blue light material
		blueLightMaterial = new TextureMaterial(Cast.bitmapTexture(BlueLight));
		blueLightMaterial.alphaBlending = true;
		blueLightMaterial.addMethod(fogMethod);

		//ground material
		groundMaterial = new TextureMaterial(Cast.bitmapTexture(FloorDiffuse));
		groundMaterial.smooth = true;
		groundMaterial.repeat = true;
		groundMaterial.mipmap = true;
		groundMaterial.lightPicker = lightPicker;
		groundMaterial.normalMap = Cast.bitmapTexture(FloorNormals);
		groundMaterial.specularMap = Cast.bitmapTexture(FloorSpecular);
		groundMaterial.shadowMethod = shadowMapMethod;
		groundMaterial.addMethod(fogMethod);

		//body material
		bodyMaterial = new TextureMaterial(Cast.bitmapTexture(BodyDiffuse));
		bodyMaterial.gloss = 20;
		bodyMaterial.specular = 1.5;
		bodyMaterial.specularMap = Cast.bitmapTexture(BodySpecular);
		bodyMaterial.normalMap = Cast.bitmapTexture(BodyNormals);
		bodyMaterial.addMethod(fogMethod);
		bodyMaterial.lightPicker = lightPicker;
		bodyMaterial.shadowMethod = shadowMapMethod;
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create light billboards
		redLight.addChild(new Sprite3D(redLightMaterial, 200, 200));
		blueLight.addChild(new Sprite3D(blueLightMaterial, 200, 200));

		//AssetLibrary.enableParser(MD5MeshParser);
		//AssetLibrary.enableParser(MD5AnimParser);

		initMesh();

		//create a snowy ground plane
		ground = new Mesh(new PlaneGeometry(50000, 50000, 1, 1), groundMaterial);
		ground.geometry.scaleUV(200, 200);
		ground.castsShadows = false;
		scene.addChild(ground);

		//create a skybox
		skyBox = new NightSkyBox();
		scene.addChild(skyBox);
	}

	/**
	 * Initialise the hellknight mesh
	 */
	private function initMesh():Void
	{
		//parse hellknight mesh
		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.loadData(new HellKnight_Mesh(), null, null, new MD5MeshParser());
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		cameraController.update();

		//update character animation
		if (mesh != null)
			mesh.rotationY += currentRotationInc;

		count += 0.01;

		redLight.x = Math.sin(count) * 1500;
		redLight.y = 250 + Math.sin(count * 0.54) * 200;
		redLight.z = Math.cos(count * 0.7) * 1500;
		blueLight.x = -Math.sin(count * 0.8) * 1500;
		blueLight.y = 250 - Math.sin(count * .65) * 200;
		blueLight.z = -Math.cos(count * 0.9) * 1500;

		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.ANIMATION_NODE)
		{

			var node:SkeletonClipNode = Std.instance(event.asset,SkeletonClipNode);
			var name:String = event.asset.assetNamespace;
			node.name = name;
			animationSet.addAnimation(node);

			if (name == IDLE_NAME || name == WALK_NAME)
			{
				node.looping = true;
			}
			else
			{
				node.looping = false;
				node.addEventListener(AnimationStateEvent.PLAYBACK_COMPLETE, onPlaybackComplete);
			}

			if (name == IDLE_NAME)
				stop();
		}
		else if (event.asset.assetType == AssetType.ANIMATION_SET)
		{
			animationSet = Std.instance(event.asset,SkeletonAnimationSet);
			animator = new SkeletonAnimator(animationSet, skeleton);
			for (i in 0...ANIM_NAMES.length)
				AssetLibrary.loadData(Type.createInstance(ANIM_CLASSES[i],[]), null, ANIM_NAMES[i], new MD5AnimParser());

			mesh.animator = animator;
		}
		else if (event.asset.assetType == AssetType.SKELETON)
		{
			skeleton = Std.instance(event.asset,Skeleton);
		}
		else if (event.asset.assetType == AssetType.MESH)
		{
			//grab mesh object and assign our material object
			mesh = Std.instance(event.asset,Mesh);
			mesh.material = bodyMaterial;
			mesh.castsShadows = true;
			scene.addChild(mesh);

			//add our lookat object to the mesh
			mesh.addChild(placeHolder);

			//add key listeners
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
	}

	private function onPlaybackComplete(event:AnimationStateEvent):Void
	{
		if (animator.activeState != event.animationState)
			return;

		onceAnim = null;

		animator.play(currentAnim, stateTransition);
		animator.playbackSpeed = isMoving ? movementDirection * (isRunning ? RUN_SPEED : WALK_SPEED) : IDLE_SPEED;
	}

	private function playAction(val:UInt):Void
	{
		onceAnim = ANIM_NAMES[val + 2];
		animator.playbackSpeed = ACTION_SPEED;
		animator.play(onceAnim, stateTransition, 0);
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
				
			case Keyboard.UP:
			case Keyboard.W:
				updateMovement(movementDirection = 1);
				
			case Keyboard.DOWN:
			case Keyboard.S:
				updateMovement(movementDirection = -1);
				
			case Keyboard.LEFT:
			case Keyboard.A:
				currentRotationInc = -ROTATION_SPEED;
				
			case Keyboard.RIGHT:
			case Keyboard.D:
				currentRotationInc = ROTATION_SPEED;
				
			case Keyboard.NUMBER_1:
				playAction(1);
				
			case Keyboard.NUMBER_2:
				playAction(2);
				
			case Keyboard.NUMBER_3:
				playAction(3);
				
			case Keyboard.NUMBER_4:
				playAction(4);
				
			case Keyboard.NUMBER_5:
				playAction(5);
				
			case Keyboard.NUMBER_6:
				playAction(6);
				
			case Keyboard.NUMBER_7:
				playAction(7);
				
			case Keyboard.NUMBER_8:
				playAction(8);
				
			case Keyboard.NUMBER_9:
				playAction(9);
				
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
		animator.playbackSpeed = dir * (isRunning ? RUN_SPEED : WALK_SPEED);

		if (currentAnim == WALK_NAME)
			return;

		currentAnim = WALK_NAME;

		if (onceAnim != null)
			return;

		//update animator
		animator.play(currentAnim, stateTransition);
	}

	private function stop():Void
	{
		isMoving = false;

		if (currentAnim == IDLE_NAME)
			return;

		currentAnim = IDLE_NAME;

		if (onceAnim != null)
			return;

		//update animator
		animator.playbackSpeed = IDLE_SPEED;
		animator.play(currentAnim, stateTransition);
	}
}

//floor diffuse map
@:bitmap("embeds/rockbase_diffuse.jpg") class FloorDiffuse extends BitmapData {}

//floor normal map
@:bitmap("embeds/rockbase_normals.png") class FloorNormals extends BitmapData {}

//floor specular map
@:bitmap("embeds/rockbase_specular.png") class FloorSpecular extends BitmapData {}

//body diffuse map
@:bitmap("embeds/hellknight/hellknight_diffuse.jpg") class BodyDiffuse extends BitmapData { }

//body normal map
@:bitmap("embeds/hellknight/hellknight_normals.png") class BodyNormals extends BitmapData {}

//bidy specular map
@:bitmap("embeds/hellknight/hellknight_specular.png") class BodySpecular extends BitmapData {}

//billboard texture for red light
@:bitmap("embeds/redlight.png") class RedLight extends BitmapData {}

//billboard texture for blue light
@:bitmap("embeds/bluelight.png") class BlueLight extends BitmapData {}

//hellknight mesh
@:file("embeds/hellknight/hellknight.md5mesh") class HellKnight_Mesh extends ByteArray {}

//hellknight animations
@:file("embeds/hellknight/idle2.md5anim") class HellKnight_Idle2 extends ByteArray {}

@:file("embeds/hellknight/walk7.md5anim") class HellKnight_Walk7 extends ByteArray {}

@:file("embeds/hellknight/attack3.md5anim") class HellKnight_Attack3 extends ByteArray {}

@:file("embeds/hellknight/turret_attack.md5anim") class HellKnight_TurretAttack extends ByteArray {}

@:file("embeds/hellknight/attack2.md5anim") class HellKnight_Attack2 extends ByteArray {}

@:file("embeds/hellknight/chest.md5anim") class HellKnight_Chest extends ByteArray {}

@:file("embeds/hellknight/roar1.md5anim") class HellKnight_Roar1 extends ByteArray {}

@:file("embeds/hellknight/leftslash.md5anim") class HellKnight_LeftSlash extends ByteArray {}

@:file("embeds/hellknight/headpain.md5anim") class HellKnight_HeadPain extends ByteArray {}

@:file("embeds/hellknight/pain1.md5anim") class HellKnight_Pain1 extends ByteArray {}

@:file("embeds/hellknight/pain_luparm.md5anim") class HellKnight_PainLUPArm extends ByteArray {}

@:file("embeds/hellknight/range_attack2.md5anim") class HellKnight_RangeAttack2 extends ByteArray {}