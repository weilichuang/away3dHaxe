package a3d.entities.primitives;

import flash.errors.Error;
import flash.geom.Vector3D;

/**
 * A WirefameCube primitive mesh.
 */
class WireframeCube extends WireframePrimitiveBase
{
	private var _width:Float;
	private var _height:Float;
	private var _depth:Float;

	/**
	 * Creates a new WireframeCube object.
	 * @param width The size of the cube along its X-axis.
	 * @param height The size of the cube along its Y-axis.
	 * @param depth The size of the cube along its Z-axis.
	 * @param color The colour of the wireframe lines
	 * @param thickness The thickness of the wireframe lines
	 */
	public function new(width:Float = 100, height:Float = 100, depth:Float = 100, color:UInt = 0xFFFFFF, thickness:Float = 1)
	{
		super(color, thickness);

		_width = width;
		_height = height;
		_depth = depth;
	}

	/**
	 * The size of the cube along its X-axis.
	 */
	private inline function get_width():Float
	{
		return _width;
	}

	private inline function set_width(value:Float):Void
	{
		_width = value;
		invalidateGeometry();
	}

	/**
	 * The size of the cube along its Y-axis.
	 */
	private inline function get_height():Float
	{
		return _height;
	}

	private inline function set_height(value:Float):Void
	{
		if (value <= 0)
			throw new Error("Value needs to be greater than 0");
		_height = value;
		invalidateGeometry();
	}

	/**
	 * The size of the cube along its Z-axis.
	 */
	private inline function get_depth():Float
	{
		return _depth;
	}

	private inline function set_depth(value:Float):Void
	{
		_depth = value;
		invalidateGeometry();
	}

	/**
	 * @inheritDoc
	 */
	override private function buildGeometry():Void
	{
		var v0:Vector3D = new Vector3D();
		var v1:Vector3D = new Vector3D();
		var hw:Float = _width * .5;
		var hh:Float = _height * .5;
		var hd:Float = _depth * .5;

		v0.x = -hw;
		v0.y = hh;
		v0.z = -hd;
		v1.x = -hw;
		v1.y = -hh;
		v1.z = -hd;

		updateOrAddSegment(0, v0, v1);
		v0.z = hd;
		v1.z = hd;
		updateOrAddSegment(1, v0, v1);
		v0.x = hw;
		v1.x = hw;
		updateOrAddSegment(2, v0, v1);
		v0.z = -hd;
		v1.z = -hd;
		updateOrAddSegment(3, v0, v1);

		v0.x = -hw;
		v0.y = -hh;
		v0.z = -hd;
		v1.x = hw;
		v1.y = -hh;
		v1.z = -hd;
		updateOrAddSegment(4, v0, v1);
		v0.y = hh;
		v1.y = hh;
		updateOrAddSegment(5, v0, v1);
		v0.z = hd;
		v1.z = hd;
		updateOrAddSegment(6, v0, v1);
		v0.y = -hh;
		v1.y = -hh;
		updateOrAddSegment(7, v0, v1);

		v0.x = -hw;
		v0.y = -hh;
		v0.z = -hd;
		v1.x = -hw;
		v1.y = -hh;
		v1.z = hd;
		updateOrAddSegment(8, v0, v1);
		v0.y = hh;
		v1.y = hh;
		updateOrAddSegment(9, v0, v1);
		v0.x = hw;
		v1.x = hw;
		updateOrAddSegment(10, v0, v1);
		v0.y = -hh;
		v1.y = -hh;
		updateOrAddSegment(11, v0, v1);
	}
}
