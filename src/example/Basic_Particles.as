/*

Basic GPU-based particle animation example in Away3d

Demonstrates:

How to use the ParticleAnimationSet to define static particle behaviour.
How to create particle geometry using the ParticleGeometryHelper class.
How to apply a particle animation to a particle geometry set using ParticleAnimator.
How to create a random spray of particles eminating from a central point.

Code by Rob Bateman & Liao Cheng
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk
liaocheng210@126.com


This code is distributed under the MIT License

Copyright (c) The Away Foundation http://www.theawayfoundation.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package example
{
	import flash.display.BlendMode;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;

	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.ParticleAnimator;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.nodes.ParticleBillboardNode;
	import away3d.animators.nodes.ParticleVelocityNode;
	import away3d.entities.View3D;
	import away3d.controllers.HoverController;
	import away3d.core.base.Geometry;
	import away3d.utils.AwayStats;
	import away3d.entities.Mesh;
	import away3d.materials.TextureMaterial;
	import away3d.entities.primitives.PlaneGeometry;
	import away3d.tools.helpers.ParticleGeometryHelper;
	import away3d.utils.Cast;

	public class Basic_Particles extends BasicApplication
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
		private var _lastPanAngle:Number;
		private var _lastTiltAngle:Number;
		private var _lastMouseX:Number;
		private var _lastMouseY:Number;

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
		private function init():void
		{
			initEngine();
			initObjects();
			initListeners();
		}

		/**
		 * Initialise the scene objects
		 */
		private function initObjects():void
		{
			//setup the particle geometry
			var plane:Geometry = new PlaneGeometry(10, 10, 1, 1, false);
			var geometrySet:Vector.<Geometry> = new Vector.<Geometry>();
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
		override protected function initEngine():void
		{
			super.initEngine();

			_cameraController = new HoverController(view.camera, null, 45, 20, 1000);

		}

		/**
		 * Initialiser function for particle properties
		 */
		private function initParticleFunc(prop:ParticleProperties):void
		{
			prop.startTime = Math.random() * 5 - 5;
			prop.duration = 5;
			var degree1:Number = Math.random() * Math.PI;
			var degree2:Number = Math.random() * Math.PI * 2;
			var r:Number = Math.random() * 50 + 400;
			prop[ParticleVelocityNode.VELOCITY_VECTOR3D] = new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), r * Math.cos(degree1) * Math.cos(degree2), r * Math.sin(degree2));
		}

		/**
		 * Navigation and render loop
		 */
		override protected function render():void
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
		override protected function onMouseDown(event:MouseEvent):void
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
		override protected function onMouseUp(event:MouseEvent):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}

		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			_move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
	}
}
