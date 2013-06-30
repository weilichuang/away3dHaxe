package a3dexample;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Vector3D;
import flash.Lib;

import a3d.animators.UVAnimationSet;
import a3d.animators.UVAnimator;
import a3d.animators.data.UVAnimationFrame;
import a3d.animators.nodes.UVClipNode;
import a3d.entities.Mesh;
import a3d.materials.TextureMaterial;
import a3d.entities.primitives.PlaneGeometry;
import a3d.textures.BitmapTexture;

@:bitmap("embeds/road.jpg") class MyRoad extends flash.display.BitmapData { }

@:bitmap("embeds/wheel.jpg") class MyWheel extends flash.display.BitmapData { }


class Basic_UVAnimation extends BasicApplication
{
	static function main()
	{
		Lib.current.addChild(new Basic_UVAnimation());
	}

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
	 * setup of the UVAnimators
	 */
	private function initObjects():Void
	{
		//the vars we will reuse
		var animID:String;
		var pg:PlaneGeometry = new PlaneGeometry(500, 500, 1, 1, false);
		var diffuse:BitmapData;
		var bt:BitmapTexture;
		var mat:TextureMaterial;
		var mesh:Mesh;
		var uvAnimationSet:UVAnimationSet;
		var uvAnimator:UVAnimator;

		//In this demo class, the two upper planes, will be using non- keyframe information
		//while the two others will display keyframe based animations

		//All the animations are non destructive (the mesh uvs are kept unchanged) and very efficient as they are executed on the gpu.

		//Endless rotations, map scrolls are very useful. They are hard to define using keyframes.
		//UVAnimator offers both options without the need to define any keyframes.

		/* 1: The top left plane, will display the endless rotation of a image*/
		animID = "anim_rotation";
		//material declaration
		diffuse = Bitmap(new MyWheel()).bitmapData;
		bt = new BitmapTexture(diffuse);
		mat = new TextureMaterial(bt);

		// adding an empty set with our animation id
		uvAnimationSet = generateBlankAnimationSet(animID);
		uvAnimator = new UVAnimator(uvAnimationSet);
		//setting the animator autoRotation
		uvAnimator.autoRotation = true;
		uvAnimator.rotationIncrease = 1.1; //default is 1 degree

		// the geometry receiver
		mesh = new Mesh(pg, mat);
		//assigning the animator to the mesh
		mesh.animator = uvAnimator;
		//let's play our animation
		uvAnimator.play(animID);
		mesh.x -= 300;
		mesh.y += 300;
		view.scene.addChild(mesh);


		/* 2: The top right plane, will display the endless scroll of an image*/
		animID = "anim_translate";
		diffuse = Bitmap(new MyRoad()).bitmapData;
		bt = new BitmapTexture(diffuse);
		mat = new TextureMaterial(bt);
		// the road map that we use is seamless, so we set repeat to true to prevent elongated pixel
		mat.repeat = true;

		uvAnimationSet = generateBlankAnimationSet(animID);
		uvAnimator = new UVAnimator(uvAnimationSet);
		// setting the auto translate
		uvAnimator.autoTranslate = true;
		// in this example we scroll a endless road, so the increase is made only along the v axis
		// note that using integers values would not affect the rendering. The image would stay still as the uvs are using values between 0 and 1.
		uvAnimator.setTranslateIncrease(0, -.01);
		uvAnimator.play(animID);
		mesh = new Mesh(pg, mat);
		mesh.animator = uvAnimator;
		mesh.x += 300;
		mesh.y += 300;
		view.scene.addChild(mesh);


		/* 3: The down left plane, will display an animation using keyframes.*/
		animID = "anim3";
		//material setup, similar to the above examples
		diffuse = Bitmap(new MyRoad()).bitmapData;
		bt = new BitmapTexture(diffuse);
		mat = new TextureMaterial(bt);
		mat.repeat = true;
		// this time, we use a keyframe based approach.
		uvAnimationSet = generateFirstAnimation(animID);
		uvAnimator = new UVAnimator(uvAnimationSet);
		mesh = new Mesh(pg, mat);
		mesh.animator = uvAnimator;
		uvAnimator.play(animID);
		mesh.x += 300;
		mesh.y -= 300;
		view.scene.addChild(mesh);


		/* 4: The down right plane, will display another animation using another set of keyframes. */
		animID = "anim4";
		diffuse = Bitmap(new MyWheel()).bitmapData;
		bt = new BitmapTexture(diffuse);
		mat = new TextureMaterial(bt);
		mat.repeat = true;
		mesh = new Mesh(pg, mat);
		uvAnimationSet = generateSecondAnimation(animID);
		uvAnimator = new UVAnimator(uvAnimationSet);
		mesh.animator = uvAnimator;
		uvAnimator.play(animID);
		mesh.x -= 300;
		mesh.y -= 300;
		view.scene.addChild(mesh);
	}

	/**
	* view setup
	*/
	override private function initEngine():Void
	{
		super.initEngine();

		view.antiAlias = 2;

		view.camera.x = 500;
		view.camera.y = 500;
		view.camera.z = -1500;

		//saving the origin, as we look at it on enterframe
		view.camera.lookAt(new Vector3D());
	}

	/**
	 * adding a blank set, to meet the generic animators architecture
	 */
	private function generateBlankAnimationSet(animID:String):UVAnimationSet
	{
		var uvAnimationSet:UVAnimationSet = new UVAnimationSet();
		var node:UVClipNode = new UVClipNode();
		node.name = animID;
		uvAnimationSet.addAnimation(node);

		return uvAnimationSet;
	}

	/**
	 * adding set, composed of multiple keyframes
	 */
	private function generateFirstAnimation(animID:String):UVAnimationSet
	{
		var uvAnimationSet:UVAnimationSet = new UVAnimationSet();

		var node:UVClipNode = new UVClipNode();
		node.name = animID;
		uvAnimationSet.addAnimation(node);

		var frame:UVAnimationFrame;
		var duration:uint = 1000;
		var offset:Float = 0;

		frame = new UVAnimationFrame();
		frame.offsetU = offset;
		frame.offsetV = offset;
		frame.scaleU = 1;
		frame.scaleV = 1;
		frame.rotation = 0;

		node.addFrame(frame, duration);

		frame = new UVAnimationFrame();
		frame.offsetU = offset;
		frame.offsetV = offset;
		frame.scaleU = 2;
		frame.scaleV = 2;
		frame.rotation = 0;

		node.addFrame(frame, duration);

		frame = new UVAnimationFrame();
		frame.offsetU = offset;
		frame.offsetV = offset;
		frame.scaleU = 1;
		frame.scaleU = 1;
		frame.rotation = 90;

		node.addFrame(frame, duration);

		frame = new UVAnimationFrame();
		frame.offsetU = offset;
		frame.offsetV = offset;
		frame.scaleU = 1;
		frame.scaleU = 1;
		frame.rotation = 90;

		node.addFrame(frame, duration);

		frame = new UVAnimationFrame();
		frame.offsetU = offset;
		frame.offsetV = offset;
		frame.scaleU = 1;
		frame.scaleU = 1;
		frame.rotation = 90;

		node.addFrame(frame, duration);

		return uvAnimationSet;
	}


	private function generateSecondAnimation(animID:String):UVAnimationSet
	{
		var uvAnimationSet:UVAnimationSet = new UVAnimationSet();
		var node:UVClipNode = new UVClipNode();
		node.name = animID;
		uvAnimationSet.addAnimation(node);

		var frame:UVAnimationFrame;

		frame = new UVAnimationFrame();
		node.addFrame(frame, 250);

		frame = new UVAnimationFrame();
		frame.scaleU = frame.scaleV = 4;
		node.addFrame(frame, 1000);

		return uvAnimationSet;
	}

}
