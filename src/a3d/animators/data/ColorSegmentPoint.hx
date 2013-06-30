package a3d.animators.data;

import flash.geom.ColorTransform;


class ColorSegmentPoint
{
	private var _color:ColorTransform;
	private var _life:Float;

	public function new(life:Float, color:ColorTransform)
	{
		//0<life<1
		if (life <= 0 || life >= 1)
			throw(new Error("life exceeds range (0,1)"));
		_life = life;
		_color = color;
	}

	private function get_color():ColorTransform
	{
		return _color;
	}

	private function get_life():Float
	{
		return _life;
	}

}
