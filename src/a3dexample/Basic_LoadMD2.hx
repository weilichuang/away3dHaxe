package a3dexample;

import a3d.animators.VertexAnimationSet;
import a3d.animators.VertexAnimator;
import a3d.controllers.HoverController;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.Mesh;
import a3d.entities.primitives.PlaneGeometry;
import a3d.events.AssetEvent;
import a3d.io.library.AssetLibrary;
import a3d.io.library.assets.AssetType;
import a3d.io.loaders.misc.AssetLoaderContext;
import a3d.io.loaders.parsers.MD2Parser;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.FilteredShadowMapMethod;
import a3d.materials.TextureMaterial;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.Lib;
import flash.utils.ByteArray;



class Basic_LoadMD2 extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_LoadMD2());
	}
	
	//pre-cached names of the states we want to use
	public static var stateNames:Array<String> = ["stand", "sniffsniff", "deathc", "attack", "crattack", "run", "paina", "cwalk", "crpain", "cstand", "deathb", "salute_alt", "painc", "painb", "flip", "jump"];

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
	private var _animationSet:VertexAnimationSet;

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
		initObjects();
		initListeners();
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//setup the lights for the scene
		_light = new DirectionalLight(0, -1, -1);
		_lightPicker = new StaticLightPicker([_light]);
		view.scene.addChild(_light);

		//setup the url map for textures in the 3ds file
		var assetLoaderContext:AssetLoaderContext = new AssetLoaderContext();
		assetLoaderContext.mapUrlToData("igdosh.jpg", new OgreDiffuse(0,0));

		//setup parser to be used on AssetLibrary
		AssetLibrary.loadData(new OgreModel(), assetLoaderContext, null, new MD2Parser());
		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);

		//setup materials
		_shadowMapMethod = new FilteredShadowMapMethod(_light);
		_floorMaterial = new TextureMaterial(createBitmapTexture(FloorDiffuse));
		_floorMaterial.lightPicker = _lightPicker;
		_floorMaterial.specular = 0;
		_floorMaterial.shadowMethod = _shadowMapMethod;
		_floor = new Mesh(new PlaneGeometry(1000, 1000), _floorMaterial);

		//setup the scene
		view.scene.addChild(_floor);
	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		//setup controller to be used on the camera
		_cameraController = new HoverController(view.camera, null, 45, 20, 1000, -90);
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

			//adjust the ogre material
			var material:TextureMaterial = Std.instance(_mesh.material,TextureMaterial);
			material.specularMap = createBitmapTexture(OgreSpecular);
			material.normalMap = createBitmapTexture(OgreNormals);
			material.lightPicker = _lightPicker;
			material.gloss = 30;
			material.specular = 1;
			material.ambientColor = 0x303040;
			material.ambient = 1;
			material.shadowMethod = _shadowMapMethod;

			//adjust the ogre mesh
			_mesh.y = 120;
			_mesh.scale(5);


			//create 16 different clones of the ogre
			var numWide:Int = 4;
			var numDeep:Int = 4;
			var k:Int = 0;
			for (i in 0...numWide)
			{
				for (j in 0...numDeep)
				{
					//clone mesh
					var clone:Mesh = Std.instance(_mesh.clone(),Mesh);
					clone.x = (i - (numWide - 1) / 2) * 1000 / numWide;
					clone.z = (j - (numDeep - 1) / 2) * 1000 / numDeep;
					clone.castsShadows = true;

					view.scene.addChild(clone);

					//create animator
					var vertexAnimator:VertexAnimator = new VertexAnimator(_animationSet);

					//play specified state
					vertexAnimator.play(stateNames[i * numDeep + j]);
					clone.animator = vertexAnimator;
					k++;
				}
			}
		}
		else if (event.asset.assetType == AssetType.ANIMATION_SET)
		{
			_animationSet = Std.instance(event.asset,VertexAnimationSet);
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
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse up listener for navigation
	 */
	override private function onMouseUp(event:MouseEvent):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		_move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
}

//plane textures
@:bitmap("embeds/floor_diffuse.jpg") class FloorDiffuse extends flash.display.BitmapData { }
//ogre diffuse texture
@:bitmap("embeds/ogre/ogre_diffuse.jpg") class OgreDiffuse extends flash.display.BitmapData { }
//ogre normal map texture
@:bitmap("embeds/ogre/ogre_normals.png") class OgreNormals extends flash.display.BitmapData { }
//ogre specular map texture
@:bitmap("embeds/ogre/ogre_specular.jpg") class OgreSpecular extends flash.display.BitmapData { }
//solider ant model
@:file("embeds/ogre/ogre.md2") class OgreModel extends ByteArray { }
