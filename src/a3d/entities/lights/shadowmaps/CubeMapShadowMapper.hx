package a3d.entities.lights.shadowmaps;

import flash.display3D.textures.TextureBase;
import flash.geom.Vector3D;
import flash.Vector;


import a3d.entities.Camera3D;
import a3d.entities.lenses.PerspectiveLens;
import a3d.core.render.DepthRenderer;
import a3d.entities.Scene3D;
import a3d.entities.lights.PointLight;
import a3d.textures.RenderCubeTexture;
import a3d.textures.TextureProxyBase;



class CubeMapShadowMapper extends ShadowMapperBase
{
	private var _depthCameras:Vector<Camera3D>;
	private var _lenses:Vector<PerspectiveLens>;
	private var _needsRender:Vector<Bool>;

	public function new()
	{
		super();

		_depthMapSize = 512;

		_needsRender = new Vector<Bool>(6, true);
		initCameras();
	}

	private function initCameras():Void
	{
		_depthCameras = new Vector<Camera3D>();
		_lenses = new Vector<PerspectiveLens>();
		// posX, negX, posY, negY, posZ, negZ
		addCamera(0, 90, 0);
		addCamera(0, -90, 0);
		addCamera(-90, 0, 0);
		addCamera(90, 0, 0);
		addCamera(0, 0, 0);
		addCamera(0, 180, 0);
	}

	private function addCamera(rotationX:Float, rotationY:Float, rotationZ:Float):Void
	{
		var cam:Camera3D = new Camera3D();
		cam.rotationX = rotationX;
		cam.rotationY = rotationY;
		cam.rotationZ = rotationZ;
		cam.lens.near = .01;
		PerspectiveLens(cam.lens).fieldOfView = 90;
		_lenses.push(PerspectiveLens(cam.lens));
		cam.lens.aspectRatio = 1;
		_depthCameras.push(cam);
	}

	override private function createDepthTexture():TextureProxyBase
	{
		return new RenderCubeTexture(_depthMapSize);
	}

	override private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		var maxDistance:Float = PointLight(_light).fallOff;
		var pos:Vector3D = _light.scenePosition;

		// todo: faces outside frustum which are pointing away from camera need not be rendered!
		for (i in 0...6)
		{
			_lenses[i].far = maxDistance;
			_depthCameras[i].position = pos;
			_needsRender[i] = true;
		}
	}

	override private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
	{
		for (i in 0...6)
		{
			if (_needsRender[i])
			{
				_casterCollector.camera = _depthCameras[i];
				_casterCollector.clear();
				scene.traversePartitions(_casterCollector);
				renderer.render(_casterCollector, target, null, i);
				_casterCollector.cleanUp();
			}
		}
	}
}
