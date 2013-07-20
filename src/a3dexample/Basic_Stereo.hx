package a3dexample;

import a3d.entities.Mesh;
import a3d.entities.primitives.CubeGeometry;
import a3d.materials.ColorMaterial;
import a3d.stereo.methods.AnaglyphStereoRenderMethod;
import a3d.stereo.StereoCamera3D;
import a3d.stereo.StereoView3D;
import flash.events.Event;
import flash.Lib;


class Basic_Stereo extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_Stereo());
	}
	
	private var _view:StereoView3D;
	private var _camera:StereoCamera3D;

	private var _cube:Mesh;

	public function new()
	{
		super();
	}
	
	/**
	 * Global initialise function
	 */
	override private function init():Void
	{
		_camera = new StereoCamera3D();
		_camera.stereoOffset = 50;

		_view = new StereoView3D();
		_view.antiAlias = 4;
		_view.camera = _camera;
		_view.stereoEnabled = true;
		_view.stereoRenderMethod = new AnaglyphStereoRenderMethod();
		//_view.stereoRenderMethod = new InterleavedStereoRenderMethod();
		addChild(_view);
		
		view = _view;

		_cube = new Mesh(new CubeGeometry(), new ColorMaterial(0xffcc00));
		_cube.scale(5);
		_view.scene.addChild(_cube);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	override private function render():Void 
	{
		_cube.rotationY += 2;
		super.render();
	}
}
