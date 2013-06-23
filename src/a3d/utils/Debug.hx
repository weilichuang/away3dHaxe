package a3d.utils
{

	/** Class for emmiting debuging messages, warnings and errors */
	class Debug
	{
		public static var active:Bool = false;
		public static var warningsAsErrors:Bool = false;

		public static function clear():Void
		{
		}

		public static function delimiter():Void
		{
		}

		public static function trace(message:Object):Void
		{
			if (active)
				dotrace(message);
		}

		public static function warning(message:Object):Void
		{
			if (warningsAsErrors)
			{
				error(message);
				return;
			}
			dotrace("WARNING: " + message);
		}

		public static function error(message:Object):Void
		{
			dotrace("ERROR: " + message);
			throw new Error(message);
		}
	}
}

/**
 * @private
 */
function dotrace(message:Object):Void
{
	trace(message);
}
