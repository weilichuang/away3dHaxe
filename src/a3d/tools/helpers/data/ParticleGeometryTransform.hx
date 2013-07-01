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

	public var vertexTransform(get, set):Matrix3D;
	private function get_vertexTransform():Matrix3D
	{
		return _defaultVertexTransform;
	}
	
	private function set_vertexTransform(value:Matrix3D):Matrix3D
	{
		_defaultVertexTransform = value;
		_defaultInvVertexTransform = value.clone();
		_defaultInvVertexTransform.invert();
		_defaultInvVertexTransform.transpose();
		
		return _defaultVertexTransform;
	}

	public var UVTransform(get, set):Matrix;
	private function set_UVTransform(value:Matrix):Matrix
	{
		return _defaultUVTransform = value;
	}

	private function get_UVTransform():Matrix
	{
		return _defaultUVTransform;
	}

	

	public var invVertexTransform(get, null):Matrix3D;
	private function get_invVertexTransform():Matrix3D
	{
		return _defaultInvVertexTransform;
	}
}
