package away3d.entities.primitives;

import away3d.core.base.CompactSubGeometry;
import flash.Vector;



/**
 * A Cube primitive mesh.
 */
class CubeGeometry extends PrimitiveBase
{
	/**
	 * The size of the cube along its X-axis.
	 */
	public var width(get, set):Float;
	/**
	 * The size of the cube along its Y-axis.
	 */
	public var height(get, set):Float;
	/**
	 * The size of the cube along its Z-axis.
	 */
	public var depth(get, set):Float;
	/**
	 * The type of uv mapping to use. When false, the entire image is mapped on each face.
	 * When true, a texture will be subdivided in a 3x2 grid, each used for a single face.
	 * Reading the tiles from left to right, top to bottom they represent the faces of the
	 * cube in the following order: bottom, top, back, left, front, right. This creates
	 * several shared edges (between the top, front, left and right faces) which simplifies
	 * texture painting.
	 */
	public var tile6(get, set):Bool;
	/**
	 * The number of segments that make up the cube along the X-axis. Defaults to 1.
	 */
	public var segmentsW(get, set):Int;
	/**
	 * The number of segments that make up the cube along the Y-axis. Defaults to 1.
	 */
	public var segmentsH(get, set):Int;
	/**
	 * The number of segments that make up the cube along the Z-axis. Defaults to 1.
	 */
	public var segmentsD(get, set):Int;
	
	private var _width:Float;
	private var _height:Float;
	private var _depth:Float;
	private var _tile6:Bool;

	private var _segmentsW:Int;
	private var _segmentsH:Int;
	private var _segmentsD:Int;

	/**
	 * Creates a new Cube object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param depth The size of the cube along its Z-axis.
	 * @param segmentsW The number of segments that make up the cube along the X-axis.
	 * @param segmentsH The number of segments that make up the cube along the Y-axis.
	 * @param segmentsD The number of segments that make up the cube along the Z-axis.
	 * @param tile6 The type of uv mapping to use. When true, a texture will be subdivided in a 2x3 grid, each used for a single face. When false, the entire image is mapped on each face.
	 */
	public function new(width:Float = 100, height:Float = 100, depth:Float = 100,
		segmentsW:Int = 1, segmentsH:Int = 1, segmentsD:Int = 1, tile6:Bool = true)
	{
		super();

		_width = width;
		_height = height;
		_depth = depth;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
		_segmentsD = segmentsD;
		_tile6 = tile6;
	}

	
	private function get_width():Float
	{
		return _width;
	}

	private function set_width(value:Float):Float
	{
		_width = value;
		invalidateGeometry();
		return _width;
	}

	
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

	
	private function get_depth():Float
	{
		return _depth;
	}

	private function set_depth(value:Float):Float
	{
		_depth = value;
		invalidateGeometry();
		return _depth;
	}

	
	private function get_tile6():Bool
	{
		return _tile6;
	}

	private function set_tile6(value:Bool):Bool
	{
		_tile6 = value;
		invalidateUVs();
		return _tile6;
	}

	
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

	
	private function get_segmentsD():Int
	{
		return _segmentsD;
	}

	private function set_segmentsD(value:Int):Int
	{
		_segmentsD = value;
		invalidateGeometry();
		invalidateUVs();
		return _segmentsD;
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var data:Vector<Float>;
		var indices:Vector<UInt>;

		var tl:Int, tr:Int, bl:Int, br:Int;
		var inc:Int = 0;

		var vidx:UInt, fidx:UInt; // indices
		var hw:Float, hh:Float, hd:Float; // halves
		var dw:Float, dh:Float, dd:Float; // deltas

		var outer_pos:Float;

		var numVerts:Int = ((_segmentsW + 1) * (_segmentsH + 1) +
							(_segmentsW + 1) * (_segmentsD + 1) +
							(_segmentsH + 1) * (_segmentsD + 1)) * 2;

		var stride:Int = target.vertexStride;
		var skip:Int = stride - 9;

		if (numVerts == target.numVertices)
		{
			data = target.vertexData;
			if (target.indexData != null)
			{
				indices = target.indexData;
			}
			else
			{
				indices = new Vector<UInt>((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12, true);
			}
		}
		else
		{
			data = new Vector<Float>(numVerts * stride, true);
			indices = new Vector<UInt>((_segmentsW * _segmentsH + _segmentsW * _segmentsD + _segmentsH * _segmentsD) * 12, true);
			invalidateUVs();
		}

		// Indices
		vidx = target.vertexOffset;
		fidx = 0;

		// half cube dimensions
		hw = _width / 2;
		hh = _height / 2;
		hd = _depth / 2;

		// Segment dimensions
		dw = _width / _segmentsW;
		dh = _height / _segmentsH;
		dd = _depth / _segmentsD;

		for (i in 0..._segmentsW + 1)
		{
			outer_pos = -hw + i * dw;

			for (j in 0..._segmentsH + 1)
			{
				// front
				data[vidx++] = outer_pos;
				data[vidx++] = -hh + j * dh;
				data[vidx++] = -hd;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = -1;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;

				// back
				data[vidx++] = outer_pos;
				data[vidx++] = -hh + j * dh;
				data[vidx++] = hd;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;

				if (i!= 0 && j!= 0)
				{
					tl = 2 * ((i - 1) * (_segmentsH + 1) + (j - 1));
					tr = 2 * (i * (_segmentsH + 1) + (j - 1));
					bl = tl + 2;
					br = tr + 2;

					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
				}
			}
		}

		inc += 2 * (_segmentsW + 1) * (_segmentsH + 1);

		for (i in 0..._segmentsW + 1)
		{
			outer_pos = -hw + i * dw;

			for (j in 0..._segmentsD + 1)
			{
				// top
				data[vidx++] = outer_pos;
				data[vidx++] = hh;
				data[vidx++] = -hd + j * dd;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;

				// bottom
				data[vidx++] = outer_pos;
				data[vidx++] = -hh;
				data[vidx++] = -hd + j * dd;
				data[vidx++] = 0;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				vidx += skip;

				if (i!= 0 && j!= 0)
				{
					tl = inc + 2 * ((i - 1) * (_segmentsD + 1) + (j - 1));
					tr = inc + 2 * (i * (_segmentsD + 1) + (j - 1));
					bl = tl + 2;
					br = tr + 2;

					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
				}
			}
		}

		inc += 2 * (_segmentsW + 1) * (_segmentsD + 1);

		for (i in 0..._segmentsD+1)
		{
			outer_pos = hd - i * dd;

			for (j in 0..._segmentsH+1)
			{
				// left
				data[vidx++] = -hw;
				data[vidx++] = -hh + j * dh;
				data[vidx++] = outer_pos;
				data[vidx++] = -1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = -1;
				vidx += skip;

				// right
				data[vidx++] = hw;
				data[vidx++] = -hh + j * dh;
				data[vidx++] = outer_pos;
				data[vidx++] = 1;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 0;
				data[vidx++] = 1;
				vidx += skip;

				if (i!= 0 && j!= 0)
				{
					tl = inc + 2 * ((i - 1) * (_segmentsH + 1) + (j - 1));
					tr = inc + 2 * (i * (_segmentsH + 1) + (j - 1));
					bl = tl + 2;
					br = tr + 2;

					indices[fidx++] = tl;
					indices[fidx++] = bl;
					indices[fidx++] = br;
					indices[fidx++] = tl;
					indices[fidx++] = br;
					indices[fidx++] = tr;
					indices[fidx++] = tr + 1;
					indices[fidx++] = br + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tr + 1;
					indices[fidx++] = bl + 1;
					indices[fidx++] = tl + 1;
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
		var uidx:UInt;
		var data:Vector<Float>;

		var u_tile_dim:Float, v_tile_dim:Float;
		var u_tile_step:Float, v_tile_step:Float;
		var tl0u:Float, tl0v:Float;
		var tl1u:Float, tl1v:Float;
		var du:Float, dv:Float;
		var stride:Int = target.UVStride;
		var numUvs:Int = ((_segmentsW + 1) * (_segmentsH + 1) +
			(_segmentsW + 1) * (_segmentsD + 1) +
			(_segmentsH + 1) * (_segmentsD + 1)) * 2 * stride;
		var skip:Int = stride - 2;

		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else
		{
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}

		if (_tile6)
		{
			u_tile_dim = u_tile_step = 1 / 3;
			v_tile_dim = v_tile_step = 1 / 2;
		}
		else
		{
			u_tile_dim = v_tile_dim = 1;
			u_tile_step = v_tile_step = 0;
		}

		// Create planes two and two, the same way that they were
		// constructed in the buildGeometry() function. First calculate
		// the top-left UV coordinate for both planes, and then loop
		// over the points, calculating the UVs from these numbers.

		// When tile6 is true, the layout is as follows:
		//       .-----.-----.-----. (1,1)
		//       | Bot |  T  | Bak |
		//       |-----+-----+-----|
		//       |  L  |  F  |  R  |
		// (0,0)'-----'-----'-----'

		uidx = target.UVOffset;
		
		var sv:Float = target.scaleV;
		var su:Float = target.scaleU;

		// FRONT / BACK
		tl0u = 1 * u_tile_step;
		tl0v = 1 * v_tile_step;
		tl1u = 2 * u_tile_step;
		tl1v = 0 * v_tile_step;
		du = u_tile_dim / _segmentsW;
		dv = v_tile_dim / _segmentsH;
		
		for (i in 0..._segmentsW + 1)
		{
			for (j in 0..._segmentsH + 1)
			{
				data[uidx++] = ( tl0u + i * du ) * su;
				data[uidx++] = ( tl0v + (v_tile_dim - j * dv)) * sv;
				uidx += skip;
				data[uidx++] = ( tl1u + (u_tile_dim - i * du)) * su;
				data[uidx++] = ( tl1v + (v_tile_dim - j * dv)) * sv;
				uidx += skip;
			}
		}

		// TOP / BOTTOM
		tl0u = 1 * u_tile_step;
		tl0v = 0 * v_tile_step;
		tl1u = 0 * u_tile_step;
		tl1v = 0 * v_tile_step;
		du = u_tile_dim / _segmentsW;
		dv = v_tile_dim / _segmentsD;
		for (i in 0..._segmentsW + 1)
		{
			for (j in 0..._segmentsD + 1)
			{
				data[uidx++] = ( tl0u + i * du) * su;
				data[uidx++] = ( tl0v + (v_tile_dim - j * dv)) * sv;
				uidx += skip;
				data[uidx++] = ( tl1u + i * du) * su;
				data[uidx++] = ( tl1v + j * dv) * sv;
				uidx += skip;
			}
		}

		// LEFT / RIGHT
		tl0u = 0 * u_tile_step;
		tl0v = 1 * v_tile_step;
		tl1u = 2 * u_tile_step;
		tl1v = 1 * v_tile_step;
		du = u_tile_dim / _segmentsD;
		dv = v_tile_dim / _segmentsH;
		for (i in 0..._segmentsD + 1)
		{
			for (j in 0..._segmentsH + 1)
			{
				data[uidx++] = ( tl0u + i * du) * su;
				data[uidx++] = ( tl0v + (v_tile_dim - j * dv)) * sv;
				uidx += skip;
				data[uidx++] = ( tl1u + (u_tile_dim - i * du)) * su;
				data[uidx++] = ( tl1v + (v_tile_dim - j * dv)) * sv;
				uidx += skip;
			}
		}

		target.updateData(data);
	}
}
