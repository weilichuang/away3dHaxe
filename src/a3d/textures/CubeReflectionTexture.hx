package a3d.textures
{
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Vector3D;

	
	import a3d.entities.Camera3D;
	import a3d.entities.lenses.PerspectiveLens;
	import a3d.core.managers.Stage3DProxy;
	import a3d.core.render.DefaultRenderer;
	import a3d.core.render.RendererBase;
	import a3d.core.traverse.EntityCollector;
	import a3d.entities.Scene3D;
	import a3d.entities.View3D;

	

	/**
	 * CubeReflectionTexture provides a cube map texture for real-time reflections, used for any method that uses environment maps,
	 * such as EnvMapMethod.
	 *
	 * @see a3d.materials.methods.EnvMapMethod
	 */
	class CubeReflectionTexture extends RenderCubeTexture
	{
		private var _mockTexture:BitmapCubeTexture;
		private var _mockBitmapData:BitmapData;
		private var _renderer:RendererBase;
		private var _entityCollector:EntityCollector;
		private var _cameras:Vector<Camera3D>;
		private var _lenses:Vector<PerspectiveLens>;
		private var _nearPlaneDistance:Float = .01;
		private var _farPlaneDistance:Float = 2000;
		private var _position:Vector3D;
		private var _isRendering:Bool;

		/**
		 * Creates a new CubeReflectionTexture object
		 * @param size The size of the cube texture
		 */
		public function CubeReflectionTexture(size:Int)
		{
			super(size);
			_renderer = new DefaultRenderer();
			_entityCollector = _renderer.createEntityCollector();
			_position = new Vector3D();
			initMockTexture();
			initCameras();
		}

		/**
		 * @inheritDoc
		 */
		override public function getTextureForStage3D(stage3DProxy:Stage3DProxy):TextureBase
		{
			return _isRendering ? _mockTexture.getTextureForStage3D(stage3DProxy) : super.getTextureForStage3D(stage3DProxy);
		}

		/**
		 * The origin where the environment map will be rendered. This is usually in the centre of the reflective object.
		 */
		private inline function get_position():Vector3D
		{
			return _position;
		}

		private inline function set_position(value:Vector3D):Void
		{
			_position = value;
		}

		/**
		 * The near plane used by the camera lens.
		 */
		private inline function get_nearPlaneDistance():Float
		{
			return _nearPlaneDistance;
		}

		private inline function set_nearPlaneDistance(value:Float):Void
		{
			_nearPlaneDistance = value;
		}

		/**
		 * The far plane of the camera lens. Can be used to cut off objects that are too far to be of interest in reflections
		 */
		private inline function get_farPlaneDistance():Float
		{
			return _farPlaneDistance;
		}

		private inline function set_farPlaneDistance(value:Float):Void
		{
			_farPlaneDistance = value;
		}

		/**
		 * Renders the scene in the given view for reflections.
		 * @param view The view containing the scene to render.
		 */
		public function render(view:View3D):Void
		{
			var stage3DProxy:Stage3DProxy = view.stage3DProxy;
			var scene:Scene3D = view.scene;
			var targetTexture:TextureBase = super.getTextureForStage3D(stage3DProxy);

			_isRendering = true;
			_renderer.stage3DProxy = stage3DProxy;

			for (var i:UInt = 0; i < 6; ++i)
				renderSurface(i, scene, targetTexture);

			_isRendering = false;
		}

		/**
		 * The renderer to use.
		 */
		private inline function get_renderer():RendererBase
		{
			return _renderer;
		}

		private inline function set_renderer(value:RendererBase):Void
		{
			_renderer.dispose();
			_renderer = value;
			_entityCollector = _renderer.createEntityCollector();
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose():Void
		{
			super.dispose();
			_mockTexture.dispose();
			for (var i:Int = 0; i < 6; ++i)
				_cameras[i].dispose();

			_mockBitmapData.dispose();
		}

		private function renderSurface(surfaceIndex:UInt, scene:Scene3D, targetTexture:TextureBase):Void
		{
			var camera:Camera3D = _cameras[surfaceIndex];

			camera.lens.near = _nearPlaneDistance;
			camera.lens.far = _farPlaneDistance;
			camera.position = position;

			_entityCollector.camera = camera;
			_entityCollector.clear();
			scene.traversePartitions(_entityCollector);

			_renderer.render(_entityCollector, targetTexture, null, surfaceIndex);

			_entityCollector.cleanUp();
		}



		private function initMockTexture():Void
		{
			// use a completely transparent map to prevent anything from using this texture when updating map
			_mockBitmapData = new BitmapData(2, 2, true, 0x00000000);
			_mockTexture = new BitmapCubeTexture(_mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData, _mockBitmapData);
		}

		private function initCameras():Void
		{
			_cameras = new Vector<Camera3D>();
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
			_cameras.push(cam);
		}
	}
}
