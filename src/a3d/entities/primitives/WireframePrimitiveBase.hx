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

	public function WireframePrimitiveBase(color:UInt = 0xffffff, thickness:Float = 1)
	{
		if (thickness <= 0)
			thickness = 1;
		_color = color;
		_thickness = thickness;
		mouseEnabled = mouseChildren = false;
	}

	private inline function get_color():UInt
	{
		return _color;
	}

	private inline function set_color(value:UInt):Void
	{
		var numSegments:UInt = _segments.length;

		_color = value;

		for (var i:Int = 0; i < numSegments; ++i)
			_segments[i].startColor = _segments[i].endColor = value;
	}

	private inline function get_thickness():Float
	{
		return _thickness;
	}

	private inline function set_thickness(value:Float):Void
	{
		var numSegments:UInt = _segments.length;

		_thickness = value;

		for (var i:Int = 0; i < numSegments; ++i)
			_segments[i].thickness = _segments[i].thickness = value;
	}

	override public function removeAllSegments():Void
	{
		super.removeAllSegments();
	}

	override private inline function get_bounds():BoundingVolumeBase
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

		if (_segments.length > index)
		{
			segment = _segments[index];
			s = segment.start;
			e = segment.end;
			s.x = v0.x;
			s.y = v0.y;
			s.z = v0.z;
			e.x = v1.x;
			e.y = v1.y;
			e.z = v1.z;
			_segments[index].updateSegment(s, e, null, _color, _color, _thickness);
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
