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
		_thickness = thickness * .5;
		// TODO: add support for curve using anchor v1
		// Prefer removing v1 from this, and make Curve a separate class extending Segment? (- David)
		_start = start.clone();
		_end = end.clone();
		startColor = colorStart;
		endColor = colorEnd;
	}

	public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D,
								colorStart:UInt = 0x333333, colorEnd:UInt = 0x333333, thickness:Float = 1):Void
	{
		_start.copyFrom(start);
		_end.copyFrom(end);

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
	public var start(get, set):Vector3D;
	private function get_start():Vector3D
	{
		return _start;
	}

	private function set_start(value:Vector3D):Vector3D
	{
		_start = value;
		update();
		
		return _start;
	}

	/**
	 * Defines the ending vertex.
	 */
	public var end(get, set):Vector3D;
	private function get_end():Vector3D
	{
		return _end;
	}

	private function set_end(value:Vector3D):Vector3D
	{
		_end = value;
		update();
		
		return _end;
	}

	/**
	 * Defines the ending vertex.
	 */
	public var thickness(get, set):Float;
	private function get_thickness():Float
	{
		return _thickness * 2;
	}

	private function set_thickness(value:Float):Float
	{
		_thickness = value * .5;
		update();
		
		return value;
	}

	/**
	 * Defines the startColor
	 */
	public var startColor(get, set):UInt;
	private function get_startColor():UInt
	{
		return _startColor;
	}

	private function set_startColor(color:UInt):UInt
	{
		startR = ((color >> 16) & 0xff) / 255;
		startG = ((color >> 8) & 0xff) / 255;
		startB = (color & 0xff) / 255;

		_startColor = color;

		update();
		
		return _startColor;
	}

	/**
	 * Defines the endColor
	 */
	public var endColor(get, set):UInt;
	private function get_endColor():UInt
	{
		return _endColor;
	}

	private function set_endColor(color:UInt):UInt
	{
		endR = ((color >> 16) & 0xff) / 255;
		endG = ((color >> 8) & 0xff) / 255;
		endB = (color & 0xff) / 255;

		_endColor = color;

		update();
		
		return _endColor;
	}

	public function dispose():Void
	{
		_start = null;
		_end = null;
	}

	public var index(get, set):Int;
	private function get_index():Int
	{
		return _index;
	}

	private function set_index(ind:Int):Int
	{
		return _index = ind;
	}

	public var subSetIndex(get, set):Int;
	private function get_subSetIndex():Int
	{
		return _subSetIndex;
	}

	private function set_subSetIndex(ind:Int):Int
	{
		return _subSetIndex = ind;
	}

	public var segmentsBase(get, set):SegmentSet;
	private function set_segmentsBase(segBase:SegmentSet):SegmentSet
	{
		return _segmentsBase = segBase;
	}

	private function get_segmentsBase():SegmentSet
	{
		return _segmentsBase;
	}

	private function update():Void
	{
		if (_segmentsBase == null)
			return;
		_segmentsBase.updateSegment(this);
	}

}
