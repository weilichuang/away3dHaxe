package away3d.core.base.data;

/**
* Texture coordinates value object.
*/
class UV
{
	/**
	 * Defines the vertical coordinate of the texture value.
	 */
	public var v:Float;
	/**
	 * Defines the horizontal coordinate of the texture value.
	 */
	public var u:Float;

	/**
	 * Creates a new <code>UV</code> object.
	 *
	 * @param	u		[optional]	The horizontal coordinate of the texture value. Defaults to 0.
	 * @param	v		[optional]	The vertical coordinate of the texture value. Defaults to 0.
	 */
	public function new(u:Float = 0, v:Float = 0)
	{
		this.u = u;
		this.v = v;
	}

	/**
	 * returns a new UV value Object
	 */
	public function clone():UV
	{
		return new UV(u, v);
	}

	/**
	 * returns the value object as a string for trace/debug purpose
	 */
	public function toString():String
	{
		return u + "," + v;
	}


}
