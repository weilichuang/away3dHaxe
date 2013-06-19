package away3d.materials.passes
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;


	import away3d.entities.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.lights.DirectionalLight;
	import away3d.entities.lights.PointLight;
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.LightingShaderCompiler;
	import away3d.materials.compilation.ShaderCompiler;



	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */

	public class ShadowCasterPass extends CompiledPass
	{
		private var _tangentSpace:Boolean;
		private var _lightVertexConstantIndex:int;
		private var _inverseSceneMatrix:Vector.<Number> = new Vector.<Number>();

		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function ShadowCasterPass(material:MaterialBase)
		{
			super(material);
		}

		override protected function createCompiler(profile:String):ShaderCompiler
		{
			return new LightingShaderCompiler(profile);
		}

		override protected function updateLights():void
		{
			super.updateLights();

			var numPointLights:int = _lightPicker.numCastingPointLights > 0 ? 1 : 0;
			var numDirectionalLights:int = _lightPicker.numCastingDirectionalLights > 0 ? 1 : 0;
			_numLightProbes = 0;
			if (numPointLights == numDirectionalLights)
				throw new Error("Must have exactly one light!");

			if (numPointLights != _numPointLights || numDirectionalLights != _numDirectionalLights)
			{
				_numPointLights = numPointLights;
				_numDirectionalLights = numDirectionalLights;
				invalidateShaderProgram();
			}
		}

		override protected function updateShaderProperties():void
		{
			super.updateShaderProperties();
			_tangentSpace = LightingShaderCompiler(_compiler).tangentSpace;
		}

		override protected function updateRegisterIndices():void
		{
			super.updateRegisterIndices();
			_lightVertexConstantIndex = LightingShaderCompiler(_compiler).lightVertexConstantIndex;
		}

		override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			renderable.inverseSceneTransform.copyRawDataTo(_inverseSceneMatrix);

			if (_tangentSpace && _cameraPositionIndex >= 0)
			{
				var pos:Vector3D = camera.scenePosition;
				var x:Number = pos.x;
				var y:Number = pos.y;
				var z:Number = pos.z;
				_vertexConstantData[_cameraPositionIndex] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z + _inverseSceneMatrix[12];
				_vertexConstantData[_cameraPositionIndex + 1] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z + _inverseSceneMatrix[13];
				_vertexConstantData[_cameraPositionIndex + 2] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z + _inverseSceneMatrix[14];
			}

			super.render(renderable, stage3DProxy, camera, viewProjection);
		}

		/**
		 * @inheritDoc
		 */
		override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(stage3DProxy, camera);

			if (!_tangentSpace && _cameraPositionIndex >= 0)
			{
				var pos:Vector3D = camera.scenePosition;
				_vertexConstantData[_cameraPositionIndex] = pos.x;
				_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
				_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
			}
		}

		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		override protected function updateLightConstants():void
		{
			// first dirs, then points
			var dirLight:DirectionalLight;
			var pointLight:PointLight;
			var k:uint, l:uint;
			var dirPos:Vector3D;

			l = _lightVertexConstantIndex;
			k = _lightFragmentConstantIndex;

			if (_numDirectionalLights > 0)
			{
				dirLight = _lightPicker.castingDirectionalLights[0];
				dirPos = dirLight.sceneDirection;

				_ambientLightR += dirLight.ambientR;
				_ambientLightG += dirLight.ambientG;
				_ambientLightB += dirLight.ambientB;

				if (_tangentSpace)
				{
					var x:Number = -dirPos.x;
					var y:Number = -dirPos.y;
					var z:Number = -dirPos.z;
					_vertexConstantData[l++] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z;
					_vertexConstantData[l++] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z;
					_vertexConstantData[l++] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z;
					_vertexConstantData[l++] = 1;
				}
				else
				{
					_fragmentConstantData[k++] = -dirPos.x;
					_fragmentConstantData[k++] = -dirPos.y;
					_fragmentConstantData[k++] = -dirPos.z;
					_fragmentConstantData[k++] = 1;
				}

				_fragmentConstantData[k++] = dirLight.diffuseR;
				_fragmentConstantData[k++] = dirLight.diffuseG;
				_fragmentConstantData[k++] = dirLight.diffuseB;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight.specularR;
				_fragmentConstantData[k++] = dirLight.specularG;
				_fragmentConstantData[k++] = dirLight.specularB;
				_fragmentConstantData[k++] = 1;
				return;
			}

			if (_numPointLights > 0)
			{
				pointLight = _lightPicker.castingPointLights[0];
				dirPos = pointLight.scenePosition;

				_ambientLightR += pointLight.ambientR;
				_ambientLightG += pointLight.ambientG;
				_ambientLightB += pointLight.ambientB;

				if (_tangentSpace)
				{
					x = dirPos.x;
					y = dirPos.y;
					z = dirPos.z;
					_vertexConstantData[l++] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z + _inverseSceneMatrix[12];
					_vertexConstantData[l++] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z + _inverseSceneMatrix[13];
					_vertexConstantData[l++] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z + _inverseSceneMatrix[14];
				}
				else
				{
					_vertexConstantData[l++] = dirPos.x;
					_vertexConstantData[l++] = dirPos.y;
					_vertexConstantData[l++] = dirPos.z;
				}
				_vertexConstantData[l++] = 1;

				_fragmentConstantData[k++] = pointLight.diffuseR;
				_fragmentConstantData[k++] = pointLight.diffuseG;
				_fragmentConstantData[k++] = pointLight.diffuseB;
				_fragmentConstantData[k++] = pointLight.radius * pointLight.radius;

				_fragmentConstantData[k++] = pointLight.specularR;
				_fragmentConstantData[k++] = pointLight.specularG;
				_fragmentConstantData[k++] = pointLight.specularB;
				_fragmentConstantData[k++] = pointLight.fallOffFactor;
			}
		}

		override protected function usesProbes():Boolean
		{
			return false;
		}

		override protected function usesLights():Boolean
		{
			return true;
		}

		override protected function updateProbes(stage3DProxy:Stage3DProxy):void
		{
		}
	}
}
