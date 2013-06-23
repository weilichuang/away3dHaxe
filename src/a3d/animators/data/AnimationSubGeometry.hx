package a3d.animators.data
{
	import a3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;

	/**
	 * ...
	 */
	class AnimationSubGeometry
	{
		private var _vertexData:Vector<Float>;

		private var _vertexBuffer:Vector<VertexBuffer3D> = new Vector<VertexBuffer3D>(8);
		private var _bufferContext:Vector<Context3D> = new Vector<Context3D>(8);
		private var _bufferDirty:Vector<Bool> = new Vector<Bool>(8);

		private var _numVertices:UInt;

		private var _totalLenOfOneVertex:UInt;

		public var numProcessedVertices:Int = 0;

		public var previousTime:Float = Number.NEGATIVE_INFINITY;

		public var animationParticles:Vector<ParticleAnimationData> = new Vector<ParticleAnimationData>();

		public function AnimationSubGeometry()
		{
			for (var i:Int = 0; i < 8; i++)
				_bufferDirty[i] = true;
		}

		public function createVertexData(numVertices:UInt, totalLenOfOneVertex:UInt):Void
		{
			_numVertices = numVertices;
			_totalLenOfOneVertex = totalLenOfOneVertex;
			_vertexData = new Vector<Float>(numVertices * totalLenOfOneVertex, true);
		}

		public function activateVertexBuffer(index:Int, bufferOffset:Int, stage3DProxy:Stage3DProxy, format:String):Void
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
			while (_vertexBuffer.length)
			{
				var vertexBuffer:VertexBuffer3D = _vertexBuffer.pop()

				if (vertexBuffer)
					vertexBuffer.dispose();
			}
		}

		public function invalidateBuffer():Void
		{
			for (var i:Int = 0; i < 8; i++)
				_bufferDirty[i] = true;
		}

		private inline function get_vertexData():Vector<Float>
		{
			return _vertexData;
		}

		private inline function get_numVertices():UInt
		{
			return _numVertices;
		}

		private inline function get_totalLenOfOneVertex():UInt
		{
			return _totalLenOfOneVertex;
		}
	}
}
