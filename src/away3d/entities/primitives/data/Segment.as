package away3d.entities.primitives.data
{
	
	import away3d.entities.SegmentSet;

	import flash.geom.Vector3D;

	

	public class Segment
	{
		public var _segmentsBase:SegmentSet;
		public var _thickness:Number;
		public var _start:Vector3D;
		public var _end:Vector3D;
		public var _startR:Number;
		public var _startG:Number;
		public var _startB:Number;
		public var _endR:Number;
		public var _endG:Number;
		public var _endB:Number;

		private var _index:int = -1;
		private var _subSetIndex:int = -1;
		private var _startColor:uint;
		private var _endColor:uint;

		public function Segment(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:uint = 0x333333, colorEnd:uint = 0x333333, thickness:Number = 1):void
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

		public function updateSegment(start:Vector3D, end:Vector3D, anchor:Vector3D, colorStart:uint = 0x333333, colorEnd:uint = 0x333333, thickness:Number = 1):void
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
		public function get start():Vector3D
		{
			return _start;
		}

		public function set start(value:Vector3D):void
		{
			_start = value;
			update();
		}

		/**
		 * Defines the ending vertex.
		 */
		public function get end():Vector3D
		{
			return _end;
		}

		public function set end(value:Vector3D):void
		{
			_end = value;
			update();
		}

		/**
		 * Defines the ending vertex.
		 */
		public function get thickness():Number
		{
			return _thickness * 2;
		}

		public function set thickness(value:Number):void
		{
			_thickness = value * .5;
			update();
		}

		/**
		 * Defines the startColor
		 */
		public function get startColor():uint
		{
			return _startColor;
		}

		public function set startColor(color:uint):void
		{
			_startR = ((color >> 16) & 0xff) / 255;
			_startG = ((color >> 8) & 0xff) / 255;
			_startB = (color & 0xff) / 255;

			_startColor = color;

			update();
		}

		/**
		 * Defines the endColor
		 */
		public function get endColor():uint
		{
			return _endColor;
		}

		public function set endColor(color:uint):void
		{
			_endR = ((color >> 16) & 0xff) / 255;
			_endG = ((color >> 8) & 0xff) / 255;
			_endB = (color & 0xff) / 255;

			_endColor = color;

			update();
		}

		public function dispose():void
		{
			_start = null;
			_end = null;
		}

		public function get index():int
		{
			return _index;
		}

		public function set index(ind:int):void
		{
			_index = ind;
		}

		public function get subSetIndex():int
		{
			return _subSetIndex;
		}

		public function set subSetIndex(ind:int):void
		{
			_subSetIndex = ind;
		}

		public function set segmentsBase(segBase:SegmentSet):void
		{
			_segmentsBase = segBase;
		}

		private function update():void
		{
			if (!_segmentsBase)
				return;
			_segmentsBase.updateSegment(this);
		}

	}
}
