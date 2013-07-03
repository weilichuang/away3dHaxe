package a3d.io.loaders.parsers.utils;

import flash.utils.ByteArray;

class ParserUtil
{
	public static function toByteArray(data:Dynamic):ByteArray
	{
		if (Std.is(data,Class))
			data = Type.createInstance(data,[]);

		if (Std.is(data,ByteArray))
			return data;
		else
			return null;
	}

	public static function toString(data:Dynamic, length:Int = 0):String
	{
		var ba:ByteArray;

		if (length == 0)
		{
			length = Std.int(Math.POSITIVE_INFINITY);
		}	

		if (Std.is(data,String))
			return Std.instance(data,String).substr(0, length);

		ba = toByteArray(data);
		if (ba != null)
		{
			ba.position = 0;
			return ba.readUTFBytes(Std.int(Math.min(ba.bytesAvailable, length)));
		}

		return null;
	}
}
