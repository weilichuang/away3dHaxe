package a3d.core.base.data;

/**
* Vertex value object.
*/
class Vertex
{
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;
	public var index(get, set):Int;
	
	private var _x:Float;
	private var _y:Float;
	private var _z:Float;
	private var _index:Int;

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
		_x = x;
		_y = y;
		_z = z;
		_index = index;
	}

	/**
	* To define/store the index of value object
	* @param	ind		The index
	*/
	private inline function set_index(ind:Int):Int
	{
		return _index = ind;
	}

	private inline function get_index():Int
	{
		return _index;
	}

	/**
	* To define/store the x value of the value object
	* @param	value		The x value
	*/
	private inline function get_x():Float
	{
		return _x;
	}

	private inline function set_x(value:Float):Float
	{
		return _x = value;
	}

	/**
	* To define/store the y value of the value object
	* @param	value		The y value
	*/
	private inline function get_y():Float
	{
		return _y;
	}

	private inline function set_y(value:Float):Float
	{
		return _y = value;
	}

	/**
	* To define/store the z value of the value object
	* @param	value		The z value
	*/
	private inline function get_z():Float
	{
		return _z;
	}

	private inline function set_z(value:Float):Float
	{
		return _z = value;
	}

	/**
	 * returns a new Vertex value Object
	 */
	public function clone():Vertex
	{
		return new Vertex(_x, _y, _z);
	}

	/**
	 * returns the value object as a string for trace/debug purpose
	 */
	public function toString():String
	{
		return _x + "," + _y + "," + _z;
	}


}
