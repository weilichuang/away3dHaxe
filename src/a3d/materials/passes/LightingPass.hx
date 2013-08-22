package a3d.materials.passes;

import a3d.core.base.IRenderable;
import a3d.core.managers.Context3DProxy;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;
import a3d.materials.compilation.LightingShaderCompiler;
import a3d.materials.compilation.ShaderCompiler;
import a3d.materials.LightSources;
import a3d.materials.MaterialBase;
import a3d.math.FMath;
import flash.display3D.Context3DProfile;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;


/**
 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
 *
 * @see a3d.materials.methods.ShadingMethodBase
 */

class LightingPass extends CompiledPass
{
	// these need to be set before the light picker is assigned
	public var directionalLightsOffset(get,set):Int;
	public var pointLightsOffset(get,set):Int;
	public var lightProbesOffset(get,set):Int;
	public var includeCasters(get, set):Bool;
	
	private var _includeCasters:Bool = true;
	private var _tangentSpace:Bool;
	private var _lightVertexConstantIndex:Int;
	private var _inverseSceneMatrix:Vector<Float>;

	private var _directionalLightsOffset:Int;
	private var _pointLightsOffset:Int;
	private var _lightProbesOffset:Int;
	private var _maxLights:Int = 3;

	/**
	 * Creates a new LightingPass objects.
	 */
	public function new(material:MaterialBase)
	{
		super(material);
		_inverseSceneMatrix = new Vector<Float>();
	}

	
	private function get_directionalLightsOffset():Int
	{
		return _directionalLightsOffset;
	}

	private function set_directionalLightsOffset(value:UInt):Int
	{
		return _directionalLightsOffset = value;
	}

	
	private function get_pointLightsOffset():Int
	{
		return _pointLightsOffset;
	}

	private function set_pointLightsOffset(value:Int):Int
	{
		return _pointLightsOffset = value;
	}

	
	private function get_lightProbesOffset():Int
	{
		return _lightProbesOffset;
	}

	private function set_lightProbesOffset(value:Int):Int
	{
		return _lightProbesOffset = value;
	}

	override private function createCompiler(profile:Context3DProfile):ShaderCompiler
	{
		_maxLights = profile == Context3DProfile.BASELINE_CONSTRAINED ? 1 : 3;
		return new LightingShaderCompiler(profile);
	}

	
	private function get_includeCasters():Bool
	{
		return _includeCasters;
	}

	private function set_includeCasters(value:Bool):Bool
	{
		if (_includeCasters == value)
			return _includeCasters;
		_includeCasters = value;
		invalidateShaderProgram();
		return _includeCasters;
	}

	override private function updateLights():Void
	{
		super.updateLights();
		
		var numDirectionalLights:Int = 0;
		var numPointLights:Int = 0;
		var numLightProbes:Int = 0;

		if (_lightPicker != null)
		{
			numDirectionalLights = calculateNumDirectionalLights(_lightPicker.numDirectionalLights);
			numPointLights = calculateNumPointLights(_lightPicker.numPointLights);
			numLightProbes = calculateNumProbes(_lightPicker.numLightProbes);
			
			if (_includeCasters)
			{
				numPointLights += _lightPicker.numCastingPointLights;
				numDirectionalLights += _lightPicker.numCastingDirectionalLights;
			}
		}

		if (numPointLights != _numPointLights ||
			numDirectionalLights != _numDirectionalLights ||
			numLightProbes != _numLightProbes)
		{
			_numPointLights = numPointLights;
			_numDirectionalLights = numDirectionalLights;
			_numLightProbes = numLightProbes;
			invalidateShaderProgram();
		}

	}

	private function calculateNumDirectionalLights(numDirectionalLights:Int):Int
	{
		return FMath.min(numDirectionalLights - _directionalLightsOffset, _maxLights);
	}

	private function calculateNumPointLights(numPointLights:Int):Int
	{
		var numFree:Int = _maxLights - _numDirectionalLights;
		return FMath.min(numPointLights - _pointLightsOffset, numFree);
	}

	private function calculateNumProbes(numLightProbes:Int):Int
	{
		var numChannels:Int = 0;
		if ((_specularLightSources & LightSources.PROBES) != 0)
			++numChannels;
		if ((_diffuseLightSources & LightSources.PROBES) != 0)
			++numChannels;

		// 4 channels available
		return FMath.min(numLightProbes - _lightProbesOffset, Std.int(4 / numChannels));
	}

	override private function updateShaderProperties():Void
	{
		super.updateShaderProperties();
		_tangentSpace = Std.instance(_compiler,LightingShaderCompiler).tangentSpace;
	}

	override private function updateRegisterIndices():Void
	{
		super.updateRegisterIndices();
		_lightVertexConstantIndex = Std.instance(_compiler,LightingShaderCompiler).lightVertexConstantIndex;
	}


	override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		renderable.inverseSceneTransform.copyRawDataTo(_inverseSceneMatrix);

		if (_tangentSpace && _cameraPositionIndex >= 0)
		{
			var pos:Vector3D = camera.scenePosition;
			var x:Float = pos.x;
			var y:Float = pos.y;
			var z:Float = pos.z;
			_vertexConstantData[_cameraPositionIndex] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z + _inverseSceneMatrix[12];
			_vertexConstantData[_cameraPositionIndex + 1] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z + _inverseSceneMatrix[13];
			_vertexConstantData[_cameraPositionIndex + 2] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z + _inverseSceneMatrix[14];
		}

		super.render(renderable, stage3DProxy, camera, viewProjection);
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
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

	private function usesProbesForSpecular():Bool
	{
		return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
	}

	private function usesProbesForDiffuse():Bool
	{
		return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
	}

	/*
	 * Updates the lights data for the render state.
	 * @param lights The lights selected to shade the current object.
	 * @param numLights The amount of lights available.
	 * @param maxLights The maximum amount of lights supported.
	 */
	override private function updateLightConstants():Void
	{
		var dirLight:DirectionalLight;
		var pointLight:PointLight;
		var i:Int, k:Int;
		var len:Int;
		var dirPos:Vector3D;
		var total:Int = 0;
		var numLightTypes:Int = _includeCasters ? 2 : 1;
		var l:Int;
		var offset:Int;

		l = _lightVertexConstantIndex;
		k = _lightFragmentConstantIndex;

		var c:Int = 0;
		var dirLights:Vector<DirectionalLight> = _lightPicker.directionalLights;
		offset = _directionalLightsOffset;
		len = _lightPicker.directionalLights.length;
		if (offset > len)
		{
			c = 1;
			offset -= len;
		}

		while (c < numLightTypes)
		{
			if (c != 0)
				dirLights = _lightPicker.castingDirectionalLights;
			len = dirLights.length;
			if (len > _numDirectionalLights)
				len = _numDirectionalLights;
			for (i in 0...len)
			{
				dirLight = dirLights[offset + i];
				dirPos = dirLight.sceneDirection;

				_ambientLightR += dirLight.ambientR;
				_ambientLightG += dirLight.ambientG;
				_ambientLightB += dirLight.ambientB;

				if (_tangentSpace)
				{
					var x:Float = -dirPos.x;
					var y:Float = -dirPos.y;
					var z:Float = -dirPos.z;
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

				if (++total == _numDirectionalLights)
				{
					c = numLightTypes;
					// break loop
					break;
				}
			}
			++c;
		}

		// more directional supported than currently picked, need to clamp all to 0
		if (_numDirectionalLights > total)
		{
			i = k + (_numDirectionalLights - total) * 12;
			while (k < i)
				_fragmentConstantData[k++] = 0;
		}

		total = 0;

		var pointLights:Vector<PointLight> = _lightPicker.pointLights;
		offset = _pointLightsOffset;
		len = _lightPicker.pointLights.length;
		if (offset > len)
		{
			c = 1;
			offset -= len;
		}
		else
			c = 0;
		while (c < numLightTypes)
		{
			if (c != 0)
				pointLights = _lightPicker.castingPointLights;
			len = pointLights.length;
			for (i in 0...len)
			{
				pointLight = pointLights[offset + i];
				dirPos = pointLight.scenePosition;

				_ambientLightR += pointLight.ambientR;
				_ambientLightG += pointLight.ambientG;
				_ambientLightB += pointLight.ambientB;

				if (_tangentSpace)
				{
					var x:Float = dirPos.x;
					var y:Float = dirPos.y;
					var z:Float = dirPos.z;
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
				var radius:Float = pointLight.radius;
				_fragmentConstantData[k++] = radius * radius;

				_fragmentConstantData[k++] = pointLight.specularR;
				_fragmentConstantData[k++] = pointLight.specularG;
				_fragmentConstantData[k++] = pointLight.specularB;
				_fragmentConstantData[k++] = pointLight.fallOffFactor;

				if (++total == _numPointLights)
				{
					c = numLightTypes;
					// break loop
					break;
				}
			}
			++c;
		}

		// more directional supported than currently picked, need to clamp all to 0
		if (_numPointLights > total)
		{
			i = k + (total - _numPointLights) * 12;
			while (k < i)
			{
				_fragmentConstantData[k] = 0;
				++k;
			}
		}
	}

	override private function updateProbes(stage3DProxy:Stage3DProxy):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;
		var probe:LightProbe;
		var lightProbes:Vector<LightProbe> = _lightPicker.lightProbes;
		var weights:Vector<Float> = _lightPicker.lightProbeWeights;
		var len:Int = lightProbes.length - _lightProbesOffset;
		var addDiff:Bool = usesProbesForDiffuse();
		var addSpec:Bool = (_methodSetup.specularMethod != null && usesProbesForSpecular());

		if (!(addDiff || addSpec))
			return;

		if (len > _numLightProbes)
			len = _numLightProbes;

		for (i in 0...len)
		{
			probe = lightProbes[_lightProbesOffset + i];

			if (addDiff)
				context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
			if (addSpec)
				context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
		}

		for (i in 0...len)
			_fragmentConstantData[_probeWeightsIndex + i] = weights[_lightProbesOffset + i];
	}
}
