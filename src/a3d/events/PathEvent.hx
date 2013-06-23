package a3d.events
{
	import flash.events.Event;

	class PathEvent extends Event
	{
		/**
		 * Dispatched when the time pointer enter a new cycle at time 0, after last time was greater than 0.99
		 */
		public static inline var CYCLE:String = "cycle";

		/**
		 * Dispatched when the time pointer is included a given from/to time region on a path
		 */
		public static inline var RANGE:String = "range";

		/**
		 * Dispatched when the time pointer enters a new PathSegment
		 */
		public static inline var CHANGE_SEGMENT:String = "change_segment";

		public function PathEvent(type:String)
		{
			super(type);
		}
	}
}
