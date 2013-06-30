package a3d.entities.primitives;


import a3d.core.base.CompactSubGeometry;
import flash.Vector;



/**
 * A UV Cylinder primitive mesh.
 */
class TorusGeometry extends PrimitiveBase
{
	private var _radius:Float;
	private var _tubeRadius:Float;
	private var _segmentsR:Int;
	private var _segmentsT:Int;
	private var _yUp:Bool;
	private var _rawVertexData:Vector<Float>;
	private var _rawIndices:Vector<UInt>;
	private var _nextVertexIndex:Int;
	private var _currentIndex:Int;
	private var _currentTriangleIndex:Int;
	private var _numVertices:Int;
	private var _vertexStride:Int;
	private var _vertexOffset:Int;

	private function addVertex(px:Float, py:Float, pz:Float,
		nx:Float, ny:Float, nz:Float,
		tx:Float, ty:Float, tz:Float):Void
	{
		var compVertInd:UInt = _vertexOffset + _nextVertexIndex * _vertexStride; // current component vertex index
		_rawVertexData[compVertInd++] = px;
		_rawVertexData[compVertInd++] = py;
		_rawVertexData[compVertInd++] = pz;
		_rawVertexData[compVertInd++] = nx;
		_rawVertexData[compVertInd++] = ny;
		_rawVertexData[compVertInd++] = nz;
		_rawVertexData[compVertInd++] = tx;
		_rawVertexData[compVertInd++] = ty;
		_rawVertexData[compVertInd] = tz;
		_nextVertexIndex++;
	}

	private function addTriangleClockWise(cwVertexIndex0:UInt, cwVertexIndex1:UInt, cwVertexIndex2:UInt):Void
	{
		_rawIndices[_currentIndex++] = cwVertexIndex0;
		_rawIndices[_currentIndex++] = cwVertexIndex1;
		_rawIndices[_currentIndex++] = cwVertexIndex2;
		_currentTriangleIndex++;
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, revolutionAngleR:Float, revolutionAngleT:Float;
		var numTriangles:UInt;
		// reset utility variables
		_numVertices = 0;
		_nextVertexIndex = 0;
		_currentIndex = 0;
		_currentTriangleIndex = 0;
		_vertexStride = target.vertexStride;
		_vertexOffset = target.vertexOffset;

		// evaluate target number of vertices, triangles and indices
		_numVertices = (_segmentsT + 1) * (_segmentsR + 1); // segmentsT + 1 because of closure, segmentsR + 1 because of closure
		numTriangles = _segmentsT * _segmentsR * 2; // each level has segmentR quads, each of 2 triangles

		// need to initialize raw arrays or can be reused?
		if (_numVertices == target.numVertices)
		{
			_rawVertexData = target.vertexData;
			if (target.indexData != null)
			{
				_rawIndices = target.indexData;
			}
			else
			{
				_rawIndices = new Vector<UInt>(numTriangles * 3, true);
			}
		
		}
		else
		{
			var numVertComponents:UInt = _numVertices * _vertexStride;
			_rawVertexData = new Vector<Float>(numVertComponents, true);
			_rawIndices = new Vector<UInt>(numTriangles * 3, true);
			invalidateUVs();
		}

		// evaluate revolution steps
		var revolutionAngleDeltaR:Float = 2 * Math.PI / _segmentsR;
		var revolutionAngleDeltaT:Float = 2 * Math.PI / _segmentsT;

		var comp1:Float, comp2:Float;
		var t1:Float, t2:Float, n1:Float, n2:Float;
		var startIndex:Int;

		// surface
		var a:Int, b:Int, c:Int, d:Int, length:Float;

		for (j in 0..._segmentsT + 1)
		{

			startIndex = _vertexOffset + _nextVertexIndex * _vertexStride;

			for (i in 0..._segmentsR + 1)
			{
				// revolution vertex
				revolutionAngleR = i * revolutionAngleDeltaR;
				revolutionAngleT = j * revolutionAngleDeltaT;

				length = Math.cos(revolutionAngleT);
				nx = length * Math.cos(revolutionAngleR);
				ny = length * Math.sin(revolutionAngleR);
				nz = Math.sin(revolutionAngleT);

				x = _radius * Math.cos(revolutionAngleR) + _tubeRadius * nx;
				y = _radius * Math.sin(revolutionAngleR) + _tubeRadius * ny;
				z = (j == _segmentsT) ? 0 : _tubeRadius * nz;

				if (_yUp)
				{
					n1 = -nz;
					n2 = ny;
					t1 = 0;
					t2 = (length != 0 ? nx / length : x / _radius);
					comp1 = -z;
					comp2 = y;

				}
				else
				{
					n1 = ny;
					n2 = nz;
					t1 = (length != 0 ? nx / length : x / _radius);
					t2 = 0;
					comp1 = y;
					comp2 = z;
				}

				if (i == _segmentsR)
				{
					addVertex(x, _rawVertexData[startIndex + 1], _rawVertexData[startIndex + 2],
						nx, n1, n2,
						-(length != 0 ? ny / length : y / _radius), t1, t2);
				}
				else
				{
					addVertex(x, comp1, comp2,
						nx, n1, n2,
						-(length != 0 ? ny / length : y / _radius), t1, t2);
				}

				// close triangle
				if (i > 0 && j > 0)
				{
					a = _nextVertexIndex - 1; // current
					b = _nextVertexIndex - 2; // previous
					c = b - _segmentsR - 1; // previous of last level
					d = a - _segmentsR - 1; // current of last level
					addTriangleClockWise(a, b, c);
					addTriangleClockWise(a, c, d);
				}
			}
		}

		// build real data from raw data
		target.updateData(_rawVertexData);
		target.updateIndexData(_rawIndices);
	}

	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var stride:Int = target.UVStride;
		var offset:Int = target.UVOffset;
		var skip:Int = target.UVStride - 2;

		// evaluate num uvs
		var numUvs:Int = _numVertices * stride;

		// need to initialize raw array or can be reused?
		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else
		{
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}

		// current uv component index
		var currentUvCompIndex:UInt = offset;

		// surface
		for (j in 0..._segmentsT + 1)
		{
			for (i in 0..._segmentsR + 1)
			{
				// revolution vertex
				data[currentUvCompIndex++] = i / _segmentsR;
				data[currentUvCompIndex++] = j / _segmentsT;
				currentUvCompIndex += skip;
			}
		}

		// build real data from raw data
		target.updateData(data);
	}

	/**
	 * The radius of the torus.
	 */
	public var radius(get, set):Float;
	private function get_radius():Float
	{
		return _radius;
	}

	private function set_radius(value:Float):Float
	{
		_radius = value;
		invalidateGeometry();
		return _radius;
	}

	/**
	 * The radius of the inner tube of the torus.
	 */
	public var tubeRadius(get, set):Float;
	private function get_tubeRadius():Float
	{
		return _tubeRadius;
	}

	private function set_tubeRadius(value:Float):Float
	{
		_tubeRadius = value;
		invalidateGeometry();
		return _tubeRadius;
	}

	/**
	 * Defines the number of horizontal segments that make up the torus. Defaults to 16.
	 */
	public var segmentsR(get, set):Int;
	private function get_segmentsR():Int
	{
		return _segmentsR;
	}

	private function set_segmentsR(value:Int):Int
	{
		_segmentsR = value;
		invalidateGeometry();
		invalidateUVs();
		return _segmentsR;
	}

	/**
	 * Defines the number of vertical segments that make up the torus. Defaults to 8.
	 */
	public var segmentsT(get, set):Int;
	private function get_segmentsT():Int
	{
		return _segmentsT;
	}

	private function set_segmentsT(value:Int):Int
	{
		_segmentsT = value;
		invalidateGeometry();
		invalidateUVs();
		return _segmentsT;
	}

	/**
	 * Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public var yUp(get, set):Bool;
	private function get_yUp():Bool
	{
		return _yUp;
	}

	private function set_yUp(value:Bool):Bool
	{
		_yUp = value;
		invalidateGeometry();
		return _yUp;
	}

	/**
	 * Creates a new <code>Torus</code> object.
	 * @param radius The radius of the torus.
	 * @param tuebRadius The radius of the inner tube of the torus.
	 * @param segmentsR Defines the number of horizontal segments that make up the torus.
	 * @param segmentsT Defines the number of vertical segments that make up the torus.
	 * @param yUp Defines whether the torus poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(radius:Float = 50, tubeRadius:Float = 50, 
						segmentsR:Int = 16, segmentsT:Int = 8, yUp:Bool = true)
	{
		super();

		_radius = radius;
		_tubeRadius = tubeRadius;
		_segmentsR = segmentsR;
		_segmentsT = segmentsT;
		_yUp = yUp;
	}
}
