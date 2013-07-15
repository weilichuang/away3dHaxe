package a3d.materials.compilation;


import a3d.materials.LightSources;
import a3d.materials.methods.EffectMethodBase;
import a3d.materials.methods.MethodVO;
import a3d.materials.methods.MethodVOSet;
import a3d.materials.methods.ShaderMethodSetup;
import a3d.materials.methods.ShadingMethodBase;
import flash.display3D.Context3DProfile;
import flash.Vector;
import flash.Vector;

/**
 * ShaderCompiler is an abstract base class for shader compilers that use modular shader methods to assemble a
 * material. Concrete subclasses are used by the default materials.
 *
 * @see away3d.materials.methods.ShadingMethodBase
 */
class ShaderCompiler
{
	private var _sharedRegisters:ShaderRegisterData;
	private var _registerCache:ShaderRegisterCache;
	private var _dependencyCounter:MethodDependencyCounter;
	private var _methodSetup:ShaderMethodSetup;

	private var _smooth:Bool;
	private var _repeat:Bool;
	private var _mipmap:Bool;
	private var _enableLightFallOff:Bool;
	private var _preserveAlpha:Bool = true;
	private var _animateUVs:Bool;
	private var _alphaPremultiplied:Bool;
	private var _vertexConstantData:Vector<Float>;
	private var _fragmentConstantData:Vector<Float>;

	private var _vertexCode:String;
	private var _fragmentCode:String;
	private var _fragmentLightCode:String;
	private var _fragmentPostLightCode:String;
	private var _commonsDataIndex:Int = -1;

	private var _animatableAttributes:Vector<String>;
	private var _animationTargetRegisters:Vector<String>;

	private var _lightProbeDiffuseIndices:Vector<UInt>;
	private var _lightProbeSpecularIndices:Vector<UInt>;
	private var _uvBufferIndex:Int = -1;
	private var _uvTransformIndex:Int = -1;
	private var _secondaryUVBufferIndex:Int = -1;
	private var _normalBufferIndex:Int = -1;
	private var _tangentBufferIndex:Int = -1;
	private var _lightFragmentConstantIndex:Int = -1;
	private var _sceneMatrixIndex:Int = -1;
	private var _sceneNormalMatrixIndex:Int = -1;
	private var _cameraPositionIndex:Int = -1;
	private var _probeWeightsIndex:Int = -1;

	private var _specularLightSources:Int;
	private var _diffuseLightSources:Int;

	private var _numLights:Int;
	private var _numLightProbes:Int;
	private var _numPointLights:Int;
	private var _numDirectionalLights:Int;

	private var _numProbeRegisters:Int;
	private var _combinedLightSources:Int;

	private var _usingSpecularMethod:Bool;

	private var _needUVAnimation:Bool;
	private var _UVTarget:String;
	private var _UVSource:String;

	private var _profile:Context3DProfile;

	private var _forceSeperateMVP:Bool;


	/**
	 * Creates a new ShaderCompiler object.
	 * @param profile The compatibility profile of the renderer.
	 */
	public function new(profile:Context3DProfile)
	{
		_sharedRegisters = new ShaderRegisterData();
		_dependencyCounter = new MethodDependencyCounter();
		_profile = profile;
		initRegisterCache(profile);
	}

	/**
	 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
	 * compatibility for constrained mode.
	 */
	public var enableLightFallOff(get,set):Bool;
	private function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}

	private function set_enableLightFallOff(value:Bool):Bool
	{
		return _enableLightFallOff = value;
	}

	/**
	 * Indicates whether the compiled code needs UV animation.
	 */
	public var needUVAnimation(get,null):Bool;
	private function get_needUVAnimation():Bool
	{
		return _needUVAnimation;
	}

	/**
	 * The target register to place the animated UV coordinate.
	 */
	public var UVTarget(get,null):String;
	private function get_UVTarget():String
	{
		return _UVTarget;
	}

	/**
	 * The souce register providing the UV coordinate to animate.
	 */
	public var UVSource(get,null):String;
	private function get_UVSource():String
	{
		return _UVSource;
	}

	/**
	 * Indicates whether the screen projection should be calculated by forcing a separate scene matrix and
	 * view-projection matrix. This is used to prevent rounding errors when using multiple passes with different
	 * projection code.
	 */
	public var forceSeperateMVP(get,set):Bool;
	private function get_forceSeperateMVP():Bool
	{
		return _forceSeperateMVP;
	}

	private function set_forceSeperateMVP(value:Bool):Bool
	{
		return _forceSeperateMVP = value;
	}

	/**
	 * Initialized the register cache.
	 * @param profile The compatibility profile of the renderer.
	 */
	private function initRegisterCache(profile:Context3DProfile):Void
	{
		_registerCache = new ShaderRegisterCache(profile);
		_registerCache.vertexAttributesOffset = 1;
		_registerCache.reset();
	}

	public var animateUVs(get,set):Bool;
	private function get_animateUVs():Bool
	{
		return _animateUVs;
	}

	private function set_animateUVs(value:Bool):Bool
	{
		return _animateUVs = value;
	}

	/**
	 * Indicates whether visible textures (or other pixels) used by this material have
	 * already been premultiplied.
	 */
	public var alphaPremultiplied(get,set):Bool;
	private function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}

	private function set_alphaPremultiplied(value:Bool):Bool
	{
		return _alphaPremultiplied = value;
	}

	/**
	 * Indicates whether the output alpha value should remain unchanged compared to the material's original alpha.
	 */
	public var preserveAlpha(get,set):Bool;
	private function get_preserveAlpha():Bool
	{
		return _preserveAlpha;
	}

	private function set_preserveAlpha(value:Bool):Bool
	{
		return _preserveAlpha = value;
	}

	/**
	 * Sets the default texture sampling properties.
	 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
	 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
	 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
	 */
	public function setTextureSampling(smooth:Bool, repeat:Bool, mipmap:Bool):Void
	{
		_smooth = smooth;
		_repeat = repeat;
		_mipmap = mipmap;
	}

	/**
	 * Sets the constant buffers allocated by the material. This allows setting constant data during compilation.
	 * @param vertexConstantData The vertex constant data buffer.
	 * @param fragmentConstantData The fragment constant data buffer.
	 */
	public function setConstantDataBuffers(vertexConstantData:Vector<Float>, fragmentConstantData:Vector<Float>):Void
	{
		_vertexConstantData = vertexConstantData;
		_fragmentConstantData = fragmentConstantData;
	}

	/**
	 * The shader method setup object containing the method configuration and their value objects for the material being compiled.
	 */
	public var methodSetup(get,set):ShaderMethodSetup;
	private function get_methodSetup():ShaderMethodSetup
	{
		return _methodSetup;
	}

	private function set_methodSetup(value:ShaderMethodSetup):ShaderMethodSetup
	{
		return _methodSetup = value;
	}

	/**
	 * Compiles the code after all setup on the compiler has finished.
	 */
	public function compile():Void
	{
		initRegisterIndices();
		initLightData();

		_animatableAttributes = Vector.ofArray(["va0"]);
		_animationTargetRegisters = Vector.ofArray(["vt0"]);
		_vertexCode = "";
		_fragmentCode = "";

		_sharedRegisters.localPosition = _registerCache.getFreeVertexVectorTemp();
		_registerCache.addVertexTempUsages(_sharedRegisters.localPosition, 1);

		createCommons();
		calculateDependencies();
		updateMethodRegisters();

		for (i in 0...4)
			_registerCache.getFreeVertexConstant();

		createNormalRegisters();
		if (_dependencyCounter.globalPosDependencies > 0 || _forceSeperateMVP)
			compileGlobalPositionCode();
		compileProjectionCode();
		compileMethodsCode();
		compileFragmentOutput();
		_fragmentPostLightCode = fragmentCode;
	}

	/**
	 * Creates the registers to contain the normal data.
	 */
	private function createNormalRegisters():Void
	{

	}

	/**
	 * Compile the code for the methods.
	 */
	private function compileMethodsCode():Void
	{
		if (_dependencyCounter.uvDependencies > 0)
			compileUVCode();
		if (_dependencyCounter.secondaryUVDependencies > 0)
			compileSecondaryUVCode();
		if (_dependencyCounter.normalDependencies > 0)
			compileNormalCode();
		if (_dependencyCounter.viewDirDependencies > 0)
			compileViewDirCode();
		compileLightingCode();
		_fragmentLightCode = _fragmentCode;
		_fragmentCode = "";
		compileMethods();
	}

	/**
	 * Compile the lighting code.
	 */
	private function compileLightingCode():Void
	{

	}

	/**
	 * Calculate the view direction.
	 */
	private function compileViewDirCode():Void
	{

	}

	/**
	 * Calculate the normal.
	 */
	private function compileNormalCode():Void
	{

	}

	/**
	 * Calculate the (possibly animated) UV coordinates.
	 */
	private function compileUVCode():Void
	{
		var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
		_uvBufferIndex = uvAttributeReg.index;

		var varying:ShaderRegisterElement = _registerCache.getFreeVarying();

		_sharedRegisters.uvVarying = varying;

		if (animateUVs)
		{
			// a, b, 0, tx
			// c, d, 0, ty
			var uvTransform1:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			var uvTransform2:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			_uvTransformIndex = uvTransform1.index * 4;

			_vertexCode += "dp4 " + varying + ".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
				"dp4 " + varying + ".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
				"mov " + varying + ".zw, " + uvAttributeReg + ".zw \n";
		}
		else
		{
			_uvTransformIndex = -1;
			_needUVAnimation = true;
			_UVTarget = varying.toString();
			_UVSource = uvAttributeReg.toString();
		}
	}

	/**
	 * Provide the secondary UV coordinates.
	 */
	private function compileSecondaryUVCode():Void
	{
		var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
		_secondaryUVBufferIndex = uvAttributeReg.index;
		_sharedRegisters.secondaryUVVarying = _registerCache.getFreeVarying();
		_vertexCode += "mov " + _sharedRegisters.secondaryUVVarying + ", " + uvAttributeReg + "\n";
	}

	/**
	 * Compile the world-space position.
	 */
	private function compileGlobalPositionCode():Void
	{
		_sharedRegisters.globalPositionVertex = _registerCache.getFreeVertexVectorTemp();
		_registerCache.addVertexTempUsages(_sharedRegisters.globalPositionVertex, _dependencyCounter.globalPosDependencies);
		var positionMatrixReg:ShaderRegisterElement = _registerCache.getFreeVertexConstant();
		_registerCache.getFreeVertexConstant();
		_registerCache.getFreeVertexConstant();
		_registerCache.getFreeVertexConstant();
		_sceneMatrixIndex = positionMatrixReg.index * 4;

		_vertexCode += "m44 " + _sharedRegisters.globalPositionVertex + ", " + _sharedRegisters.localPosition + ", " + positionMatrixReg + "\n";

		if (_dependencyCounter.usesGlobalPosFragment)
		{
			_sharedRegisters.globalPositionVarying = _registerCache.getFreeVarying();
			_vertexCode += "mov " + _sharedRegisters.globalPositionVarying + ", " + _sharedRegisters.globalPositionVertex + "\n";
		}
	}

	/**
	 * Get the projection coordinates.
	 */
	private function compileProjectionCode():Void
	{
		var pos:String = _dependencyCounter.globalPosDependencies > 0 || _forceSeperateMVP ? _sharedRegisters.globalPositionVertex.toString() : _animationTargetRegisters[0];
		var code:String;

		if (_dependencyCounter.projectionDependencies > 0)
		{
			_sharedRegisters.projectionFragment = _registerCache.getFreeVarying();
			code = "m44 vt5, " + pos + ", vc0		\n" +
				"mov " + _sharedRegisters.projectionFragment + ", vt5\n" +
				"mov op, vt5\n";
		}
		else
		{
			code = "m44 op, " + pos + ", vc0		\n";
		}

		_vertexCode += code;
	}

	/**
	 * Assign the final output colour the the output register.
	 */
	private function compileFragmentOutput():Void
	{
		_fragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _sharedRegisters.shadedTarget + "\n";
		_registerCache.removeFragmentTempUsage(_sharedRegisters.shadedTarget);
	}

	/**
	 * Reset all the indices to "unused".
	 */
	private function initRegisterIndices():Void
	{
		_commonsDataIndex = -1;
		_cameraPositionIndex = -1;
		_uvBufferIndex = -1;
		_uvTransformIndex = -1;
		_secondaryUVBufferIndex = -1;
		_normalBufferIndex = -1;
		_tangentBufferIndex = -1;
		_lightFragmentConstantIndex = -1;
		_sceneMatrixIndex = -1;
		_sceneNormalMatrixIndex = -1;
		_probeWeightsIndex = -1;
	}

	/**
	 * Prepares the setup for the light code.
	 */
	private function initLightData():Void
	{
		_numLights = _numPointLights + _numDirectionalLights;
		_numProbeRegisters = Math.ceil(_numLightProbes / 4);

		if (_methodSetup.specularMethod != null)
			_combinedLightSources = _specularLightSources | _diffuseLightSources;
		else
			_combinedLightSources = _diffuseLightSources;

		_usingSpecularMethod = (_methodSetup.specularMethod != null && (
			usesLightsForSpecular() ||
			usesProbesForSpecular()));
	}

	/**
	 * Create the commonly shared constant register.
	 */
	private function createCommons():Void
	{
		_sharedRegisters.commons = _registerCache.getFreeFragmentConstant();
		_commonsDataIndex = _sharedRegisters.commons.index * 4;
	}

	/**
	 * Figure out which named registers are required, and how often.
	 */
	private function calculateDependencies():Void
	{
		_dependencyCounter.reset();

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:UInt;

		setupAndCountMethodDependencies(_methodSetup.diffuseMethod, _methodSetup.diffuseMethodVO);
		if (_methodSetup.shadowMethod != null)
			setupAndCountMethodDependencies(_methodSetup.shadowMethod, _methodSetup.shadowMethodVO);
		setupAndCountMethodDependencies(_methodSetup.ambientMethod, _methodSetup.ambientMethodVO);
		if (_usingSpecularMethod)
			setupAndCountMethodDependencies(_methodSetup.specularMethod, _methodSetup.specularMethodVO);
		if (_methodSetup.colorTransformMethod != null)
			setupAndCountMethodDependencies(_methodSetup.colorTransformMethod, _methodSetup.colorTransformMethodVO);

		len = methods.length;
		for (i in 0...len)
			setupAndCountMethodDependencies(methods[i].method, methods[i].data);

		if (usesNormals)
			setupAndCountMethodDependencies(_methodSetup.normalMethod, _methodSetup.normalMethodVO);

		// todo: add spotlights to count check
		_dependencyCounter.setPositionedLights(_numPointLights, _combinedLightSources);
	}

	/**
	 * Counts the dependencies for a given method.
	 * @param method The method to count the dependencies for.
	 * @param methodVO The method's data for this material.
	 */
	private function setupAndCountMethodDependencies(method:ShadingMethodBase, methodVO:MethodVO):Void
	{
		setupMethod(method, methodVO);
		_dependencyCounter.includeMethodVO(methodVO);
	}

	/**
	 * Assigns all prerequisite data for the methods, so we can calculate dependencies for them.
	 */
	private function setupMethod(method:ShadingMethodBase, methodVO:MethodVO):Void
	{
		method.reset();
		methodVO.reset();
		methodVO.vertexData = _vertexConstantData;
		methodVO.fragmentData = _fragmentConstantData;
		methodVO.useSmoothTextures = _smooth;
		methodVO.repeatTextures = _repeat;
		methodVO.useMipmapping = _mipmap;
		methodVO.useLightFallOff = _enableLightFallOff && _profile != Context3DProfile.BASELINE_CONSTRAINED;
		methodVO.numLights = _numLights + _numLightProbes;
		method.initVO(methodVO);
	}

	/**
	 * The index for the common data register.
	 */
	public var commonsDataIndex(get,null):Int;
	private function get_commonsDataIndex():Int
	{
		return _commonsDataIndex;
	}

	/**
	 * Assigns the shared register data to all methods.
	 */
	private function updateMethodRegisters():Void
	{
		_methodSetup.normalMethod.sharedRegisters = _sharedRegisters;
		_methodSetup.diffuseMethod.sharedRegisters = _sharedRegisters;
		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.sharedRegisters = _sharedRegisters;
		_methodSetup.ambientMethod.sharedRegisters = _sharedRegisters;
		if (_methodSetup.specularMethod != null)
			_methodSetup.specularMethod.sharedRegisters = _sharedRegisters;
		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.sharedRegisters = _sharedRegisters;

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:Int = methods.length;
		for (i in 0...len)
			methods[i].method.sharedRegisters = _sharedRegisters;
	}

	/**
	 * The amount of vertex constants used by the material. Any animation code to be added can append its vertex
	 * constant data after this.
	 */
	public var numUsedVertexConstants(get,null):UInt;
	private function get_numUsedVertexConstants():UInt
	{
		return _registerCache.numUsedVertexConstants;
	}

	/**
	 * The amount of fragment constants used by the material. Any animation code to be added can append its vertex
	 * constant data after this.
	 */
	public var numUsedFragmentConstants(get,null):UInt;
	private function get_numUsedFragmentConstants():UInt
	{
		return _registerCache.numUsedFragmentConstants;
	}

	/**
	 * The amount of vertex attribute streams used by the material. Any animation code to be added can add its
	 * streams after this. Also used to automatically disable attribute slots on pass deactivation.
	 */
	public var numUsedStreams(get,null):UInt;
	private function get_numUsedStreams():UInt
	{
		return _registerCache.numUsedStreams;
	}

	/**
	 * The amount of textures used by the material. Used to automatically disable texture slots on pass deactivation.
	 */
	public var numUsedTextures(get,null):UInt;
	private function get_numUsedTextures():UInt
	{
		return _registerCache.numUsedTextures;
	}

	/**
	 * Number of used varyings. Any animation code to be added can add its used varyings after this.
	 */
	public var numUsedVaryings(get,null):UInt;
	private function get_numUsedVaryings():UInt
	{
		return _registerCache.numUsedVaryings;
	}

	/**
	 * Indicates whether lights are used for specular reflections.
	 */
	private function usesLightsForSpecular():Bool
	{
		return _numLights > 0 && (_specularLightSources & LightSources.LIGHTS) != 0;
	}

	/**
	 * Indicates whether lights are used for diffuse reflections.
	 */
	private function usesLightsForDiffuse():Bool
	{
		return _numLights > 0 && (_diffuseLightSources & LightSources.LIGHTS) != 0;
	}

	/**
	 * Disposes all resources used by the compiler.
	 */
	public function dispose():Void
	{
		cleanUpMethods();
		_registerCache.dispose();
		_registerCache = null;
		_sharedRegisters = null;
	}

	/**
	 * Clean up method's compilation data after compilation finished.
	 */
	private function cleanUpMethods():Void
	{
		if (_methodSetup.normalMethod != null)
			_methodSetup.normalMethod.cleanCompilationData();
		if (_methodSetup.diffuseMethod != null)
			_methodSetup.diffuseMethod.cleanCompilationData();
		if (_methodSetup.ambientMethod != null)
			_methodSetup.ambientMethod.cleanCompilationData();
		if (_methodSetup.specularMethod != null)
			_methodSetup.specularMethod.cleanCompilationData();
		if (_methodSetup.shadowMethod != null)
			_methodSetup.shadowMethod.cleanCompilationData();
		if (_methodSetup.colorTransformMethod != null)
			_methodSetup.colorTransformMethod.cleanCompilationData();

		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var len:UInt = methods.length;
		for (i in 0...len)
			methods[i].method.cleanCompilationData();
	}


	/**
	 * Define which light source types to use for specular reflections. This allows choosing between regular lights
	 * and/or light probes for specular reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	public var specularLightSources(get,set):UInt;
	private function get_specularLightSources():UInt
	{
		return _specularLightSources;
	}

	private function set_specularLightSources(value:UInt):UInt
	{
		return _specularLightSources = value;
	}

	/**
	 * Define which light source types to use for diffuse reflections. This allows choosing between regular lights
	 * and/or light probes for diffuse reflections.
	 *
	 * @see away3d.materials.LightSources
	 */
	public var diffuseLightSources(get,set):UInt;
	private function get_diffuseLightSources():UInt
	{
		return _diffuseLightSources;
	}

	private function set_diffuseLightSources(value:UInt):UInt
	{
		return _diffuseLightSources = value;
	}

	/**
	 * Indicates whether light probes are being used for specular reflections.
	 */
	private function usesProbesForSpecular():Bool
	{
		return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
	}

	/**
	 * Indicates whether light probes are being used for diffuse reflections.
	 */
	private function usesProbesForDiffuse():Bool
	{
		return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
	}

	/**
	 * Indicates whether any light probes are used.
	 */
	private function usesProbes():Bool
	{
		return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
	}

	/**
	 * The index for the UV vertex attribute stream.
	 */
	public var uvBufferIndex(get,null):Int;
	private function get_uvBufferIndex():Int
	{
		return _uvBufferIndex;
	}

	/**
	 * The index for the UV transformation matrix vertex constant.
	 */
	public var uvTransformIndex(get,null):Int;
	private function get_uvTransformIndex():Int
	{
		return _uvTransformIndex;
	}

	/**
	 * The index for the secondary UV vertex attribute stream.
	 */
	public var secondaryUVBufferIndex(get,null):Int;
	private function get_secondaryUVBufferIndex():Int
	{
		return _secondaryUVBufferIndex;
	}
	
	/**
	 * The index for the vertex normal attribute stream.
	 */
	public var normalBufferIndex(get,null):Int;
	private function get_normalBufferIndex():Int
	{
		return _normalBufferIndex;
	}
	
	/**
	 * The index for the vertex tangent attribute stream.
	 */
	public var tangentBufferIndex(get,null):Int;
	private function get_tangentBufferIndex():Int
	{
		return _tangentBufferIndex;
	}

	/**
	 * The first index for the fragment constants containing the light data.
	 */
	public var lightFragmentConstantIndex(get,null):Int;
	private function get_lightFragmentConstantIndex():Int
	{
		return _lightFragmentConstantIndex;
	}

	/**
	 * The index of the vertex constant containing the camera position.
	 */
	public var cameraPositionIndex(get,null):Int;
	private function get_cameraPositionIndex():Int
	{
		return _cameraPositionIndex;
	}

	/**
	 * The index of the vertex constant containing the scene matrix.
	 */
	public var sceneMatrixIndex(get,null):Int;
	private function get_sceneMatrixIndex():Int
	{
		return _sceneMatrixIndex;
	}

	/**
	 * The index of the vertex constant containing the uniform scene matrix (the inverse transpose).
	 */
	public var sceneNormalMatrixIndex(get,null):Int;
	private function get_sceneNormalMatrixIndex():Int
	{
		return _sceneNormalMatrixIndex;
	}

	/**
	 * The index of the fragment constant containing the weights for the light probes.
	 */
	public var probeWeightsIndex(get,null):Int;
	private function get_probeWeightsIndex():Int
	{
		return _probeWeightsIndex;
	}

	/**
	 * The generated vertex code.
	 */
	public var vertexCode(get,null):String;
	private function get_vertexCode():String
	{
		return _vertexCode;
	}

	/**
	 * The generated fragment code.
	 */
	public var fragmentCode(get,null):String;
	private function get_fragmentCode():String
	{
		return _fragmentCode;
	}

	/**
	 * The code containing the lighting calculations.
	 */
	public var fragmentLightCode(get,null):String;
	private function get_fragmentLightCode():String
	{
		return _fragmentLightCode;
	}

	/**
	 * The code containing the post-lighting calculations.
	 */
	public var fragmentPostLightCode(get,null):String;
	private function get_fragmentPostLightCode():String
	{
		return _fragmentPostLightCode;
	}

	/**
	 * The register name containing the final shaded colour.
	 */
	public var shadedTarget(get,null):String;
	private function get_shadedTarget():String
	{
		return _sharedRegisters.shadedTarget.toString();
	}

	/**
	 * The amount of point lights that need to be supported.
	 */
	public var numPointLights(get,set):UInt;
	private function get_numPointLights():UInt
	{
		return _numPointLights;
	}

	private function set_numPointLights(numPointLights:UInt):UInt
	{
		return _numPointLights = numPointLights;
	}


	/**
	 * The amount of directional lights that need to be supported.
	 */
	public var numDirectionalLights(get,set):UInt;
	private function get_numDirectionalLights():UInt
	{
		return _numDirectionalLights;
	}

	private function set_numDirectionalLights(value:UInt):UInt
	{
		return _numDirectionalLights = value;
	}


	/**
	 * The amount of light probes that need to be supported.
	 */
	public var numLightProbes(get,set):UInt;
	private function get_numLightProbes():UInt
	{
		return _numLightProbes;
	}

	private function set_numLightProbes(value:UInt):UInt
	{
		return _numLightProbes = value;
	}

	/**
	 * Indicates whether the specular method is used.
	 */
	public var usingSpecularMethod(get,null):Bool;
	private function get_usingSpecularMethod():Bool
	{
		return _usingSpecularMethod;
	}

	/**
	 * The attributes that need to be animated by animators.
	 */
	public var animatableAttributes(get,null):Vector<String>;
	private function get_animatableAttributes():Vector<String>
	{
		return _animatableAttributes;
	}

	/**
	 * The target registers for animated properties, written to by the animators.
	 */
	public var animationTargetRegisters(get,null):Vector<String>;
	private function get_animationTargetRegisters():Vector<String>
	{
		return _animationTargetRegisters;
	}

	/**
	 * Indicates whether the compiled shader uses normals.
	 */
	public var usesNormals(get,null):Bool;
	private function get_usesNormals():Bool
	{
		return _dependencyCounter.normalDependencies > 0 && _methodSetup.normalMethod.hasOutput;
	}

	/**
	 * Indicates whether the compiled shader uses lights.
	 */
	private function usesLights():Bool
	{
		return _numLights > 0 && (_combinedLightSources & LightSources.LIGHTS) != 0;
	}

	/**
	 * Compiles the code for the methods.
	 */
	private function compileMethods():Void
	{
		var methods:Vector<MethodVOSet> = _methodSetup.methods;
		var numMethods:UInt = methods.length;
		var method:EffectMethodBase=null;
		var data:MethodVO=null;
		var alphaReg:ShaderRegisterElement=null;

		if (_preserveAlpha)
		{
			alphaReg = _registerCache.getFreeFragmentSingleTemp();
			_registerCache.addFragmentTempUsages(alphaReg, 1);
			_fragmentCode += "mov " + alphaReg + ", " + _sharedRegisters.shadedTarget + ".w\n";
		}

		for (i in 0...numMethods)
		{
			method = methods[i].method;
			data = methods[i].data;
			_vertexCode += method.getVertexCode(data, _registerCache);
			if (data.needsGlobalVertexPos || data.needsGlobalFragmentPos)
				_registerCache.removeVertexTempUsage(_sharedRegisters.globalPositionVertex);

			_fragmentCode += method.getFragmentCode(data, _registerCache, _sharedRegisters.shadedTarget);
			if (data.needsNormals)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.normalFragment);
			if (data.needsView)
				_registerCache.removeFragmentTempUsage(_sharedRegisters.viewDirFragment);
		}

		if (_preserveAlpha)
		{
			_fragmentCode += "mov " + _sharedRegisters.shadedTarget + ".w, " + alphaReg + "\n";
			_registerCache.removeFragmentTempUsage(alphaReg);
		}

		if (_methodSetup.colorTransformMethod != null)
		{
			_vertexCode += _methodSetup.colorTransformMethod.getVertexCode(_methodSetup.colorTransformMethodVO, _registerCache);
			_fragmentCode += _methodSetup.colorTransformMethod.getFragmentCode(_methodSetup.colorTransformMethodVO, _registerCache, _sharedRegisters.shadedTarget);
		}
	}

	/**
	 * Indices for the light probe diffuse textures.
	 */
	public var lightProbeDiffuseIndices(get,null):Vector<UInt>;
	private function get_lightProbeDiffuseIndices():Vector<UInt>
	{
		return _lightProbeDiffuseIndices;
	}

	/**
	 * Indices for the light probe specular textures.
	 */
	public var lightProbeSpecularIndices(get,null):Vector<UInt>;
	private function get_lightProbeSpecularIndices():Vector<UInt>
	{
		return _lightProbeSpecularIndices;
	}
}
