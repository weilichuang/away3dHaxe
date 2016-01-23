package example;

import away3d.primitives.SphereGeometry;
import away3d.textures.BitmapTexture;
import flash.events.Event;
import flash.geom.Vector3D;
import flash.Lib;

import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.utils.Cast;

class Basic_View extends BasicApplication
{
	static function main()
	{
		var v:Basic_View = new Basic_View();
		Lib.current.addChild(v);
	}
	//scene objects
	private var _plane:Mesh;

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

	override private function initEngine():Void
	{
		super.initEngine();

		//setup the camera
		view.camera.z = -600;
		view.camera.y = 500;
		view.camera.lookAt(new Vector3D());
	}

	private function initObjects():Void
	{
		//setup the scene
		var material:TextureMaterial = new TextureMaterial(new BitmapTexture(new FloorDiffuse(0, 0)));
		_plane = new Mesh(new PlaneGeometry(700, 700), material);
		view.scene.addChild(_plane);
		
		var sphere:Mesh = new Mesh(new SphereGeometry(100, 40, 20), material);
		sphere.x = 0;
		sphere.y = 100;
		sphere.z = 0;

		view.scene.addChild(sphere);
	}

	/**
	 * render loop
	 */
	override private function render():Void
	{
		_plane.rotationY += 1;

		super.render();
	}
}

@:bitmap("embeds/floor_diffuse.jpg") class FloorDiffuse extends flash.display.BitmapData { }