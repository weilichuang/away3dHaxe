package a3d.utils;
import flash.Vector;

/**
 * ...
 * @author 
 */
class VectorUtil<T>
{

	public static inline function toUIntVector(array:Array<Int>):Vector<UInt>
	{
		return untyped __vector__(array);
	}
	
	public static inline function insert<T>(list:Vector<T>, pos:Int, element:T):Void 
	{
		var rightCount:Int =  list.length - pos;
		var listAfter:Vector<T> = list.splice(pos, rightCount);
		
		list.push(element);
		for (i in 0...rightCount)
		{
			list.push(listAfter[i]);
		}
	};
}