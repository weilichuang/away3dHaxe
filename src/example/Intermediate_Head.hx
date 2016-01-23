/*

3D Head scan example in a3d

Demonstrates:

How to use the AssetLibrary to load an internal OBJ model.
How to set custom material methods on a model.
How a natural skin texture can be achived with sub-surface diffuse shading and fresnel specular shading.

Code by Rob Bateman & David Lenaerts
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
david.lenaerts@gmail.com
http://www.derschmale.com

Model by Lee Perry-Smith, based on a work at triplegangers.com,  licensed under CC

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
import away3d.cameras.Camera3D;
import away3d.lights.PointLight;
import away3d.entities.Mesh;
import away3d.containers.Scene3D;
import away3d.events.AssetEvent;
import away3d.library.AssetLibrary;
import away3d.library.assets.AssetType;
import away3d.loaders.parsers.Parsers;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.BasicDiffuseMethod;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.materials.methods.FresnelSpecularMethod;
import away3d.materials.methods.SubsurfaceScatteringDiffuseMethod;
import away3d.materials.TextureMaterial;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.Lib;
import flash.utils.ByteArray;


class Intermediate_Head extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_Head());
	}
	
	//engine variables
	private var cameraController:HoverController;

	//material objects
	private var headMaterial:TextureMaterial;
	private var subsurfaceMethod:SubsurfaceScatteringDiffuseMethod;
	private var fresnelMethod:FresnelSpecularMethod;
	private var diffuseMethod:BasicDiffuseMethod;
	private var specularMethod:BasicSpecularMethod;

	//scene objects
	private var light:PointLight;
	private var lightPicker:StaticLightPicker;
	private var headModel:Mesh;
	private var advancedMethod:Bool = true;

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

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 45, 10, 800);
	}

	/**
	 * Initialise the lights in a scene
	 */
	private function initLights():Void
	{
		light = new PointLight();
		light.x = 15000;
		light.z = 15000;
		light.color = 0xffddbb;
		light.ambient = 1;
		lightPicker = new StaticLightPicker([light]);

		scene.addChild(light);
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//setup custom bitmap material
		headMaterial = new TextureMaterial(createBitmapTexture(Diffuse));
		headMaterial.normalMap = createBitmapTexture(Normal);
		headMaterial.specularMap = createBitmapTexture(Specular);
		headMaterial.lightPicker = lightPicker;
		headMaterial.gloss = 10;
		headMaterial.specular = 3;
		headMaterial.ambientColor = 0x303040;
		headMaterial.ambient = 1;

		//create subscattering diffuse method
		subsurfaceMethod = new SubsurfaceScatteringDiffuseMethod(2048, 2);
		subsurfaceMethod.scatterColor = 0xff7733;
		subsurfaceMethod.scattering = 0.05;
		subsurfaceMethod.translucency = 4;
		headMaterial.diffuseMethod = subsurfaceMethod;

		//create fresnel specular method
		fresnelMethod = new FresnelSpecularMethod(true);
		headMaterial.specularMethod = fresnelMethod;

		//add default diffuse method
		diffuseMethod = new BasicDiffuseMethod();

		//add default specular method
		specularMethod = new BasicSpecularMethod();
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//default available parsers to all
		Parsers.enableAllBundled();

		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.loadData(new HeadModel());
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

		light.x = Math.sin(Lib.getTimer() / 10000) * 15000;
		light.y = 1000;
		light.z = Math.cos(Lib.getTimer() / 10000) * 15000;

		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			headModel = Std.instance(event.asset,Mesh);
			headModel.geometry.scale(100); //TODO scale cannot be performed on mesh when using sub-surface diffuse method
			headModel.y = -50;
			headModel.rotationY = 180;
			headModel.material = headMaterial;

			scene.addChild(headModel);
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
	 * Key up listener for swapping between standard diffuse & specular shading, and sub-surface diffuse shading with fresnel specular shading
	 */
	override private function onKeyUp(event:KeyboardEvent):Void
	{
		advancedMethod = !advancedMethod;

		headMaterial.gloss = (advancedMethod) ? 10 : 50;
		headMaterial.specular = (advancedMethod) ? 3 : 1;
		headMaterial.diffuseMethod = (advancedMethod) ? subsurfaceMethod : diffuseMethod;
		headMaterial.specularMethod = (advancedMethod) ? fresnelMethod : specularMethod;
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

//Infinite, 3D head model
@:file("embeds/head.obj") class HeadModel extends ByteArray {}

//Diffuse map texture
@:bitmap("embeds/head_diffuse.jpg") class Diffuse extends BitmapData {}

//Specular map texture
@:bitmap("embeds/head_specular.jpg") class Specular extends BitmapData {}

//Normal map texture
@:bitmap("embeds/head_normals.jpg") class Normal extends BitmapData {}
