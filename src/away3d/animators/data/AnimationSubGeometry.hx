package away3d.animators.data;

import away3d.Away3D;
import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.Vector;


/**
 * ...
 */
class AnimationSubGeometry
{
	public var vertexData(get,null):Vector<Float>;
	public var numVertices(get,null):Int;
	public var totalLenOfOneVertex(get, null):Int;
	
	public var numProcessedVertices:Int;

	public var previousTime:Float;

	public var animationParticles:Vector<ParticleAnimationData>;
	
	private var _vertexData:Vector<Float>;

	private var _vertexBuffer:VertexBuffer3D;
	private var _bufferContext:Context3DProxy;
	private var _bufferDirty:Bool;

	private var _numVertices:Int;

	private var _totalLenOfOneVertex:Int;

	
	public function new()
	{
		numProcessedVertices = 0;
		previousTime = Math.NEGATIVE_INFINITY;
		animationParticles = new Vector<ParticleAnimationData>();
		
		_bufferDirty = true;
	}

	public function createVertexData(numVertices:UInt, totalLenOfOneVertex:UInt):Void
	{
		_numVertices = numVertices;
		_totalLenOfOneVertex = totalLenOfOneVertex;
		_vertexData = new Vector<Float>(numVertices * totalLenOfOneVertex, true);
	}

	public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:Context3DVertexBufferFormat):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;
		if (_vertexBuffer == null || _bufferContext != context)
		{
			_vertexBuffer = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
			_bufferContext = context;
			_bufferDirty = true;
		}
		
		if (_bufferDirty)
		{
			_vertexBuffer.uploadFromVector(_vertexData, 0, _numVertices);
			_bufferDirty = false;
		}
		context.setVertexBufferAt(index, _vertexBuffer, bufferOffset, format);
	}

	public function dispose():Void
	{
		if (_vertexBuffer != null)
		{
			_vertexBuffer.dispose();
			_vertexBuffer = null;
		}
		_bufferContext = null;
	}

	public inline function invalidateBuffer():Void
	{
		_bufferDirty = true;
	}

	
	private inline function get_vertexData():Vector<Float>
	{
		return _vertexData;
	}

	
	private inline function get_numVertices():Int
	{
		return _numVertices;
	}

	
	private inline function get_totalLenOfOneVertex():Int
	{
		return _totalLenOfOneVertex;
	}
}
