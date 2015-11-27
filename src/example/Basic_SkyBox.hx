package example;

import flash.events.Event;
import flash.geom.Vector3D;
import flash.Lib;

import away3d.entities.lenses.PerspectiveLens;
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.materials.methods.EnvMapMethod;
import away3d.entities.primitives.SkyBox;
import away3d.entities.primitives.TorusGeometry;
import away3d.textures.BitmapCubeTexture;
import away3d.utils.Cast;

class Basic_SkyBox extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_SkyBox());
	}
	
	//scene objects
	private var _skyBox:SnowSkyBox;
	private var _torus:Mesh;

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
		_skyBox = new SnowSkyBox();
		view.scene.addChild(_skyBox);

		//setup the environment map material
		var material:ColorMaterial = new ColorMaterial(0xFFFFFF, 1);
		material.specular = 0.5;
		material.ambient = 0.25;
		material.ambientColor = 0x111199;
		material.ambient = 1;
		material.addMethod(new EnvMapMethod(_skyBox.cubeTexture, 1));

		//setup the scene
		_torus = new Mesh(new TorusGeometry(150, 60, 40, 20), material);
		view.scene.addChild(_torus);


	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		view.camera.z = -600;
		view.camera.y = 0;
		view.camera.lookAt(new Vector3D());
		view.camera.lens = new PerspectiveLens(90);
	}

	/**
	 * render loop
	 */
	override private function render():Void
	{
		_torus.rotationX += 2;
		_torus.rotationY += 1;

		view.camera.position = new Vector3D();
		view.camera.rotationY += 0.5 * (stage.mouseX - stage.stageWidth / 2) / 800;
		view.camera.moveBackward(600);

		super.render();
	}
}
