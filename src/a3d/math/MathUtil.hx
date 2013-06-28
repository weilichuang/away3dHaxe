package a3d.math;


/**
 * MathConsts provides some commonly used mathematical constants
 */
class MathUtil
{
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
}

