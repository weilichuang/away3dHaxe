package away3d.loaders.parsers.utils;

import away3d.math.FMath;
import flash.utils.ByteArray;

class ParserUtil
{
	/**
	 * Returns a object as ByteArray, if possible.
	 * 
	 * @param data The object to return as ByteArray
	 * 
	 * @return The ByteArray or null
	 *
	 */
	public static function toByteArray(data:Dynamic):ByteArray
	{
		if (Std.is(data,Class))
			data = Type.createInstance(data,[]);

		if (Std.is(data,ByteArray))
			return data;
		else
			return null;
	}

	/**
	 * Returns a object as String, if possible.
	 * 
	 * @param data The object to return as String
	 * @param length The length of the returned String
	 * 
	 * @return The String or null
	 *
	 */
	public static function toString(data:Dynamic, length:Int = 0):String
	{
		var ba:ByteArray;

		if (length == 0)
		{
			length = FMath.INT_MAX_VALUE();
		}	

		if (Std.is(data,String))
			return Std.instance(data,String).substr(0, length);

		ba = toByteArray(data);
		if (ba != null)
		{
			ba.position = 0;
			return ba.readUTFBytes(FMath.min(ba.bytesAvailable, length));
		}

		return null;
	}
}
