package away3d.core.base;

import away3d.Away3D;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.Vector;

/**
 * The SubGeometry class is a collections of geometric data that describes a triangle mesh. It is owned by a
 * Geometry instance, and wrapped by a SubMesh in the scene graph.
 * Several SubGeometries are grouped so they can be rendered with different materials, but still represent a single
 * object.
 *
 * @see away3d.core.base.Geometry
 * @see away3d.core.base.SubMesh
 */
class SubGeometry extends SubGeometryBase implements ISubGeometry
{
	public var numVertices(get, null):Int;
	
	public var secondaryUVData(get, null):Vector<Float>;
	public var secondaryUVStride(get, null):Int;
	public var secondaryUVOffset(get, null):Int;
	
	// raw data:
	private var _uvs:Vector<Float>;
	private var _secondaryUvs:Vector<Float>;
	private var _vertexNormals:Vector<Float>;
	private var _vertexTangents:Vector<Float>;
	
	private var _verticesInvalid:Bool;
	private var _uvsInvalid:Bool;
	private var _secondaryUvsInvalid:Bool;
	private var _normalsInvalid:Bool;
	private var _tangentsInvalid:Bool;
	
	private function invalidVerticesBuffer():Void
	{
		_verticesInvalid = true;
	}
	
	private function invaliduvsBuffer():Void
	{
		_uvsInvalid = true;
	}
	
	private function invalidSecondaryUvsBuffer():Void
	{
		_secondaryUvsInvalid = true;
	}
	
	private function invalidNormalBuffer():Void
	{
		_normalsInvalid = true;
	}
	
	private function invalidTangentsBuffer():Void
	{
		_tangentsInvalid = true;
	}

	// buffers:
	private var _vertexBuffer:VertexBuffer3D;
	private var _uvBuffer:VertexBuffer3D;
	private var _secondaryUvBuffer:VertexBuffer3D;
	private var _vertexNormalBuffer:VertexBuffer3D;
	private var _vertexTangentBuffer:VertexBuffer3D;

	// buffer dirty flags, per context:
	private var _vertexBufferContext:Context3DProxy;
	private var _uvBufferContext:Context3DProxy;
	private var _secondaryUvBufferContext:Context3DProxy;
	private var _vertexNormalBufferContext:Context3DProxy;
	private var _vertexTangentBufferContext:Context3DProxy;

	private var _numVertices:Int;


	/**
	 * Creates a new SubGeometry object.
	 */
	public function new()
	{
		super();
	}

	private function get_numVertices():Int
	{
		return _numVertices;
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;
		
		if (_vertexBuffer == null || 
			_vertexBufferContext != context)
		{
			_vertexBuffer = context.createVertexBuffer(_numVertices, 3);
			_vertexBufferContext = context;
			_verticesInvalid = true;
		}
		
		if (_verticesInvalid)
		{
			_vertexBuffer.uploadFromVector(_vertexData, 0, _numVertices);
			_verticesInvalid = false;
		}

		context.setVertexBufferAt(index, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
	}

	/**
	 * @inheritDoc
	 */
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_autoGenerateUVs && _uvsDirty)
			_uvs = updateDummyUVs(_uvs);

		if (_uvBuffer == null || 
			_uvBufferContext != context)
		{
			_uvBuffer = context.createVertexBuffer(_numVertices, 2);
			_uvBufferContext = context;
			_uvsInvalid = true;
		}
		
		if (_uvsInvalid)
		{
			_uvBuffer.uploadFromVector(_uvs, 0, _numVertices);
			_uvsInvalid = false;
		}

		context.setVertexBufferAt(index, _uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
	}

	/**
	 * @inheritDoc
	 */
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_secondaryUvBuffer == null || 
			_secondaryUvBufferContext != context)
		{
			_secondaryUvBuffer = context.createVertexBuffer(_numVertices, 2);
			_secondaryUvBufferContext = context;
			_secondaryUvsInvalid = true;
		}
		if (_secondaryUvsInvalid)
		{
			_secondaryUvBuffer.uploadFromVector(_secondaryUvs, 0, _numVertices);
			_secondaryUvsInvalid = false;
		}

		context.setVertexBufferAt(index, _secondaryUvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
	}

	/**
	 * Retrieves the VertexBuffer3D object that contains vertex normals.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains vertex normals.
	 */
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);

		if (_vertexNormalBuffer == null || 
			_vertexNormalBufferContext != context)
		{
			_vertexNormalBuffer = context.createVertexBuffer(_numVertices, 3);
			_vertexNormalBufferContext = context;
			_normalsInvalid = true;
		}
		
		if (_normalsInvalid)
		{
			_vertexNormalBuffer.uploadFromVector(_vertexNormals, 0, _numVertices);
			_normalsInvalid = false;
		}

		context.setVertexBufferAt(index, _vertexNormalBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
	}

	/**
	 * Retrieves the VertexBuffer3D object that contains vertex tangents.
	 * @param context The Context3D for which we request the buffer
	 * @return The VertexBuffer3D object that contains vertex tangents.
	 */
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3DProxy = stage3DProxy.context3D;

		if (_vertexTangentsDirty)
			_vertexTangents = updateVertexTangents(_vertexTangents);

		if (_vertexTangentBuffer == null || 
			_vertexTangentBufferContext != context)
		{
			_vertexTangentBuffer = context.createVertexBuffer(_numVertices, 3);
			_vertexTangentBufferContext = context;
			_tangentsInvalid = true;
		}
		
		if (_tangentsInvalid)
		{
			_vertexTangentBuffer.uploadFromVector(_vertexTangents, 0, _numVertices);
			_tangentsInvalid = false;
		}
		context.setVertexBufferAt(index, _vertexTangentBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
	}

	override public function applyTransformation(transform:Matrix3D):Void
	{
		super.applyTransformation(transform);
		
		invalidVerticesBuffer();
		invalidNormalBuffer();
		invalidTangentsBuffer();
	}

	/**
	 * Clones the current object
	 * @return An exact duplicate of the current object.
	 */
	public function clone():ISubGeometry
	{
		var clone:SubGeometry = new SubGeometry();
		clone.updateVertexData(_vertexData.concat());
		clone.updateUVData(_uvs.concat());
		clone.updateIndexData(_indices.concat());
		
		if (_secondaryUvs != null)
			clone.updateSecondaryUVData(_secondaryUvs.concat());
			
		if (!_autoDeriveVertexNormals)
			clone.updateVertexNormalData(_vertexNormals.concat());
			
		if (!_autoDeriveVertexTangents)
			clone.updateVertexTangentData(_vertexTangents.concat());
		return clone;
	}

	/**
	 * @inheritDoc
	 */
	override public function scale(scale:Float):Void
	{
		super.scale(scale);
		invalidVerticesBuffer();
	}

	/**
	 * @inheritDoc
	 */
	override public function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void
	{
		super.scaleUV(scaleU, scaleV);
		invaliduvsBuffer();
	}

	/**
	 * Clears all resources used by the SubGeometry object.
	 */
	override public function dispose():Void
	{
		super.dispose();
		disposeAllVertexBuffers();
		_vertexBuffer = null;
		_vertexNormalBuffer = null;
		_uvBuffer = null;
		_secondaryUvBuffer = null;
		_vertexTangentBuffer = null;
		_indexBuffer = null;
		_uvs = null;
		_secondaryUvs = null;
		_vertexNormals = null;
		_vertexTangents = null;
		_vertexBufferContext = null;
		_uvBufferContext = null;
		_secondaryUvBufferContext = null;
		_vertexNormalBufferContext = null;
		_vertexTangentBufferContext = null;
	}

	private function disposeAllVertexBuffers():Void
	{
		if (_vertexBuffer != null)
		{
			_vertexBuffer.dispose();
			_vertexBuffer = null;
		}
		
		if (_vertexNormalBuffer != null)
		{
			_vertexNormalBuffer.dispose();
			_vertexNormalBuffer = null;
		}
		
		if (_uvBuffer != null)
		{
			_uvBuffer.dispose();
			_uvBuffer = null;
		}
		
		if (_secondaryUvBuffer != null)
		{
			_secondaryUvBuffer.dispose();
			_secondaryUvBuffer = null;
		}
		
		if (_vertexTangentBuffer != null)
		{
			_vertexTangentBuffer.dispose();
			_vertexTangentBuffer = null;
		}
		//disposeVertexBuffers(_vertexBuffer);
		//disposeVertexBuffers(_vertexNormalBuffer);
		//disposeVertexBuffers(_uvBuffer);
		//disposeVertexBuffers(_secondaryUvBuffer);
		//disposeVertexBuffers(_vertexTangentBuffer);
	}

	/**
	 * The raw vertex position data.
	 */
	override private function get_vertexData():Vector<Float>
	{
		return _vertexData;
	}

	override private function get_vertexPositionData():Vector<Float>
	{
		return _vertexData;
	}

	/**
	 * Updates the vertex data of the SubGeometry.
	 * @param vertices The new vertex data to upload.
	 */
	public function updateVertexData(vertices:Vector<Float>):Void
	{
		if (_autoDeriveVertexNormals)
			_vertexNormalsDirty = true;
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;

		_faceNormalsDirty = true;

		_vertexData = vertices;
		var numVertices:Int = Std.int(vertices.length / 3);
		if (numVertices != _numVertices)
			disposeAllVertexBuffers();
		_numVertices = numVertices;

		//invalidateBuffers(_verticesInvalid);
		invalidVerticesBuffer();

		invalidateBounds();
	}

	/**
	 * The raw texture coordinate data.
	 */
	override private function get_UVData():Vector<Float>
	{
		if (_uvsDirty && _autoGenerateUVs)
			_uvs = updateDummyUVs(_uvs);
		return _uvs;
	}

	
	private function get_secondaryUVData():Vector<Float>
	{
		return _secondaryUvs;
	}

	/**
	 * Updates the uv coordinates of the SubGeometry.
	 * @param uvs The uv coordinates to upload.
	 */
	public function updateUVData(uvs:Vector<Float>):Void
	{
		// normals don't get dirty from this
		if (_autoDeriveVertexTangents)
			_vertexTangentsDirty = true;
		_faceTangentsDirty = true;
		_uvs = uvs;
		//invalidateBuffers(_uvsInvalid);
		invaliduvsBuffer();
	}

	public function updateSecondaryUVData(uvs:Vector<Float>):Void
	{
		_secondaryUvs = uvs;
		invalidSecondaryUvsBuffer();
	}

	/**
	 * The raw vertex normal data.
	 */
	override private function get_vertexNormalData():Vector<Float>
	{
		if (_autoDeriveVertexNormals && _vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);
		return _vertexNormals;
	}

	/**
	 * Updates the vertex normals of the SubGeometry. When updating the vertex normals like this,
	 * autoDeriveVertexNormals will be set to false and vertex normals will no longer be calculated automatically.
	 * @param vertexNormals The vertex normals to upload.
	 */
	public function updateVertexNormalData(vertexNormals:Vector<Float>):Void
	{
		_vertexNormalsDirty = false;
		_autoDeriveVertexNormals = (vertexNormals == null);
		_vertexNormals = vertexNormals;
		invalidNormalBuffer();
	}

	/**
	 * The raw vertex tangent data.
	 *
	 * @private
	 */
	override private function get_vertexTangentData():Vector<Float>
	{
		if (_autoDeriveVertexTangents && _vertexTangentsDirty)
			_vertexTangents = updateVertexTangents(_vertexTangents);
		return _vertexTangents;
	}

	/**
	 * Updates the vertex tangents of the SubGeometry. When updating the vertex tangents like this,
	 * autoDeriveVertexTangents will be set to false and vertex tangents will no longer be calculated automatically.
	 * @param vertexTangents The vertex tangents to upload.
	 */
	public function updateVertexTangentData(vertexTangents:Vector<Float>):Void
	{
		_vertexTangentsDirty = false;
		_autoDeriveVertexTangents = (vertexTangents == null);
		_vertexTangents = vertexTangents;
		invalidTangentsBuffer();
	}

	public function fromVectors(vertices:Vector<Float>, uvs:Vector<Float>, normals:Vector<Float>, tangents:Vector<Float>):Void
	{
		updateVertexData(vertices);
		updateUVData(uvs);
		updateVertexNormalData(normals);
		updateVertexTangentData(tangents);
	}

	override private function updateVertexNormals(target:Vector<Float>):Vector<Float>
	{
		invalidNormalBuffer();
		return super.updateVertexNormals(target);
	}

	override private function updateVertexTangents(target:Vector<Float>):Vector<Float>
	{
		if (_vertexNormalsDirty)
			_vertexNormals = updateVertexNormals(_vertexNormals);
		invalidTangentsBuffer();
		return super.updateVertexTangents(target);
	}


	override private function updateDummyUVs(target:Vector<Float>):Vector<Float>
	{
		invaliduvsBuffer();
		return super.updateDummyUVs(target);
	}

	private function disposeForStage3D(stage3DProxy:Stage3DProxy):Void
	{
		var index:Int = stage3DProxy.stage3DIndex;
		if (_vertexBuffer != null)
		{
			_vertexBuffer.dispose();
			_vertexBuffer = null;
		}
		if (_uvBuffer != null)
		{
			_uvBuffer.dispose();
			_uvBuffer = null;
		}
		if (_secondaryUvBuffer != null)
		{
			_secondaryUvBuffer.dispose();
			_secondaryUvBuffer = null;
		}
		if (_vertexNormalBuffer != null)
		{
			_vertexNormalBuffer.dispose();
			_vertexNormalBuffer = null;
		}
		if (_vertexTangentBuffer != null)
		{
			_vertexTangentBuffer.dispose();
			_vertexTangentBuffer = null;
		}
		if (_indexBuffer != null)
		{
			_indexBuffer.dispose();
			_indexBuffer = null;
		}
	}

	override private function get_vertexStride():Int
	{
		return 3;
	}

	override private function get_vertexTangentStride():Int
	{
		return 3;
	}

	override private function get_vertexNormalStride():Int
	{
		return 3;
	}

	override private function get_UVStride():Int
	{
		return 2;
	}

	
	private function get_secondaryUVStride():Int
	{
		return 2;
	}

	override private function get_vertexOffset():Int
	{
		return 0;
	}

	override private function get_vertexNormalOffset():Int
	{
		return 0;
	}

	override private function get_vertexTangentOffset():Int
	{
		return 0;
	}

	override private function get_UVOffset():Int
	{
		return 0;
	}

	private function get_secondaryUVOffset():Int
	{
		return 0;
	}

	public function cloneWithSeperateBuffers():SubGeometry
	{
		return Std.instance(clone(),SubGeometry);
	}
}
