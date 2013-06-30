package a3d.materials.utils;
import flash.display3D.Context3DVertexBufferFormat;

/**
 * ...
 * @author ...
 */
class VertexFormatUtil
{

	public static inline function getVertexBufferFormat(size:Int):Context3DVertexBufferFormat
	{
		switch(size)
		{
			case 1:
				return Context3DVertexBufferFormat.FLOAT_1;
			case 2:
				return Context3DVertexBufferFormat.FLOAT_2;
			case 3:
				return Context3DVertexBufferFormat.FLOAT_3;
			case 4:
				return Context3DVertexBufferFormat.FLOAT_3;
			default:
				return null;
		}
	}
	
}