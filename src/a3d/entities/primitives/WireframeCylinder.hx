package a3d.entities.primitives;

import flash.geom.Vector3D;

/**
 * Generates a wireframd cylinder primitive.
 */
class WireframeCylinder extends WireframePrimitiveBase
{
	private static inline var TWO_PI:Float = 2 * Math.PI;

	private var _topRadius:Float;
	private var _bottomRadius:Float;
	private var _height:Float;
	private var _segmentsW:UInt;
	private var _segmentsH:UInt;

	/**
	 * Creates a new WireframeCylinder instance
	 * @param topRadius Top radius of the cylinder
	 * @param bottomRadius Bottom radius of the cylinder
	 * @param height The height of the cylinder
	 * @param segmentsW Number of radial segments
	 * @param segmentsH Number of vertical segments
	 * @param color The color of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(topRadius:Float = 50, bottomRadius:Float = 50, height:Float = 100, segmentsW:UInt = 16, segmentsH:UInt = 1, color:UInt = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);
		_topRadius = topRadius;
		_bottomRadius = bottomRadius;
		_height = height;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
	}


	override private function buildGeometry():Void
	{

		var i:UInt, j:UInt;
		var radius:Float = _topRadius;
		var revolutionAngle:Float;
		var revolutionAngleDelta:Float = TWO_PI / _segmentsW;
		var nextVertexIndex:Int = 0;
		var x:Float, y:Float, z:Float;
		var lastLayer:Vector<Vector<Vector3D>> = new Vector<Vector<Vector3D>>(_segmentsH + 1, true);

		for (j = 0; j <= _segmentsH; ++j)
		{
			lastLayer[j] = new Vector<Vector3D>(_segmentsW + 1, true);

			radius = _topRadius - ((j / _segmentsH) * (_topRadius - _bottomRadius));
			z = -(_height / 2) + (j / _segmentsH * _height);

			var previousV:Vector3D = null;

			for (i = 0; i <= _segmentsW; ++i)
			{
				// revolution vertex
				revolutionAngle = i * revolutionAngleDelta;
				x = radius * Math.cos(revolutionAngle);
				y = radius * Math.sin(revolutionAngle);
				var vertex:Vector3D;
				if (previousV)
				{
					vertex = new Vector3D(x, -z, y);
					updateOrAddSegment(nextVertexIndex++, vertex, previousV);
					previousV = vertex;
				}
				else
				{
					previousV = new Vector3D(x, -z, y);
				}

				if (j > 0)
					updateOrAddSegment(nextVertexIndex++, vertex, lastLayer[j - 1][i]);
				lastLayer[j][i] = previousV;
			}
		}
	}


	/**
	 * Top radius of the cylinder
	 */
	private inline function get_topRadius():Float
	{
		return _topRadius;
	}


	private inline function set_topRadius(value:Float):Void
	{
		_topRadius = value;
		invalidateGeometry();
	}


	/**
	 * Bottom radius of the cylinder
	 */
	private inline function get_bottomRadius():Float
	{
		return _bottomRadius;
	}


	private inline function set_bottomRadius(value:Float):Void
	{
		_bottomRadius = value;
		invalidateGeometry();
	}


	/**
	 * The height of the cylinder
	 */
	private inline function get_height():Float
	{
		return _height;
	}


	private inline function set_height(value:Float):Void
	{
		if (height <= 0)
			throw new Error('Height must be a value greater than zero.');
		_height = value;
		invalidateGeometry();
	}
}
