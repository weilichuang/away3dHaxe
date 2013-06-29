package a3d.entities.primitives;


import a3d.bounds.BoundingVolumeBase;
import a3d.entities.SegmentSet;
import a3d.errors.AbstractMethodError;
import a3d.entities.primitives.data.Segment;

import flash.geom.Vector3D;



class WireframePrimitiveBase extends SegmentSet
{
	private var _geomDirty:Bool = true;
	private var _color:UInt;
	private var _thickness:Float;

	public function new(color:UInt = 0xffffff, thickness:Float = 1)
	{
		super();
		if (thickness <= 0)
			thickness = 1;
		_color = color;
		_thickness = thickness;
		mouseEnabled = mouseChildren = false;
	}

	public var color(get, set):UInt;
	private inline function get_color():UInt
	{
		return _color;
	}

	private inline function set_color(value:UInt):UInt
	{
		_color = value;

		var iterator:Iterator<SegRef> = _segments.iterator();
		for (ref in iterator)
		{
			var segment:Segment = ref.segment;
			segment.startColor = segment.endColor = value;
		}
		
		return _color;
	}

	public var thickness(get, set):Float;
	private inline function get_thickness():Float
	{
		return _thickness;
	}

	private inline function set_thickness(value:Float):Float
	{
		_thickness = value;

		var iterator:Iterator<SegRef> = _segments.iterator();
		for (ref in iterator)
		{
			var segment:Segment = ref.segment;
			segment.thickness = value;
		}
		
		return _thickness;
	}

	override public function removeAllSegments():Void
	{
		super.removeAllSegments();
	}

	override private function get_bounds():BoundingVolumeBase
	{
		if (_geomDirty)
			updateGeometry();
		return super.bounds;
	}

	private function buildGeometry():Void
	{
		throw new AbstractMethodError();
	}

	private function invalidateGeometry():Void
	{
		_geomDirty = true;
		invalidateBounds();
	}

	private function updateGeometry():Void
	{
		buildGeometry();
		_geomDirty = false;
	}

	private function updateOrAddSegment(index:UInt, v0:Vector3D, v1:Vector3D):Void
	{
		var segment:Segment;
		var s:Vector3D, e:Vector3D;

		if (_segments.exists(index))
		{
			segment = _segments.get(index).segment;
			s = segment.start;
			e = segment.end;
			s.x = v0.x;
			s.y = v0.y;
			s.z = v0.z;
			e.x = v1.x;
			e.y = v1.y;
			e.z = v1.z;
			segment.updateSegment(s, e, null, _color, _color, _thickness);
		}
		else
		{
			addSegment(new LineSegment(v0.clone(), v1.clone(), _color, _color, _thickness));
		}
	}

	override private function updateMouseChildren():Void
	{
		_ancestorsAllowMouseEnabled = false;
	}
}
