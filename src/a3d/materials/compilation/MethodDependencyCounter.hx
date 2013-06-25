package a3d.materials.compilation;

import a3d.materials.LightSources;
import a3d.materials.methods.MethodVO;

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

	// why always true?

	public function new()
	{
	}

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

	public function setPositionedLights(numPointLights:UInt, lightSourceMask:UInt):Void
	{
		_numPointLights = numPointLights;
		_lightSourceMask = lightSourceMask;
	}

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

	private inline function get_tangentDependencies():UInt
	{
		return _tangentDependencies;
	}

	private inline function get_usesGlobalPosFragment():Bool
	{
		return _usesGlobalPosFragment;
	}

	private inline function get_projectionDependencies():UInt
	{
		return _projectionDependencies;
	}

	private inline function get_normalDependencies():UInt
	{
		return _normalDependencies;
	}

	private inline function get_viewDirDependencies():UInt
	{
		return _viewDirDependencies;
	}

	private inline function get_uvDependencies():UInt
	{
		return _uvDependencies;
	}

	private inline function get_secondaryUVDependencies():UInt
	{
		return _secondaryUVDependencies;
	}

	private inline function get_globalPosDependencies():UInt
	{
		return _globalPosDependencies;
	}

	public function addWorldSpaceDependencies(fragmentLights:Bool):Void
	{
		if (_viewDirDependencies > 0)
			++_globalPosDependencies;

		if (_numPointLights > 0 && (_lightSourceMask & LightSources.LIGHTS))
		{
			++_globalPosDependencies;
			if (fragmentLights)
				_usesGlobalPosFragment = true;
		}
	}
}
