package away3d.materials.compilation
{


	public class SuperShaderCompiler extends ShaderCompiler
	{
		public var pointLightRegisters:Vector.<ShaderRegisterElement>;
		public var dirLightRegisters:Vector.<ShaderRegisterElement>;



		public function SuperShaderCompiler(profile:String)
		{
			super(profile);
		}

		override protected function initLightData():void
		{
			super.initLightData();

			pointLightRegisters = new Vector.<ShaderRegisterElement>(_numPointLights * 3, true);
			dirLightRegisters = new Vector.<ShaderRegisterElement>(_numDirectionalLights * 3, true);
		}

		/**
		 * Calculates register dependencies for commonly used data.
		 */
		override protected function calculateDependencies():void
		{
			super.calculateDependencies();
			_dependencyCounter.addWorldSpaceDependencies(true);
		}

		override protected function compileNormalCode():void
		{
			var normalMatrix:Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(3, true);

			_sharedRegisters.normalFragment = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.normalFragment, _dependencyCounter.normalDependencies);

			if (_methodSetup.normalMethod.hasOutput && !_methodSetup.normalMethod.tangentSpace)
			{
				_vertexCode += _methodSetup.normalMethod.getVertexCode(_methodSetup.normalMethodVO, _registerCache);
				_fragmentCode += _methodSetup.normalMethod.getFragmentCode(_methodSetup.normalMethodVO, _registerCache, _sharedRegisters.normalFragment);
				return;
			}

			_sharedRegisters.normalVarying = _registerCache.getFreeVarying();

			normalMatrix[0] = _registerCache.getFreeVertexConstant();
			normalMatrix[1] = _registerCache.getFreeVertexConstant();
			normalMatrix[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneNormalMatrixIndex = normalMatrix[0].index * 4;

			if (_methodSetup.normalMethod.hasOutput)
			{
				// tangent stream required
				compileTangentVertexCode(normalMatrix);
				compileTangentNormalMapFragmentCode();
			}
			else
			{
				_vertexCode += "m33 " + _sharedRegisters.normalVarying + ".xyz, " + _sharedRegisters.animatedNormal + ", " + normalMatrix[0] + "\n" +
					"mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.animatedNormal + ".w	\n";

				_fragmentCode += "nrm " + _sharedRegisters.normalFragment + ".xyz, " + _sharedRegisters.normalVarying + "\n" +
					"mov " + _sharedRegisters.normalFragment + ".w, " + _sharedRegisters.normalVarying + ".w		\n";


				if (_dependencyCounter.tangentDependencies > 0)
				{
					_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
					_tangentBufferIndex = _sharedRegisters.tangentInput.index;
					_sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
					_vertexCode += "mov " + _sharedRegisters.tangentVarying + ", " + _sharedRegisters.tangentInput + "\n";
				}
			}

			_registerCache.removeVertexTempUsage(_sharedRegisters.animatedNormal);
		}

		override protected function createNormalRegisters():void
		{
			if (_dependencyCounter.normalDependencies > 0)
			{
				_sharedRegisters.normalInput = _registerCache.getFreeVertexAttribute();
				_normalBufferIndex = _sharedRegisters.normalInput.index;
				_sharedRegisters.animatedNormal = _registerCache.getFreeVertexVectorTemp();
				_registerCache.addVertexTempUsages(_sharedRegisters.animatedNormal, 1);
				_animatableAttributes.push(_sharedRegisters.normalInput.toString());
				_animationTargetRegisters.push(_sharedRegisters.animatedNormal.toString());
			}

			if (_methodSetup.normalMethod.hasOutput)
			{
				_sharedRegisters.tangentInput = _registerCache.getFreeVertexAttribute();
				_tangentBufferIndex = _sharedRegisters.tangentInput.index;

				_sharedRegisters.animatedTangent = _registerCache.getFreeVertexVectorTemp();
				_registerCache.addVertexTempUsages(_sharedRegisters.animatedTangent, 1);

				_animatableAttributes.push(_sharedRegisters.tangentInput.toString());
				_animationTargetRegisters.push(_sharedRegisters.animatedTangent.toString());
			}
		}

		private function compileTangentVertexCode(matrix:Vector.<ShaderRegisterElement>):void
		{
			_sharedRegisters.tangentVarying = _registerCache.getFreeVarying();
			_sharedRegisters.bitangentVarying = _registerCache.getFreeVarying();

			_vertexCode += "m33 " + _sharedRegisters.animatedNormal + ".xyz, " + _sharedRegisters.animatedNormal + ", " + matrix[0] + "\n" +
				"nrm " + _sharedRegisters.animatedNormal + ".xyz, " + _sharedRegisters.animatedNormal + "\n";

			_vertexCode += "m33 " + _sharedRegisters.animatedTangent + ".xyz, " + _sharedRegisters.animatedTangent + ", " + matrix[0] + "\n" +
				"nrm " + _sharedRegisters.animatedTangent + ".xyz, " + _sharedRegisters.animatedTangent + "\n";

			var bitanTemp:ShaderRegisterElement = _registerCache.getFreeVertexVectorTemp();
			_vertexCode += "mov " + _sharedRegisters.tangentVarying + ".x, " + _sharedRegisters.animatedTangent + ".x  \n" +
				"mov " + _sharedRegisters.tangentVarying + ".z, " + _sharedRegisters.animatedNormal + ".x  \n" +
				"mov " + _sharedRegisters.tangentVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
				"mov " + _sharedRegisters.bitangentVarying + ".x, " + _sharedRegisters.animatedTangent + ".y  \n" +
				"mov " + _sharedRegisters.bitangentVarying + ".z, " + _sharedRegisters.animatedNormal + ".y  \n" +
				"mov " + _sharedRegisters.bitangentVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
				"mov " + _sharedRegisters.normalVarying + ".x, " + _sharedRegisters.animatedTangent + ".z  \n" +
				"mov " + _sharedRegisters.normalVarying + ".z, " + _sharedRegisters.animatedNormal + ".z  \n" +
				"mov " + _sharedRegisters.normalVarying + ".w, " + _sharedRegisters.normalInput + ".w  \n" +
				"crs " + bitanTemp + ".xyz, " + _sharedRegisters.animatedNormal + ", " + _sharedRegisters.animatedTangent + "\n" +
				"mov " + _sharedRegisters.tangentVarying + ".y, " + bitanTemp + ".x    \n" +
				"mov " + _sharedRegisters.bitangentVarying + ".y, " + bitanTemp + ".y  \n" +
				"mov " + _sharedRegisters.normalVarying + ".y, " + bitanTemp + ".z    \n";

			_registerCache.removeVertexTempUsage(_sharedRegisters.animatedTangent);
		}

		private function compileTangentNormalMapFragmentCode():void
		{
			var t:ShaderRegisterElement;
			var b:ShaderRegisterElement;
			var n:ShaderRegisterElement;

			t = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(t, 1);
			b = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(b, 1);
			n = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(n, 1);

			_fragmentCode += "nrm " + t + ".xyz, " + _sharedRegisters.tangentVarying + "\n" +
				"mov " + t + ".w, " + _sharedRegisters.tangentVarying + ".w	\n" +
				"nrm " + b + ".xyz, " + _sharedRegisters.bitangentVarying + "\n" +
				"nrm " + n + ".xyz, " + _sharedRegisters.normalVarying + "\n";

			var temp:ShaderRegisterElement = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(temp, 1);
			_fragmentCode += _methodSetup.normalMethod.getFragmentCode(_methodSetup.normalMethodVO, _registerCache, temp) +
				"m33 " + _sharedRegisters.normalFragment + ".xyz, " + temp + ", " + t + "	\n" +
				"mov " + _sharedRegisters.normalFragment + ".w,   " + _sharedRegisters.normalVarying + ".w			\n";

			_registerCache.removeFragmentTempUsage(temp);

			if (_methodSetup.normalMethodVO.needsView)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			if (_methodSetup.normalMethodVO.needsGlobalVertexPos || _methodSetup.normalMethodVO.needsGlobalFragmentPos)
				_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
			_registerCache.removeFragmentTempUsage(b);
			_registerCache.removeFragmentTempUsage(t);
			_registerCache.removeFragmentTempUsage(n);
		}

		override protected function compileViewDirCode():void
		{
			var cameraPositionReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			_sharedRegisters.viewDirVarying = _registerCache.getFreeVarying();
			_sharedRegisters.viewDirFragment = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.viewDirFragment, _dependencyCounter.viewDirDependencies);

			_cameraPositionIndex = cameraPositionReg.index * 4;

			_vertexCode += "sub " + _sharedRegisters.viewDirVarying + ", " + cameraPositionReg + ", " + _sharedRegisters.globalPositionVertex + "\n";
			_fragmentCode += "nrm " + _sharedRegisters.viewDirFragment + ".xyz, " + _sharedRegisters.viewDirVarying + "\n" +
				"mov " + _sharedRegisters.viewDirFragment + ".w,   " + _sharedRegisters.viewDirVarying + ".w 		\n";

			_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);
		}

		override protected function compileLightingCode():void
		{
			var shadowReg:ShaderRegisterElement;

			_sharedRegisters.shadedTarget = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_sharedRegisters.shadedTarget, 1);

			_vertexCode += _methodSetup.diffuseMethod.getVertexCode(_methodSetup.diffuseMethodVO, _registerCache);
			_fragmentCode += _methodSetup.diffuseMethod.getFragmentPreLightingCode(_methodSetup.diffuseMethodVO, _registerCache);

			if (_usingSpecularMethod)
			{
				_vertexCode += _methodSetup.specularMethod.getVertexCode(_methodSetup.specularMethodVO, _registerCache);
				_fragmentCode += _methodSetup.specularMethod.getFragmentPreLightingCode(_methodSetup.specularMethodVO, _registerCache);
			}

			if (usesLights())
			{
				initLightRegisters();
				compileDirectionalLightCode();
				compilePointLightCode();
			}

			if (usesProbes())
				compileLightProbeCode();

			// only need to create and reserve _shadedTargetReg here, no earlier?
			_vertexCode += _methodSetup.ambientMethod.getVertexCode(_methodSetup.ambientMethodVO, _registerCache);
			_fragmentCode += _methodSetup.ambientMethod.getFragmentCode(_methodSetup.ambientMethodVO, _registerCache, _sharedRegisters.shadedTarget);
			if (_methodSetup.ambientMethodVO.needsNormals)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (_methodSetup.ambientMethodVO.needsView)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);


			if (_methodSetup.shadowMethod)
			{
				_vertexCode += _methodSetup.shadowMethod.getVertexCode(_methodSetup.shadowMethodVO, _registerCache);
				// using normal to contain shadow data if available is perhaps risky :s
				// todo: improve compilation with lifetime analysis so this isn't necessary?
				if (_dependencyCounter.normalDependencies == 0)
				{
					shadowReg = _registerCache.getFreeFragmentVectorTemp();
					_registerCache.addFragmentTempUsages(shadowReg, 1);
				}
				else
					shadowReg = _sharedRegisters.normalFragment;

				_methodSetup.diffuseMethod.shadowRegister = shadowReg;
				_fragmentCode += _methodSetup.shadowMethod.getFragmentCode(_methodSetup.shadowMethodVO, _registerCache, shadowReg);
			}
			_fragmentCode += _methodSetup.diffuseMethod.getFragmentPostLightingCode(_methodSetup.diffuseMethodVO, _registerCache, _sharedRegisters.shadedTarget);

			if (_alphaPremultiplied)
			{
				_fragmentCode += "add " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
					"div " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + ", " + _sharedRegisters.shadedTarget + ".w\n" +
					"sub " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.shadedTarget + ".w, " + _sharedRegisters.commons + ".z\n" +
					"sat " + _sharedRegisters.shadedTarget + ".xyz, " + _sharedRegisters.shadedTarget + "\n";
			}

			// resolve other dependencies as well?
			if (_methodSetup.diffuseMethodVO.needsNormals)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (_methodSetup.diffuseMethodVO.needsView)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);

			if (_usingSpecularMethod)
			{
				_methodSetup.specularMethod.shadowRegister = shadowReg;
				_fragmentCode += _methodSetup.specularMethod.getFragmentPostLightingCode(_methodSetup.specularMethodVO, _registerCache, _sharedRegisters.shadedTarget);
				if (_methodSetup.specularMethodVO.needsNormals)
					_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
				if (_methodSetup.specularMethodVO.needsView)
					_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
			}
		}


		private function initLightRegisters():void
		{
			// init these first so we're sure they're in sequence
			var i:uint, len:uint;

			len = dirLightRegisters.length;
			for (i = 0; i < len; ++i)
			{
				dirLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightFragmentConstantIndex == -1)
					_lightFragmentConstantIndex = dirLightRegisters[i].index * 4;
			}

			len = pointLightRegisters.length;
			for (i = 0; i < len; ++i)
			{
				pointLightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (_lightFragmentConstantIndex == -1)
					_lightFragmentConstantIndex = pointLightRegisters[i].index * 4;
			}
		}

		private function compileDirectionalLightCode():void
		{
			var diffuseColorReg:ShaderRegisterElement;
			var specularColorReg:ShaderRegisterElement;
			var lightDirReg:ShaderRegisterElement;
			var regIndex:int;
			var addSpec:Boolean = _usingSpecularMethod && usesLightsForSpecular();
			var addDiff:Boolean = usesLightsForDiffuse();

			if (!(addSpec || addDiff))
				return;

			for (var i:uint = 0; i < _numDirectionalLights; ++i)
			{
				lightDirReg = dirLightRegisters[regIndex++];
				diffuseColorReg = dirLightRegisters[regIndex++];
				specularColorReg = dirLightRegisters[regIndex++];
				if (addDiff)
					_fragmentCode += _methodSetup.diffuseMethod.getFragmentCodePerLight(_methodSetup.diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);
				if (addSpec)
					_fragmentCode += _methodSetup.specularMethod.getFragmentCodePerLight(_methodSetup.specularMethodVO, lightDirReg, specularColorReg, _registerCache);
			}
		}

		private function compilePointLightCode():void
		{
			var diffuseColorReg:ShaderRegisterElement;
			var specularColorReg:ShaderRegisterElement;
			var lightPosReg:ShaderRegisterElement;
			var lightDirReg:ShaderRegisterElement;
			var regIndex:int;
			var addSpec:Boolean = _usingSpecularMethod && usesLightsForSpecular();
			var addDiff:Boolean = usesLightsForDiffuse();

			if (!(addSpec || addDiff))
				return;

			for (var i:uint = 0; i < _numPointLights; ++i)
			{
				lightPosReg = pointLightRegisters[regIndex++];
				diffuseColorReg = pointLightRegisters[regIndex++];
				specularColorReg = pointLightRegisters[regIndex++];
				lightDirReg = _registerCache.getFreeFragmentVectorTemp();
				_registerCache.addFragmentTempUsages(lightDirReg, 1);

				// calculate attenuation
				_fragmentCode += "sub " + lightDirReg + ", " + lightPosReg + ", " + _sharedRegisters.globalPositionVarying + "\n" +
					// attenuate
					"dp3 " + lightDirReg + ".w, " + lightDirReg + ", " + lightDirReg + "\n" +
					// w = d - radis
					"sub " + lightDirReg + ".w, " + lightDirReg + ".w, " + diffuseColorReg + ".w\n" +
					// w = (d - radius)/(max-min)
					"mul " + lightDirReg + ".w, " + lightDirReg + ".w, " + specularColorReg + ".w\n" +
					// w = clamp(w, 0, 1)
					"sat " + lightDirReg + ".w, " + lightDirReg + ".w\n" +
					// w = 1-w
					"sub " + lightDirReg + ".w, " + lightPosReg + ".w, " + lightDirReg + ".w\n" +
					// normalize
					"nrm " + lightDirReg + ".xyz, " + lightDirReg + "\n";

				if (_lightFragmentConstantIndex == -1)
					_lightFragmentConstantIndex = lightPosReg.index * 4;

				if (addDiff)
					_fragmentCode += _methodSetup.diffuseMethod.getFragmentCodePerLight(_methodSetup.diffuseMethodVO, lightDirReg, diffuseColorReg, _registerCache);

				if (addSpec)
					_fragmentCode += _methodSetup.specularMethod.getFragmentCodePerLight(_methodSetup.specularMethodVO, lightDirReg, specularColorReg, _registerCache);

				_registerCache.removeFragmentTempUsage(lightDirReg);
			}
		}

		private function compileLightProbeCode():void
		{
			var weightReg:String;
			var weightComponents:Array = [".x", ".y", ".z", ".w"];
			var weightRegisters:Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>();
			var i:uint;
			var texReg:ShaderRegisterElement;
			var addSpec:Boolean = _usingSpecularMethod && usesProbesForSpecular();
			var addDiff:Boolean = usesProbesForDiffuse();

			if (!(addSpec || addDiff))
				return;

			if (addDiff)
				_lightProbeDiffuseIndices = new Vector.<uint>();
			if (addSpec)
				_lightProbeSpecularIndices = new Vector.<uint>();

			for (i = 0; i < _numProbeRegisters; ++i)
			{
				weightRegisters[i] = _registerCache.getFreeFragmentConstant();
				if (i == 0)
					_probeWeightsIndex = weightRegisters[i].index * 4;
			}

			for (i = 0; i < _numLightProbes; ++i)
			{
				weightReg = weightRegisters[Math.floor(i / 4)].toString() + weightComponents[i % 4];

				if (addDiff)
				{
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeDiffuseIndices[i] = texReg.index;
					_fragmentCode += _methodSetup.diffuseMethod.getFragmentCodePerProbe(_methodSetup.diffuseMethodVO, texReg, weightReg, _registerCache);
				}

				if (addSpec)
				{
					texReg = _registerCache.getFreeTextureReg();
					_lightProbeSpecularIndices[i] = texReg.index;
					_fragmentCode += _methodSetup.specularMethod.getFragmentCodePerProbe(_methodSetup.specularMethodVO, texReg, weightReg, _registerCache);
				}
			}
		}
	}
}
