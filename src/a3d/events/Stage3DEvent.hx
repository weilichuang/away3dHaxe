/**
 *
 */
package a3d.events
{
	import flash.events.Event;

	class Stage3DEvent extends Event
	{
		public static inline var CONTEXT3D_CREATED:String = "Context3DCreated";
		public static inline var CONTEXT3D_DISPOSED:String = "Context3DDisposed";
		public static inline var CONTEXT3D_RECREATED:String = "Context3DRecreated";
		public static inline var VIEWPORT_UPDATED:String = "ViewportUpdated";

		public function Stage3DEvent(type:String, bubbles:Bool = false, cancelable:Bool = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
