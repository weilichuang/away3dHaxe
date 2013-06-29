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
	private var _vertexConstantOffset:UInt;
	private var _vertexAttributesOffset:UInt;
	private var _varyingsOffset:UInt;
	private var _fragmentConstantOffset:UInt;

	private var _fragmentOutputRegister:ShaderRegisterElement;
	private var _vertexOutputRegister:ShaderRegisterElement;
	private var _numUsedVertexConstants:UInt;
	private var _numUsedFragmentConstants:UInt;
	private var _numUsedStreams:UInt;
	private var _numUsedTextures:UInt;
	private var _numUsedVaryings:UInt;
	private var _profile:Context3DProfile;

	/**
	 * Create a new ShaderRegisterCache object.
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
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */
	public function addFragmentTempUsages(register:ShaderRegisterElement, usageCount:UInt):Void
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
	 * Marks a vertex temporary register as used, so it cannot be retrieved.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */
	public function addVertexTempUsages(register:ShaderRegisterElement, usageCount:UInt):Void
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
	 * Retrieve an entire fragment temporary register that's still available.
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
		++_numUsedVaryings;
		return _varyingCache.requestFreeVectorReg();
	}

	/**
	 * Retrieve an available fragment constant register
	 */
	public function getFreeFragmentConstant():ShaderRegisterElement
	{
		++_numUsedFragmentConstants;
		return _fragmentConstantsCache.requestFreeVectorReg();
	}

	/**
	 * Retrieve an available vertex constant register
	 */
	public function getFreeVertexConstant():ShaderRegisterElement
	{
		++_numUsedVertexConstants;
		return _vertexConstantsCache.requestFreeVectorReg();
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
		++_numUsedStreams;
		return _vertexAttributesCache.requestFreeVectorReg();
	}

	/**
	 * Retrieve an available texture register
	 */
	public function getFreeTextureReg():ShaderRegisterElement
	{
		++_numUsedTextures;
		return _textureCache.requestFreeVectorReg();
	}

	/**
	 * Indicates the start index from which to retrieve vertex constants.
	 */
	public var vertexConstantOffset(get,set):UInt;
	private inline function get_vertexConstantOffset():UInt
	{
		return _vertexConstantOffset;
	}

	private inline function set_vertexConstantOffset(vertexConstantOffset:UInt):UInt
	{
		return _vertexConstantOffset = vertexConstantOffset;
	}

	/**
	 * Indicates the start index from which to retrieve vertex attributes.
	 */
	public var vertexAttributesOffset(get,set):UInt;
	private inline function get_vertexAttributesOffset():UInt
	{
		return _vertexAttributesOffset;
	}

	private inline function set_vertexAttributesOffset(value:UInt):UInt
	{
		return _vertexAttributesOffset = value;
	}

	public var varyingsOffset(get,set):UInt;
	private inline function get_varyingsOffset():UInt
	{
		return _varyingsOffset;
	}

	private inline function set_varyingsOffset(value:UInt):UInt
	{
		return _varyingsOffset = value;
	}

	public var fragmentConstantOffset(get,set):UInt;
	private inline function get_fragmentConstantOffset():UInt
	{
		return _fragmentConstantOffset;
	}

	private inline function set_fragmentConstantOffset(value:UInt):UInt
	{
		return _fragmentConstantOffset = value;
	}

	/**
	 * The fragment output register.
	 */
	public var fragmentOutputRegister(get,null):ShaderRegisterElement;
	private inline function get_fragmentOutputRegister():ShaderRegisterElement
	{
		return _fragmentOutputRegister;
	}

	/**
	 * The amount of used vertex constant registers.
	 */
	public var numUsedVertexConstants(get,null):UInt;
	private inline function get_numUsedVertexConstants():UInt
	{
		return _numUsedVertexConstants;
	}

	/**
	 * The amount of used fragment constant registers.
	 */
	public var numUsedFragmentConstants(get,null):UInt;
	private inline function get_numUsedFragmentConstants():UInt
	{
		return _numUsedFragmentConstants;
	}

	/**
	 * The amount of used vertex streams.
	 */
	public var numUsedStreams(get,null):UInt;
	private inline function get_numUsedStreams():UInt
	{
		return _numUsedStreams;
	}

	public var numUsedTextures(get,null):UInt;
	private inline function get_numUsedTextures():UInt
	{
		return _numUsedTextures;
	}

	public var numUsedVaryings(get,null):UInt;
	private inline function get_numUsedVaryings():UInt
	{
		return _numUsedVaryings;
	}
}
