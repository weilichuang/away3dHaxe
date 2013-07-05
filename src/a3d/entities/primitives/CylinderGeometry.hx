package a3d.entities.primitives;

	
import a3d.core.base.CompactSubGeometry;
import flash.Vector;



/**
 * A Cylinder primitive mesh.
 */
class CylinderGeometry extends PrimitiveBase
{
	private var _topRadius:Float;
	private var _bottomRadius:Float;
	private var _height:Float;
	private var _segmentsW:Int;
	private var _segmentsH:Int;
	private var _topClosed:Bool;
	private var _bottomClosed:Bool;
	private var _surfaceClosed:Bool;
	private var _yUp:Bool;
	private var _rawData:Vector<Float>;
	private var _rawIndices:Vector<UInt>;
	private var _nextVertexIndex:Int;
	private var _currentIndex:Int;
	private var _currentTriangleIndex:Int;
	private var _numVertices:Int;
	private var _stride:Int;
	private var _vertexOffset:Int;
	
	/**
	 * Creates a new Cylinder object.
	 * @param topRadius The radius of the top end of the cylinder.
	 * @param bottomRadius The radius of the bottom end of the cylinder
	 * @param height The radius of the bottom end of the cylinder
	 * @param segmentsW Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
	 * @param segmentsH Defines the number of vertical segments that make up the cylinder. Defaults to 1.
	 * @param topClosed Defines whether the top end of the cylinder is closed (true) or open.
	 * @param bottomClosed Defines whether the bottom end of the cylinder is closed (true) or open.
	 * @param yUp Defines whether the cone poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, 
						segmentsW:Int = 16, segmentsH:Int = 1, 
						topClosed:Bool = true, bottomClosed:Bool = true, 
						surfaceClosed:Bool = true, yUp:Bool = true)
	{
		super();

		_topRadius = topRadius;
		_bottomRadius = bottomRadius;
		_height = height;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
		_topClosed = topClosed;
		_bottomClosed = bottomClosed;
		_surfaceClosed = surfaceClosed;
		_yUp = yUp;
	}

	private function addVertex(px:Float, py:Float, pz:Float,
		nx:Float, ny:Float, nz:Float,
		tx:Float, ty:Float, tz:Float):Void
	{
		var compVertInd:UInt = _vertexOffset + _nextVertexIndex * _stride; // current component vertex index
		_rawData[compVertInd++] = px;
		_rawData[compVertInd++] = py;
		_rawData[compVertInd++] = pz;
		_rawData[compVertInd++] = nx;
		_rawData[compVertInd++] = ny;
		_rawData[compVertInd++] = nz;
		_rawData[compVertInd++] = tx;
		_rawData[compVertInd++] = ty;
		_rawData[compVertInd++] = tz;
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
		var x:Float, y:Float, z:Float, radius:Float, revolutionAngle:Float;
		var dr:Float, latNormElev:Float, latNormBase:Float;
		
		var numTriangles:Int = 0;

		var comp1:Float, comp2:Float;
		var startIndex:Int = 0;
		//numvert:Int = 0;
		var t1:Float, t2:Float;

		_stride = target.vertexStride;
		_vertexOffset = target.vertexOffset;

		// reset utility variables
		_numVertices = 0;
		_nextVertexIndex = 0;
		_currentIndex = 0;
		_currentTriangleIndex = 0;

		// evaluate target number of vertices, triangles and indices
		if (_surfaceClosed)
		{
			_numVertices += (_segmentsH + 1) * (_segmentsW + 1); // segmentsH + 1 because of closure, segmentsW + 1 because of UV unwrapping
			numTriangles += _segmentsH * _segmentsW * 2; // each level has segmentW quads, each of 2 triangles
		}
		if (_topClosed)
		{
			_numVertices += 2 * (_segmentsW + 1); // segmentsW + 1 because of unwrapping
			numTriangles += _segmentsW; // one triangle for each segment
		}
		if (_bottomClosed)
		{
			_numVertices += 2 * (_segmentsW + 1);
			numTriangles += _segmentsW;
		}

		// need to initialize raw arrays or can be reused?
		if (_numVertices == target.numVertices)
		{
			_rawData = target.vertexData;
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
			var numVertComponents:UInt = _numVertices * _stride;
			_rawData = new Vector<Float>(numVertComponents, true);
			_rawIndices = new Vector<UInt>(numTriangles * 3, true);
		}

		// evaluate revolution steps
		var revolutionAngleDelta:Float = 2 * Math.PI / _segmentsW;

		// top
		if (_topClosed && _topRadius > 0)
		{

			z = -0.5 * _height;

			for (i in 0..._segmentsW+1)
			{
				// central vertex
				if (_yUp)
				{
					t1 = 1;
					t2 = 0;
					comp1 = -z;
					comp2 = 0;

				}
				else
				{
					t1 = 0;
					t2 = -1;
					comp1 = 0;
					comp2 = z;
				}

				addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);

				// revolution vertex
				revolutionAngle = i * revolutionAngleDelta;
				x = _topRadius * Math.cos(revolutionAngle);
				y = _topRadius * Math.sin(revolutionAngle);

				if (_yUp)
				{
					comp1 = -z;
					comp2 = y;
				}
				else
				{
					comp1 = y;
					comp2 = z;
				}

				if (i == _segmentsW)
				{
					addVertex(_rawData[startIndex + _stride], _rawData[startIndex + _stride + 1], _rawData[startIndex + _stride + 2], 0, t1, t2, 1, 0, 0);
				}
				else
				{
					addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
				}

				if (i > 0) // add triangle
					addTriangleClockWise(_nextVertexIndex - 1, _nextVertexIndex - 3, _nextVertexIndex - 2);
			}
		}

		// bottom
		if (_bottomClosed && _bottomRadius > 0)
		{

			z = 0.5 * _height;

			startIndex = _vertexOffset + _nextVertexIndex * _stride;

			for (i in 0..._segmentsW+1)
			{
				if (_yUp)
				{
					t1 = -1;
					t2 = 0;
					comp1 = -z;
					comp2 = 0;
				}
				else
				{
					t1 = 0;
					t2 = 1;
					comp1 = 0;
					comp2 = z;
				}

				addVertex(0, comp1, comp2, 0, t1, t2, 1, 0, 0);

				// revolution vertex
				revolutionAngle = i * revolutionAngleDelta;
				x = _bottomRadius * Math.cos(revolutionAngle);
				y = _bottomRadius * Math.sin(revolutionAngle);

				if (_yUp)
				{
					comp1 = -z;
					comp2 = y;
				}
				else
				{
					comp1 = y;
					comp2 = z;
				}

				if (i == _segmentsW)
				{
					addVertex(x, _rawData[startIndex + 1], _rawData[startIndex + 2], 0, t1, t2, 1, 0, 0);
				}
				else
				{
					addVertex(x, comp1, comp2, 0, t1, t2, 1, 0, 0);
				}

				if (i > 0) // add triangle
					addTriangleClockWise(_nextVertexIndex - 2, _nextVertexIndex - 3, _nextVertexIndex - 1);
			}
		}

		// The normals on the lateral surface all have the same incline, i.e.
		// the "elevation" component (Y or Z depending on yUp) is constant.
		// Same principle goes for the "base" of these vectors, which will be
		// calculated such that a vector [base,elev] will be a unit vector.
		dr = (_bottomRadius - _topRadius);
		latNormElev = dr / _height;
		latNormBase = (latNormElev == 0) ? 1 : _height / dr;


		// lateral surface
		if (_surfaceClosed)
		{
			var a:UInt, b:UInt, c:UInt, d:UInt;
			var na0:Float, na1:Float, naComp1:Float, naComp2:Float;

			for (j in 0..._segmentsH+1)
			{
				radius = _topRadius - ((j / _segmentsH) * (_topRadius - _bottomRadius));
				z = -(_height / 2) + (j / _segmentsH * _height);

				startIndex = _vertexOffset + _nextVertexIndex * _stride;

				for (i in 0..._segmentsW+1)
				{
					// revolution vertex
					revolutionAngle = i * revolutionAngleDelta;
					x = radius * Math.cos(revolutionAngle);
					y = radius * Math.sin(revolutionAngle);
					na0 = latNormBase * Math.cos(revolutionAngle);
					na1 = latNormBase * Math.sin(revolutionAngle);

					if (_yUp)
					{
						t1 = 0;
						t2 = -na0;
						comp1 = -z;
						comp2 = y;
						naComp1 = latNormElev;
						naComp2 = na1;

					}
					else
					{
						t1 = -na0;
						t2 = 0;
						comp1 = y;
						comp2 = z;
						naComp1 = na1;
						naComp2 = latNormElev;
					}

					if (i == _segmentsW)
					{
						addVertex(_rawData[startIndex], _rawData[startIndex + 1], _rawData[startIndex + 2],
							na0, latNormElev, na1,
							na1, t1, t2);
					}
					else
					{
						addVertex(x, comp1, comp2,
							na0, naComp1, naComp2,
							-na1, t1, t2);
					}

					// close triangle
					if (i > 0 && j > 0)
					{
						a = _nextVertexIndex - 1; // current
						b = _nextVertexIndex - 2; // previous
						c = b - _segmentsW - 1; // previous of last level
						d = a - _segmentsW - 1; // current of last level
						addTriangleClockWise(a, b, c);
						addTriangleClockWise(a, c, d);
					}
				}
			}
		}

		// build real data from raw data
		target.updateData(_rawData);
		target.updateIndexData(_rawIndices);
	}

	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var i:Int, j:Int;
		var x:Float, y:Float, revolutionAngle:Float;
		var stride:UInt = target.UVStride;
		var skip:UInt = stride - 2;
		var UVData:Vector<Float>;

		// evaluate num uvs
		var numUvs:Int = _numVertices * stride;

		// need to initialize raw array or can be reused?
		if (target.UVData != null && numUvs == target.UVData.length)
			UVData = target.UVData;
		else
		{
			UVData = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}

		// evaluate revolution steps
		var revolutionAngleDelta:Float = 2 * Math.PI / _segmentsW;

		// current uv component index
		var currentUvCompIndex:UInt = target.UVOffset;

		// top
		if (_topClosed)
		{
			for (i in 0..._segmentsW+1)
			{

				revolutionAngle = i * revolutionAngleDelta;
				x = 0.5 + 0.5 * -Math.cos(revolutionAngle);
				y = 0.5 + 0.5 * Math.sin(revolutionAngle);

				UVData[currentUvCompIndex++] = 0.5; // central vertex
				UVData[currentUvCompIndex++] = 0.5;
				currentUvCompIndex += skip;
				UVData[currentUvCompIndex++] = x; // revolution vertex
				UVData[currentUvCompIndex++] = y;
				currentUvCompIndex += skip;
			}
		}

		// bottom
		if (_bottomClosed)
		{
			for (i in 0..._segmentsW+1)
			{

				revolutionAngle = i * revolutionAngleDelta;
				x = 0.5 + 0.5 * Math.cos(revolutionAngle);
				y = 0.5 + 0.5 * Math.sin(revolutionAngle);

				UVData[currentUvCompIndex++] = 0.5; // central vertex
				UVData[currentUvCompIndex++] = 0.5;
				currentUvCompIndex += skip;
				UVData[currentUvCompIndex++] = x; // revolution vertex
				UVData[currentUvCompIndex++] = y;
				currentUvCompIndex += skip;
			}
		}

		// lateral surface
		if (_surfaceClosed)
		{
			for (j in 0..._segmentsH+1)
			{
				for (i in 0..._segmentsW+1)
				{
					// revolution vertex
					UVData[currentUvCompIndex++] = i / _segmentsW;
					UVData[currentUvCompIndex++] = j / _segmentsH;
					currentUvCompIndex += skip;
				}
			}
		}

		// build real data from raw data
		target.updateData(UVData);
	}

	/**
	 * The radius of the top end of the cylinder.
	 */
	public var topRadius(get, set):Float;
	private function get_topRadius():Float
	{
		return _topRadius;
	}

	private function set_topRadius(value:Float):Float
	{
		_topRadius = value;
		invalidateGeometry();
		return _topRadius;
	}

	/**
	 * The radius of the bottom end of the cylinder.
	 */
	public var bottomRadius(get, set):Float;
	private function get_bottomRadius():Float
	{
		return _bottomRadius;
	}

	private function set_bottomRadius(value:Float):Float
	{
		_bottomRadius = value;
		invalidateGeometry();
		return _bottomRadius;
	}

	/**
	 * The radius of the top end of the cylinder.
	 */
	public var height(get, set):Float;
	private function get_height():Float
	{
		return _height;
	}

	private function set_height(value:Float):Float
	{
		_height = value;
		invalidateGeometry();
		return _height;
	}

	/**
	 * Defines the number of horizontal segments that make up the cylinder. Defaults to 16.
	 */
	public var segmentsW(get, set):Int;
	private function get_segmentsW():Int
	{
		return _segmentsW;
	}

	private function set_segmentsW(value:Int):Int
	{
		_segmentsW = value;
		invalidateGeometry();
		invalidateUVs();
		return _segmentsW;
	}

	/**
	 * Defines the number of vertical segments that make up the cylinder. Defaults to 1.
	 */
	public var segmentsH(get, set):Int;
	private function get_segmentsH():Int
	{
		return _segmentsH;
	}

	private function set_segmentsH(value:Int):Int
	{
		_segmentsH = value;
		invalidateGeometry();
		invalidateUVs();
		return _segmentsH;
	}

	/**
	 * Defines whether the top end of the cylinder is closed (true) or open.
	 */
	public var topClosed(get, set):Bool;
	private function get_topClosed():Bool
	{
		return _topClosed;
	}

	private function set_topClosed(value:Bool):Bool
	{
		_topClosed = value;
		invalidateGeometry();
		return _topClosed;
	}

	/**
	 * Defines whether the bottom end of the cylinder is closed (true) or open.
	 */
	public var bottomClosed(get, set):Bool;
	private function get_bottomClosed():Bool
	{
		return _bottomClosed;
	}

	private function set_bottomClosed(value:Bool):Bool
	{
		_bottomClosed = value;
		invalidateGeometry();
		return _bottomClosed;
	}

	/**
	 * Defines whether the cylinder poles should lay on the Y-axis (true) or on the Z-axis (false).
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
}
