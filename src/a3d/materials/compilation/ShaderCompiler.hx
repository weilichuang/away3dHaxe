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

	private var _specularLightSources:UInt;
	private var _diffuseLightSources:UInt;

	private var _numLights:Int;
	private var _numLightProbes:UInt;
	private var _numPointLights:UInt;
	private var _numDirectionalLights:UInt;

	private var _numProbeRegisters:UInt;
	private var _combinedLightSources:UInt;

	private var _usingSpecularMethod:Bool;

	private var _needUVAnimation:Bool;
	private var _UVTarget:String;
	private var _UVSource:String;

	private var _profile:Context3DProfile;

	private var _forceSeperateMVP:Bool;



	public function new(profile:Context3DProfile)
	{
		_sharedRegisters = new ShaderRegisterData();
		_dependencyCounter = new MethodDependencyCounter();
		_profile = profile;
		initRegisterCache(profile);
	}

	public var enableLightFallOff(get,set):Bool;
	private inline function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}

	private inline function set_enableLightFallOff(value:Bool):Bool
	{
		return _enableLightFallOff = value;
	}

	public var needUVAnimation(get,null):Bool;
	private inline function get_needUVAnimation():Bool
	{
		return _needUVAnimation;
	}

	public var UVTarget(get,null):String;
	private inline function get_UVTarget():String
	{
		return _UVTarget;
	}

	public var UVSource(get,null):String;
	private inline function get_UVSource():String
	{
		return _UVSource;
	}

	public var forceSeperateMVP(get,set):Bool;
	private inline function get_forceSeperateMVP():Bool
	{
		return _forceSeperateMVP;
	}

	private inline function set_forceSeperateMVP(value:Bool):Bool
	{
		return _forceSeperateMVP = value;
	}

	private function initRegisterCache(profile:Context3DProfile):Void
	{
		_registerCache = new ShaderRegisterCache(profile);
		_registerCache.vertexAttributesOffset = 1;
		_registerCache.reset();
	}

	public var animateUVs(get,set):Bool;
	private inline function get_animateUVs():Bool
	{
		return _animateUVs;
	}

	private inline function set_animateUVs(value:Bool):Bool
	{
		return _animateUVs = value;
	}

	public var alphaPremultiplied(get,set):Bool;
	private inline function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}

	private inline function set_alphaPremultiplied(value:Bool):Bool
	{
		return _alphaPremultiplied = value;
	}

	public var preserveAlpha(get,set):Bool;
	private inline function get_preserveAlpha():Bool
	{
		return _preserveAlpha;
	}

	private inline function set_preserveAlpha(value:Bool):Bool
	{
		return _preserveAlpha = value;
	}

	public function setTextureSampling(smooth:Bool, repeat:Bool, mipmap:Bool):Void
	{
		_smooth = smooth;
		_repeat = repeat;
		_mipmap = mipmap;
	}

	public function setConstantDataBuffers(vertexConstantData:Vector<Float>, fragmentConstantData:Vector<Float>):Void
	{
		_vertexConstantData = vertexConstantData;
		_fragmentConstantData = fragmentConstantData;
	}

	public var methodSetup(get,set):ShaderMethodSetup;
	private inline function get_methodSetup():ShaderMethodSetup
	{
		return _methodSetup;
	}

	private inline function set_methodSetup(value:ShaderMethodSetup):ShaderMethodSetup
	{
		return _methodSetup = value;
	}

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

	private function createNormalRegisters():Void
	{

	}

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

	private function compileLightingCode():Void
	{

	}

	private function compileViewDirCode():Void
	{

	}

	private function compileNormalCode():Void
	{

	}

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

	private function compileSecondaryUVCode():Void
	{
		var uvAttributeReg:ShaderRegisterElement = _registerCache.getFreeVertexAttribute();
		_secondaryUVBufferIndex = uvAttributeReg.index;
		_sharedRegisters.secondaryUVVarying = _registerCache.getFreeVarying();
		_vertexCode += "mov " + _sharedRegisters.secondaryUVVarying + ", " + uvAttributeReg + "\n";
	}

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

	private function compileFragmentOutput():Void
	{
		_fragmentCode += "mov " + _registerCache.fragmentOutputRegister + ", " + _sharedRegisters.shadedTarget + "\n";
		_registerCache.removeFragmentTempUsage(_sharedRegisters.shadedTarget);
	}

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

	private function createCommons():Void
	{
		_sharedRegisters.commons = _registerCache.getFreeFragmentConstant();
		_commonsDataIndex = _sharedRegisters.commons.index * 4;
	}

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

	private function setupAndCountMethodDependencies(method:ShadingMethodBase, methodVO:MethodVO):Void
	{
		setupMethod(method, methodVO);
		_dependencyCounter.includeMethodVO(methodVO);
	}

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

	public var commonsDataIndex(get,null):Int;
	private inline function get_commonsDataIndex():Int
	{
		return _commonsDataIndex;
	}

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

	public var numUsedVertexConstants(get,null):UInt;
	private inline function get_numUsedVertexConstants():UInt
	{
		return _registerCache.numUsedVertexConstants;
	}

	public var numUsedFragmentConstants(get,null):UInt;
	private inline function get_numUsedFragmentConstants():UInt
	{
		return _registerCache.numUsedFragmentConstants;
	}

	public var numUsedStreams(get,null):UInt;
	private inline function get_numUsedStreams():UInt
	{
		return _registerCache.numUsedStreams;
	}

	public var numUsedTextures(get,null):UInt;
	private inline function get_numUsedTextures():UInt
	{
		return _registerCache.numUsedTextures;
	}

	public var numUsedVaryings(get,null):UInt;
	private inline function get_numUsedVaryings():UInt
	{
		return _registerCache.numUsedVaryings;
	}

	private function usesLightsForSpecular():Bool
	{
		return _numLights > 0 && (_specularLightSources & LightSources.LIGHTS) != 0;
	}

	private function usesLightsForDiffuse():Bool
	{
		return _numLights > 0 && (_diffuseLightSources & LightSources.LIGHTS) != 0;
	}

	public function dispose():Void
	{
		cleanUpMethods();
		_registerCache.dispose();
		_registerCache = null;
		_sharedRegisters = null;
	}

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



	public var specularLightSources(get,set):UInt;
	private inline function get_specularLightSources():UInt
	{
		return _specularLightSources;
	}

	private inline function set_specularLightSources(value:UInt):UInt
	{
		return _specularLightSources = value;
	}

	public var diffuseLightSources(get,set):UInt;
	private inline function get_diffuseLightSources():UInt
	{
		return _diffuseLightSources;
	}

	private inline function set_diffuseLightSources(value:UInt):UInt
	{
		return _diffuseLightSources = value;
	}

	private function usesProbesForSpecular():Bool
	{
		return _numLightProbes > 0 && (_specularLightSources & LightSources.PROBES) != 0;
	}

	private function usesProbesForDiffuse():Bool
	{
		return _numLightProbes > 0 && (_diffuseLightSources & LightSources.PROBES) != 0;
	}

	private function usesProbes():Bool
	{
		return _numLightProbes > 0 && ((_diffuseLightSources | _specularLightSources) & LightSources.PROBES) != 0;
	}

	public var uvBufferIndex(get,null):Int;
	private inline function get_uvBufferIndex():Int
	{
		return _uvBufferIndex;
	}

	public var uvTransformIndex(get,null):Int;
	private inline function get_uvTransformIndex():Int
	{
		return _uvTransformIndex;
	}

	public var secondaryUVBufferIndex(get,null):Int;
	private inline function get_secondaryUVBufferIndex():Int
	{
		return _secondaryUVBufferIndex;
	}
	
	public var normalBufferIndex(get,null):Int;
	private inline function get_normalBufferIndex():Int
	{
		return _normalBufferIndex;
	}
	
	public var tangentBufferIndex(get,null):Int;
	private inline function get_tangentBufferIndex():Int
	{
		return _tangentBufferIndex;
	}

	public var lightFragmentConstantIndex(get,null):Int;
	private inline function get_lightFragmentConstantIndex():Int
	{
		return _lightFragmentConstantIndex;
	}

	public var cameraPositionIndex(get,null):Int;
	private inline function get_cameraPositionIndex():Int
	{
		return _cameraPositionIndex;
	}

	public var sceneMatrixIndex(get,null):Int;
	private inline function get_sceneMatrixIndex():Int
	{
		return _sceneMatrixIndex;
	}

	public var sceneNormalMatrixIndex(get,null):Int;
	private inline function get_sceneNormalMatrixIndex():Int
	{
		return _sceneNormalMatrixIndex;
	}

	public var probeWeightsIndex(get,null):Int;
	private inline function get_probeWeightsIndex():Int
	{
		return _probeWeightsIndex;
	}

	public var vertexCode(get,null):String;
	private inline function get_vertexCode():String
	{
		return _vertexCode;
	}

	public var fragmentCode(get,null):String;
	private inline function get_fragmentCode():String
	{
		return _fragmentCode;
	}

	public var fragmentLightCode(get,null):String;
	private inline function get_fragmentLightCode():String
	{
		return _fragmentLightCode;
	}

	public var fragmentPostLightCode(get,null):String;
	private inline function get_fragmentPostLightCode():String
	{
		return _fragmentPostLightCode;
	}

	public var shadedTarget(get,null):String;
	private inline function get_shadedTarget():String
	{
		return _sharedRegisters.shadedTarget.toString();
	}


	public var numPointLights(get,set):UInt;
	private inline function get_numPointLights():UInt
	{
		return _numPointLights;
	}

	private inline function set_numPointLights(numPointLights:UInt):UInt
	{
		return _numPointLights = numPointLights;
	}


	public var numDirectionalLights(get,set):UInt;
	private inline function get_numDirectionalLights():UInt
	{
		return _numDirectionalLights;
	}

	private inline function set_numDirectionalLights(value:UInt):UInt
	{
		return _numDirectionalLights = value;
	}


	public var numLightProbes(get,set):UInt;
	private inline function get_numLightProbes():UInt
	{
		return _numLightProbes;
	}

	private inline function set_numLightProbes(value:UInt):UInt
	{
		return _numLightProbes = value;
	}

	public var usingSpecularMethod(get,null):Bool;
	private inline function get_usingSpecularMethod():Bool
	{
		return _usingSpecularMethod;
	}

	public var animatableAttributes(get,null):Vector<String>;
	private inline function get_animatableAttributes():Vector<String>
	{
		return _animatableAttributes;
	}

	public var animationTargetRegisters(get,null):Vector<String>;
	private inline function get_animationTargetRegisters():Vector<String>
	{
		return _animationTargetRegisters;
	}

	public var usesNormals(get,null):Bool;
	private inline function get_usesNormals():Bool
	{
		return _dependencyCounter.normalDependencies > 0 && _methodSetup.normalMethod.hasOutput;
	}

	private function usesLights():Bool
	{
		return _numLights > 0 && (_combinedLightSources & LightSources.LIGHTS) != 0;
	}

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

	public var lightProbeDiffuseIndices(get,null):Vector<UInt>;
	private inline function get_lightProbeDiffuseIndices():Vector<UInt>
	{
		return _lightProbeDiffuseIndices;
	}

	public var lightProbeSpecularIndices(get,null):Vector<UInt>;
	private inline function get_lightProbeSpecularIndices():Vector<UInt>
	{
		return _lightProbeSpecularIndices;
	}
}
