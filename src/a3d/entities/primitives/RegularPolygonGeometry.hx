package a3d.entities.primitives;


/**
 * A UV RegularPolygon primitive mesh.
 */
class RegularPolygonGeometry extends CylinderGeometry
{

	/**
	 * The radius of the regular polygon.
	 */
	private inline function get_radius():Float
	{
		return _bottomRadius;
	}

	private inline function set_radius(value:Float):Void
	{
		_bottomRadius = value;
		invalidateGeometry();
	}


	/**
	 * The number of sides of the regular polygon.
	 */
	private inline function get_sides():UInt
	{
		return _segmentsW;
	}

	private inline function set_sides(value:UInt):Void
	{
		segmentsW = value;
	}

	/**
	 * The number of subdivisions from the edge to the center of the regular polygon.
	 */
	private inline function get_subdivisions():UInt
	{
		return _segmentsH;
	}

	private inline function set_subdivisions(value:UInt):Void
	{
		segmentsH = value;
	}

	/**
	 * Creates a new RegularPolygon disc object.
	 * @param radius The radius of the regular polygon
	 * @param sides Defines the number of sides of the regular polygon.
	 * @param yUp Defines whether the regular polygon should lay on the Y-axis (true) or on the Z-axis (false).
	 */
	public function RegularPolygonGeometry(radius:Float = 100, sides:UInt = 16, yUp:Bool = true)
	{
		super(radius, 0, 0, sides, 1, true, false, false, yUp);
	}
}
