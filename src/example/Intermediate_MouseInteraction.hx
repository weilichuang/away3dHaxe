package example;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

import away3d.bounds.BoundingSphere;
import away3d.bounds.BoundingVolumeBase;
import away3d.cameras.Camera3D;
import away3d.containers.Scene3D;
import away3d.containers.View3D;
import away3d.controllers.HoverController;
import away3d.core.base.Geometry;
import away3d.core.pick.PickingColliderType;
import away3d.core.pick.PickingCollisionVO;
import away3d.core.pick.PickingType;
import away3d.core.pick.RaycastPicker;
import away3d.debug.AwayStats;
import away3d.entities.Mesh;
import away3d.entities.SegmentSet;
import away3d.events.AssetEvent;
import away3d.events.MouseEvent3D;
import away3d.library.assets.AssetType;
import away3d.lights.PointLight;
import away3d.loaders.parsers.OBJParser;
import away3d.materials.ColorMaterial;
import away3d.materials.TextureMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.primitives.CubeGeometry;
import away3d.primitives.CylinderGeometry;
import away3d.primitives.LineSegment;
import away3d.primitives.SphereGeometry;
import away3d.primitives.TorusGeometry;
import away3d.textures.BitmapTexture;

class Intermediate_MouseInteraction extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_MouseInteraction());
	}
	
	//engine variables
	private var cameraController:HoverController;

	//light objects
	private var pointLight:PointLight;
	private var lightPicker:StaticLightPicker;

	//material objects
	private var painter:Sprite;
	private var blackMaterial:ColorMaterial;
	private var whiteMaterial:ColorMaterial;
	private var grayMaterial:ColorMaterial;
	private var blueMaterial:ColorMaterial;
	private var redMaterial:ColorMaterial;

	//scene objects
	private var text:TextField;
	private var pickingPositionTracer:Mesh;
	private var scenePositionTracer:Mesh;
	private var pickingNormalTracer:SegmentSet;
	private var sceneNormalTracer:SegmentSet;
	private var previoiusCollidingObject:PickingCollisionVO;
	private var raycastPicker:RaycastPicker;
	private var head:Mesh;
	private var cubeGeometry:CubeGeometry;
	private var sphereGeometry:SphereGeometry;
	private var cylinderGeometry:CylinderGeometry;
	private var torusGeometry:TorusGeometry;

	//navigation variables
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var tiltSpeed:Float = 4;
	private var panSpeed:Float = 4;
	private var distanceSpeed:Float = 4;
	private var tiltIncrement:Float = 0;
	private var panIncrement:Float = 0;
	private var distanceIncrement:Float = 0;

	private var PAINT_TEXTURE_SIZE:Int = 1024;

	/**
	 * Constructor
	 */
	public function new()
	{
		raycastPicker = new RaycastPicker(false);
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

		view.forceMouseMove = true;

		// Chose global picking method ( chose one ).
//			view.mousePicker = PickingType.SHADER; // Uses the GPU, considers gpu animations, and suffers from Stage3D's drawToBitmapData()'s bottleneck.
//			view.mousePicker = PickingType.RAYCAST_FIRST_ENCOUNTERED; // Uses the CPU, fast, but might be inaccurate with intersecting objects.
		view.mousePicker = PickingType.RAYCAST_BEST_HIT; // Uses the CPU, guarantees accuracy with a little performance cost.

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 180, 20, 320, 5);
	}

	/**
	 * Create an instructions overlay
	 */
	private function initText():Void
	{
		text = new TextField();
		text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
		text.width = 1000;
		text.height = 200;
		text.x = 25;
		text.y = 50;
		text.selectable = false;
		text.mouseEnabled = false;
		text.text = "Camera controls -----\n";
		text.text = "  Click and drag on the stage to rotate camera.\n";
		text.appendText("  Keyboard arrows and WASD also rotate camera and Z and X zoom camera.\n");
		text.appendText("Picking ----- \n");
		text.appendText("  Click on the head model to draw on its texture. \n");
		text.appendText("  Red objects have triangle picking precision. \n");
		text.appendText("  Blue objects have bounds picking precision. \n");
		text.appendText("  Gray objects are disabled for picking but occlude picking on other objects. \n");
		text.appendText("  Black objects are completely ignored for picking. \n");
		text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
		addChild(text);
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		//create a light for the camera
		pointLight = new PointLight();
		scene.addChild(pointLight);
		lightPicker = new StaticLightPicker([pointLight]);
	}

	/**
	 * Initialise the material
	 */
	private function initMaterials():Void
	{
		// uv painter
		painter = new Sprite();
		painter.graphics.beginFill(0xFF0000);
		painter.graphics.drawCircle(0, 0, 10);
		painter.graphics.endFill();

		// locator materials
		whiteMaterial = new ColorMaterial(0xFFFFFF);
		whiteMaterial.lightPicker = lightPicker;
		blackMaterial = new ColorMaterial(0x333333);
		blackMaterial.lightPicker = lightPicker;
		grayMaterial = new ColorMaterial(0xCCCCCC);
		grayMaterial.lightPicker = lightPicker;
		blueMaterial = new ColorMaterial(0x0000FF);
		blueMaterial.lightPicker = lightPicker;
		redMaterial = new ColorMaterial(0xFF0000);
		redMaterial.lightPicker = lightPicker;
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		// To trace mouse hit position.
		pickingPositionTracer = new Mesh(new SphereGeometry(2), new ColorMaterial(0x00FF00, 0.5));
		pickingPositionTracer.visible = false;
		pickingPositionTracer.mouseEnabled = false;
		pickingPositionTracer.mouseChildren = false;
		scene.addChild(pickingPositionTracer);

		scenePositionTracer = new Mesh(new SphereGeometry(2), new ColorMaterial(0x0000FF, 0.5));
		scenePositionTracer.visible = false;
		scenePositionTracer.mouseEnabled = false;
		scene.addChild(scenePositionTracer);


		// To trace picking normals.
		pickingNormalTracer = new SegmentSet();
		pickingNormalTracer.mouseEnabled = pickingNormalTracer.mouseChildren = false;
		var lineSegment1:LineSegment = new LineSegment(new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3);
		pickingNormalTracer.addSegment(lineSegment1);
		pickingNormalTracer.visible = false;
		view.scene.addChild(pickingNormalTracer);

		sceneNormalTracer = new SegmentSet();
		sceneNormalTracer.mouseEnabled = sceneNormalTracer.mouseChildren = false;
		var lineSegment2:LineSegment = new LineSegment(new Vector3D(), new Vector3D(), 0xFFFFFF, 0xFFFFFF, 3);
		sceneNormalTracer.addSegment(lineSegment2);
		sceneNormalTracer.visible = false;
		view.scene.addChild(sceneNormalTracer);
		
		var headByte:ByteArray = new HeadAsset();

		// Load a head model that we will be able to paint on on mouse down.
		var parser:OBJParser = new OBJParser(25);
		parser.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		parser.parseAsync(headByte);

		// Produce a bunch of objects to be around the scene.
		createABunchOfObjects();

		raycastPicker.setIgnoreList([sceneNormalTracer, scenePositionTracer]);
		raycastPicker.onlyMouseEnabled = false;
	}

	private function onAssetComplete(event:AssetEvent):Void
	{
		if (event.asset.assetType == AssetType.MESH)
		{
			initializeHeadModel(Std.instance(event.asset,Mesh));
		}
	}

	private function initializeHeadModel(model:Mesh):Void
	{

		head = model;

		// Apply a bitmap material that can be painted on.
		var bmd:BitmapData = new BitmapData(PAINT_TEXTURE_SIZE, PAINT_TEXTURE_SIZE, false, 0xFF0000);
		bmd.perlinNoise(50, 50, 8, 1, false, true, 7, true);
		var bitmapTexture:BitmapTexture = new BitmapTexture(bmd);
		var textureMaterial:TextureMaterial = new TextureMaterial(bitmapTexture);
		textureMaterial.lightPicker = lightPicker;
		model.material = textureMaterial;

		// Set up a ray picking collider.
		// The head model has quite a lot of triangles, so its best to use pixel bender for ray picking calculations.
		// NOTE: Pixel bender will not produce faster results on devices with only one cpu core, and will not work on iOS.
		model.pickingCollider = PickingColliderType.PB_BEST_HIT;
//			model.pickingCollider = PickingColliderType.PB_FIRST_ENCOUNTERED; // is faster, but causes weirdness around the eyes

		// Apply mouse interactivity.
		model.mouseEnabled = model.mouseChildren = model.shaderPickingDetails = true;
		enableMeshMouseListeners(model);

		view.scene.addChild(model);
	}

	private function createABunchOfObjects():Void
	{

		cubeGeometry = new CubeGeometry(25, 25, 25);
		sphereGeometry = new SphereGeometry(12);
		cylinderGeometry = new CylinderGeometry(12, 12, 25);
		torusGeometry = new TorusGeometry(12, 12);

		for (i in 0...40)
		{

			// Create object.
			var object:Mesh = createSimpleObject();

			// Random orientation.
			object.rotationX = 360 * Math.random();
			object.rotationY = 360 * Math.random();
			object.rotationZ = 360 * Math.random();

			// Random position.
			var r:Float = 200 + 100 * Math.random();
			var azimuth:Float = 2 * Math.PI * Math.random();
			var elevation:Float = 0.25 * Math.PI * Math.random();
			object.x = r * Math.cos(elevation) * Math.sin(azimuth);
			object.y = r * Math.sin(elevation);
			object.z = r * Math.cos(elevation) * Math.cos(azimuth);
		}
	}

	private function createSimpleObject():Mesh
	{

		var geometry:Geometry = null;
		var bounds:BoundingVolumeBase = null;

		// Chose a random geometry.
		var randGeometry:Float = Math.random();
		if (randGeometry > 0.75)
		{
			geometry = cubeGeometry;
		}
		else if (randGeometry > 0.5)
		{
			geometry = sphereGeometry;
			bounds = new BoundingSphere(); // better on spherical meshes with bound picking colliders
		}
		else if (randGeometry > 0.25)
		{
			geometry = cylinderGeometry;

		}
		else
		{
			geometry = torusGeometry;
		}

		var mesh:Mesh = new Mesh(geometry);

		if (bounds != null)
			mesh.bounds = bounds;

		// For shader based picking.
		mesh.shaderPickingDetails = true;

		// Randomly decide if the mesh has a triangle collider.
		var usesTriangleCollider:Bool = Math.random() > 0.5;
		if (usesTriangleCollider)
		{
			// AS3 triangle pickers for meshes with low poly counts are faster than pixel bender ones.
//				mesh.pickingCollider = PickingColliderType.BOUNDS_ONLY; // this is the default value for all meshes
			mesh.pickingCollider = PickingColliderType.AS3_FIRST_ENCOUNTERED;
//				mesh.pickingCollider = PickingColliderType.AS3_BEST_HIT; // slower and more accurate, best for meshes with folds
//				mesh.pickingCollider = PickingColliderType.AUTO_FIRST_ENCOUNTERED; // automatically decides when to use pixel bender or actionscript
		}

		// Enable mouse interactivity?
		var isMouseEnabled:Bool = Math.random() > 0.25;
		mesh.mouseEnabled = mesh.mouseChildren = isMouseEnabled;

		// Enable mouse listeners?
		var listensToMouseEvents:Bool = Math.random() > 0.25;
		if (isMouseEnabled && listensToMouseEvents)
		{
			enableMeshMouseListeners(mesh);
		}

		// Apply material according to the random setup of the object.
		choseMeshMaterial(mesh);

		// Add to scene and store.
		view.scene.addChild(mesh);

		return mesh;
	}

	private function choseMeshMaterial(mesh:Mesh):Void
	{
		if (!mesh.mouseEnabled)
		{
			mesh.material = blackMaterial;
		}
		else
		{
			if (!mesh.hasEventListener(MouseEvent3D.MOUSE_MOVE))
			{
				mesh.material = grayMaterial;
			}
			else
			{
				if (mesh.pickingCollider != PickingColliderType.BOUNDS_ONLY)
				{
					mesh.material = redMaterial;
				}
				else
				{
					mesh.material = blueMaterial;
				}
			}
		}
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		// Update camera.
		if (move)
		{
			cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
		}
		cameraController.panAngle += panIncrement;
		cameraController.tiltAngle += tiltIncrement;
		cameraController.distance += distanceIncrement;

		// Move light with camera.
		pointLight.position = camera.position;

		var collidingObject:PickingCollisionVO = raycastPicker.getSceneCollision(camera.position, view.camera.forwardVector, view.scene);
		//var mesh:Mesh;

		if (previoiusCollidingObject != null && previoiusCollidingObject != collidingObject)
		{ //equivalent to mouse out
			scenePositionTracer.visible = sceneNormalTracer.visible = false;
			scenePositionTracer.position = new Vector3D();
		}

		if (collidingObject != null)
		{
			// Show tracers.
			scenePositionTracer.visible = sceneNormalTracer.visible = true;

			// Update position tracer.
			scenePositionTracer.position = collidingObject.entity.sceneTransform.transformVector(collidingObject.localPosition);

			// Update normal tracer.
			sceneNormalTracer.position = scenePositionTracer.position;
			var normal:Vector3D = collidingObject.entity.sceneTransform.deltaTransformVector(collidingObject.localNormal);
			normal.normalize();
			normal.scaleBy(25);
			var lineSegment:LineSegment = Std.instance(sceneNormalTracer.getSegment(0),LineSegment);
			lineSegment.end = normal.clone();
		}


		previoiusCollidingObject = collidingObject;

		// Render 3D.
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
				tiltIncrement = tiltSpeed;
			case Keyboard.DOWN,Keyboard.S:
				tiltIncrement = -tiltSpeed;
			case Keyboard.LEFT,Keyboard.A:
				panIncrement = panSpeed;
			case Keyboard.RIGHT,Keyboard.D:
				panIncrement = -panSpeed;
			case Keyboard.Z:
				distanceIncrement = distanceSpeed;
			case Keyboard.X:
				distanceIncrement = -distanceSpeed;
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
				tiltIncrement = 0;
			case Keyboard.LEFT,Keyboard.A,Keyboard.RIGHT,Keyboard.D:
				panIncrement = 0;
			case Keyboard.Z,Keyboard.X:
				distanceIncrement = 0;
		}
	}

	/**
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
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
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
	{
		move = true;
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}

	// ---------------------------------------------------------------------
	// 3D mouse event handlers.
	// ---------------------------------------------------------------------

	private function enableMeshMouseListeners(mesh:Mesh):Void
	{
		mesh.addEventListener(MouseEvent3D.MOUSE_OVER, onMeshMouseOver);
		mesh.addEventListener(MouseEvent3D.MOUSE_OUT, onMeshMouseOut);
		mesh.addEventListener(MouseEvent3D.MOUSE_MOVE, onMeshMouseMove);
		mesh.addEventListener(MouseEvent3D.MOUSE_DOWN, onMeshMouseDown);
	}

	/**
	 * mesh listener for mouse down interaction
	 */
	private function onMeshMouseDown(event:MouseEvent3D):Void
	{
		var mesh:Mesh = Std.instance(event.object,Mesh);
		// Paint on the head's material.
		if (mesh == head)
		{
			var uv:Point = event.uv;
			var textureMaterial:TextureMaterial = Std.instance(Std.instance(event.object,Mesh).material,TextureMaterial);
			var bmd:BitmapData = Std.instance(textureMaterial.texture,BitmapTexture).bitmapData;
			var x:Int = Std.int(PAINT_TEXTURE_SIZE * uv.x);
			var y:Int = Std.int(PAINT_TEXTURE_SIZE * uv.y);
			var matrix:Matrix = new Matrix();
			matrix.translate(x, y);
			bmd.draw(painter, matrix);
			Std.instance(textureMaterial.texture,BitmapTexture).invalidateContent();
		}
	}

	/**
	 * mesh listener for mouse over interaction
	 */
	private function onMeshMouseOver(event:MouseEvent3D):Void
	{
		var mesh:Mesh = Std.instance(event.object,Mesh);
		mesh.showBounds = true;
		if (mesh != head)
			mesh.material = whiteMaterial;
		pickingPositionTracer.visible = pickingNormalTracer.visible = true;
		onMeshMouseMove(event);
	}

	/**
	 * mesh listener for mouse out interaction
	 */
	private function onMeshMouseOut(event:MouseEvent3D):Void
	{
		var mesh:Mesh = Std.instance(event.object,Mesh);
		mesh.showBounds = false;
		if (mesh != head)
			choseMeshMaterial(mesh);
		pickingPositionTracer.visible = pickingNormalTracer.visible = false;
		pickingPositionTracer.position = new Vector3D();
	}

	/**
	 * mesh listener for mouse move interaction
	 */
	private function onMeshMouseMove(event:MouseEvent3D):Void
	{
		// Show tracers.
		pickingPositionTracer.visible = pickingNormalTracer.visible = true;

		// Update position tracer.
		pickingPositionTracer.position = event.scenePosition;

		// Update normal tracer.
		pickingNormalTracer.position = pickingPositionTracer.position;
		var normal:Vector3D = event.sceneNormal.clone();
		normal.scaleBy(25);
		var lineSegment:LineSegment = Std.instance(pickingNormalTracer.getSegment(0),LineSegment);
		lineSegment.end = normal.clone();
	}
}

// Assets.
@:file("embeds/head.obj") class HeadAsset extends ByteArray {}
