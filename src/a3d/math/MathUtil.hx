package a3d.math;


/**
 * MathConsts provides some commonly used mathematical constants
 */
class MathUtil
{
	public static inline function INT_MAX_VALUE():Int
	{
		return 2147483647;
	}
	
	public static inline function INT_MIN_VALUE():Int
	{
		return -2147483648;
	}
	
	public static inline function FLOAT_MAX_VALUE():Float
	{
		return 1.79e+308;
	}
	
	public static inline function FLOAT_MIN_VALUE():Float
	{
		return 5e-324;
	}
	
	//public static inline function UINT_MAX_VALUE():Int
	//{
		//return 4294967295;
	//}
	//
	//public static inline function UINT_MIN_VALUE():Int
	//{
		//return 0;
	//}
	
	/**
	 * The amount to multiply with when converting radians to degrees.
	 */
	public static inline function RADIANS_TO_DEGREES():Float
	{
		return 180 / Math.PI;
	}

	/**
	 * The amount to multiply with when converting degrees to radians.
	 */
	public static inline function DEGREES_TO_RADIANS():Float 
	{
		return Math.PI / 180;
	}
	
	public static inline function fclamp(value:Float, min:Float, max:Float):Float
	{
		if (value <= min)
			return min;
		else if (value >= max)
			return max;
		else
			return value;
	}
	
	public static inline function max(a:Int, b:Int):Int
	{
		return a > b ? a : b;
	}
	
	public static inline function min(a:Int, b:Int):Int
	{
		return a < b ? a : b;
	}
	
	public static inline function toPrecision(value:Float,precision:Int):String
	{
		return untyped value.toPrecision(precision);
	}
	
}

