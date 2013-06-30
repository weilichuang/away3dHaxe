package a3d.paths;

import flash.geom.Vector3D;

/**
 * Holds information about a single Path definition.
 * DEBUG OPTION OUT AT THIS TIME OF DEV
 */
class QuadraticPath extends SegmentedPathBase implements IPath
{
	private var _averaged:Bool;
	private var _smoothed:Bool;

	/**
	 * Creates a new <code>Path</code> object.
	 *
	 * @param	 aVectors		[optional] An array of a series of Vector3D's organized in the following fashion. [a,b,c,a,b,c etc...] a = pEnd, b=pControl (control point), c = v2
	 */

	public function new(data:Vector<Vector3D> = null)
	{
		super(3, data);
	}

	/**
	 * returns true if the smoothPath handler is being used.
	 */
	private function get_smoothed():Bool
	{
		return _smoothed;
	}

	override private function createSegmentFromArrayEntry(data:Vector<Vector3D>, offset:UInt):IPathSegment
	{
		return new QuadraticPathSegment(data[offset], data[offset + 1], data[offset + 2]);
	}

	override private function stitchSegment(start:IPathSegment, middle:IPathSegment, end:IPathSegment):Void
	{
		var seg:QuadraticPathSegment = QuadraticPathSegment(middle);
		var prevSeg:QuadraticPathSegment = QuadraticPathSegment(start);
		var nextSeg:QuadraticPathSegment = QuadraticPathSegment(end);

		prevSeg.control.x = (prevSeg.control.x + seg.control.x) * .5;
		prevSeg.control.y = (prevSeg.control.y + seg.control.y) * .5;
		prevSeg.control.z = (prevSeg.control.z + seg.control.z) * .5;

		nextSeg.control.x = (nextSeg.control.x + seg.control.x) * .5;
		nextSeg.control.y = (nextSeg.control.y + seg.control.y) * .5;
		nextSeg.control.z = (nextSeg.control.z + seg.control.z) * .5;

		prevSeg.end.x = (seg.start.x + seg.end.x) * .5;
		prevSeg.end.y = (seg.start.y + seg.end.y) * .5;
		prevSeg.end.z = (seg.start.z + seg.end.z) * .5;

		nextSeg.start.x = prevSeg.end.x;
		nextSeg.start.y = prevSeg.end.y;
		nextSeg.start.z = prevSeg.end.z;
	}


	/**
	 * returns true if the averagePath handler is being used.
	 */
	private function get_averaged():Bool
	{
		return _averaged;
	}

	/**
	 * handler will smooth the path using anchors as control vector of the PathSegments
	 * note that this is not dynamic, the PathSegments values are overwrited
	 */
	public function smoothPath():Void
	{
		if (_segments.length <= 2)
			return;

		_smoothed = true;
		_averaged = false;

		var x:Float;
		var y:Float;
		var z:Float;
		var seg0:Vector3D;
		var seg1:Vector3D;
		var tmp:Vector<Vector3D> = new Vector<Vector3D>();
		var i:UInt;

		var seg:QuadraticPathSegment = Std.instance(_segments[0],QuadraticPathSegment);
		var segnext:QuadraticPathSegment = Std.instance(_segments[_segments.length - 1],QuadraticPathSegment);

		var startseg:Vector3D = new Vector3D(seg.start.x, seg.start.y, seg.start.z);
		var endseg:Vector3D = new Vector3D(segnext.end.x, segnext.end.y, segnext.end.z);

		for (i = 0; i < numSegments - 1; ++i)
		{
			seg = Std.instance(_segments[i],QuadraticPathSegment);
			segnext = Std.instance(_segments[i + 1],QuadraticPathSegment);

			if (seg.control == null)
				seg.control = seg.end;

			if (segnext.control == null)
				segnext.control = segnext.end;

			seg0 = seg.control;
			seg1 = segnext.control;
			x = (seg0.x + seg1.x) * .5;
			y = (seg0.y + seg1.y) * .5;
			z = (seg0.z + seg1.z) * .5;

			tmp.push(startseg, new Vector3D(seg0.x, seg0.y, seg0.z), new Vector3D(x, y, z));
			startseg = new Vector3D(x, y, z);
			seg = null;
		}

		seg0 = QuadraticPathSegment(_segments[_segments.length - 1]).control;
		tmp.push(startseg, new Vector3D((seg0.x + seg1.x) * .5, (seg0.y + seg1.y) * .5, (seg0.z + seg1.z) * .5), endseg);

		_segments = new Vector<IPathSegment>();

		for (i = 0; i < tmp.length; i += 3)
			_segments.push(new QuadraticPathSegment(tmp[i], tmp[i + 1], tmp[i + 2]));

		tmp = null;
	}

	/**
	 * handler will average the path using averages of the PathSegments
	 * note that this is not dynamic, the path values are overwrited
	 */
	public function averagePath():Void
	{
		_averaged = true;
		_smoothed = false;

		var seg:QuadraticPathSegment;

		for (i in 0..._segments.length)
		{
			seg = Std.instance(_segments[i],QuadraticPathSegment);
			seg.control.x = (seg.start.x + seg.end.x) * .5;
			seg.control.y = (seg.start.y + seg.end.y) * .5;
			seg.control.z = (seg.start.z + seg.end.z) * .5;
		}
	}

	public function continuousCurve(points:Vector<Vector3D>, closed:Bool = false):Void
	{
		var aVectors:Vector<Vector3D> = new Vector<Vector3D>();
		var i:UInt;
		var X:Float;
		var Y:Float;
		var Z:Float;
		var midPoint:Vector3D;

		// Find the mid points and inject them into the array.
		for (i = 0; i < points.length - 1; i++)
		{
			var currentPoint:Vector3D = points[i];
			var nextPoint:Vector3D = points[i + 1];

			X = (currentPoint.x + nextPoint.x) / 2;
			Y = (currentPoint.y + nextPoint.y) / 2;
			Z = (currentPoint.z + nextPoint.z) / 2;
			midPoint = new Vector3D(X, Y, Z);

			if (i)
				aVectors.push(midPoint);

			if (i < points.length - 2 || closed)
			{
				aVectors.push(midPoint);
				aVectors.push(nextPoint);
			}
		}

		if (closed)
		{
			currentPoint = points[points.length - 1];
			nextPoint = points[0];
			X = (currentPoint.x + nextPoint.x) / 2;
			Y = (currentPoint.y + nextPoint.y) / 2;
			Z = (currentPoint.z + nextPoint.z) / 2;
			midPoint = new Vector3D(X, Y, Z);

			aVectors.push(midPoint);
			aVectors.push(midPoint);
			aVectors.push(points[0]);
			aVectors.push(aVectors[0]);
		}

		_segments = new Vector<IPathSegment>();

		for (i = 0; i < aVectors.length; i += 3)
			_segments.push(new QuadraticPathSegment(aVectors[i], aVectors[i + 1], aVectors[i + 2]));
	}
}
