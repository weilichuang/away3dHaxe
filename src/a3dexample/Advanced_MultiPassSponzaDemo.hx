package a3dexample;

import a3d.controllers.FirstPersonController;
import a3d.core.base.Geometry;
import a3d.core.base.SubMesh;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.PointLight;
import a3d.entities.lights.shadowmaps.CascadeShadowMapper;
import a3d.entities.Mesh;
import a3d.entities.primitives.PlaneGeometry;
import a3d.entities.primitives.SkyBox;
import a3d.events.AssetEvent;
import a3d.events.LoaderEvent;
import a3d.io.library.assets.AssetType;
import a3d.io.loaders.Loader3D;
import a3d.io.loaders.misc.AssetLoaderContext;
import a3d.io.loaders.parsers.AWDParser;
import a3d.materials.BlendMode;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.MaterialBase;
import a3d.materials.methods.CascadeShadowMapMethod;
import a3d.materials.methods.DitheredShadowMapMethod;
import a3d.materials.methods.FilteredShadowMapMethod;
import a3d.materials.methods.FogMethod;
import a3d.materials.methods.HardShadowMapMethod;
import a3d.materials.methods.SoftShadowMapMethod;
import a3d.materials.TextureMaterial;
import a3d.materials.TextureMultiPassMaterial;
import a3d.textures.ATFCubeTexture;
import a3d.textures.ATFTexture;
import a3d.textures.SpecularBitmapTexture;
import a3d.textures.Texture2DBase;
import a3d.textures.TextureProxyBase;
import a3d.tools.commands.Merge;
import a3d.utils.Cast;
import a3d.utils.VectorUtil.VectorUtil;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Vector3D;
import flash.Lib;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.text.AntiAliasType;
import flash.text.GridFitType;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import uk.co.soulwire.gui.SimpleGUI;



class Advanced_MultiPassSponzaDemo extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Advanced_MultiPassSponzaDemo());
	}
	//root filepath for asset loading
	private var _assetsRoot:String = "assets/";

	//default material data strings
	private var _materialNameStrings:Vector<String>;

	private var _diffuseTextureStrings:Vector<String>;
	private var _normalTextureStrings:Vector<String>;
	private var _specularTextureStrings:Vector<String>;
	private var _numTexStrings:Vector<UInt>;
	private var _meshReference:Vector<Mesh>;

	//flame data objects
	private var _flameData:Vector<FlameVO>;

	//material dictionaries to hold instances
	private var _textureMap:StringMap<TextureProxyBase>;
	private var _multiMaterialMap:StringMap<MaterialBase>;
	private var _singleMaterialMap:StringMap<MaterialBase>;

	private var vaseMeshes:Vector<Mesh>;
	private var poleMeshes:Vector<Mesh>;
	private var colMeshes:Vector<Mesh>;

	//engien variables
	private var _cameraController:FirstPersonController;
	private var _text:TextField;

	//gui variables
	private var _singlePassMaterial:Bool = false;
	private var _multiPassMaterial:Bool = true;
	private var _cascadeLevels:UInt = 3;
	private var _shadowOptions:String = "PCF";
	private var _depthMapSize:UInt = 2048;
	private var _lightDirection:Float;
	private var _lightElevation:Float;
	private var _gui:SimpleGUI;

	//light variables
	private var _lightPicker:StaticLightPicker;
	private var _baseShadowMethod:FilteredShadowMapMethod;
	private var _cascadeMethod:CascadeShadowMapMethod;
	private var _fogMethod:FogMethod;
	private var _cascadeShadowMapper:CascadeShadowMapper;
	private var _directionalLight:DirectionalLight;
	private var _lights:Array<LightBase>;

	//material variables
	private var _skyMap:ATFCubeTexture;
	private var _flameMaterial:TextureMaterial;
	private var _numTextures:UInt = 0;
	private var _currentTexture:UInt = 0;
	private var _loadingTextureStrings:Vector<String>;
	private var _n:Int = 0;
	private var _loadingText:String;

	//scene variables
	private var _meshes:Vector<Mesh>;
	private var _flameGeometry:PlaneGeometry;

	//rotation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;

	//movement variables
	private var _drag:Float = 0.5;
	private var _walkIncrement:Float = 10;
	private var _strafeIncrement:Float = 10;
	private var _walkSpeed:Float = 0;
	private var _strafeSpeed:Float = 0;
	private var _walkAcceleration:Float = 0;
	private var _strafeAcceleration:Float = 0;
	
	/**
	 * Constructor
	 */
	public function new()
	{
		_materialNameStrings = Vector.ofArray(["arch", "Material__298", "bricks", "ceiling", "chain", "column_a", "column_b", "column_c", "fabric_g", "fabric_c", "fabric_f",
		"details", "fabric_d", "fabric_a", "fabric_e", "flagpole", "floor", "16___Default", "Material__25", "roof", "leaf", "vase", "vase_hanging", "Material__57", "vase_round"]);

		_diffuseTextureStrings = Vector.ofArray(["arch_diff.jpg", "background.jpg", "bricks_a_diff.jpg", "ceiling_a_diff.jpg", "chain_texture.png", "column_a_diff.jpg", "column_b_diff.jpg",
			"column_c_diff.jpg", "curtain_blue_diff.jpg", "curtain_diff.jpg", "curtain_green_diff.jpg", "details_diff.jpg", "fabric_blue_diff.jpg", "fabric_diff.jpg", "fabric_green_diff.jpg", "flagpole_diff.jpg",
			"floor_a_diff.jpg", "gi_flag.jpg", "lion.jpg", "roof_diff.jpg", "thorn_diff.png", "vase_dif.jpg", "vase_hanging.jpg", "vase_plant.png", "vase_round.jpg"]);
		_normalTextureStrings = Vector.ofArray(["arch_ddn.jpg", "background_ddn.jpg", "bricks_a_ddn.jpg", null, "chain_texture_ddn.jpg", "column_a_ddn.jpg", "column_b_ddn.jpg",
			"column_c_ddn.jpg", null, null, null, null, null, null, null, null, null, null, "lion2_ddn.jpg", null, "thorn_ddn.jpg", "vase_ddn.jpg", null, null, "vase_round_ddn.jpg"]);
		_specularTextureStrings = Vector.ofArray(["arch_spec.jpg", null, "bricks_a_spec.jpg", "ceiling_a_spec.jpg", null, "column_a_spec.jpg", "column_b_spec.jpg", "column_c_spec.jpg",
			"curtain_spec.jpg", "curtain_spec.jpg", "curtain_spec.jpg", "details_spec.jpg", "fabric_spec.jpg", "fabric_spec.jpg", "fabric_spec.jpg", "flagpole_spec.jpg", "floor_a_spec.jpg", null, null,
			null, "thorn_spec.jpg", null, null, "vase_plant_spec.jpg", "vase_round_spec.jpg"]);
		_numTexStrings = VectorUtil.toUIntVector([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
		_meshReference = new Vector<Mesh>(25);

		//flame data objects
		_flameData = Vector.ofArray([new FlameVO(new Vector3D( -625, 165, 219), 0xffaa44), 
									new FlameVO(new Vector3D(485, 165, 219), 0xffaa44), 
									new FlameVO(new Vector3D(-625,165, -148), 0xffaa44), 
									new FlameVO(new Vector3D(485, 165, -148), 0xffaa44)]);

		//material dictionaries to hold instances
		_textureMap = new StringMap<TextureProxyBase>();
		_multiMaterialMap = new StringMap<MaterialBase>();
		_singleMaterialMap = new StringMap<MaterialBase>();

		//meshDictionary:Dictionary = new Dictionary();
		vaseMeshes = new Vector<Mesh>();
		poleMeshes = new Vector<Mesh>();
		colMeshes = new Vector<Mesh>();
		
		_meshes = new Vector<Mesh>();
		
		_lights = [];
		
		lightDirection = Math.PI / 2;
		_lightElevation = Math.PI / 18;
		
		super();
	}

	/**
	 * GUI variable for setting material mode to single pass
	 */
	public var singlePassMaterial(get, set):Bool;
	public function get_singlePassMaterial():Bool
	{
		return _singlePassMaterial;
	}

	public function set_singlePassMaterial(value:Bool):Bool
	{
		_singlePassMaterial = value;
		_multiPassMaterial = !value;

		updateMaterialPass(value ? _singleMaterialMap : _multiMaterialMap);
		
		return _singlePassMaterial;
	}

	/**
	 * GUI variable for setting material mode to multi pass
	 */
	public var multiPassMaterial(get, set):Bool;
	public function get_multiPassMaterial():Bool
	{
		return _multiPassMaterial;
	}

	public function set_multiPassMaterial(value:Bool):Bool
	{
		_multiPassMaterial = value;
		_singlePassMaterial = !value;

		updateMaterialPass(value ? _multiMaterialMap : _singleMaterialMap);
		
		return _multiPassMaterial;
	}

	/**
	 * GUI variable for setting number of cascade levels.
	 */
	public var cascadeLevels(get, set):Int;
	public function get_cascadeLevels():Int
	{
		return _cascadeLevels;
	}

	public function set_cascadeLevels(value:Int):Int
	{
		_cascadeLevels = value;

		_cascadeShadowMapper.numCascades = value;
		
		return _cascadeLevels;
	}

	/**
	 * GUI variable for setting the active shadow option
	 */
	public var shadowOptions(get, set):String;
	public function get_shadowOptions():String
	{
		return _shadowOptions;
	}

	public function set_shadowOptions(value:String):String
	{
		_shadowOptions = value;

		switch (value)
		{
			case "Unfiltered":
				_cascadeMethod.baseMethod = new HardShadowMapMethod(_directionalLight);
			case "Multiple taps":
				_cascadeMethod.baseMethod = new SoftShadowMapMethod(_directionalLight);
			case "PCF":
				_cascadeMethod.baseMethod = new FilteredShadowMapMethod(_directionalLight);
			case "Dithered":
				_cascadeMethod.baseMethod = new DitheredShadowMapMethod(_directionalLight);
		}
		return _shadowOptions;
	}

	/**
	 * GUI variable for setting the depth map size of the shadow mapper.
	 */
	public var depthMapSize(get, set):Int;
	public function get_depthMapSize():Int
	{
		return _depthMapSize;
	}

	public function set_depthMapSize(value:Int):Int
	{
		_depthMapSize = value;

		_directionalLight.shadowMapper.depthMapSize = value;
		
		return _depthMapSize;
	}

	/**
	 * GUI variable for setting the direction of the directional lightsource
	 */
	public var lightDirection(get, set):Float;
	public function get_lightDirection():Float
	{
		return _lightDirection * 180 / Math.PI;
	}

	public function set_lightDirection(value:Float):Float
	{
		_lightDirection = value * Math.PI / 180;

		updateDirection();
		
		return lightDirection;
	}

	/**
	 * GUI variable for setting The elevation of the directional lightsource
	 */
	public var lightElevation(get, set):Float;
	public function get_lightElevation():Float
	{
		return 90 - _lightElevation * 180 / Math.PI;
	}

	public function set_lightElevation(value:Float):Float
	{
		_lightElevation = (90 - value) * Math.PI / 180;

		updateDirection();
		
		return lightElevation;
	}

	

	/**
	 * Global initialise function
	 */
	override private function init():Void
	{
		initEngine();
		initText();
		initLights();
		initGUI();
		initListeners();


		//count textures
		_n = 0;
		_loadingTextureStrings = _diffuseTextureStrings;
		countNumTextures();

		//kickoff asset loading
		_n = 0;
		_loadingTextureStrings = _diffuseTextureStrings;
		load(_loadingTextureStrings[_n]);
	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		view.camera.y = 150;
		view.camera.z = 0;

		//setup controller to be used on the camera
		_cameraController = new FirstPersonController(view.camera, 90, 0, -80, 80);
	}

	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		_text = new TextField();
		_text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
		_text.embedFonts = true;
		_text.antiAliasType = AntiAliasType.ADVANCED;
		_text.gridFitType = GridFitType.PIXEL;
		_text.width = 300;
		_text.height = 250;
		_text.selectable = false;
		_text.mouseEnabled = true;
		_text.wordWrap = true;
		_text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		addChild(_text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create lights array
		_lights = [];

		//create global directional light
		_cascadeShadowMapper = new CascadeShadowMapper(3);
		_cascadeShadowMapper.lightOffset = 20000;
		_directionalLight = new DirectionalLight(-1, -15, 1);
		_directionalLight.shadowMapper = _cascadeShadowMapper;
		_directionalLight.castsShadows = false;
		_directionalLight.color = 0xeedddd;
		_directionalLight.ambient = .35;
		_directionalLight.ambientColor = 0x808090;
		view.scene.addChild(_directionalLight);
		_lights.push(_directionalLight);

		updateDirection();

		//creat flame lights
		var flameVO:FlameVO;
		for (flameVO in _flameData)
		{
			var light:PointLight = flameVO.light = new PointLight();
			light.radius = 200;
			light.fallOff = 600;
			light.color = flameVO.color;
			light.y = 10;
			_lights.push(light);
		}

		//create our global light picker
		_lightPicker = new StaticLightPicker(_lights);
		_baseShadowMethod = new FilteredShadowMapMethod(_directionalLight);

		//create our global fog method
		_fogMethod = new FogMethod(0, 4000, 0x9090e7);
		_cascadeMethod = new CascadeShadowMapMethod(_baseShadowMethod);
	}

	/**
	 * Initialise the scene materials
	 */
	private function initMaterials():Void
	{
		//create skybox texture map
		_skyMap = new ATFCubeTexture(new SkyMapCubeTexture());

		//create flame material
		//_flameMaterial = new TextureMaterial(Cast.bitmapTexture(FlameTexture));
		_flameMaterial = new TextureMaterial(new ATFTexture(new FlameTexture()));
		_flameMaterial.blendMode = BlendMode.ADD;
		_flameMaterial.animateUVs = true;

	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create skybox
		view.scene.addChild(new SkyBox(_skyMap));

		//create flame meshes
		_flameGeometry = new PlaneGeometry(40, 80, 1, 1, false, true);
		var flameVO:FlameVO;
		for (flameVO in _flameData)
		{
			var mesh:Mesh = flameVO.mesh = new Mesh(_flameGeometry, _flameMaterial);
			mesh.position = flameVO.position;
			mesh.subMeshes[0].scaleU = 1 / 16;
			view.scene.addChild(mesh);
			mesh.addChild(flameVO.light);
		}
	}

	/**
	 * Initialise the GUI
	 */
	private function initGUI():Void
	{
		var shadowOptions:Array<Dynamic> = [
			{label: "Unfiltered", data: "Unfiltered"},
			{label: "PCF", data: "PCF"},
			{label: "Multiple taps", data: "Multiple taps"},
			{label: "Dithered", data: "Dithered"}
			];

		var depthMapSize:Array<Dynamic> = [
			{label: "512", data: 512},
			{label: "1024", data: 1024},
			{label: "2048", data: 2048}
			];

		_gui = new SimpleGUI(this, "");

		_gui.addColumn("Instructions");
		var instr:String = "Click and drag on the stage to rotate camera.\n";
		instr += "Keyboard arrows and WASD to move.\n";
		instr += "F to enter Fullscreen mode.\n";
		instr += "C to toggle camera mode between walk and fly.\n";
		_gui.addLabel(instr);

		_gui.addColumn("Material Settings");
		_gui.addToggle("singlePassMaterial", {label: "Single pass"});
		_gui.addToggle("multiPassMaterial", {label: "Multiple pass"});

		_gui.addColumn("Shadow Settings");
		_gui.addStepper("cascadeLevels", 1, 4, {label: "Cascade level"});
		_gui.addComboBox("shadowOptions", shadowOptions, {label: "Filter method"});
		_gui.addComboBox("depthMapSize", depthMapSize, {label: "Depth map size"});


		_gui.addColumn("Light Position");
		_gui.addSlider("lightDirection", 0, 360, {label: "Direction", tick: 0.1});
		_gui.addSlider("lightElevation", 0, 90, {label: "Elevation", tick: 0.1});
		_gui.show();
	}

	/**
	 * Updates the mateiral mode between single pass and multi pass
	 */
	private function updateMaterialPass(materialDictionary:StringMap<MaterialBase>):Void
	{
		var mesh:Mesh;
		var name:String;
		for (mesh in _meshes)
		{
			if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
				continue;
			name = mesh.material.name;
			var textureIndex:Int = _materialNameStrings.indexOf(name);
			if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
				continue;

			mesh.material = materialDictionary.get(name);
		}
	}

	/**
	 * Updates the direction of the directional lightsource
	 */
	private function updateDirection():Void
	{
		if (_directionalLight == null)
			return;
		_directionalLight.direction = new Vector3D(
			Math.sin(_lightElevation) * Math.cos(_lightDirection),
			-Math.cos(_lightElevation),
			Math.sin(_lightElevation) * Math.sin(_lightDirection)
			);
	}

	/**
	 * Count the total number of textures to be loaded
	 */
	private function countNumTextures():Void
	{
		_numTextures++;

		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] == null)
				break;

		//switch to next teture set
		if (_n < _loadingTextureStrings.length)
		{
			countNumTextures();
		}
		else if (_loadingTextureStrings == _diffuseTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			countNumTextures();
		}
		else if (_loadingTextureStrings == _normalTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			countNumTextures();
		}
	}

	/**
	 * Global binary file loader
	 */
	private function load(url:String):Void
	{
		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;

		var format:String = url.substring(url.length - 3).toLowerCase();
		switch (format)
		{
			case "awd":
				_loadingText = "Loading Model";
				loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
			case "png","jpg":
				_currentTexture++;
				_loadingText = "Loading Textures";
				loader.addEventListener(Event.COMPLETE, parseBitmap);
				url = "sponza/" + url;
			case "atf":
				_currentTexture++;
				_loadingText = "Loading Textures";
				loader.addEventListener(Event.COMPLETE, onATFComplete);
				url = "sponza/atf/" + url;
		}

		loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
		var urlReq:URLRequest = new URLRequest(_assetsRoot + url);
		loader.load(urlReq);

	}

	/**
	 * Display current load
	 */
	private function loadProgress(e:ProgressEvent):Void
	{
		var P:Int = Std.int(e.bytesLoaded / e.bytesTotal * 100);
		if (P != 100)
		{
			log(_loadingText + '\n' + ((_loadingText == "Loading Model") ? (Std.int(e.bytesLoaded / 1024) << 0) + 'kb | ' + (Std.int(e.bytesTotal / 1024) << 0) + 'kb' : _currentTexture + ' | ' + _numTextures));
		}
		else if (_loadingText == "Loading Model")
		{
			_text.visible = false;
		}
	}

	/**
	 * Parses the ATF file
	 */
	private function onATFComplete(e:Event):Void
	{
		var loader:URLLoader = Std.instance(e.target,URLLoader);
		loader.removeEventListener(Event.COMPLETE, onATFComplete);

		if (!_textureMap.exists(_loadingTextureStrings[_n]))
		{
			_textureMap.set(_loadingTextureStrings[_n],new ATFTexture(loader.data));
		}

		loader.data = null;
		loader.close();
		loader = null;


		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] != null && _loadingTextureStrings[_n] != "")
				break;

		//switch to next teture set
		if (_n < _loadingTextureStrings.length)
		{
			load(_loadingTextureStrings[_n]);
		}
		else if (_loadingTextureStrings == _diffuseTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			load(_loadingTextureStrings[_n]);
		}
		else if (_loadingTextureStrings == _normalTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			load(_loadingTextureStrings[_n]);
		}
		else
		{
			load("sponza/sponza.awd");
		}
	}


	/**
	 * Parses the Bitmap file
	 */
	private function parseBitmap(e:Event):Void
	{
		var urlLoader:URLLoader = Std.instance(e.target,URLLoader);
		var loader:Loader = new Loader();
		loader.loadBytes(urlLoader.data);
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
		urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
		urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
		loader = null;
	}

	/**
	 * Listener function for bitmap complete event on loader
	 */
	private function onBitmapComplete(e:Event):Void
	{
		var loader:Loader = Std.instance(e.target,LoaderInfo).loader;
		loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBitmapComplete);

		//create bitmap texture in dictionary
		if (!_textureMap.exists(_loadingTextureStrings[_n]))
			_textureMap.set(_loadingTextureStrings[_n], 
								(_loadingTextureStrings == _specularTextureStrings) ? 
								new SpecularBitmapTexture(Std.instance(e.target.content, Bitmap).bitmapData) : 
								Cast.bitmapTexture(e.target.content));

		loader.unload();
		loader = null;

		//skip null textures
		while (_n++ < _loadingTextureStrings.length - 1)
			if (_loadingTextureStrings[_n] != null)
				break;

		//switch to next teture set
		if (_n < _loadingTextureStrings.length)
		{
			load(_loadingTextureStrings[_n]);
		}
		else if (_loadingTextureStrings == _diffuseTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _normalTextureStrings;
			load(_loadingTextureStrings[_n]);
		}
		else if (_loadingTextureStrings == _normalTextureStrings)
		{
			_n = 0;
			_loadingTextureStrings = _specularTextureStrings;
			load(_loadingTextureStrings[_n]);
		}
		else
		{
			load("sponza/sponza.awd");
		}
	}

	/**
	 * Parses the AWD file
	 */
	private function parseAWD(e:Event):Void
	{
		log("Parsing Data");
		var loader:URLLoader = Std.instance(e.target,URLLoader);
		var loader3d:Loader3D = new Loader3D(false);
		var context:AssetLoaderContext = new AssetLoaderContext();
		//context.includeDependencies = false;
		context.dependencyBaseUrl = "assets/sponza/";
		loader3d.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
		loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete, false, 0, true);
		loader3d.loadData(loader.data, context, null, new AWDParser());

		loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
		loader.removeEventListener(Event.COMPLETE, parseAWD);
		loader = null;
	}

	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			//store meshes
			_meshes.push(Std.instance(event.asset,Mesh));
		}
	}

	/**
	 * Triggered once all resources are loaded
	 */
	private function onResourceComplete(e:LoaderEvent):Void
	{
		var merge:Merge = new Merge(false, false, true);

		_text.visible = false;

		var loader3d:Loader3D = Std.instance(e.target,Loader3D);
		loader3d.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);

		//reassign materials
		var mesh:Mesh;
		var name:String;

		for (mesh in _meshes)
		{
			if (mesh.name == "sponza_04" || mesh.name == "sponza_379")
				continue;

			var num:Float = Std.parseFloat(mesh.name.substring(7));

			name = mesh.material.name;

			if (name == "column_c" && (num < 22 || num > 33))
				continue;

			var colNum:Float = (num - 125);
			if (name == "column_b")
			{
				if (colNum >= 0 && colNum < 132 && (colNum % 11) < 10)
				{
					colMeshes.push(mesh);
					continue;
				}
				else
				{
					colMeshes.push(mesh);
					var colMerge:Merge = new Merge();
					var colMesh:Mesh = new Mesh(new Geometry());
					colMerge.applyToMeshes(colMesh, colMeshes);
					mesh = colMesh;
					colMeshes = new Vector<Mesh>();
				}
			}

			var vaseNum:Float = (num - 334);
			if (name == "vase_hanging" && (vaseNum % 9) < 5)
			{
				if (vaseNum >= 0 && vaseNum < 370 && (vaseNum % 9) < 4)
				{
					vaseMeshes.push(mesh);
					continue;
				}
				else
				{
					vaseMeshes.push(mesh);
					var vaseMerge:Merge = new Merge();
					var vaseMesh:Mesh = new Mesh(new Geometry());
					vaseMerge.applyToMeshes(vaseMesh, vaseMeshes);
					mesh = vaseMesh;
					vaseMeshes = new Vector<Mesh>();
				}
			}

			var poleNum:Float = num - 290;
			if (name == "flagpole")
			{
				if (poleNum >= 0 && poleNum < 320 && (poleNum % 3) < 2)
				{
					poleMeshes.push(mesh);
					continue;
				}
				else if (poleNum >= 0)
				{
					poleMeshes.push(mesh);
					var poleMerge:Merge = new Merge();
					var poleMesh:Mesh = new Mesh(new Geometry());
					poleMerge.applyToMeshes(poleMesh, poleMeshes);
					mesh = poleMesh;
					poleMeshes = new Vector<Mesh>();
				}
			}

			if (name == "flagpole" && (num == 260 || num == 261 || num == 263 || num == 265 || num == 268 || num == 269 || num == 271 || num == 273))
				continue;

			var textureIndex:Int = _materialNameStrings.indexOf(name);
			if (textureIndex == -1 || textureIndex >= _materialNameStrings.length)
				continue;

			_numTexStrings[textureIndex]++;

			var textureName:String = _diffuseTextureStrings[textureIndex];
			var normalTextureName:String;
			var specularTextureName:String;

			//store single pass materials for use later
			var singleMaterial:TextureMaterial = Std.instance(_singleMaterialMap.get(name),TextureMaterial);

			if (singleMaterial == null)
			{

				//create singlepass material
				singleMaterial = new TextureMaterial(Std.instance(_textureMap.get(textureName),Texture2DBase));

				singleMaterial.name = name;
				singleMaterial.lightPicker = _lightPicker;
				singleMaterial.addMethod(_fogMethod);
				singleMaterial.mipmap = true;
				singleMaterial.repeat = true;
				singleMaterial.specular = 2;

				//use alpha transparancy if texture is png
				if (textureName.substring(textureName.length - 3) == "png")
					singleMaterial.alphaThreshold = 0.5;

				//add normal map if it exists
				normalTextureName = _normalTextureStrings[textureIndex];
				if (normalTextureName != null && normalTextureName != "")
					singleMaterial.normalMap = Std.instance(_textureMap.get(normalTextureName),Texture2DBase);

				//add specular map if it exists
				specularTextureName = _specularTextureStrings[textureIndex];
				if (specularTextureName != null && specularTextureName != "")
					singleMaterial.specularMap = Std.instance(_textureMap.get(specularTextureName),Texture2DBase);

				_singleMaterialMap.set(name, singleMaterial);

			}

			//store multi pass materials for use later
			var multiMaterial:TextureMultiPassMaterial = Std.instance(_multiMaterialMap.get(name),TextureMultiPassMaterial);
			if (multiMaterial == null)
			{

				//create multipass material
				multiMaterial = new TextureMultiPassMaterial(Std.instance(_textureMap.get(textureName),Texture2DBase));
				multiMaterial.name = name;
				multiMaterial.lightPicker = _lightPicker;
				multiMaterial.shadowMethod = _cascadeMethod;
				multiMaterial.addMethod(_fogMethod);
				multiMaterial.mipmap = true;
				multiMaterial.repeat = true;
				multiMaterial.specular = 2;


				//use alpha transparancy if texture is png
				if (textureName.substring(textureName.length - 3) == "png")
					multiMaterial.alphaThreshold = 0.5;

				//add normal map if it exists
				normalTextureName = _normalTextureStrings[textureIndex];
				if (normalTextureName != null && normalTextureName != "")
					multiMaterial.normalMap = Std.instance(_textureMap.get(normalTextureName),Texture2DBase);

				//add specular map if it exists
				specularTextureName = _specularTextureStrings[textureIndex];
				if (specularTextureName != null && specularTextureName != "")
					multiMaterial.specularMap = Std.instance(_textureMap.get(specularTextureName),Texture2DBase);

				//add to material dictionary
				_multiMaterialMap.set(name, multiMaterial);
			}
			/*
			if (_meshReference[textureIndex]) {
				var m:Mesh = mesh.clone() as Mesh;
				m.material = multiMaterial;
				_view.scene.addChild(m);
				continue;
			}
			*/
			//default to multipass material
			mesh.material = multiMaterial;

			view.scene.addChild(mesh);

			_meshReference[textureIndex] = mesh;
		}

		var z:Int = 0;

		while (z < _numTexStrings.length)
		{
			trace(_diffuseTextureStrings[z], _numTexStrings[z]);
			z++;
		}

		initMaterials();
		initObjects();
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

		if (_walkSpeed != 0 || _walkAcceleration != 0)
		{
			_walkSpeed = (_walkSpeed + _walkAcceleration) * _drag;
			if (Math.abs(_walkSpeed) < 0.01)
				_walkSpeed = 0;
			_cameraController.incrementWalk(_walkSpeed);
		}

		if (_strafeSpeed != 0 || _strafeAcceleration != 0)
		{
			_strafeSpeed = (_strafeSpeed + _strafeAcceleration) * _drag;
			if (Math.abs(_strafeSpeed) < 0.01)
				_strafeSpeed = 0;
			_cameraController.incrementStrafe(_strafeSpeed);
		}

		//animate flames
		var flameVO:FlameVO;
		for (flameVO in _flameData)
		{
			//update flame light
			var light:PointLight = flameVO.light;

			if (light == null)
				continue;

			light.fallOff = 380 + Math.random() * 20;
			light.radius = 200 + Math.random() * 30;
			light.diffuse = .9 + Math.random() * .1;

			//update flame mesh
			var mesh:Mesh = flameVO.mesh;

			if (mesh == null)
				continue;

			var subMesh:SubMesh = mesh.subMeshes[0];
			subMesh.offsetU += 1 / 16;
			subMesh.offsetU %= 1;
			mesh.rotationY = Math.atan2(mesh.x - view.camera.x, mesh.z - view.camera.z) * 180 / Math.PI;
		}

		super.render();
	}


	/**
	 * Key down listener for camera control
	 */
	override private function onKeyDown(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W:
				_walkAcceleration = _walkIncrement;
			case Keyboard.DOWN,Keyboard.S:
				_walkAcceleration = -_walkIncrement;
			case Keyboard.LEFT,Keyboard.A:
				_strafeAcceleration = -_strafeIncrement;
			case Keyboard.RIGHT,Keyboard.D:
				_strafeAcceleration = _strafeIncrement;
			case Keyboard.F:
				stage.displayState = StageDisplayState.FULL_SCREEN;
			case Keyboard.C:
				_cameraController.fly = !_cameraController.fly;
		}
	}

	/**
	 * Key up listener for camera control
	 */
	override private function onKeyUp(event:KeyboardEvent):Void
	{
		switch (event.keyCode)
		{
			case Keyboard.UP,Keyboard.W,Keyboard.DOWN,Keyboard.S:
				_walkAcceleration = 0;
			case Keyboard.LEFT,Keyboard.A,Keyboard.RIGHT,Keyboard.D:
				_strafeAcceleration = 0;
		}
	}

	/**
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
	{
		_move = true;
		_lastPanAngle = _cameraController.panAngle;
		_lastTiltAngle = _cameraController.tiltAngle;
		_lastMouseX = stage.mouseX;
		_lastMouseY = stage.mouseY;
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

	/**
	 * stage listener for resize events
	 */
	override private function onResize(event:Event = null):Void
	{
		super.onResize(event);
		_text.x = (stage.stageWidth - _text.width) / 2;
		_text.y = (stage.stageHeight - _text.height) / 2;
	}

	/**
	 * log for display info
	 */
	private function log(t:String):Void
	{
		_text.htmlText = t;
		_text.visible = true;
	}
}

/**
 * Data class for the Flame objects
 */
class FlameVO
{
	public var position:Vector3D;
	public var color:UInt;
	public var mesh:Mesh;
	public var light:PointLight;

	public function new(position:Vector3D, color:UInt)
	{
		this.position = position;
		this.color = color;
	}
}


//skybox texture
@:file("embeds/skybox/hourglass_cubemap.atf") class SkyMapCubeTexture extends ByteArray {}

//fire texture

@:file("embeds/fire.atf") class FlameTexture extends ByteArray {}