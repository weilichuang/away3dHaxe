package a3d.entities.primitives;

import flash.geom.Vector3D;

/**
 * A WireframeSphere primitive mesh
 */
class WireframeSphere extends WireframePrimitiveBase
{
	private var _segmentsW:UInt;
	private var _segmentsH:UInt;
	private var _radius:Float;

	/**
	 * Creates a new WireframeSphere object.
	 * @param radius The radius of the sphere.
	 * @param segmentsW Defines the number of horizontal segments that make up the sphere.
	 * @param segmentsH Defines the number of vertical segments that make up the sphere.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(radius:Float = 50, segmentsW:UInt = 16, segmentsH:UInt = 12, color:UInt = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);

		_radius = radius;
		_segmentsW = segmentsW;
		_segmentsH = segmentsH;
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry():Void
	{
		var vertices:Vector<Float> = new Vector<Float>();
		var v0:Vector3D = new Vector3D();
		var v1:Vector3D = new Vector3D();
		var i:UInt, j:UInt;
		var numVerts:UInt = 0;
		var index:Int;

		for (j = 0; j <= _segmentsH; ++j)
		{
			var horangle:Float = Math.PI * j / _segmentsH;
			var z:Float = -_radius * Math.cos(horangle);
			var ringradius:Float = _radius * Math.sin(horangle);

			for (i = 0; i <= _segmentsW; ++i)
			{
				var verangle:Float = 2 * Math.PI * i / _segmentsW;
				var x:Float = ringradius * Math.cos(verangle);
				var y:Float = ringradius * Math.sin(verangle);
				vertices[numVerts++] = x;
				vertices[numVerts++] = -z;
				vertices[numVerts++] = y;
			}
		}

		for (j = 1; j <= _segmentsH; ++j)
		{
			for (i = 1; i <= _segmentsW; ++i)
			{
				var a:Int = ((_segmentsW + 1) * j + i) * 3;
				var b:Int = ((_segmentsW + 1) * j + i - 1) * 3;
				var c:Int = ((_segmentsW + 1) * (j - 1) + i - 1) * 3;
				var d:Int = ((_segmentsW + 1) * (j - 1) + i) * 3;

				if (j == _segmentsH)
				{
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					v1.x = vertices[d];
					v1.y = vertices[d + 1];
					v1.z = vertices[d + 2];
					updateOrAddSegment(index++, v0, v1);
					v0.x = vertices[a];
					v0.y = vertices[a + 1];
					v0.z = vertices[a + 2];
					updateOrAddSegment(index++, v0, v1);
				}
				else if (j == 1)
				{
					v1.x = vertices[b];
					v1.y = vertices[b + 1];
					v1.z = vertices[b + 2];
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					updateOrAddSegment(index++, v0, v1);
				}
				else
				{
					v1.x = vertices[b];
					v1.y = vertices[b + 1];
					v1.z = vertices[b + 2];
					v0.x = vertices[c];
					v0.y = vertices[c + 1];
					v0.z = vertices[c + 2];
					updateOrAddSegment(index++, v0, v1);
					v1.x = vertices[d];
					v1.y = vertices[d + 1];
					v1.z = vertices[d + 2];
					updateOrAddSegment(index++, v0, v1);
				}
			}
		}
	}
}
