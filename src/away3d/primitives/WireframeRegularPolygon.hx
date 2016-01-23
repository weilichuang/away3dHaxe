package away3d.primitives;
import flash.geom.Vector3D;

/**
 * A WireframeRegularPolygon primitive mesh.
 */
class WireframeRegularPolygon extends WireframePrimitiveBase
{
	public static inline var ORIENTATION_YZ:String = "yz";
	public static inline var ORIENTATION_XY:String = "xy";
	public static inline var ORIENTATION_XZ:String = "xz";
	
	/**
	 * The orientaion in which the polygon lies.
	 */
	public var orientation(get, set):String;
	/**
	 * The radius of the regular polygon.
	 */
	public var radius(get, set):Float;
	/**
	 * The number of sides to the regular polygon.
	 */
	public var sides(get, set):Int;

	private var _radius : Float;
	private var _sides : Int;
	private var _orientation : String;

	/**
	 * Creates a new WireframeRegularPolygon object.
	 * @param radius The radius of the polygon.
	 * @param sides The number of sides on the polygon.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 * @param orientation The orientaion in which the plane lies.
	 */
	public function new(radius : Float, sides : Int, 
						color:UInt = 0xFFFFFF, thickness:Float = 1, 
						orientation : String = "yz") 
	{
		super(color, thickness);

		_radius = radius;
		_sides = sides;
		_orientation = orientation;
	}

	
	private function get_orientation() : String
	{
		return _orientation;
	}

	private function set_orientation(value : String) : String
	{
		_orientation = value;
		invalidateGeometry();
		return _orientation;
	}

	
	private function get_radius() : Float
	{
		return _radius;
	}

	private function set_radius(value : Float) : Float
	{
		_radius = value;
		invalidateGeometry();
		return _radius;
	}

	
	private function get_sides() : Int
	{
		return _sides;
	}

	private function set_sides(value : Int) : Int
	{
		_sides = value;
		removeAllSegments();
		invalidateGeometry();
		return _sides;
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry() : Void
	{
		var v0 : Vector3D = new Vector3D();
		var v1 : Vector3D = new Vector3D();
		var index : Int = 0;
		var s : Int;
		var pi:Float = Math.PI;

		if (_orientation == ORIENTATION_XY)
		{
			v0.z = 0;
			v1.z = 0;

			for (s in 0..._sides) 
			{
				v0.x = _radius * Math.cos(2 * pi * s/_sides);
				v0.y = _radius * Math.sin(2 * pi * s/_sides);
				v1.x = _radius * Math.cos(2 * pi * (s+1)/_sides);
				v1.y = _radius * Math.sin(2 * pi * (s+1)/_sides);
				updateOrAddSegment(index++, v0, v1);
			}
		}

		else if (_orientation == ORIENTATION_XZ) 
		{
			v0.y = 0;
			v1.y = 0;

			for (s in 0..._sides)
			{
				v0.x = _radius * Math.cos(2 * pi * s/_sides);
				v0.z = _radius * Math.sin(2 * pi * s/_sides);
				v1.x = _radius * Math.cos(2 * pi * (s+1)/_sides);
				v1.z = _radius * Math.sin(2 * pi * (s+1)/_sides);
				updateOrAddSegment(index++, v0, v1);
			}
		}

		else if (_orientation == ORIENTATION_YZ)
		{
			v0.x = 0;
			v1.x = 0;

			for (s in 0..._sides) 
			{
				v0.z = _radius * Math.cos(2 * pi * s/_sides);
				v0.y = _radius * Math.sin(2 * pi * s/_sides);
				v1.z = _radius * Math.cos(2 * pi * (s+1)/_sides);
				v1.y = _radius * Math.sin(2 * pi * (s+1)/_sides);
				updateOrAddSegment(index++, v0, v1);
			}
		}
	}
}