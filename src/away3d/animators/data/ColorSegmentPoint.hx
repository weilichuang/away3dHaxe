package away3d.animators.data;

import away3d.math.FMath;
import flash.errors.Error;
import flash.geom.ColorTransform;


class ColorSegmentPoint
{
	public var color(get, null):ColorTransform;
	public var life(get, null):Float;
	
	private var _color:ColorTransform;
	private var _life:Float;

	public function new(life:Float, color:ColorTransform)
	{	
		_life = FMath.fclamp(life, 0, 0.999);
		_color = color;
	}

	private inline function get_color():ColorTransform
	{
		return _color;
	}

	private inline function get_life():Float
	{
		return _life;
	}

}
