package a3d.io.loaders.parsers.utils;

import flash.utils.ByteArray;

class ParserUtil
{
	public static function toByteArray(data:*):ByteArray
	{
		if (Std.is(data,Class))
			data = new data();

		if (Std.is(data,ByteArray))
			return data;
		else
			return null;
	}

	public static function toString(data:*, length:UInt = 0):String
	{
		var ba:ByteArray;

		length ||= uint.MAX_VALUE;

		if (Std.is(data,String))
			return String(data).substr(0, length);

		ba = toByteArray(data);
		if (ba)
		{
			ba.position = 0;
			return ba.readUTFBytes(Math.min(ba.bytesAvailable, length));
		}

		return null;
	}
}
