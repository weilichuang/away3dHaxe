package example
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Vector3D;
	import flash.Vector;

	import a3d.animators.SpriteSheetAnimationSet;
	import a3d.animators.SpriteSheetAnimator;
	import a3d.animators.nodes.SpriteSheetClipNode;
	import a3d.entities.Mesh;
	import a3d.materials.SpriteSheetMaterial;
	import a3d.materials.TextureMaterial;
	import a3d.entities.primitives.PlaneGeometry;
	import a3d.textures.BitmapTexture;
	import a3d.textures.Texture2DBase;
	import a3d.tools.helpers.SpriteSheetHelper;
	import a3d.utils.Cast;

	class Basic_SpriteSheetAnimation extends BasicApplication
	{
		//the sprite sheets sources
		[Embed(source = "../embeds/spritesheets/testSheet1.jpg")]
		public static var testSheet1:Class;

		[Embed(source = "../embeds/spritesheets/testSheet2.jpg")]
		public static var testSheet2:Class;

		/**
		 * Constructor
		 */
		public function Basic_SpriteSheetAnimation()
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
		 * view setup
		 */
		override private function initEngine():Void
		{
			super.initEngine();

			//setup the camera
			view.camera.z = -1500;
			view.camera.y = 200;
			view.camera.lookAt(new Vector3D());
		}


		private function initObjects():Void
		{
			//setup the meshes and their SpriteSheetAnimator
			prepareSingleMap();
			prepareMultipleMaps();
		}

		/**
		 * setting up the spritesheets with a single map
		 */
		private function prepareSingleMap():Void
		{
			//if the animation is something that plays non stop, and fits a single map,
			// you can use a regular TextureMaterial
			var material:TextureMaterial = new TextureMaterial(Cast.bitmapTexture(testSheet1));

			// the name of the animation
			var animID:String = "mySingleMapAnim";
			// to simplify the generation of the required nodes for the animator, away3d has an helper class.
			var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
			// first we make our SpriteSheetAnimationSet, which will hold one or more spriteSheetClipNode
			var spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			// in this case our simple map is composed of 4 cells: 2 rows, 2 colums
			var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, 2, 2);
			//we can now add the animation to the set.
			spriteSheetAnimationSet.addAnimation(spriteSheetClipNode);
			// Finally we can build the animator and add the animation set to it.
			var spriteSheetAnimator:SpriteSheetAnimator = new SpriteSheetAnimator(spriteSheetAnimationSet);

			// construct the receiver geometry, in this case a plane;
			var mesh:Mesh = new Mesh(new PlaneGeometry(700, 700, 1, 1, false), material);
			mesh.x = -400;
			//asign the animator
			mesh.animator = spriteSheetAnimator;
			// because our very simple map has only 4 images in itself, playing it the same speed as the swf would be way too fast.
			spriteSheetAnimator.fps = 4;
			//start play the animation
			spriteSheetAnimator.play(animID);

			view.scene.addChild(mesh);
		}

		/**
		* Because one animation may require more resolution or duration. The animation source may be spreaded over multiple sources
		* A dedicated material handles the maps management
		*/
		private function prepareMultipleMaps():Void
		{
			//the first map, we the beginning of the animation
			var bmd1:BitmapData = Bitmap(new testSheet1()).bitmapData;
			var texture1:BitmapTexture = new BitmapTexture(bmd1);

			//the rest of teh animation
			var bmd2:BitmapData = Bitmap(new testSheet2()).bitmapData;
			var texture2:BitmapTexture = new BitmapTexture(bmd2);

			var diffuses:Vector<Texture2DBase> = Vector<Texture2DBase>([texture1, texture2]);
			var material:SpriteSheetMaterial = new SpriteSheetMaterial(diffuses);

			// the name of the animation
			var animID:String = "myMultipleMapsAnim";
			// to simplify the generation of the required nodes for the animator, away3d has an helper class.
			var spriteSheetHelper:SpriteSheetHelper = new SpriteSheetHelper();
			// first we make our SpriteSheetAnimationSet, which will hold one or more spriteSheetClipNode
			var spriteSheetAnimationSet:SpriteSheetAnimationSet = new SpriteSheetAnimationSet();
			// in this case our simple map is composed of 4 cells: 2 rows, 2 colums
			// note compared to the above "prepareSingleMap" method, we now pass a third parameter (2): how many maps are used inthis animation
			var spriteSheetClipNode:SpriteSheetClipNode = spriteSheetHelper.generateSpriteSheetClipNode(animID, 2, 2, 2);
			//we can now add the animation to the set and build the animator
			spriteSheetAnimationSet.addAnimation(spriteSheetClipNode);
			var spriteSheetAnimator:SpriteSheetAnimator = new SpriteSheetAnimator(spriteSheetAnimationSet);

			// construct the reciever geometry, in this case a plane;
			var mesh:Mesh = new Mesh(new PlaneGeometry(700, 700, 1, 1, false), material);
			mesh.x = 400;
			//asign the animator
			mesh.animator = spriteSheetAnimator;
			//the frame rate at which the animation should be played
			spriteSheetAnimator.fps = 10;
			//we can set the animation to play back and forth
			spriteSheetAnimator.backAndForth = true;

			//start play the animation
			spriteSheetAnimator.play(animID);

			view.scene.addChild(mesh);
		}
	}
}
