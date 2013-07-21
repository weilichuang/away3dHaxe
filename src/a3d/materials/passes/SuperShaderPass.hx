package a3d.materials.passes;

import flash.display3D.Context3D;
import flash.display3D.Context3DProfile;
import flash.geom.ColorTransform;
import flash.geom.Vector3D;
import flash.Vector;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;
import a3d.materials.LightSources;
import a3d.materials.MaterialBase;
import a3d.materials.compilation.ShaderCompiler;
import a3d.materials.compilation.SuperShaderCompiler;
import a3d.materials.methods.ColorTransformMethod;
import a3d.materials.methods.EffectMethodBase;
import a3d.materials.methods.MethodVOSet;



/**
 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
 *
 * @see a3d.materials.methods.ShadingMethodBase
 */

class SuperShaderPass extends CompiledPass
{
	public var includeCasters(get,set):Bool;
	/**
	 * The ColorTransform object to transform the colour of the material with.
	 */
	public var colorTransform(get,set):ColorTransform;
	public var colorTransformMethod(get,set):ColorTransformMethod;
	public var numMethods(get,null):Int;
	public var ignoreLights(get, set):Bool;
	
	private var _includeCasters:Bool = true;
	private var _ignoreLights:Bool;

	/**
	 * Creates a new DefaultScreenPass objects.
	 */
	public function new(material:MaterialBase)
	{
		super(material);
		_needFragmentAnimation = true;
	}

	override private function createCompiler(profile:Context3DProfile):ShaderCompiler
	{
		return new SuperShaderCompiler(profile);
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

	
	private function get_colorTransform():ColorTransform
	{
		return _methodSetup.colorTransformMethod != null ? _methodSetup.colorTransformMethod.colorTransform : null;
	}

	private function set_colorTransform(value:ColorTransform):ColorTransform
	{
		if (value != null)
		{
			if (colorTransformMethod == null)
				colorTransformMethod = new ColorTransformMethod();
			_methodSetup.colorTransformMethod.colorTransform = value;
		}
		else if (value == null)
		{
			if (_methodSetup.colorTransformMethod != null)
				colorTransformMethod = null;
			colorTransformMethod = _methodSetup.colorTransformMethod = null;
		}
		return colorTransform;
	}

	
	private function get_colorTransformMethod():ColorTransformMethod
	{
		return _methodSetup.colorTransformMethod;
	}

	private function set_colorTransformMethod(value:ColorTransformMethod):ColorTransformMethod
	{
		return _methodSetup.colorTransformMethod = value;
	}

	/**
	 * Adds a shading method to the end of the shader. Note that shading methods can
	 * not be reused across materials.
	 */
	public function addMethod(method:EffectMethodBase):Void
	{
		_methodSetup.addMethod(method);
	}

	
	private function get_numMethods():Int
	{
		return _methodSetup.numMethods;
	}

	public function hasMethod(method:EffectMethodBase):Bool
	{
		return _methodSetup.hasMethod(method);
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return _methodSetup.getMethodAt(index);
	}

	/**
	 * Adds a shading method to the end of a shader, at the specified index amongst
	 * the methods in that section of the shader. Note that shading methods can not
	 * be reused across materials.
	 */
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		_methodSetup.addMethodAt(method, index);
	}

	public function removeMethod(method:EffectMethodBase):Void
	{
		_methodSetup.removeMethod(method);
	}

	override private function updateLights():Void
	{
//			super.updateLights();
		if (_lightPicker != null && !_ignoreLights)
		{
			_numPointLights = _lightPicker.numPointLights;
			_numDirectionalLights = _lightPicker.numDirectionalLights;
			_numLightProbes = _lightPicker.numLightProbes;

			if (_includeCasters)
			{
				_numPointLights += _lightPicker.numCastingPointLights;
				_numDirectionalLights += _lightPicker.numCastingDirectionalLights;
			}
		}
		else
		{
			_numPointLights = 0;
			_numDirectionalLights = 0;
			_numLightProbes = 0;
		}

		invalidateShaderProgram();
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		super.activate(stage3DProxy, camera);

		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.activate(_methodSetup.colorTransformMethodVO, stage3DProxy);

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:Int = methods.length;
		for (i in 0...len)
		{
			var mset:MethodVOSet = methods[i];
			mset.method.activate(mset.data, stage3DProxy);
		}

		if (_cameraPositionIndex >= 0)
		{
			var pos:Vector3D = camera.scenePosition;
			_vertexConstantData[_cameraPositionIndex] = pos.x;
			_vertexConstantData[_cameraPositionIndex + 1] = pos.y;
			_vertexConstantData[_cameraPositionIndex + 2] = pos.z;
		}
	}

	/**
	 * @inheritDoc
	 */
	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);

		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.deactivate(_methodSetup.colorTransformMethodVO, stage3DProxy);

		var mset:MethodVOSet;
		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:Int = methods.length;
		for (i in 0...len)
		{
			mset = methods[i];
			mset.method.deactivate(mset.data, stage3DProxy);
		}
	}

	override private function addPassesFromMethods():Void
	{
		super.addPassesFromMethods();

		if (_methodSetup.colorTransformMethod != null)
			addPasses(_methodSetup.colorTransformMethod.passes);

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		for (i in 0...methods.length)
			addPasses(methods[i].method.passes);
	}

	private function usesProbesForSpecular():Bool
	{
		return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
	}

	private function usesProbesForDiffuse():Bool
	{
		return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
	}

	override private function updateMethodConstants():Void
	{
		super.updateMethodConstants();
		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.initConstants(_methodSetup.colorTransformMethodVO);

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:Int = methods.length;
		for (i in 0...len)
		{
			methods[i].method.initConstants(methods[i].data);
		}
	}

	/**
	 * Updates the lights data for the render state.
	 * @param lights The lights selected to shade the current object.
	 * @param numLights The amount of lights available.
	 * @param maxLights The maximum amount of lights supported.
	 */
	override private function updateLightConstants():Void
	{
		// first dirs, then points
		var dirLight:DirectionalLight;
		var pointLight:PointLight;
		var i:Int, k:Int;
		var len:Int;
		var dirPos:Vector3D;
		var total:Int = 0;
		var numLightTypes:Int = _includeCasters ? 2 : 1;

		k = _lightFragmentConstantIndex;

		for (c in 0...numLightTypes)
		{
			var dirLights:Vector<DirectionalLight> = (c != 0) ? _lightPicker.castingDirectionalLights : _lightPicker.directionalLights;
			len = dirLights.length;
			total += len;

			for (i in 0...len)
			{
				dirLight = dirLights[i];
				dirPos = dirLight.sceneDirection;

				_ambientLightR += dirLight.ambientR;
				_ambientLightG += dirLight.ambientG;
				_ambientLightB += dirLight.ambientB;

				_fragmentConstantData[k++] = -dirPos.x;
				_fragmentConstantData[k++] = -dirPos.y;
				_fragmentConstantData[k++] = -dirPos.z;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight.diffuseR;
				_fragmentConstantData[k++] = dirLight.diffuseG;
				_fragmentConstantData[k++] = dirLight.diffuseB;
				_fragmentConstantData[k++] = 1;

				_fragmentConstantData[k++] = dirLight.specularR;
				_fragmentConstantData[k++] = dirLight.specularG;
				_fragmentConstantData[k++] = dirLight.specularB;
				_fragmentConstantData[k++] = 1;
			}
		}

		// more directional supported than currently picked, need to clamp all to 0
		if (_numDirectionalLights > total)
		{
			i = k + (_numDirectionalLights - total) * 12;
			while (k < i)
				_fragmentConstantData[k++] = 0;
		}

		total = 0;
		for (c in 0...numLightTypes)
		{
			var pointLights:Vector<PointLight> = (c != 0) ? _lightPicker.castingPointLights : _lightPicker.pointLights;
			len = pointLights.length;
			for (i in 0...len)
			{
				pointLight = pointLights[i];
				dirPos = pointLight.scenePosition;

				_ambientLightR += pointLight.ambientR;
				_ambientLightG += pointLight.ambientG;
				_ambientLightB += pointLight.ambientB;

				_fragmentConstantData[k++] = dirPos.x;
				_fragmentConstantData[k++] = dirPos.y;
				_fragmentConstantData[k++] = dirPos.z;
				_fragmentConstantData[k++] = 1;

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
		var probe:LightProbe;
		var lightProbes:Vector<LightProbe> = _lightPicker.lightProbes;
		var weights:Vector<Float> = _lightPicker.lightProbeWeights;
		var len:Int = lightProbes.length;
		var addDiff:Bool = usesProbesForDiffuse();
		var addSpec:Bool = (_methodSetup.specularMethod != null && usesProbesForSpecular());
		var context:Context3D = stage3DProxy.context3D;

		if (!(addDiff || addSpec))
			return;

		for (i in 0...len)
		{
			probe = lightProbes[i];

			if (addDiff)
				context.setTextureAt(_lightProbeDiffuseIndices[i], probe.diffuseMap.getTextureForStage3D(stage3DProxy));
			if (addSpec)
				context.setTextureAt(_lightProbeSpecularIndices[i], probe.specularMap.getTextureForStage3D(stage3DProxy));
		}

		_fragmentConstantData[_probeWeightsIndex] = weights[0];
		_fragmentConstantData[_probeWeightsIndex + 1] = weights[1];
		_fragmentConstantData[_probeWeightsIndex + 2] = weights[2];
		_fragmentConstantData[_probeWeightsIndex + 3] = weights[3];
	}

	
	private function set_ignoreLights(ignoreLights:Bool):Bool
	{
		return _ignoreLights = ignoreLights;
	}

	private function get_ignoreLights():Bool
	{
		return _ignoreLights;
	}
}
