package away3d.entities.primitives;


import away3d.core.base.CompactSubGeometry;
import flash.Vector;



/**
 * A UV Sphere primitive mesh.
 */
class SphereGeometry extends PrimitiveBase
{
	/**
	 * The radius of the sphere.
	 */
	public var radius(get, set):Float;
	/**
	 * Defines the number of horizontal segments that make up the sphere. Defaults to 16.
	 */
	public var segmentsW(get, set):Int;
	/**
	 * Defines the number of vertical segments that make up the sphere. Defaults to 12.
	 */
	public var segmentsH(get, set):Int;
	/**
	 * Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public var yUp(get, set):Bool;
	
	private var _radius:Float;
	private var _segmentsW:Int;
	private var _segmentsH:Int;
	private var _yUp:Bool;

	/**
	 * Creates a new Sphere object.
	 * @param radius The radius of the sphere.
	 * @param segmentsW Defines the number of horizontal segments that make up the sphere.
	 * @param segmentsH Defines the number of vertical segments that make up the sphere.
	 * @param yUp Defines whether the sphere poles should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function new(radius:Float = 50, segmentsW:Int = 16, segmentsH:Int = 12, yUp:Bool = true)
	{
		super();

		_radius = radius;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
		_yUp = yUp;
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry(target:CompactSubGeometry):Void
	{
		var vertices:Vector<Float>;
		var indices:Vector<UInt>;
		var triIndex:Int = 0;
		var numVerts:Int = (_segmentsH + 1) * (_segmentsW + 1);
		var stride:Int = target.vertexStride;
		var skip:Int = stride - 9;

		if (numVerts == target.numVertices)
		{
			vertices = target.vertexData;
			if (target.indexData != null)
			{
				indices = target.indexData;
			}
			else
			{
				indices = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);
			}
			
		}
		else
		{
			vertices = new Vector<Float>(numVerts * stride, true);
			indices = new Vector<UInt>((_segmentsH - 1) * _segmentsW * 6, true);
			invalidateGeometry();
		}

		var startIndex:UInt;
		var index:UInt = target.vertexOffset;
		var comp1:Float, comp2:Float, t1:Float, t2:Float;

		for (j in 0..._segmentsH + 1)
		{
			startIndex = index;

			var horangle:Float = Math.PI * j / _segmentsH;
			var z:Float = -_radius * Math.cos(horangle);
			var ringradius:Float = _radius * Math.sin(horangle);

			for (i in 0..._segmentsW + 1)
			{
				var verangle:Float = 2 * Math.PI * i / _segmentsW;
				var x:Float = ringradius * Math.cos(verangle);
				var y:Float = ringradius * Math.sin(verangle);
				var normLen:Float = 1 / Math.sqrt(x * x + y * y + z * z);
				var tanLen:Float = Math.sqrt(y * y + x * x);

				if (_yUp)
				{
					t1 = 0;
					t2 = tanLen > .007 ? x / tanLen : 0;
					comp1 = -z;
					comp2 = y;

				}
				else
				{
					t1 = tanLen > .007 ? x / tanLen : 0;
					t2 = 0;
					comp1 = y;
					comp2 = z;
				}

				if (i == _segmentsW)
				{
					vertices[index++] = vertices[startIndex];
					vertices[index++] = vertices[startIndex + 1];
					vertices[index++] = vertices[startIndex + 2];
					vertices[index++] = vertices[startIndex + 3] + (x * normLen) * .5;
					vertices[index++] = vertices[startIndex + 4] + (comp1 * normLen) * .5;
					vertices[index++] = vertices[startIndex + 5] + (comp2 * normLen) * .5;
					vertices[index++] = tanLen > .007 ? -y / tanLen : 1;
					vertices[index++] = t1;
					vertices[index++] = t2;

				}
				else
				{
					vertices[index++] = x;
					vertices[index++] = comp1;
					vertices[index++] = comp2;
					vertices[index++] = x * normLen;
					vertices[index++] = comp1 * normLen;
					vertices[index++] = comp2 * normLen;
					vertices[index++] = tanLen > .007 ? -y / tanLen : 1;
					vertices[index++] = t1;
					vertices[index++] = t2;
				}

				if (i > 0 && j > 0)
				{
					var a:Int = (_segmentsW + 1) * j + i;
					var b:Int = (_segmentsW + 1) * j + i - 1;
					var c:Int = (_segmentsW + 1) * (j - 1) + i - 1;
					var d:Int = (_segmentsW + 1) * (j - 1) + i;

					if (j == _segmentsH)
					{
						vertices[index - 9] = vertices[startIndex];
						vertices[index - 8] = vertices[startIndex + 1];
						vertices[index - 7] = vertices[startIndex + 2];

						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;

					}
					else if (j == 1)
					{
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;

					}
					else
					{
						indices[triIndex++] = a;
						indices[triIndex++] = b;
						indices[triIndex++] = c;
						indices[triIndex++] = a;
						indices[triIndex++] = c;
						indices[triIndex++] = d;
					}
				}

				index += skip;
			}
		}

		target.updateData(vertices);
		target.updateIndexData(indices);
	}

	/**
	 * @inheritDoc
	 */
	override private function buildUVs(target:CompactSubGeometry):Void
	{
		var stride:Int = target.UVStride;
		var numUvs:Int = (_segmentsH + 1) * (_segmentsW + 1) * stride;
		var data:Vector<Float>;
		var skip:Int = stride - 2;

		if (target.UVData != null && numUvs == target.UVData.length)
			data = target.UVData;
		else
		{
			data = new Vector<Float>(numUvs, true);
			invalidateGeometry();
		}

		var su:Float = target.scaleU;
		var sv:Float = target.scaleV;
		var index:Int = target.UVOffset;
		for (j in 0..._segmentsH + 1)
		{
			for (i in 0..._segmentsW + 1)
			{
				data[index++] = ( i / _segmentsW ) * su;
				data[index++] = ( j / _segmentsH ) * sv;
				index += skip;
			}
		}

		target.updateData(data);
	}

	
	private function get_radius():Float
	{
		return _radius;
	}

	private function set_radius(value:Float):Float
	{
		_radius = value;
		invalidateGeometry();
		return value;
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
		return value;
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
		return value;
	}

	
	private function get_yUp():Bool
	{
		return _yUp;
	}

	private function set_yUp(value:Bool):Bool
	{
		_yUp = value;
		invalidateGeometry();
		return value;
	}
}
