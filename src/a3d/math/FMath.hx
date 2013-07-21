package a3d.math;


/**
 * MathConsts provides some commonly used mathematical constants
 */
class FMath
{
	public static inline var PI:Float = 3.141592653589793;
	
	public static inline function DOUBLEPI():Float
	{
		return PI * 2;
	}
	
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
	
	public static inline function lengthSquared(x:Float,y:Float,z:Float):Float
	{
		return x * x + y * y + z * z;
	}
	
	public static inline function sqrt(value:Float):Float
	{
		return Math.sqrt(value);
	}
	
	public static inline function invSqrt(value:Float):Float
	{
		return 1 / sqrt(value);
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
	
	public static inline function clamp(value:Int, min:Int, max:Int):Int
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
	
	public static inline function fabs(a:Float):Float
	{
		return a > 0 ? a : -a;
	}
	
	public static inline function abs(a:Int):Int
	{
		return a > 0 ? a : -a;
	}
	
	public static inline function toPrecision(value:Float,precision:Int):String
	{
		return untyped value.toPrecision(precision);
	}
	
}

