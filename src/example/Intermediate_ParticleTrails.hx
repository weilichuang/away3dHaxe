/*

Particle trails in a3d

Demonstrates:

How to create a complex static parrticle behaviour
How to reuse a particle animation set and particle geometry in multiple animators and meshes
How to create a particle trail

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

package example;

import away3d.animators.data.ParticleProperties;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleBillboardNode;
import away3d.animators.nodes.ParticleColorNode;
import away3d.animators.nodes.ParticleFollowNode;
import away3d.animators.nodes.ParticleVelocityNode;
import away3d.animators.ParticleAnimationSet;
import away3d.animators.ParticleAnimator;
import away3d.controllers.HoverController;
import away3d.core.base.Geometry;
import away3d.core.base.Object3D;
import away3d.core.base.ParticleGeometry;
import away3d.entities.Camera3D;
import away3d.entities.Mesh;
import away3d.entities.primitives.PlaneGeometry;
import away3d.entities.primitives.WireframeAxesGrid;
import away3d.entities.Scene3D;
import away3d.materials.BlendMode;
import away3d.materials.TextureMaterial;
import away3d.tools.helpers.data.ParticleGeometryTransform;
import away3d.tools.helpers.ParticleGeometryHelper;
import away3d.utils.Cast;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Vector3D;
import flash.Lib;
import flash.Vector.Vector;



using Reflect;

class Intermediate_ParticleTrails extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Intermediate_ParticleTrails());
	}
	
	//engine variables
	private var cameraController:HoverController;

	//material objects
	private var particleMaterial:TextureMaterial;

	//particle objects
	private var particleAnimationSet:ParticleAnimationSet;
	private var particleFollowNode:ParticleFollowNode;
	private var particleGeometry:ParticleGeometry;

	//scene objects
	private var followTarget1:Object3D;
	private var followTarget2:Object3D;
	private var particleMesh1:Mesh;
	private var particleMesh2:Mesh;
	private var animator1:ParticleAnimator;
	private var animator2:ParticleAnimator;

	//navigation variables
	private var angle:Float = 0;
	private var move:Bool = false;
	private var lastPanAngle:Float;
	private var lastTiltAngle:Float;
	private var lastMouseX:Float;
	private var lastMouseY:Float;

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
		initMaterials();
		initParticles();
		initObjects();
		initListeners();
	}

	/**
	 * Initialise the engine
	 */
	override private function initEngine():Void
	{
		super.initEngine();

		scene = new Scene3D();

		camera = new Camera3D();

		view.antiAlias = 4;
		view.scene = scene;
		view.camera = camera;

		//setup controller to be used on the camera
		cameraController = new HoverController(camera, null, 45, 20, 1000, 5);
	}

	/**
	 * Initialise the materials
	 */
	private function initMaterials():Void
	{
		//setup particle material
		particleMaterial = new TextureMaterial(Cast.bitmapTexture(ParticleTexture));
		particleMaterial.blendMode = BlendMode.ADD;
	}

	/**
	 * Initialise the particles
	 */
	private function initParticles():Void
	{
		//setup the base geometry for one particle
		var plane:Geometry = new PlaneGeometry(30, 30, 1, 1, false);

		//create the particle geometry
		var geometrySet:Vector<Geometry> = new Vector<Geometry>();
		var setTransforms:Vector<ParticleGeometryTransform> = new Vector<ParticleGeometryTransform>();
		var particleTransform:ParticleGeometryTransform;
		var uvTransform:Matrix;
		for (i in 0...1000)
		{
			geometrySet.push(plane);
			particleTransform = new ParticleGeometryTransform();
			uvTransform = new Matrix();
			uvTransform.scale(0.5, 0.5);
			uvTransform.translate(Std.int(Math.random() * 2) / 2, Std.int(Math.random() * 2) / 2);
			particleTransform.UVTransform = uvTransform;
			setTransforms.push(particleTransform);
		}

		particleGeometry = ParticleGeometryHelper.generateGeometry(geometrySet, setTransforms);


		//create the particle animation set
		particleAnimationSet = new ParticleAnimationSet(true, true, true);

		//define the particle animations and init function
		particleAnimationSet.addAnimation(new ParticleBillboardNode());
		particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
		particleAnimationSet.addAnimation(new ParticleColorNode(ParticlePropertiesMode.GLOBAL, true, false, false, false, new ColorTransform(), new ColorTransform(1, 1, 1, 0)));
		particleAnimationSet.addAnimation(particleFollowNode = new ParticleFollowNode(true, false));
		particleAnimationSet.initParticleFunc = initParticleProperties;
	}

	/**
	 * Initialise the scene objects
	 */
	private function initObjects():Void
	{
		//create wireframe axes
		scene.addChild(new WireframeAxesGrid(10, 1500));

		//create follow targets
		followTarget1 = new Object3D();
		followTarget2 = new Object3D();

		//create the particle meshes
		particleMesh1 = new Mesh(particleGeometry, particleMaterial);
		particleMesh1.y = 300;
		scene.addChild(particleMesh1);

		particleMesh2 = Std.instance(particleMesh1.clone(),Mesh);
		particleMesh2.y = 300;
		scene.addChild(particleMesh2);

		//create and start the particle animators
		animator1 = new ParticleAnimator(particleAnimationSet);
		particleMesh1.animator = animator1;
		animator1.start();
		particleFollowNode.getAnimationState(animator1).followTarget = followTarget1;

		animator2 = new ParticleAnimator(particleAnimationSet);
		particleMesh2.animator = animator2;
		animator2.start();
		particleFollowNode.getAnimationState(animator2).followTarget = followTarget2;
	}

	/**
	 * Initialiser function for particle properties
	 */
	private function initParticleProperties(properties:ParticleProperties):Void
	{
		properties.startTime = Math.random() * 4.1;
		properties.duration = 4;
		properties.setField(ParticleVelocityNode.VELOCITY_VECTOR3D, new Vector3D(Math.random() * 100 - 50, Math.random() * 100 - 200, Math.random() * 100 - 50));
	}

	/**
	 * Navigation and render loop
	 */
	override private function render():Void
	{
		if (move)
		{
			cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
			cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
		}

		angle += 0.04;
		followTarget1.x = Math.cos(angle) * 500;
		followTarget1.z = Math.sin(angle) * 500;
		followTarget2.x = Math.sin(angle) * 500;

		super.render();
	}

	/**
	 * Mouse down listener for navigation
	 */
	override private function onMouseDown(event:MouseEvent):Void
	{
		lastPanAngle = cameraController.panAngle;
		lastTiltAngle = cameraController.tiltAngle;
		lastMouseX = stage.mouseX;
		lastMouseY = stage.mouseY;
		move = true;
		stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
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
	 * Mouse stage leave listener for navigation
	 */
	private function onStageMouseLeave(event:Event):Void
	{
		move = false;
		stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
	}
}

@:bitmap("embeds/cards_suit.png") class ParticleTexture extends flash.display.BitmapData { }
