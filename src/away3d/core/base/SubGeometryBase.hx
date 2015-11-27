package away3d.core.base;

import away3d.Away3D;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import away3d.errors.AbstractMethodError;
import away3d.math.FMath;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;


class SubGeometryBase
{
	/**
	 * Defines whether a UV buffer should be automatically generated to contain dummy UV coordinates.
	 * Set to true if a geometry lacks UV data but uses a material that requires it, or leave as false
	 * in cases where UV data is explicitly defined or the material does not require UV data.
	 */
	public var autoGenerateDummyUVs(get, set):Bool;
	/**
	 * True if the vertex normals should be derived from the geometry, false if the vertex normals are set
	 * explicitly.
	 */
	public var autoDeriveVertexNormals(get, set):Bool;
	/**
	 * True if the vertex tangents should be derived from the geometry, false if the vertex normals are set
	 * explicitly.
	 */
	public var autoDeriveVertexTangents(get, set):Bool;
	
	/**
	 * Indicates whether or not to take the size of faces into account when auto-deriving vertex normals and tangents.
	 */
	public var useFaceWeights(get, set):Bool;
	/**
	 * The total amount of triangles in the SubGeometry.
	 */
	public var numTriangles(get, null):Int;
	/**
	 * The raw index data that define the faces.
	 *
	 */
	public var indexData(get, null):Vector<UInt>;
	
	/**
	 * The raw data of the face normals, in the same order as the faces are listed in the index list.
	 *
	 * @private
	 */
	public var faceNormals(get, null):Vector<Float>;
	public var UVStride(get, null):Int;
	public var vertexData(get, null):Vector<Float>;
	
	public var vertexPositionData(get, null):Vector<Float>;
	public var vertexNormalData(get, null):Vector<Float>;
	public var vertexTangentData(get, null):Vector<Float>;
	public var UVData(get, null):Vector<Float>;
	
	public var vertexStride(get, null):Int;
	public var vertexNormalStride(get, null):Int;
	public var vertexTangentStride(get, null):Int;
	
	public var vertexOffset(get, null):Int;
	public var vertexNormalOffset(get, null):Int;
	public var vertexTangentOffset(get, null):Int;
	public var UVOffset(get, null):Int;
	/**
	 * The Geometry object that 'owns' this SubGeometry object.
	 *
	 * @private
	 */
	public var parentGeometry(get, set):Geometry;
	/**
	 * Scales the uv coordinates
	 * @param scaleU The amount by which to scale on the u axis. Default is 1;
	 * @param scaleV The amount by which to scale on the v axis. Default is 1;
	 */
	public var scaleU(get, set):Float;
	public var scaleV(get, set):Float;
	
	private var _parentGeometry:Geometry;
	private var _vertexData:Vector<Float>;

	private var _faceNormalsDirty:Bool;
	private var _faceTangentsDirty:Bool;
	private var _faceTangents:Vector<Float>;
	private var _indices:Vector<UInt>;
	private var _indexBuffer:IndexBuffer3D;
	private var _numIndices:Int;
	private var _indexBufferContext:Context3DProxy;
	private var _indicesInvalid:Bool;
	private var _numTriangles:Int;

	private var _autoDeriveVertexNormals:Bool = true;
	private var _autoDeriveVertexTangents:Bool = true;
	private var _autoGenerateUVs:Bool = false;
	private var _useFaceWeights:Bool = false;
	private var _vertexNormalsDirty:Bool = true;
	private var _vertexTangentsDirty:Bool = true;

	private var _faceNormals:Vector<Float>;
	private var _faceWeights:Vector<Float>;

	private var _scaleU:Float = 1;
	private var _scaleV:Float = 1;

	private var _uvsDirty:Bool = true;

	public function new()
	{
		_faceNormalsDirty = true;
		_faceTangentsDirty = true;
		
		_autoDeriveVertexNormals = true;
		_autoDeriveVertexTangents = true;
		_autoGenerateUVs = false;
		_useFaceWeights = false;
		_vertexNormalsDirty = true;
		_vertexTangentsDirty = true;
		
		_scaleU = 1;
		_scaleV = 1;
		
		_uvsDirty = true;
	}


	
	private function get_autoGenerateDummyUVs():Bool
	{
		return _autoGenerateUVs;
	}

	private function set_autoGenerateDummyUVs(value:Bool):Bool
	{
		_autoGenerateUVs = value;
		_uvsDirty = value;
		return _autoGenerateUVs;
	}

	
	private function get_autoDeriveVertexNormals():Bool
	{
		return _autoDeriveVertexNormals;
	}

	private function set_autoDeriveVertexNormals(value:Bool):Bool
	{
		_autoDeriveVertexNormals = value;

		_vertexNormalsDirty = value;
		return _autoDeriveVertexNormals;
	}

	
	private function get_useFaceWeights():Bool
	{
		return _useFaceWeights;
	}

	private function set_useFaceWeights(value:Bool):Bool
	{
		_useFaceWeights = value;
		if (_autoDeriveVertexNormals)
			_vertexNormalsDirty = true;
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
		_faceNormalsDirty = true;
		return _useFaceWeights;
	}

	
	private function get_numTriangles():Int
	{
		return _numTriangles;
	}

	/**
	 * Retrieves the VertexBuffer3D object that contains triangle indices.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains triangle indices.
	 */
	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_indexBuffer == null || _indexBufferContext != context)
		{
			_indexBuffer = context.createIndexBuffer(_numIndices);
			_indexBufferContext = context;
			_indicesInvalid = true;
		}
		
		if (_indicesInvalid)
		{
			_indexBuffer.uploadFromVector(_indices, 0, _numIndices);
			_indicesInvalid = false;
		}

		return _indexBuffer;
	}

	/**
	 * Updates the tangents for each face.
	 */
	private function updateFaceTangents():Void
	{
		
		var index1:UInt, index2:UInt, index3:UInt;
		var len:Int = _indices.length;
		var ui:UInt, vi:UInt;
		var v0:Float;
		var dv1:Float, dv2:Float;
		var denom:Float;
		var x0:Float, y0:Float, z0:Float;
		var dx1:Float, dy1:Float, dz1:Float;
		var dx2:Float, dy2:Float, dz2:Float;
		var cx:Float, cy:Float, cz:Float;
		var vertices:Vector<Float> = _vertexData;
		var uvs:Vector<Float> = UVData;
		var posStride:Int = vertexStride;
		var posOffset:Int = vertexOffset;
		var texStride:Int = UVStride;
		var texOffset:Int = UVOffset;

		if(_faceTangents == null)
			_faceTangents = new Vector<Float>(_indices.length, true);

		var i:Int = 0;
		while (i < len)
		{
			index1 = _indices[i];
			index2 = _indices[i + 1];
			index3 = _indices[i + 2];

			ui = texOffset + index1 * texStride + 1;
			v0 = uvs[ui];
			ui = texOffset + index2 * texStride + 1;
			dv1 = uvs[ui] - v0;
			ui = texOffset + index3 * texStride + 1;
			dv2 = uvs[ui] - v0;

			vi = posOffset + index1 * posStride;
			x0 = vertices[vi];
			y0 = vertices[vi + 1];
			z0 = vertices[vi + 2];
			vi = posOffset + index2 * posStride;
			dx1 = vertices[vi] - x0;
			dy1 = vertices[vi + 1] - y0;
			dz1 = vertices[vi + 2] - z0;
			vi = posOffset + index3 * posStride;
			dx2 = vertices[vi] - x0;
			dy2 = vertices[vi + 1] - y0;
			dz2 = vertices[vi + 2] - z0;

			cx = dv2 * dx1 - dv1 * dx2;
			cy = dv2 * dy1 - dv1 * dy2;
			cz = dv2 * dz1 - dv1 * dz2;
			denom = FMath.invSqrt(cx * cx + cy * cy + cz * cz);
			_faceTangents[i++] = denom * cx;
			_faceTangents[i++] = denom * cy;
			_faceTangents[i++] = denom * cz;
		}

		_faceTangentsDirty = false;
	}

	/**
	 * Updates the normals for each face.
	 */
	private function updateFaceNormals():Void
	{
		var index:Int;
		var len:Int = _indices.length;
		var x1:Float, x2:Float, x3:Float;
		var y1:Float, y2:Float, y3:Float;
		var z1:Float, z2:Float, z3:Float;
		var dx1:Float, dy1:Float, dz1:Float;
		var dx2:Float, dy2:Float, dz2:Float;
		var cx:Float, cy:Float, cz:Float;
		var d:Float;
		var vertices:Vector<Float> = _vertexData;
		var posStride:Int = vertexStride;
		var posOffset:Int = vertexOffset;

		if (_faceNormals == null)
			_faceNormals = new Vector<Float>(len, true);
			
		if (_useFaceWeights)
		{
			if (_faceWeights == null)
				_faceWeights = new Vector<Float>(Std.int(len / 3), true);
		}

		var i:Int = 0;
		var k:Int = 0;
		var j:Int = 0;
		while (i < len)
		{
			index = posOffset + _indices[i++] * posStride;
			x1 = vertices[index];
			y1 = vertices[index + 1];
			z1 = vertices[index + 2];
			
			index = posOffset + _indices[i++] * posStride;
			x2 = vertices[index];
			y2 = vertices[index + 1];
			z2 = vertices[index + 2];
			
			index = posOffset + _indices[i++] * posStride;
			x3 = vertices[index];
			y3 = vertices[index + 1];
			z3 = vertices[index + 2];
			
			dx1 = x3 - x1;
			dy1 = y3 - y1;
			dz1 = z3 - z1;
			dx2 = x2 - x1;
			dy2 = y2 - y1;
			dz2 = z2 - z1;
			cx = dz1 * dy2 - dy1 * dz2;
			cy = dx1 * dz2 - dz1 * dx2;
			cz = dy1 * dx2 - dx1 * dy2;
			d = Math.sqrt(cx * cx + cy * cy + cz * cz);
			// length of cross product = 2*triangle area
			if (_useFaceWeights)
			{
				var w:Float = d * 10000;
				if (w < 1)
					w = 1;
				_faceWeights[k++] = w;
			}
			d = 1 / d;
			_faceNormals[j++] = cx * d;
			_faceNormals[j++] = cy * d;
			_faceNormals[j++] = cz * d;
		}

		_faceNormalsDirty = false;
	}

	/**
	 * Updates the vertex normals based on the geometry.
	 */
	private function updateVertexNormals(target:Vector<Float>):Vector<Float>
	{
		if (_faceNormalsDirty)
			updateFaceNormals();

		var v1:Int;
		var f1:Int = 0, f2:Int = 1, f3:Int = 2;
		var lenV:Int = _vertexData.length;
		var normalStride:Int = vertexNormalStride;
		var normalOffset:Int = vertexNormalOffset;

		if (target == null)
			target = new Vector<Float>(lenV, true);
			
		v1 = normalOffset;
		while (v1 < lenV)
		{
			target[v1] = 0.0;
			target[v1 + 1] = 0.0;
			target[v1 + 2] = 0.0;
			v1 += normalStride;
		}

		var i:Int = 0, k:Int = 0;
		var lenI:Int = _indices.length;
		var index:Int;
		var weight:Float;
		while (i < lenI)
		{
			weight = _useFaceWeights ? _faceWeights[k++] : 1;
			index = normalOffset + _indices[i++] * normalStride;
			target[index++] += _faceNormals[f1] * weight;
			target[index++] += _faceNormals[f2] * weight;
			target[index] += _faceNormals[f3] * weight;
			index = normalOffset + _indices[i++] * normalStride;
			target[index++] += _faceNormals[f1] * weight;
			target[index++] += _faceNormals[f2] * weight;
			target[index] += _faceNormals[f3] * weight;
			index = normalOffset + _indices[i++] * normalStride;
			target[index++] += _faceNormals[f1] * weight;
			target[index++] += _faceNormals[f2] * weight;
			target[index] += _faceNormals[f3] * weight;
			f1 += 3;
			f2 += 3;
			f3 += 3;
		}

		v1 = normalOffset;
		while (v1 < lenV)
		{
			var vx:Float = target[v1];
			var vy:Float = target[v1 + 1];
			var vz:Float = target[v1 + 2];
			var d:Float = FMath.invSqrt(vx * vx + vy * vy + vz * vz);
			target[v1] = vx * d;
			target[v1 + 1] = vy * d;
			target[v1 + 2] = vz * d;
			v1 += normalStride;
		}

		_vertexNormalsDirty = false;

		return target;
	}

	/**
	 * Updates the vertex tangents based on the geometry.
	 */
	private function updateVertexTangents(target:Vector<Float>):Vector<Float>
	{
		if (_faceTangentsDirty)
			updateFaceTangents();

		var i:Int;
		var lenV:Int = _vertexData.length;
		var tangentStride:Int = vertexTangentStride;
		var tangentOffset:Int = vertexTangentOffset;

		if (target == null)
			target = new Vector<Float>(lenV, true);

		i = tangentOffset;
		while (i < lenV)
		{
			target[i] = 0.0;
			target[i + 1] = 0.0;
			target[i + 2] = 0.0;
			i += tangentStride;
		}

		var k:Int = 0;
		var lenI:Int = _indices.length;
		var index:Int;
		var weight:Float;
		var f1:Int = 0, f2:Int = 1, f3:Int = 2;

		i = 0;
		while (i < lenI)
		{
			weight = _useFaceWeights ? _faceWeights[k++] : 1;
			index = tangentOffset + _indices[i++] * tangentStride;
			target[index++] += _faceTangents[f1] * weight;
			target[index++] += _faceTangents[f2] * weight;
			target[index] += _faceTangents[f3] * weight;
			
			index = tangentOffset + _indices[i++] * tangentStride;
			target[index++] += _faceTangents[f1] * weight;
			target[index++] += _faceTangents[f2] * weight;
			target[index] += _faceTangents[f3] * weight;
			
			index = tangentOffset + _indices[i++] * tangentStride;
			target[index++] += _faceTangents[f1] * weight;
			target[index++] += _faceTangents[f2] * weight;
			target[index] += _faceTangents[f3] * weight;
			
			f1 += 3;
			f2 += 3;
			f3 += 3;
		}

		i = tangentOffset;
		while (i < lenV)
		{
			var vx:Float = target[i];
			var vy:Float = target[i + 1];
			var vz:Float = target[i + 2];
			var d:Float = 1.0 / Math.sqrt(vx * vx + vy * vy + vz * vz);
			target[i] = vx * d;
			target[i + 1] = vy * d;
			target[i + 2] = vz * d;
			i += tangentStride;
		}

		_vertexTangentsDirty = false;

		return target;
	}

	public function dispose():Void
	{
		disposeIndexBuffer();
		_indices = null;
		_indexBufferContext = null;
		_faceNormals = null;
		_faceWeights = null;
		_faceTangents = null;
		_vertexData = null;
	}
	
	private inline function disposeIndexBuffer():Void
	{
		if (_indexBuffer != null)
		{
			_indexBuffer.dispose();
			_indexBuffer = null;
		}
	}

	
	private function get_indexData():Vector<UInt>
	{
		return _indices;
	}

	/**
	 * Updates the face indices of the SubGeometry.
	 * @param indices The face indices to upload.
	 */
	public function updateIndexData(indices:Vector<UInt>):Void
	{
		_indices = indices;
		_numIndices = indices.length;

		var numTriangles:Int = Std.int(_numIndices / 3);
		if (_numTriangles != numTriangles)
		{
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
		}
			
		_numTriangles = numTriangles;
		//invalidateBuffers(_indicesInvalid);
		invalidIndicesBuffer();
		_faceNormalsDirty = true;

		if (_autoDeriveVertexNormals)
			_vertexNormalsDirty = true;
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
	}
	
	private function invalidIndicesBuffer():Void
	{
		_indicesInvalid = true;
	}
	
	private function get_autoDeriveVertexTangents():Bool
	{
		return _autoDeriveVertexTangents;
	}

	private function set_autoDeriveVertexTangents(value:Bool):Bool
	{
		_autoDeriveVertexTangents = value;

		_vertexTangentsDirty = value;
		
		return _autoDeriveVertexTangents;
	}

	
	private function get_faceNormals():Vector<Float>
	{
		if (_faceNormalsDirty)
			updateFaceNormals();
		return _faceNormals;
	}
	
	private function get_UVStride():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexPositionData():Vector<Float>
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexTangentData():Vector<Float>
	{
		throw new AbstractMethodError();
	}

	
	private function get_UVData():Vector<Float>
	{
		throw new AbstractMethodError();
	}

	
	
	private function get_vertexData():Vector<Float>
	{
		throw new AbstractMethodError();
	}
	
	private function get_vertexNormalData():Vector<Float>
	{
		throw new AbstractMethodError();
	}
	private function get_vertexStride():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexNormalStride():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexTangentStride():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexOffset():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexNormalOffset():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_vertexTangentOffset():Int
	{
		throw new AbstractMethodError();
	}

	
	private function get_UVOffset():Int
	{
		throw new AbstractMethodError();
	}

	private function invalidateBounds():Void
	{
		if (_parentGeometry != null)
			_parentGeometry.invalidateBounds(cast(this,ISubGeometry));
	}

	
	private function get_parentGeometry():Geometry
	{
		return _parentGeometry;
	}

	private function set_parentGeometry(value:Geometry):Geometry
	{
		return _parentGeometry = value;
	}

	
	private function get_scaleU():Float
	{
		return _scaleU;
	}
	
	private function set_scaleU(value:Float):Float
	{
		return _scaleU = value;
	}

	
	private function get_scaleV():Float
	{
		return _scaleV;
	}
	
	private function set_scaleV(value:Float):Float
	{
		return _scaleV = value;
	}

	public function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void
	{
		var offset:Int = UVOffset;
		var stride:Int = UVStride;
		var uvs:Vector<Float> = UVData;
		var len:Int = uvs.length;
		
		var ratioU:Float = scaleU / _scaleU;
		var ratioV:Float = scaleV / _scaleV;

		var i:Int = offset;
		while (i < len)
		{
			uvs[i] *= ratioU;
			uvs[i + 1] *= ratioV;
			i += stride;
		}

		_scaleU = scaleU;
		_scaleV = scaleV;
	}

	/**
	 * Scales the geometry.
	 * @param scale The amount by which to scale.
	 */
	public function scale(scale:Float):Void
	{
		var vertices:Vector<Float> = vertexPositionData;
		var len:Int = vertices.length;
		var offset:Int = vertexOffset;
		var stride:Int = vertexStride;

		var i:Int = offset;
		while (i < len)
		{
			vertices[i] *= scale;
			vertices[i + 1] *= scale;
			vertices[i + 2] *= scale;
			i += stride;
		}
	}

	public function applyTransformation(transform:Matrix3D):Void
	{
		var vertices:Vector<Float> = _vertexData;
		var normals:Vector<Float> = vertexNormalData;
		var tangents:Vector<Float> = vertexTangentData;
		var posStride:Int = vertexStride;
		var normalStride:Int = vertexNormalStride;
		var tangentStride:Int = vertexTangentStride;
		var posOffset:Int = vertexOffset;
		var normalOffset:Int = vertexNormalOffset;
		var tangentOffset:Int = vertexTangentOffset;
		var len:Int = Std.int(vertices.length / posStride);
		var i1:Int, i2:Int;
		var vector:Vector3D = new Vector3D();

		var bakeNormals:Bool = normals != null;
		var bakeTangents:Bool = tangents != null;
		var invTranspose:Matrix3D = null;

		if (bakeNormals || bakeTangents)
		{
			invTranspose = transform.clone();
			invTranspose.invert();
			invTranspose.transpose();
		}

		var vi0:Int = posOffset;
		var ni0:Int = normalOffset;
		var ti0:Int = tangentOffset;

		for (i in 0...len)
		{
			i1 = vi0 + 1;
			i2 = vi0 + 2;

			// bake position
			vector.x = vertices[vi0];
			vector.y = vertices[i1];
			vector.z = vertices[i2];
			vector = transform.transformVector(vector);
			vertices[vi0] = vector.x;
			vertices[i1] = vector.y;
			vertices[i2] = vector.z;
			vi0 += posStride;

			// bake normal
			if (bakeNormals)
			{
				i1 = ni0 + 1;
				i2 = ni0 + 2;
				vector.x = normals[ni0];
				vector.y = normals[i1];
				vector.z = normals[i2];
				vector = invTranspose.deltaTransformVector(vector);
				vector.normalize();
				normals[ni0] = vector.x;
				normals[i1] = vector.y;
				normals[i2] = vector.z;
				ni0 += normalStride;
			}

			// bake tangent
			if (bakeTangents)
			{
				i1 = ti0 + 1;
				i2 = ti0 + 2;
				vector.x = tangents[ti0];
				vector.y = tangents[i1];
				vector.z = tangents[i2];
				vector = invTranspose.deltaTransformVector(vector);
				vector.normalize();
				tangents[ti0] = vector.x;
				tangents[i1] = vector.y;
				tangents[i2] = vector.z;
				ti0 += tangentStride;
			}
		}
	}

	private function updateDummyUVs(target:Vector<Float>):Vector<Float>
	{
		_uvsDirty = false;

		var idx:Int, uvIdx:Int;
		var stride:Int = UVStride;
		var skip:Int = stride - 2;
		var len:Int = Std.int(_vertexData.length / vertexStride * stride);

		if (target == null)
			target = new Vector<Float>();
		target.fixed = false;
		target.length = len;
		target.fixed = true;

		idx = UVOffset;
		uvIdx = 0;
		while (idx < len)
		{
			target[idx++] = uvIdx * .5;
			target[idx++] = 1.0 - (uvIdx & 1);
			idx += skip;

			if (++uvIdx == 3)
				uvIdx = 0;
		}

		return target;
	}
}