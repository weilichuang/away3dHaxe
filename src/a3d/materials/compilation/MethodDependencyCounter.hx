package a3d.materials.compilation;

import a3d.materials.LightSources;
import a3d.materials.methods.MethodVO;

/**
 * MethodDependencyCounter keeps track of the number of dependencies for "named registers" used across methods.
 * Named registers are that are not necessarily limited to a single method. They are created by the compiler and
 * passed on to methods. The compiler uses the results to reserve usages through RegisterPool, which can be removed
 * each time a method has been compiled into the shader.
 *
 * @see RegisterPool.addUsage
 */
class MethodDependencyCounter
{
	private var _projectionDependencies:UInt;
	private var _normalDependencies:UInt;
	private var _viewDirDependencies:UInt;
	private var _uvDependencies:UInt;
	private var _secondaryUVDependencies:UInt;
	private var _globalPosDependencies:UInt;
	private var _tangentDependencies:UInt;
	private var _usesGlobalPosFragment:Bool = false;
	private var _numPointLights:UInt;
	private var _lightSourceMask:UInt;

	/**
	 * Creates a new MethodDependencyCounter object.
	 */
	public function new()
	{
	}

	/**
	 * Clears dependency counts for all registers. Called when recompiling a pass.
	 */
	public function reset():Void
	{
		_projectionDependencies = 0;
		_normalDependencies = 0;
		_viewDirDependencies = 0;
		_uvDependencies = 0;
		_secondaryUVDependencies = 0;
		_globalPosDependencies = 0;
		_tangentDependencies = 0;
		_usesGlobalPosFragment = false;
	}

	/**
	 * Sets the amount of lights that have a position associated with them.
	 * @param numPointLights The amount of point lights.
	 * @param lightSourceMask The light source types used by the material.
	 */
	public function setPositionedLights(numPointLights:UInt, lightSourceMask:UInt):Void
	{
		_numPointLights = numPointLights;
		_lightSourceMask = lightSourceMask;
	}

	/**
	 * Increases dependency counters for the named registers listed as required by the given MethodVO.
	 * @param methodVO the MethodVO object for which to include dependencies.
	 */
	public function includeMethodVO(methodVO:MethodVO):Void
	{
		if (methodVO.needsProjection)
			++_projectionDependencies;
		if (methodVO.needsGlobalVertexPos)
		{
			++_globalPosDependencies;
			if (methodVO.needsGlobalFragmentPos)
				_usesGlobalPosFragment = true;
		}
		else if (methodVO.needsGlobalFragmentPos)
		{
			++_globalPosDependencies;
			_usesGlobalPosFragment = true;
		}
		if (methodVO.needsNormals)
			++_normalDependencies;
		if (methodVO.needsTangents)
			++_tangentDependencies;
		if (methodVO.needsView)
			++_viewDirDependencies;
		if (methodVO.needsUV)
			++_uvDependencies;
		if (methodVO.needsSecondaryUV)
			++_secondaryUVDependencies;
	}

	/**
	 * The amount of tangent vector dependencies (fragment shader).
	 */
	public var tangentDependencies(get, null):UInt;
	private function get_tangentDependencies():UInt
	{
		return _tangentDependencies;
	}

	/**
	 * Indicates whether there are any dependencies on the world-space position vector.
	 */
	public var usesGlobalPosFragment(get, null):Bool;
	private function get_usesGlobalPosFragment():Bool
	{
		return _usesGlobalPosFragment;
	}

	/**
	 * The amount of dependencies on the projected position.
	 */
	public var projectionDependencies(get, null):UInt;
	private function get_projectionDependencies():UInt
	{
		return _projectionDependencies;
	}

	/**
	 * The amount of dependencies on the normal vector.
	 */
	public var normalDependencies(get, null):UInt;
	private function get_normalDependencies():UInt
	{
		return _normalDependencies;
	}

	/**
	 * The amount of dependencies on the view direction.
	 */
	public var viewDirDependencies(get, null):UInt;
	private function get_viewDirDependencies():UInt
	{
		return _viewDirDependencies;
	}

	/**
	 * The amount of dependencies on the primary UV coordinates.
	 */
	public var uvDependencies(get, null):UInt;
	private function get_uvDependencies():UInt
	{
		return _uvDependencies;
	}

	/**
	 * The amount of dependencies on the secondary UV coordinates.
	 */
	public var secondaryUVDependencies(get, null):UInt;
	private function get_secondaryUVDependencies():UInt
	{
		return _secondaryUVDependencies;
	}

	/**
	 * The amount of dependencies on the global position. This can be 0 while hasGlobalPosDependencies is true when
	 * the global position is used as a temporary value (fe to calculate the view direction)
	 */
	public var globalPosDependencies(get, null):UInt;
	private function get_globalPosDependencies():UInt
	{
		return _globalPosDependencies;
	}

	/**
	 * Adds any external world space dependencies, used to force world space calculations.
	 */
	public function addWorldSpaceDependencies(fragmentLights:Bool):Void
	{
		if (_viewDirDependencies > 0)
			++_globalPosDependencies;

		if (_numPointLights > 0 && (_lightSourceMask != 0 & LightSources.LIGHTS))
		{
			++_globalPosDependencies;
			if (fragmentLights)
				_usesGlobalPosFragment = true;
		}
	}
}
