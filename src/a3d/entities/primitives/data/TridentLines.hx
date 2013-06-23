package a3d.entities.primitives.data
{
	import flash.geom.Vector3D;
	
	import a3d.entities.SegmentSet;
	import a3d.entities.primitives.LineSegment;

	class TridentLines extends SegmentSet
	{
		public function TridentLines(vectors:Vector<Vector<Vector3D>>, colors:Vector<UInt>):Void
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
			
			for(var i:UInt= 0; i<vectors.length;++i){
				color = colors[i];
				letter = vectors[i];
				
				for(j =0; j<letter.length; j+=2){
					v0 = letter[j];
					v1 = letter[j+1];
					addSegment( new LineSegment(v0, v1, color, color, 1));
				}
			}
		}

	}
}

 