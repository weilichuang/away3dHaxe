package away3d.entities.primitives.data;

import flash.geom.Vector3D;
import flash.Vector;

import away3d.entities.SegmentSet;
import away3d.entities.primitives.LineSegment;

class TridentLines extends SegmentSet
{
	public function new(vectors:Vector<Vector<Vector3D>>, colors:Vector<UInt>):Void
	{
		super();
		build(vectors, colors);
	}
	
	private function build(vectors:Vector<Vector<Vector3D>>, colors:Vector<UInt>):Void
	{
		var letter:Vector<Vector3D>;
		var v0 : Vector3D;
		var v1 : Vector3D;
		var color:UInt;
		var j:UInt;
		
		for (i in 0...vectors.length)
		{
			color = colors[i];
			letter = vectors[i];
			
			j = 0;
			while (j < letter.length)
			{
				v0 = letter[j];
				v1 = letter[j+1];
				addSegment( new LineSegment(v0, v1, color, color, 1));
				j += 2;
			}
		}
	}

}

 