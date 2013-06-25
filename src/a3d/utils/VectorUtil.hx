package a3d.utils;
import flash.Vector;

/**
 * ...
 * @author 
 */
class VectorUtil
{

	public static inline function toUIntVector(array:Array<Int>):Vector<UInt>
	{
		return untyped __vector__(array);
	}
	
}