package a3d.tools.helpers.data;

import flash.geom.Matrix;
import flash.geom.Matrix3D;

/**
 * ...
 */
class ParticleGeometryTransform
{
	private var _defaultVertexTransform:Matrix3D;
	private var _defaultInvVertexTransform:Matrix3D;
	private var _defaultUVTransform:Matrix;

	public function new()
	{
	}

	private inline function set_vertexTransform(value:Matrix3D):Void
	{
		_defaultVertexTransform = value;
		_defaultInvVertexTransform = value.clone();
		_defaultInvVertexTransform.invert();
		_defaultInvVertexTransform.transpose();
	}

	private inline function set_UVTransform(value:Matrix):Void
	{
		_defaultUVTransform = value;
	}

	private inline function get_UVTransform():Matrix
	{
		return _defaultUVTransform;
	}

	private inline function get_vertexTransform():Matrix3D
	{
		return _defaultVertexTransform;
	}

	private inline function get_invVertexTransform():Matrix3D
	{
		return _defaultInvVertexTransform;
	}
}
