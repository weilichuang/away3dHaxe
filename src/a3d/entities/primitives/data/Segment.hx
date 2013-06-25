package a3d.entities.primitives.data;


import a3d.entities.SegmentSet;

import flash.geom.Vector3D;



class Segment
{
	private var _segmentsBase:SegmentSet;
	private var _thickness:Float;
	private var _start:Vector3D;
	private var _end:Vector3D;
	public var startR:Float;
	public var startG:Float;
	public var startB:Float;
	public var endR:Float;
	public var endG:Float;
	public var endB:Float;

	private var _index:Int = -1;
	private var _subSetIndex:Int = -1;
	private var _startColor:UInt;
	private var _endColor:UInt;

	public function new(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:UInt = 0x333333, colorEnd:UInt = 0x333333, thickness:Float = 1):Void
	{
		// TODO: not yet used: for CurveSegment support
		anchor = null;

		_thickness = thickness * .5;
		// TODO: add support for curve using anchor v1
		// Prefer removing v1 from this, and make Curve a separate class extending Segment? (- David)
		_start = start;
		_end = end;
		startColor = colorStart;
		endColor = colorEnd;
	}

	public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:UInt = 0x333333, colorEnd:UInt = 0x333333, thickness:Float = 1):Void
	{
		// TODO: not yet used: for CurveSegment support
		anchor = null;
		_start = start;
		_end = end;

		if (_startColor != colorStart)
			startColor = colorStart;

		if (_endColor != colorEnd)
			endColor = colorEnd;

		_thickness = thickness * .5;
		update();
	}

	/**
	 * Defines the starting vertex.
	 */
	private inline function get_start():Vector3D
	{
		return _start;
	}

	private inline function set_start(value:Vector3D):Void
	{
		_start = value;
		update();
	}

	/**
	 * Defines the ending vertex.
	 */
	private inline function get_end():Vector3D
	{
		return _end;
	}

	private inline function set_end(value:Vector3D):Void
	{
		_end = value;
		update();
	}

	/**
	 * Defines the ending vertex.
	 */
	private inline function get_thickness():Float
	{
		return _thickness * 2;
	}

	private inline function set_thickness(value:Float):Void
	{
		_thickness = value * .5;
		update();
	}

	/**
	 * Defines the startColor
	 */
	private inline function get_startColor():UInt
	{
		return _startColor;
	}

	private inline function set_startColor(color:UInt):Void
	{
		startR = ((color >> 16) & 0xff) / 255;
		startG = ((color >> 8) & 0xff) / 255;
		startB = (color & 0xff) / 255;

		_startColor = color;

		update();
	}

	/**
	 * Defines the endColor
	 */
	private inline function get_endColor():UInt
	{
		return _endColor;
	}

	private inline function set_endColor(color:UInt):Void
	{
		endR = ((color >> 16) & 0xff) / 255;
		endG = ((color >> 8) & 0xff) / 255;
		endB = (color & 0xff) / 255;

		_endColor = color;

		update();
	}

	public function dispose():Void
	{
		_start = null;
		_end = null;
	}

	private inline function get_index():Int
	{
		return _index;
	}

	private inline function set_index(ind:Int):Void
	{
		_index = ind;
	}

	private inline function get_subSetIndex():Int
	{
		return _subSetIndex;
	}

	private inline function set_subSetIndex(ind:Int):Void
	{
		_subSetIndex = ind;
	}

	private inline function set_segmentsBase(segBase:SegmentSet):Void
	{
		_segmentsBase = segBase;
	}

	private inline function get_segmentsBase():SegmentSet
	{
		return _segmentsBase;
	}

	private function update():Void
	{
		if (!_segmentsBase)
			return;
		_segmentsBase.updateSegment(this);
	}

}
