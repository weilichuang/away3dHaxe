package example;

import away3d.animators.VertexAnimationSet;
import away3d.animators.VertexAnimator;
import away3d.controllers.HoverController;
import away3d.entities.lights.DirectionalLight;
import away3d.entities.Mesh;
import away3d.entities.primitives.PlaneGeometry;
import away3d.events.AssetEvent;
import away3d.events.LoaderEvent;
import away3d.io.library.AssetLibrary;
import away3d.io.library.assets.AssetType;
import away3d.io.loaders.parsers.MD2Parser;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.materials.methods.FilteredShadowMapMethod;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import away3d.utils.Cast;
import example.utils.BitmapFilterEffects;
import flash.display.BitmapData;
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
import flash.Vector;



class Intermediate_PerelithKnightMD2 extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_PerelithKnightMD2());
	}
	
	//array of textures for random sampling
	private var _pKnightTextures:Vector<BitmapData>;
	private var _pKnightMaterials:Vector<TextureMaterial>;

	//engine variables
	private var _cameraController:HoverController;

	//light objects
	private var _light:DirectionalLight;
	private var _lightPicker:StaticLightPicker;

	//material objects
	private var _floorMaterial:TextureMaterial;
	private var _shadowMapMethod:FilteredShadowMapMethod;

	//scene objects
	private var _floor:Mesh;
	private var _mesh:Mesh;

	//navigation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;
	private var _keyUp:Bool;
	private var _keyDown:Bool;
	private var _keyLeft:Bool;
	private var _keyRight:Bool;
	private var _lookAtPosition:Vector3D;
	private var _animationSet:VertexAnimationSet;

	/**
	 * Constructor
	 */
	public function new()
	{
		_lookAtPosition = new Vector3D();
		_pKnightTextures = Vector.ofArray([new PKnightTexture1(0, 0), 
											new PKnightTexture2(0, 0), 
											new PKnightTexture3(0, 0), 
											new PKnightTexture4(0,0)]);
		_pKnightMaterials = new Vector<TextureMaterial>();
		
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

	override private function initEngine():Void
	{
		super.initEngine();

		//setup the camera for optimal rendering
		view.camera.lens.far = 5000;

		//setup controller to be used on the camera
		_cameraController = new HoverController(view.camera, null, 45, 20, 2000, 5);
	}

	override private function initListeners():Void
	{
		super.initListeners();
		stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
	}

	private function initObjects():Void
	{
		//setup the help text
		var text:TextField = new TextField();
		text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.ADVANCED;
		text.gridFitType = GridFitType.PIXEL;
		text.width = 240;
		text.height = 100;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Click and drag - rotate\n" +
			"Cursor keys / WSAD / ZSQD - move\n" +
			"Scroll wheel - zoom";

		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];

		addChild(text);

		//setup the floor
		_floor = new Mesh(new PlaneGeometry(10000, 10000), _floorMaterial);
		_floor.geometry.scaleUV(5, 5);

		//setup the scene
		view.scene.addChild(_floor);

		//setup parser to be used on AssetLibrary
		AssetLibrary.loadData(new PKnightModel(), null, null, new MD2Parser());
		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
	}

	private function initMaterials():Void
	{
		//create a global shadow map method
		_shadowMapMethod = new FilteredShadowMapMethod(_light);

		//setup floor material
		_floorMaterial = new TextureMaterial(createBitmapTexture(FloorDiffuse));
		_floorMaterial.lightPicker = _lightPicker;
		_floorMaterial.specular = 0;
		_floorMaterial.ambient = 1;
		_floorMaterial.shadowMethod = _shadowMapMethod;
		_floorMaterial.repeat = true;

		//setup Perelith Knight materials
		for (i in 0..._pKnightTextures.length)
		{
			var bitmapData:BitmapData = _pKnightTextures[i];
			var knightMaterial:TextureMaterial = new TextureMaterial(new BitmapTexture(bitmapData));
			knightMaterial.normalMap = new BitmapTexture(BitmapFilterEffects.normalMap(bitmapData));
			knightMaterial.specularMap = new BitmapTexture(BitmapFilterEffects.outline(bitmapData));
			knightMaterial.lightPicker = _lightPicker;
			knightMaterial.gloss = 30;
			knightMaterial.specular = 1;
			knightMaterial.ambient = 1;
			knightMaterial.shadowMethod = _shadowMapMethod;
			_pKnightMaterials.push(knightMaterial);
		}
	}

	private function initLights():Void
	{
		//setup the lights for the scene
		_light = new DirectionalLight(-0.5, -1, -1);
		_light.ambient = 0.4;
		_lightPicker = new StaticLightPicker([_light]);
		view.scene.addChild(_light);
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		if (_move)
		{
			_cameraController.panAngle = 0.3 * (stage.mouseX - _lastMouseX) + _lastPanAngle;
			_cameraController.tiltAngle = 0.3 * (stage.mouseY - _lastMouseY) + _lastTiltAngle;
		}

		if (_keyUp)
			_lookAtPosition.x -= 10;
		if (_keyDown)
			_lookAtPosition.x += 10;
		if (_keyLeft)
			_lookAtPosition.z -= 10;
		if (_keyRight)
			_lookAtPosition.z += 10;

		//_cameraController.lookAtPosition = _lookAtPosition;

		super.render();
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			_mesh = Std.instance(event.asset,Mesh);

			//adjust the ogre mesh
			_mesh.y = 120;
			_mesh.scale(5);

		}
		else if (event.asset.assetType == AssetType.ANIMATION_SET)
		{
			_animationSet = Std.instance(event.asset,VertexAnimationSet);
		}
	}

	/**
	 * Listener function for resource complete event on loader
	 */
	private function onResourceComplete(event:LoaderEvent):Void
	{
		//create 20 x 20 different clones of the ogre
		var numWide:Int = 50;
		var numDeep:Int = 50;
		var k:Int = 0;
		for (i in 0...numWide)
		{
			for (j in 0...numDeep)
			{
				//clone mesh
				var clone:Mesh = Std.instance(_mesh.clone(),Mesh);
				clone.x = (i - (numWide - 1) / 2) * 10000 / numWide;
				clone.z = (j - (numDeep - 1) / 2) * 10000 / numDeep;
				clone.castsShadows = true;
				clone.material = _pKnightMaterials[Std.int(Math.random() * _pKnightMaterials.length)];
				view.scene.addChild(clone);

				//create animator
				var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);

				//play specified state
				vertexAnimator.play(_animationSet.animationNames[Std.int(Math.random() * _animationSet.animationNames.length)], null, Math.random() * 1000);
				clone.animator = vertexAnimator;
				k++;
			}
		}
	}

	/**
	 * Key down listener for animation
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W,Keyboard.Z: //fr
				_keyUp = true;
			case Keyboard.DOWN,Keyboard.S:
				_keyDown = true;
			case Keyboard.LEFT,Keyboard.A,Keyboard.Q: //fr
				_keyLeft = true;
			case Keyboard.RIGHT,Keyboard.D:
				_keyRight = true;
		}
	}

	/**
	 * Key up listener
	 */
	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W,Keyboard.Z: //fr
				_keyUp = false;
			case Keyboard.DOWN, Keyboard.S:
				_keyDown = false;
			case Keyboard.LEFT,Keyboard.A,Keyboard.Q: //fr
				_keyLeft = false;
			case Keyboard.RIGHT,Keyboard.D:
				_keyRight = false;
		}
	}

	/**
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
	{
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
		_move = true;
	}

	/**
	 * Mouse up listener for navigation
	 */
	override private function onMouseUp(event:MouseEvent):Void
	{
		_move = false;
	}

	/**
	 * Mouse wheel listener for navigation
	 */
	private function onMouseWheel(ev:MouseEvent):Void
	{
		_cameraController.distance -= ev.delta * 5;

		if (_cameraController.distance < 100)
			_cameraController.distance = 100;
		else if (_cameraController.distance > 2000)
			_cameraController.distance = 2000;
	}
}

//plane textures
@:bitmap("embeds/floor_diffuse.jpg") class FloorDiffuse extends flash.display.BitmapData { }

//Perelith Knight diffuse texture 1
@:bitmap("embeds/pknight/pknight1.png") class PKnightTexture1 extends flash.display.BitmapData { }

//Perelith Knight diffuse texture 2
@:bitmap("embeds/pknight/pknight2.png") class PKnightTexture2 extends flash.display.BitmapData { }

//Perelith Knight diffuse texture 3
@:bitmap("embeds/pknight/pknight3.png") class PKnightTexture3 extends flash.display.BitmapData { }

//Perelith Knight diffuse texture 4
@:bitmap("embeds/pknight/pknight4.png") class PKnightTexture4 extends flash.display.BitmapData { }

//Perelith Knight model
@:file("embeds/pknight/pknight.md2") class PKnightModel extends flash.utils.ByteArray { }
