package example;

import away3d.materials.BlendMode;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.Lib;
import flash.Vector;

import away3d.animators.ParticleAnimationSet;
import away3d.animators.ParticleAnimator;
import away3d.animators.data.ParticleProperties;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.ParticleBillboardNode;
import away3d.animators.nodes.ParticleVelocityNode;
import away3d.containers.View3D;
import away3d.controllers.HoverController;
import away3d.core.base.Geometry;
import away3d.debug.AwayStats;
import away3d.entities.Mesh;
import away3d.materials.TextureMaterial;
import away3d.primitives.PlaneGeometry;
import away3d.tools.helpers.ParticleGeometryHelper;
import away3d.utils.Cast;

using Reflect;

//particle image
@:bitmap("embeds/blue.png") class ParticleImg extends flash.display.BitmapData { }

class Basic_Particles extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_Particles());
	}

	//engine variables
	private var _cameraController:HoverController;

	//particle variables
	private var _particleAnimationSet:ParticleAnimationSet;
	private var _particleMesh:Mesh;
	private var _particleAnimator:ParticleAnimator;

	//navigation variables
	private var _move:Bool = false;
	private var _lastPanAngle:Float;
	private var _lastTiltAngle:Float;
	private var _lastMouseX:Float;
	private var _lastMouseY:Float;

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
	override  private function init():Void
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
		for (i in 0...20000)
			geometrySet.push(plane);

		//setup the particle animation set
		_particleAnimationSet = new ParticleAnimationSet(true, true);
		_particleAnimationSet.addAnimation(new ParticleBillboardNode());
		_particleAnimationSet.addAnimation(new ParticleVelocityNode(ParticlePropertiesMode.LOCAL_STATIC));
		_particleAnimationSet.initParticleFunc = initParticleFunc;

		//setup the particle material
		var material:TextureMaterial = new TextureMaterial(createBitmapTexture(ParticleImg));
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
		prop.setField(ParticleVelocityNode.VELOCITY_VECTOR3D,
			new Vector3D(r * Math.sin(degree1) * Math.cos(degree2), 
			r * Math.cos(degree1) * Math.cos(degree2), 
			r * Math.sin(degree2)));
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
