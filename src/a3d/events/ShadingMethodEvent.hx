package a3d.events
{
	import flash.events.Event;

	class ShadingMethodEvent extends Event
	{
		public static inline var SHADER_INVALIDATED:String = "ShaderInvalidated";

		public function ShadingMethodEvent(type:String, bubbles:Bool = false, cancelable:Bool = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}
