package example
{
	import flash.display.BlendMode;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	import a3d.animators.ParticleAnimationSet;
	import a3d.animators.ParticleAnimator;
	import a3d.animators.data.ParticleProperties;
	import a3d.animators.data.ParticlePropertiesMode;
	import a3d.animators.nodes.ParticleBillboardNode;
	import a3d.animators.nodes.ParticleVelocityNode;
	import a3d.entities.View3D;
	import a3d.controllers.HoverController;
	import a3d.core.base.Geometry;
	import a3d.utils.AwayStats;
	import a3d.entities.Mesh;
	import a3d.materials.TextureMaterial;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.tools.helpers.ParticleGeometryHelper;
	import a3d.utils.Cast;

	class Basic_Particles extends BasicApplication
	{
		//particle image
		[Embed(source = "../embeds/blue.png")]
		private var ParticleImg:Class;

		//engine variables
		private var _cameraController:HoverController;

		//particle variables
		private var _particleAnimationSet:ParticleAnimationSet;
		private var _particleMesh:Mesh;
		private var _particleAnimator:ParticleAnimator;

		//navigation variables
		private var _move:Boolean = false;
		private var _lastPanAngle:Float;
		private var _lastTiltAngle:Float;
		private var _lastMouseX:Float;
		private var _lastMouseY:Float;

		/**
		 * Constructor
		 */
		public function Basic_Particles()
		{
			init();
		}

		/**
		 * Global initialise function
		 */
		private function init():Void
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
			//setup the particle geometry
			var plane:Geometry = new PlaneGeometry(10, 10, 1, 1, false);
			var geometrySet:Vector<Geometry> = new Vector<Geometry>();
			for (var i:int = 0; i < 20000; i++)
				geometrySet.push(plane);

			//setup the particle animation set
			_particleAnimationSet = new ParticleAnimationSet(true, true);
			_particleAnimationSet.addAnimation(new ParticleBillboardNode());
			_particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
			_particleAnimationSet.initParticleFunc = initParticleFunc;

			//setup the particle material
			var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(ParticleImg));
			material.blendMode = BlendMode.ADD;

			//setup the particle animator and mesh
			_particleAnimator = new ParticleAnimator(_particleAnimationSet);
			_particleMesh = new Mesh(ParticleGeometryHelper.generateGeometry(geometrySet), material);
			_particleMesh.animator = _particleAnimator;
			view.scene.addChild(_particleMesh);

			//start the animation
			_particleAnimator.start();
		}

		/**
		 * Initialise the engine
		 */
		override private function initEngine():Void
		{
			super.initEngine();

			_cameraController = new HoverController(view.camera, null, 45, 20, 1000);

		}

		/**
		 * Initialiser function for particle properties
		 */
		private function initParticleFunc(prop:ParticleProperties):Void
		{
			prop.startTime = Math.random() * 5 - 5;
			prop.duration = 5;
			var degree1:Float = Math.random() * Math.PI;
			var degree2:Float = Math.random() * Math.PI * 2;
			var r:Float = Math.random() * 50 + 400;
			prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
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
}
