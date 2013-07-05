/*

Sprite sheet animation example in Away3d

Demonstrates:

How to use the SpriteSheetAnimator.
- using SpriteSheetMaterial
- using the SpriteSheetHelper for generation of the sprite sheets sources stored in an external swf source.
- multiple animators

How to tween the camera in an endless movement

How to assign an enviroMethod

Code by Fabrice Closier
fabrice3d@gmail.com
http://www.closier.nl

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

import feffects.Tween;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.Lib;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.Vector;

import a3d.animators.SpriteSheetAnimationSet;
import a3d.animators.SpriteSheetAnimator;
import a3d.animators.nodes.SpriteSheetClipNode;
import a3d.entities.ObjectContainer3D;
import a3d.entities.View3D;
import a3d.entities.Mesh;
import a3d.events.AssetEvent;
import a3d.events.LoaderEvent;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.PointLight;
import a3d.io.loaders.Loader3D;
import a3d.io.loaders.parsers.AWD2Parser;
import a3d.materials.SinglePassMaterialBase;
import a3d.materials.SpriteSheetMaterial;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.EnvMapMethod;
import a3d.materials.methods.FogMethod;
import a3d.textures.BitmapCubeTexture;
import a3d.textures.Texture2DBase;
import a3d.tools.helpers.SpriteSheetHelper;

using Reflect;
using feffects.Tween.TweenObject;

// The tweener swc is provided in the 'libs' package
class Intermediate_SpriteSheetAnimation extends BasicApplication
{
	public static function main()
	{
		Lib.current.addChild(new Intermediate_SpriteSheetAnimation());
	}
	
	//engine variables
	private var _loader:Loader3D;
	private var _origin:Vector3D;
	private var _staticLightPicker:StaticLightPicker;

	//demo variables
	private var _hoursDigits:SpriteSheetMaterial;
	private var _minutesDigits:SpriteSheetMaterial;
	private var _secondsDigits:SpriteSheetMaterial;
	private var _delimiterMaterial:SpriteSheetMaterial;
	private var _pulseMaterial:SpriteSheetMaterial;

	private var _hoursAnimator:SpriteSheetAnimator;
	private var _minutesAnimator:SpriteSheetAnimator;
	private var _secondsAnimator:SpriteSheetAnimator;
	private var _pulseAnimator:SpriteSheetAnimator;
	private var _delimiterAnimator:SpriteSheetAnimator;

	//value set higher to force an update
	private var _lastHour:Int = 24;
	private var _lastSecond:Int = 60;
	private var _lastMinute:Int = 60;

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
		initObjects();
	}
	
	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		view.antiAlias = 2;
		view.backgroundColor = 0x10c14;

		//setup the camera
		view.camera.lens.near = 1000;
		view.camera.lens.far = 100000;
		view.camera.x = -17850;
		view.camera.y = 12390;
		view.camera.z = -9322;

		//saving the origin, as we look at it on enterframe
		_origin = new Vector3D();
	}

	/**
	 * Lights setup
	 */
	private function initLights():Void
	{
		//Note that in 4.0, you could define the radius and falloff as Number.maxValue.
		//this is no longer the case in 4.1. As the default values are high enough, we do not need to declare them for light 1
		var plight1:PointLight = new PointLight();
		plight1.x = 5691;
		plight1.y = 10893;
		plight1.diffuse = 0.3;
		plight1.z = -11242;
		plight1.ambient = 0.3;
		plight1.ambientColor = 0x18235B;
		plight1.color = 0x2E71FF;
		plight1.specular = 0.4;
		view.scene.addChild(plight1);

		var plight2:PointLight = new PointLight();
		plight2.x = -20250;
		plight2.y = 4545;
		plight2.diffuse = 0.1;
		plight2.z = 500;
		plight2.ambient = 0.09;
		plight2.ambientColor = 0xC2CDFF;
		plight2.radius = 1000;
		plight2.color = 0xFFA825;
		plight2.fallOff = 6759;
		plight2.specular = 0.1;
		view.scene.addChild(plight2);

		var plight3:PointLight = new PointLight();
		plight3.x = -7031;
		plight3.y = 2583;
		plight3.diffuse = 1.3;
		plight3.z = -8319;
		plight3.ambient = 0.01;
		plight3.ambientColor = 0xFFFFFF;
		plight3.radius = 1000;
		plight3.color = 0xFF0500;
		plight3.fallOff = 6759;
		plight3.specular = 0;
		view.scene.addChild(plight3);

		_staticLightPicker = new StaticLightPicker([plight1, plight2, plight3]);
	}

	/**
	 * In this example the sprite sheets are genererated runtime, the data is stored into different movieclips in an swf file.
	 */
	private function initObjects():Void
	{
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, setUpAnimators);
		loader.loadBytes(new SourceSWF());
	}

	/**
	 * Defining the spriteSheetAnimators and their data
	 */
	private function setUpAnimators(e:Event):Void
	{
		var loader:Loader = Std.instance(e.currentTarget.loader,Loader);
		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, setUpAnimators);

		var sourceSwf:MovieClip = Std.instance(e.currentTarget.content,MovieClip);

		//in example swf, the source swf has a movieclip on stage named: "digits", it will be used for seconds, minutes and hours.
		var animID:String = "digits";
		var sourceMC:MovieClip = sourceSwf.field(animID);
		//the animation holds 60 frames, as we spread over 2 maps, we'll have 2 maps of 30 frames
		var cols:UInt = 6;
		var rows:UInt = 5;

		var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
		//the spriteSheetHelper has a build method, that will return us one or more maps from our movieclips.
		var diffuseSpriteSheets:Vector<Texture2DBase> = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 512, 512, false);

		//We do not have yet geometry to apply on, but we can declare the materials.
		//As they need to be async from each other, we cannot share them in this clock case
		_hoursDigits = new SpriteSheetMaterial(diffuseSpriteSheets);
		_minutesDigits = new SpriteSheetMaterial(diffuseSpriteSheets);
		_secondsDigits = new SpriteSheetMaterial(diffuseSpriteSheets);

		//we declare 3 different animators, as we will need to drive the time animations independantly. Reusing the same set.
		var digitsSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
		var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 2, 0, 60);
		digitsSet.addAnimation(spriteSheetClipNode);

		_hoursAnimator = new SpriteSheetAnimator(digitsSet);
		_minutesAnimator = new SpriteSheetAnimator(digitsSet);
		_secondsAnimator = new SpriteSheetAnimator(digitsSet);

		// the button on top of model gets a nice glowing and pulsing animation
		animID = "pulse";
		//the animation movieclip has 12 frames, we define the row and cols
		cols = 4;
		rows = 3;
		sourceMC = sourceSwf.field(animID);
		diffuseSpriteSheets = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 256, 256, false);
		var pulseAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
		spriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 1, 0, 12);
		pulseAnimationSet.addAnimation(spriteSheetClipNode);
		_pulseAnimator = new SpriteSheetAnimator(pulseAnimationSet);
		_pulseAnimator.fps = 12;
		// to make it interresting, it will loop back and fourth. So a full iteration will take 2 seconds
		_pulseAnimator.backAndForth = true;
		_pulseMaterial = new SpriteSheetMaterial(diffuseSpriteSheets);

		// the delimiter,
		animID = "delimiter";
		//the animation has 5 frames, it can fit on one row
		cols = 5;
		rows = 2;
		sourceMC = sourceSwf.field(animID);
		diffuseSpriteSheets = spriteSheetHelper.generateFromMovieClip(sourceMC, cols, rows, 256, 256, false);
		var delimiterAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
		spriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, cols, rows, 1, 0, sourceMC.totalFrames);
		delimiterAnimationSet.addAnimation(spriteSheetClipNode);
		_delimiterAnimator = new SpriteSheetAnimator(delimiterAnimationSet);
		_delimiterAnimator.fps = 6;
		_delimiterMaterial = new SpriteSheetMaterial(diffuseSpriteSheets);

		//the required data is ready, time to load our model. We are now sure, all will be there when needed.
		loadModel();
	}

	/**
		 * we can start load the model
		 */
	private function loadModel():Void
	{
		//adding the awd 2.0 source file to the scene
		_loader = new Loader3D();
		Loader3D.enableParser(AWD2Parser);

		_loader.addEventListener(AssetEvent.MESH_COMPLETE, onMeshReady);
		_loader.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onLoadedComplete);
		_loader.addEventListener(LoaderEvent.LOAD_ERROR, onLoadedError);
		//the url must be relative to swf once published, change the url for your setup accordingly.
		_loader.load(new URLRequest("assets/tictac/tictac.awd"), null, null, new AWD2Parser());
	}

	private function onLoadedError(event:LoaderEvent):Void
	{
		trace("0_o " + event.message);
	}

	/**
	 * assigning the animators
	 */
	private function onMeshReady(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			var mesh:Mesh = Std.instance(event.asset,Mesh);

			switch (mesh.name)
			{

				case "hours":
					mesh.material = _hoursDigits;
					mesh.animator = _hoursAnimator;
					_hoursAnimator.play("digits");

				case "minutes":
					mesh.material = _minutesDigits;
					mesh.animator = _minutesAnimator;
					_minutesAnimator.play("digits");

				case "seconds":
					mesh.material = _secondsDigits;
					mesh.animator = _secondsAnimator;
					_secondsAnimator.play("digits");

				case "delimiter":
					mesh.material = _delimiterMaterial;
					mesh.animator = _delimiterAnimator;
					_delimiterAnimator.play("delimiter");
					
				case "button":
					mesh.material = _pulseMaterial;
					mesh.animator = _pulseAnimator;
					_pulseAnimator.play("pulse");

				case "furniture":
					mesh.material.lightPicker = _staticLightPicker;

				case "frontscreen":
					//ignoring lightpicker on this mesh

				case "chromebody":
					var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(new Back_CB0_Bitmap(0,0),
						new Back_CB1_Bitmap(0,0),
						new Back_CB2_Bitmap(0,0),
						new Back_CB3_Bitmap(0,0),
						new Back_CB4_Bitmap(0,0),
						new Back_CB5_Bitmap(0,0));

					var envMapMethod:EnvMapMethod = new EnvMapMethod(cubeTexture, 0.1);
					Std.instance(mesh.material,SinglePassMaterialBase).addMethod(envMapMethod);

				default:
					if (mesh.material.lightPicker == null)
						mesh.material.lightPicker = _staticLightPicker;

			}

			var fogMethod:FogMethod = new FogMethod(20000, 50000, 0x10C14);
			Std.instance(mesh.material,SinglePassMaterialBase).addMethod(fogMethod);
		}
	}

	private function clearListeners():Void
	{
		_loader.removeEventListener(AssetEvent.MESH_COMPLETE, onMeshReady);
		_loader.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onLoadedComplete);
		_loader.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadedError);
	}

	/**
	 * the model is loaded. Time to display our work
	 */

	private function onLoadedComplete(event:LoaderEvent):Void
	{
		clearListeners();

		view.scene.addChild(Std.instance(event.currentTarget,ObjectContainer3D));

		initListeners();
		
		startTween();
	}


	/**
	 * updating the digit according to current time
	 */
	private function updateClock():Void
	{
		var date:Date = Date.now();

		if (_lastHour != date.getHours() + 1)
		{
			_lastHour = date.getHours() + 1;
			_hoursAnimator.gotoAndStop(_lastHour);
		}

		if (_lastMinute != date.getMinutes() + 1)
		{
			_lastMinute = date.getMinutes() + 1;
			_minutesAnimator.gotoAndStop(_lastMinute);
		}

		if (_lastSecond != date.getSeconds() + 1)
		{
			_lastSecond = date.getSeconds() + 1;
			_secondsAnimator.gotoAndStop(_lastSecond);
			_delimiterAnimator.gotoAndPlay(1);
		}
	}

	/**
	 * endless tween to add some dramatic!
	 */
	private function startTween():Void
	{
		var destX:Float = -(Math.random() * 24000) + 4000;
		var destY:Float = Math.random() * 16000;
		var destZ:Float = 3000 + Math.random() * 18000;
		
		view.camera.tween( { x:destX, y:destY, z: -destZ }, Std.int(4 + (Math.random() * 2)) * 1000, null, true, startTween).start();

		//Tweener.addTween(view.camera, {x: destX, y: destY, z: -destZ,
				//time: 4 + (Math.random() * 2),
				//transition: "easeInOutQuad",
				//onComplete: startTween});
	}

	/**
	 * render loop
	 */
	override private function render():Void
	{
		updateClock();
		view.camera.lookAt(_origin);
		super.render();
	}
}


//the swf file holding timeline animations
@:file("embeds/spritesheets/digits.swf")
class SourceSWF extends ByteArray { }

@:bitmap("embeds/spritesheets/textures/back_CB0.jpg")
class Back_CB0_Bitmap extends BitmapData { }

@:bitmap("embeds/spritesheets/textures/back_CB1.jpg")
class Back_CB1_Bitmap extends BitmapData { }

@:bitmap("embeds/spritesheets/textures/back_CB2.jpg")
class Back_CB2_Bitmap extends BitmapData { }

@:bitmap("embeds/spritesheets/textures/back_CB3.jpg")
class Back_CB3_Bitmap extends BitmapData { }

@:bitmap("embeds/spritesheets/textures/back_CB4.jpg")
class Back_CB4_Bitmap extends BitmapData { }

@:bitmap("embeds/spritesheets/textures/back_CB5.jpg")
class Back_CB5_Bitmap extends BitmapData { }