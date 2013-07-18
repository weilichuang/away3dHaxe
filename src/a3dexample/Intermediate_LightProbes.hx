/*

 Light probe usage in a3d 4.0

 Demonstrates:

 How to use the Loader3D object to load an embedded internal obj model.
 How to use LightProbe objects in combination with StaticLightPicker to simulate indirect lighting
 How to use shadow mapping with point lights

 Code by David Lenaerts
 www.derschmale.com

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
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.Lib;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

import a3d.entities.Camera3D;
import a3d.entities.Scene3D;
import a3d.entities.View3D;
import a3d.controllers.LookAtController;
import a3d.entities.Mesh;
import a3d.events.AssetEvent;
import a3d.io.library.AssetLibrary;
import a3d.io.library.assets.AssetType;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;
import a3d.io.loaders.misc.AssetLoaderContext;
import a3d.io.loaders.parsers.OBJParser;
import a3d.materials.LightSources;
import a3d.materials.TextureMaterial;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.FresnelSpecularMethod;
import a3d.materials.methods.HardShadowMapMethod;
import a3d.materials.methods.LightMapMethod;
import a3d.materials.methods.RimLightMethod;
import a3d.textures.BitmapTexture;
import a3d.textures.SpecularBitmapTexture;

import a3dexample.cornell.CornellDiffuseEnvMapFL;
import a3dexample.cornell.CornellDiffuseEnvMapFR;
import a3dexample.cornell.CornellDiffuseEnvMapNL;
import a3dexample.cornell.CornellDiffuseEnvMapNR;

class Intermediate_LightProbes extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_LightProbes());
	}
	
	//engine variables
	private var cameraController:LookAtController;

	//light objects
	private var mainLight:PointLight;
	private var lightProbeFL:LightProbe;
	private var lightProbeFR:LightProbe;
	private var lightProbeNL:LightProbe;
	private var lightProbeNR:LightProbe;

	private var mesh:Mesh;

	// movement related
	private var xDir:Float = 0;
	private var zDir:Float = 0;
	private var speed:Float = 2;
	private var mouseDown:Bool;
	private var referenceMouseX:Float;

	private var headTexture:BitmapTexture;
	private var whiteTexture:BitmapTexture;
	private var headMaterial:TextureMaterial;

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
		camera.lens.far = 2000;
		camera.lens.near = 20;
		camera.lookAt(new Vector3D(0, 0, 1000));

		view.antiAlias = 16;
		view.scene = scene;
		view.camera = camera;

		//setup controller to be used on the camera
		cameraController = new LookAtController(camera);
	}

	private function initLights():Void
	{
		mainLight = new PointLight();
		mainLight.castsShadows = true;
		// maximum, small scene
		mainLight.shadowMapper.depthMapSize = 1024;
		mainLight.y = 120;
		mainLight.color = 0xffffff;
		mainLight.diffuse = 1;
		mainLight.specular = 1;
		mainLight.radius = 400;
		mainLight.fallOff = 500;
		mainLight.ambient = 0xa0a0c0;
		mainLight.ambient = .5;
		scene.addChild(mainLight);

		// each map was taken at position +/-75, 0,  +-/75
		lightProbeFL = new LightProbe(new CornellDiffuseEnvMapFL());
		lightProbeFL.x = -75;
		lightProbeFL.z = 75;
		scene.addChild(lightProbeFL);
		lightProbeFR = new LightProbe(new CornellDiffuseEnvMapFR());
		lightProbeFR.x = 75;
		lightProbeFR.z = 75;
		scene.addChild(lightProbeFR);
		lightProbeNL = new LightProbe(new CornellDiffuseEnvMapNL());
		lightProbeNL.x = -75;
		lightProbeNL.z = -75;
		scene.addChild(lightProbeNL);
		lightProbeNR = new LightProbe(new CornellDiffuseEnvMapNR());
		lightProbeNR.x = 75;
		lightProbeNR.z = -75;
		scene.addChild(lightProbeNR);
	}

	override private function onMouseDown(event:MouseEvent):Void
	{
		mouseDown = true;
		referenceMouseX = stage.mouseX;
	}

	override private function onMouseUp(event:MouseEvent):Void
	{
		mouseDown = false;
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		if (!mouseDown)
		{
			camera.x = camera.x * .9 + (stage.stageWidth * .5 - mouseX) * .05;
			camera.y = camera.y * .9 + (stage.stageHeight * .5 - mouseY) * .05;
			camera.z = -300;
		}

		if (mesh != null)
		{
			if (mouseDown)
			{
				mesh.rotationY += (referenceMouseX - stage.mouseX) / 5;
				referenceMouseX = stage.mouseX;
			}
			mesh.x += xDir * speed;
			mesh.z += zDir * speed;
			if (mesh.x < -75)
				mesh.x = -75;
			else if (mesh.x > 75)
				mesh.x = 75;
			if (mesh.z < -75)
				mesh.z = -75;
			else if (mesh.z > 75)
				mesh.z = 75;
		}

		cameraController.update();

		super.render();
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		AssetLibrary.enableParser(OBJParser);

		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onCornellComplete);
		AssetLibrary.loadData(CornellOBJ);
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onCornellComplete(event:AssetEvent):Void
	{
		var material:TextureMaterial;
		var mesh:Mesh;

		if (event.asset.assetType == AssetType.MESH)
		{
			mesh = Std.instance(event.asset,Mesh);
			//create material object and assign it to our mesh
			material = new TextureMaterial(new BitmapTexture(new CornellTexture(0,0)));
			material.normalMap = new BitmapTexture(new CornellNormals(0,0));
			material.lightPicker = new StaticLightPicker([mainLight]);
			material.shadowMethod = new HardShadowMapMethod(mainLight);
			material.specular = .25;
			material.gloss = 20;
			mesh.material = material;
			mesh.scale(100);
			mesh.geometry.subGeometries[0].autoDeriveVertexNormals = true;

			scene.addChild(mesh);

			AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, onCornellComplete);
			AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onHeadComplete);
			AssetLibrary.loadData(HeadOBJ, new AssetLoaderContext(false));
		}
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onHeadComplete(event:AssetEvent):Void
	{
		var specularMethod:FresnelSpecularMethod;

		if (event.asset.assetType == AssetType.MESH)
		{
			mesh = Std.instance(event.asset,Mesh);
			//create material object and assign it to our mesh
			headTexture = new BitmapTexture(new HeadAlbedo(0,0));
			whiteTexture = new BitmapTexture(new BitmapData(512, 512, false, 0xbbbbaa));
			headMaterial = new TextureMaterial(headTexture);
			headMaterial.normalMap = new BitmapTexture(new HeadNormals(0,0));
			headMaterial.specularMap = new SpecularBitmapTexture(new HeadSpecular(0,0));
			specularMethod = new FresnelSpecularMethod();
			specularMethod.normalReflectance = .2;
			headMaterial.specularMethod = specularMethod;
			headMaterial.gloss = 10;
			headMaterial.addMethod(new RimLightMethod(0xffffff, .4, 5, RimLightMethod.ADD));
			headMaterial.addMethod(new LightMapMethod(new BitmapTexture(new HeadOcclusion(0,0))));
			headMaterial.lightPicker = new StaticLightPicker([mainLight, lightProbeFL, lightProbeFR, lightProbeNL, lightProbeNR]);
			headMaterial.diffuseLightSources = LightSources.PROBES;
			headMaterial.specularLightSources = LightSources.LIGHTS;

			// turn off ambient contribution from lights, it's included in the probes' contribution
			headMaterial.ambient = 0;
			mesh.scale(20);
			mesh.material = headMaterial;
			cameraController.lookAtObject = mesh;
			scene.addChild(mesh);
		}
	}

	/**
	 * Key down listener for animation
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP:
				zDir = 1;
				
			case Keyboard.DOWN:
				zDir = -1;
				
			case Keyboard.LEFT:
				xDir = -1;
				
			case Keyboard.RIGHT:
				xDir = 1;
				
		}
	}

	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.DOWN:
				zDir = 0;
				
			case Keyboard.LEFT,Keyboard.RIGHT:
				xDir = 0;
				
			case Keyboard.SPACE:
				switchTextures();
				
		}
	}

	private function switchTextures():Void
	{
		if (headMaterial == null)
			return;

		if (headMaterial.texture == whiteTexture)
			headMaterial.texture = headTexture;
		else
			headMaterial.texture = whiteTexture;
	}
}

// cornell baked lighting map
@:file("embeds/cornell.obj") class CornellOBJ extends ByteArray {}

@:file("embeds/head.obj") class HeadOBJ extends ByteArray {}

// cornell map with baked AO and irradiance
@:bitmap("embeds/cornell_baked.jpg") class CornellTexture extends BitmapData {}

// cornell map with baked AO and irradiance
@:bitmap("embeds/cornellWallNormals.jpg") class CornellNormals extends BitmapData {}

@:bitmap("embeds/head_diffuse.jpg") class HeadAlbedo extends BitmapData {}

@:bitmap("embeds/head_normals.jpg") class HeadNormals extends BitmapData {}

@:bitmap("embeds/head_specular.jpg") class HeadSpecular extends BitmapData {}

@:bitmap("embeds/head_AO.jpg") class HeadOcclusion extends BitmapData {}
