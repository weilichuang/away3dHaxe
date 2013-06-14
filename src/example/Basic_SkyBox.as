/*

SkyBox example in Away3d

Demonstrates:

How to use a CubeTexture to create a SkyBox object.
How to apply a CubeTexture to a material as an environment map.

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

	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.materials.methods.EnvMapMethod;
	import away3d.primitives.SkyBox;
	import away3d.primitives.TorusGeometry;
	import away3d.textures.BitmapCubeTexture;
	import away3d.utils.Cast;

	public class Basic_SkyBox extends BasicApplication
	{
		//scene objects
		private var _skyBox:SnowSkyBox;
		private var _torus:Mesh;

		/**
		 * Constructor
		 */
		public function Basic_SkyBox()
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
			_skyBox = new SnowSkyBox();
			view.scene.addChild(_skyBox);

			//setup the environment map material
			var material:ColorMaterial = new ColorMaterial(0xFFFFFF, 1);
			material.specular = 0.5;
			material.ambient = 0.25;
			material.ambientColor = 0x111199;
			material.ambient = 1;
			material.addMethod(new EnvMapMethod(_skyBox.cubeTexture, 1));

			//setup the scene
			_torus = new Mesh(new TorusGeometry(150, 60, 40, 20), material);
			view.scene.addChild(_torus);


		}

		/**
		 * Initialise the engine
		 */
		override protected function initEngine():void
		{
			super.initEngine();

			view.camera.z = -600;
			view.camera.y = 0;
			view.camera.lookAt(new Vector3D());
			view.camera.lens = new PerspectiveLens(90);
		}

		/**
		 * render loop
		 */
		override protected function render():void
		{
			_torus.rotationX += 2;
			_torus.rotationY += 1;

			view.camera.position = new Vector3D();
			view.camera.rotationY += 0.5 * (stage.mouseX - stage.stageWidth / 2) / 800;
			view.camera.moveBackward(600);

			super.render();
		}
	}
}
