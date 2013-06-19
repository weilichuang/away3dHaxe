/*

3D Tweening example in Away3d

Demonstrates:

How to use Tweener within a 3D coordinate system.
How to create a 3D mouse event listener on a scene object.
How to return the scene coordinates of a mouse click on the surface of a scene object.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

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
	import flash.geom.Vector3D;

	import away3d.entities.Mesh;
	import away3d.materials.TextureMaterial;
	import away3d.entities.primitives.PlaneGeometry;
	import away3d.utils.Cast;

	public class Basic_View extends BasicApplication
	{
		//plane texture
		[Embed(source = "../embeds/floor_diffuse.jpg")]
		public static var FloorDiffuse:Class;

		//scene objects
		private var _plane:Mesh;

		/**
		 * Constructor
		 */
		public function Basic_View()
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

		override protected function initEngine():void
		{
			super.initEngine();

			//setup the camera
			view.camera.z = -600;
			view.camera.y = 500;
			view.camera.lookAt(new Vector3D());
		}

		private function initObjects():void
		{
			//setup the scene
			_plane = new Mesh(new PlaneGeometry(700, 700), new TextureMaterial(Cast.bitmapTexture(FloorDiffuse)));
			view.scene.addChild(_plane);
		}

		/**
		 * render loop
		 */
		override protected function render():void
		{
			_plane.rotationY += 1;

			super.render();
		}
	}
}
