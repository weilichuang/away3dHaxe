package away3d.entities.primitives;

import away3d.entities.SegmentSet;
import flash.geom.Vector3D;


using away3d.math.FVector3D;

/**
* Class WireframeAxesGrid generates a grid of lines on a given plane<code>WireframeAxesGrid</code>
* @param	subDivision			[optional] uint . Default is 10;
* @param	gridSize			[optional] uint . Default is 100;
* @param	thickness			[optional] Number . Default is 1;
* @param	colorXY				[optional] uint. Default is 0x0000FF.
* @param	colorZY				[optional] uint. Default is 0xFF0000. 
* @param	colorXZ				[optional] uint. Default is 0x00FF00.
*/

class WireframeAxesGrid extends SegmentSet
{
	private static inline var PLANE_ZY:String = "zy";
	private static inline var PLANE_XY:String = "xy";
	private static inline var PLANE_XZ:String = "xz";

	public function new(subDivision:Int = 10, gridSize:Int = 100, thickness:Float = 1, 
						colorXY : UInt = 0x0000FF, colorZY : UInt = 0xFF0000, colorXZ : UInt = 0x00FF00) 
	{
		super();

		if(subDivision == 0) subDivision = 1;
		if(thickness <= 0) thickness = 1;
		if(gridSize ==  0) gridSize = 1;

		build(subDivision, gridSize, colorXY, thickness, PLANE_XY);
		build(subDivision, gridSize, colorZY, thickness, PLANE_ZY);
		build(subDivision, gridSize, colorXZ, thickness, PLANE_XZ);
	}

	private function build(subDivision:Int, gridSize:Int, color:UInt, thickness:Float, plane:String):Void
	{
		var bound:Float = gridSize *.5;
		var step:Float = gridSize/subDivision;
		var v0 : Vector3D = new Vector3D(0, 0, 0);
		var v1 : Vector3D = new Vector3D(0, 0, 0);
		var inc:Float = -bound;

		while (inc <= bound)
		{
			switch(plane)
			{
				case PLANE_ZY:
					v0.fastSetTo(0, inc, bound);
					v1.fastSetTo(0, inc, -bound);
					addSegment( new LineSegment(v0, v1, color, color, thickness));

					v0.fastSetTo(0, bound, inc);
					v1.fastSetTo(0, -bound, inc);
					addSegment(new LineSegment(v0, v1, color, color, thickness ));
					
				case PLANE_XY:
					v0.fastSetTo(bound, inc, 0);
					v1.fastSetTo(-bound, inc, 0);
					addSegment( new LineSegment(v0, v1, color, color, thickness));

					v0.fastSetTo(inc, bound, 0);
					v1.fastSetTo(inc, -bound, 0);
					addSegment(new LineSegment(v0, v1, color, color, thickness ));
					
				default:

					v0.fastSetTo(bound, 0, inc);
					v1.fastSetTo(-bound, 0, inc);
					addSegment( new LineSegment(v0, v1, color, color, thickness));

					v0.fastSetTo(inc, 0, bound);
					v1.fastSetTo(inc, 0, -bound);
					addSegment(new LineSegment(v0, v1, color, color, thickness ));
			}

			inc += step;
		}
	}

}
