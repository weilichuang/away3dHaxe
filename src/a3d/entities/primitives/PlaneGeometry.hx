package a3d.entities.primitives;


import a3d.core.base.CompactSubGeometry;



/**
 * A Plane primitive mesh.
 */
class PlaneGeometry extends PrimitiveBase
{
	private var _segmentsW:UInt;
	private var _segmentsH:UInt;
	private var _yUp:Bool;
	private var _width:Float;
	private var _height:Float;
	private var _doubleSided:Bool;

	/**
	 * Creates a new Plane object.
	 * @param width The width of the plane.
	 * @param height The height of the plane.
	 * @param segmentsW The number of segments that make up the plane along the X-axis.
	 * @param segmentsH The number of segments that make up the plane along the Y or Z-axis.
	 * @param yUp Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false).
	 * @param doubleSided Defines whether the plane will be visible from both sides, with correct vertex normals.
	 */
	public function PlaneGeometry(width:Float = 100, height:Float = 100, segmentsW:UInt = 1, segmentsH:UInt = 1, yUp:Bool = true, doubleSided:Bool = false)
	{
		super();

		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
		_yUp = yUp;
		_width = width;
		_height = height;
		_doubleSided = doubleSided;
	}

	/**
	 * The number of segments that make up the plane along the X-axis. Defaults to 1.
	 */
	private inline function get_segmentsW():UInt
	{
		return _segmentsW;
	}

	private inline function set_segmentsW(value:UInt):Void
	{
		_segmentsW = value;
		invalidateGeometry();
		invalidateUVs();
	}

	/**
	 * The number of segments that make up the plane along the Y or Z-axis, depending on whether yUp is true or
	 * false, respectively. Defaults to 1.
	 */
	private inline function get_segmentsH():UInt
	{
		return _segmentsH;
	}

	private inline function set_segmentsH(value:UInt):Void
	{
		_segmentsH = value;
		invalidateGeometry();
		invalidateUVs();
	}

	/**
	 *  Defines whether the normal vector of the plane should point along the Y-axis (true) or Z-axis (false). Defaults to true.
	 */
	private inline function get_yUp():Bool
	{
		return _yUp;
	}

	private inline function set_yUp(value:Bool):Void
	{
		_yUp = value;
		invalidateGeometry();
	}

	/**
	 * Defines whether the plane will be visible from both sides, with correct vertex normals (as opposed to bothSides on Material). Defaults to false.
	 */
	private inline function get_doubleSided():Bool
	{
		return _doubleSided;
	}

	private inline function set_doubleSided(value:Bool):Void
	{
		_doubleSided = value;
		invalidateGeometry();
	}

	/**
	 * The width of the plane.
	 */
	private inline function get_width():Float
	{
		return _width;
	}

	private inline function set_width(value:Float):Void
	{
		_width = value;
		invalidateGeometry();
	}

	/**
	 * The height of the plane.
	 */
	private inline function get_height():Float
	{
		return _height;
	}

	private inline function set_height(value:Float):Void
	{
		_height = value;
		invalidateGeometry();
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;
		var x:Float, y:Float;
		var numIndices:UInt;
		var base:UInt;
		var tw:UInt = _segmentsW + 1;
		var numVertices:UInt = (_segmentsH + 1) * tw;
		var stride:UInt = target.vertexStride;
		var skip:UInt = stride - 9;
		if (_doubleSided)
			numVertices *= 2;

		numIndices = _segmentsH * _segmentsW * 6;
		if (_doubleSided)
			numIndices <<= 1;

		if (numVertices == target.numVertices)
		{
			data = target.vertexData;
			indices = target.indexData || new Vector<UInt>(numIndices, true);
		}
		else
		{
			data = new Vector<Float>(numVertices * stride, true);
			indices = new Vector<UInt>(numIndices, true);
			invalidateUVs();
		}

		numIndices = 0;
		var index:UInt = target.vertexOffset;
		for (var yi:UInt = 0; yi <= _segmentsH; ++yi)
		{
			for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
			{
				x = (xi / _segmentsW - .5) * _width;
				y = (yi / _segmentsH - .5) * _height;

				data[index++] = x;
				if (_yUp)
				{
					data[index++] = 0;
					data[index++] = y;
				}
				else
				{
					data[index++] = y;
					data[index++] = 0;
				}

				data[index++] = 0;
				if (_yUp)
				{
					data[index++] = 1;
					data[index++] = 0;
				}
				else
				{
					data[index++] = 0;
					data[index++] = -1;
				}

				data[index++] = 1;
				data[index++] = 0;
				data[index++] = 0;

				index += skip;


				// add vertex with same position, but with inverted normal & tangent
				if (_doubleSided)
				{
					for (var i:Int = 0; i < 3; ++i)
					{
						data[index] = data[index - stride];
						++index;
					}
					for (i = 0; i < 3; ++i)
					{
						data[index] = -data[index - stride];
						++index;
					}
					for (i = 0; i < 3; ++i)
					{
						data[index] = -data[index - stride];
						++index;
					}
					index += skip;
				}

				if (xi != _segmentsW && yi != _segmentsH)
				{
					base = xi + yi * tw;
					var mult:Int = _doubleSided ? 2 : 1;

					indices[numIndices++] = base * mult;
					indices[numIndices++] = (base + tw) * mult;
					indices[numIndices++] = (base + tw + 1) * mult;
					indices[numIndices++] = base * mult;
					indices[numIndices++] = (base + tw + 1) * mult;
					indices[numIndices++] = (base + 1) * mult;

					if (_doubleSided)
					{
						indices[numIndices++] = (base + tw + 1) * mult + 1;
						indices[numIndices++] = (base + tw) * mult + 1;
						indices[numIndices++] = base * mult + 1;
						indices[numIndices++] = (base + 1) * mult + 1;
						indices[numIndices++] = (base + tw + 1) * mult + 1;
						indices[numIndices++] = base * mult + 1;
					}
				}
			}
		}

		target.updateData(data);
		target.updateIndexData(indices);
	}

	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var stride:UInt = target.UVStride;
		var numUvs:UInt = (_segmentsH + 1) * (_segmentsW + 1) * stride;
		var skip:UInt = stride - 2;

		if (_doubleSided)
			numUvs *= 2;

		if (target.UVData && numUvs == target.UVData.length)
			data = target.UVData;
		else
		{
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}

		var index:UInt = target.UVOffset;

		for (var yi:UInt = 0; yi <= _segmentsH; ++yi)
		{
			for (var xi:UInt = 0; xi <= _segmentsW; ++xi)
			{
				data[index++] = xi / _segmentsW;
				data[index++] = 1 - yi / _segmentsH;
				index += skip;

				if (_doubleSided)
				{
					data[index++] = xi / _segmentsW;
					data[index++] = 1 - yi / _segmentsH;
					index += skip;
				}
			}
		}

		target.updateData(data);
	}
}
