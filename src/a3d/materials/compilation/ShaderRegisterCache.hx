package a3d.materials.compilation;
import flash.display3D.Context3DProfile;


/**
 * ShaderRegister Cache provides the usage management system for all registers during shading compilation.
 */
class ShaderRegisterCache
{
	private var _fragmentTempCache:RegisterPool;
	private var _vertexTempCache:RegisterPool;
	private var _varyingCache:RegisterPool;
	private var _fragmentConstantsCache:RegisterPool;
	private var _vertexConstantsCache:RegisterPool;
	private var _textureCache:RegisterPool;
	private var _vertexAttributesCache:RegisterPool;
	private var _vertexConstantOffset:Int;
	private var _vertexAttributesOffset:Int;
	private var _varyingsOffset:Int;
	private var _fragmentConstantOffset:Int;

	private var _fragmentOutputRegister:ShaderRegisterElement;
	private var _vertexOutputRegister:ShaderRegisterElement;
	private var _numUsedVertexConstants:Int;
	private var _numUsedFragmentConstants:Int;
	private var _numUsedStreams:Int;
	private var _numUsedTextures:Int;
	private var _numUsedVaryings:Int;
	private var _profile:Context3DProfile;

	/**
	 * Create a new ShaderRegisterCache object.
	 *
	 * @param profile The compatibility profile used by the renderer.
	 */
	public function new(profile:Context3DProfile)
	{
		_profile = profile;
	}

	/**
	 * Resets all registers.
	 */
	public function reset():Void
	{
		_fragmentTempCache = new RegisterPool("ft", 8, false);
		_vertexTempCache = new RegisterPool("vt", 8, false);
		_varyingCache = new RegisterPool("v", 8);
		_textureCache = new RegisterPool("fs", 8);
		_vertexAttributesCache = new RegisterPool("va", 8);
		_fragmentConstantsCache = new RegisterPool("fc", 28);
		_vertexConstantsCache = new RegisterPool("vc", 128);
		_fragmentOutputRegister = new ShaderRegisterElement("oc", -1);
		_vertexOutputRegister = new ShaderRegisterElement("op", -1);
		_numUsedVertexConstants = 0;
		_numUsedStreams = 0;
		_numUsedTextures = 0;
		_numUsedVaryings = 0;
		_numUsedFragmentConstants = 0;

		for (i in 0..._vertexAttributesOffset)
			getFreeVertexAttribute();
		for (i in 0..._vertexConstantOffset)
			getFreeVertexConstant();
		for (i in 0..._varyingsOffset)
			getFreeVarying();
		for (i in 0..._fragmentConstantOffset)
			getFreeFragmentConstant();

	}

	/**
	 * Disposes all resources used.
	 */
	public function dispose():Void
	{
		_fragmentTempCache.dispose();
		_vertexTempCache.dispose();
		_varyingCache.dispose();
		_fragmentConstantsCache.dispose();
		_vertexAttributesCache.dispose();

		_fragmentTempCache = null;
		_vertexTempCache = null;
		_varyingCache = null;
		_fragmentConstantsCache = null;
		_vertexAttributesCache = null;
		_fragmentOutputRegister = null;
		_vertexOutputRegister = null;
	}

	/**
	 * Marks a fragment temporary register as used, so it cannot be retrieved. 
	 * The register won't be able to be used until removeUsage
	 * has been called usageCount times again.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */
	public function addFragmentTempUsages(register:ShaderRegisterElement, usageCount:Int):Void
	{
		_fragmentTempCache.addUsage(register, usageCount);
	}

	/**
	 * Removes a usage from a fragment temporary register. When usages reach 0, the register is freed again.
	 * @param register The register for which to remove a usage.
	 */
	public function removeFragmentTempUsage(register:ShaderRegisterElement):Void
	{
		_fragmentTempCache.removeUsage(register);
	}

	/**
	 * Marks a vertex temporary register as used, so it cannot be retrieved. The register won't be able to be used
	 * until removeUsage has been called usageCount times again.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */
	public function addVertexTempUsages(register:ShaderRegisterElement, usageCount:Int):Void
	{
		_vertexTempCache.addUsage(register, usageCount);
	}

	/**
	 * Removes a usage from a vertex temporary register. When usages reach 0, the register is freed again.
	 * @param register The register for which to remove a usage.
	 */
	public function removeVertexTempUsage(register:ShaderRegisterElement):Void
	{
		_vertexTempCache.removeUsage(register);
	}

	/**
	 * Retrieve an entire fragment temporary register that's still available. The register won't be able to be used until removeUsage
	 * has been called usageCount times again.
	 */
	public function getFreeFragmentVectorTemp():ShaderRegisterElement
	{
		return _fragmentTempCache.requestFreeVectorReg();
	}

	/**
	 * Retrieve a single component from a fragment temporary register that's still available.
	 */
	public function getFreeFragmentSingleTemp():ShaderRegisterElement
	{
		return _fragmentTempCache.requestFreeRegComponent();
	}

	/**
	 * Retrieve an available varying register
	 */
	public function getFreeVarying():ShaderRegisterElement
	{
		var result:ShaderRegisterElement = _varyingCache.requestFreeVectorReg();
		++_numUsedVaryings;
		return result;
	}

	/**
	 * Retrieve an available fragment constant register
	 */
	public function getFreeFragmentConstant():ShaderRegisterElement
	{
		var result:ShaderRegisterElement = _fragmentConstantsCache.requestFreeVectorReg();
		++_numUsedFragmentConstants;
		return result;
	}

	/**
	 * Retrieve an available vertex constant register
	 */
	public function getFreeVertexConstant():ShaderRegisterElement
	{
		var result:ShaderRegisterElement = _vertexConstantsCache.requestFreeVectorReg();
		++_numUsedVertexConstants;
		return result;
	}

	/**
	 * Retrieve an entire vertex temporary register that's still available.
	 */
	public function getFreeVertexVectorTemp():ShaderRegisterElement
	{
		return _vertexTempCache.requestFreeVectorReg();
	}

	/**
	 * Retrieve a single component from a vertex temporary register that's still available.
	 */
	public function getFreeVertexSingleTemp():ShaderRegisterElement
	{
		return _vertexTempCache.requestFreeRegComponent();
	}

	/**
	 * Retrieve an available vertex attribute register
	 */
	public function getFreeVertexAttribute():ShaderRegisterElement
	{
		var result:ShaderRegisterElement = _vertexAttributesCache.requestFreeVectorReg();
		++_numUsedStreams;
		return result;
	}

	/**
	 * Retrieve an available texture register
	 */
	public function getFreeTextureReg():ShaderRegisterElement
	{
		var result:ShaderRegisterElement = _textureCache.requestFreeVectorReg();
		++_numUsedTextures;
		return result;
	}

	/**
	 * Indicates the start index from which to retrieve vertex constants.
	 */
	public var vertexConstantOffset(get,set):Int;
	private function get_vertexConstantOffset():Int
	{
		return _vertexConstantOffset;
	}

	private function set_vertexConstantOffset(vertexConstantOffset:Int):Int
	{
		return _vertexConstantOffset = vertexConstantOffset;
	}

	/**
	 * Indicates the start index from which to retrieve vertex attributes.
	 */
	public var vertexAttributesOffset(get,set):Int;
	private function get_vertexAttributesOffset():Int
	{
		return _vertexAttributesOffset;
	}

	private function set_vertexAttributesOffset(value:Int):Int
	{
		return _vertexAttributesOffset = value;
	}

	/**
	 * Indicates the start index from which to retrieve varying registers.
	 */
	public var varyingsOffset(get,set):Int;
	private function get_varyingsOffset():Int
	{
		return _varyingsOffset;
	}

	private function set_varyingsOffset(value:Int):Int
	{
		return _varyingsOffset = value;
	}

	/**
	 * Indicates the start index from which to retrieve fragment constants.
	 */
	public var fragmentConstantOffset(get,set):Int;
	private function get_fragmentConstantOffset():Int
	{
		return _fragmentConstantOffset;
	}

	private function set_fragmentConstantOffset(value:Int):Int
	{
		return _fragmentConstantOffset = value;
	}

	/**
	 * The fragment output register.
	 */
	public var fragmentOutputRegister(get,null):ShaderRegisterElement;
	private function get_fragmentOutputRegister():ShaderRegisterElement
	{
		return _fragmentOutputRegister;
	}

	/**
	 * The amount of used vertex constant registers.
	 */
	public var numUsedVertexConstants(get,null):Int;
	private function get_numUsedVertexConstants():Int
	{
		return _numUsedVertexConstants;
	}

	/**
	 * The amount of used fragment constant registers.
	 */
	public var numUsedFragmentConstants(get,null):Int;
	private function get_numUsedFragmentConstants():Int
	{
		return _numUsedFragmentConstants;
	}

	/**
	 * The amount of used vertex streams.
	 */
	public var numUsedStreams(get,null):Int;
	private function get_numUsedStreams():Int
	{
		return _numUsedStreams;
	}

	/**
	 * The amount of used texture slots.
	 */
	public var numUsedTextures(get,null):Int;
	private function get_numUsedTextures():Int
	{
		return _numUsedTextures;
	}

	/**
	 * The amount of used varying registers.
	 */
	public var numUsedVaryings(get,null):Int;
	private function get_numUsedVaryings():Int
	{
		return _numUsedVaryings;
	}
}
