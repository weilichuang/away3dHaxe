package away3d.core.base.data;

/**
* Vertex value object.
*/
class Vertex
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var index:Int;

	/**
	* Creates a new <code>Vertex</code> value object.
	*
	* @param	x			[optional]	The x value. Defaults to 0.
	* @param	y			[optional]	The y value. Defaults to 0.
	* @param	z			[optional]	The z value. Defaults to 0.
	* @param	index		[optional]	The index value. Defaults is NaN.
	*/
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, index:Int = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.index = index;
	}

	/**
	 * returns a new Vertex value Object
	 */
	public function clone():Vertex
	{
		return new Vertex(x, y, z);
	}

	/**
	 * returns the value object as a string for trace/debug purpose
	 */
	public function toString():String
	{
		return x + "," + y + "," + z;
	}


}
