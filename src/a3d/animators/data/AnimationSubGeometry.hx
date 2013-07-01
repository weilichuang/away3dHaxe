package a3d.animators.data;

import a3d.core.managers.Stage3DProxy;
import flash.display3D.Context3DVertexBufferFormat;
import flash.Vector;

import flash.display3D.Context3D;
import flash.display3D.VertexBuffer3D;

/**
 * ...
 */
class AnimationSubGeometry
{
	private var _vertexData:Vector<Float>;

	private var _vertexBuffer:Vector<VertexBuffer3D>;
	private var _bufferContext:Vector<Context3D>;
	private var _bufferDirty:Vector<Bool>;

	private var _numVertices:UInt;

	private var _totalLenOfOneVertex:UInt;

	public var numProcessedVertices:Int;

	public var previousTime:Float;

	public var animationParticles:Vector<ParticleAnimationData>;

	public function new()
	{
		_vertexBuffer = new Vector<VertexBuffer3D>(8);
		_bufferContext = new Vector<Context3D>(8);
		
		numProcessedVertices = 0;
		previousTime = Math.NEGATIVE_INFINITY;
		animationParticles = new Vector<ParticleAnimationData>();
		
		_bufferDirty = new Vector<Bool>(8);
		for (i in 0...8)
			_bufferDirty[i] = true;
	}

	public function createVertexData(numVertices:UInt, totalLenOfOneVertex:UInt):Void
	{
		_numVertices = numVertices;
		_totalLenOfOneVertex = totalLenOfOneVertex;
		_vertexData = new Vector<Float>(numVertices * totalLenOfOneVertex, true);
	}

	public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:Context3DVertexBufferFormat):Void
	{
		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3D = stage3DProxy.context3D;

		var buffer:VertexBuffer3D = _vertexBuffer[contextIndex];
		if (buffer == null || _bufferContext[contextIndex] != context)
		{
			buffer = _vertexBuffer[contextIndex] = context.createVertexBuffer(_numVertices, _totalLenOfOneVertex);
			_bufferContext[contextIndex] = context;
			_bufferDirty[contextIndex] = true;
		}
		if (_bufferDirty[contextIndex])
		{
			buffer.uploadFromVector(_vertexData, 0, _numVertices);
			_bufferDirty[contextIndex] = false;
		}
		context.setVertexBufferAt(index, buffer, bufferOffset, format);
	}

	public function dispose():Void
	{
		while (_vertexBuffer.length > 0)
		{
			var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop();

			if (vertexBuffer != null)
				vertexBuffer.dispose();
		}
	}

	public function invalidateBuffer():Void
	{
		for (i in 0...8)
			_bufferDirty[i] = true;
	}

	public var vertexData(get,null):Vector<Float>;
	private function get_vertexData():Vector<Float>
	{
		return _vertexData;
	}

	public var numVertices(get,null):Int;
	private function get_numVertices():Int
	{
		return _numVertices;
	}

	public var totalLenOfOneVertex(get,null):Int;
	private function get_totalLenOfOneVertex():Int
	{
		return _totalLenOfOneVertex;
	}
}
