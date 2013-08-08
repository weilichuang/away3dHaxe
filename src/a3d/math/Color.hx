package a3d.math;

import flash.Vector;

class Color
{
	public var r:Float = 0;

	public var g:Float = 0;

	public var b:Float = 0;

	public var a:Float = 0;

	/**
	 * Constructor instantiates a new <code>Color</code> object. The
	 * values are defined as passed parameters. These values are then clamped
	 * to insure that they are between 0 and 1.
	 * @param r the red component of this color.
	 * @param g the green component of this color.
	 * @param b the blue component of this color.
	 * @param a the alpha component of this color.
	 */
	public function new(r:Float = 0.0, g:Float = 0.0, b:Float = 0.0, a:Float = 1.0)
	{
		setTo(r, g, b, a);
	}
	
	public inline function setRGBA(r:Float, g:Float, b:Float, a:Float = 255):Void
	{
		var invert:Float = 1 / 255;
		this.r = r * invert;
		this.g = g * invert;
		this.b = b * invert;
		this.a = a * invert;
	}

	//		
	public inline function setTo(r:Float, g:Float, b:Float, a:Float = 1.0):Void
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
	
	public inline function toUniform(result:Vector<Float>):Void
	{
		result[0] = r;
		result[1] = g;
		result[2] = b;
		result[3] = a;
	}

	public function get_color():Int
	{
		return (Std.int(a * 255) << 24 | Std.int(r * 255) << 16 | Std.int(g * 255) << 8 | Std.int(b * 255));
	}

	public function set_color(value:Int):Int
	{
		var invert:Float = 1 / 255;
		a = (value >> 24 & 0xFF) * invert;
		r = (value >> 16 & 0xFF) * invert;
		g = (value >> 8 & 0xFF) * invert;
		b = (value & 0xFF) * invert;
		return value;
	}

	public function setRGB(color:Int):Void
	{
		var invert:Float = 1 / 255;
		r = (color >> 16 & 0xFF) * invert;
		g = (color >> 8 & 0xFF) * invert;
		b = (color & 0xFF) * invert;
	}

	public inline function clone():Color
	{
		return new Color(r, g, b, a);
	}

	public inline function copyFrom(other:Color):Void
	{
		setTo(other.r, other.g, other.b, other.a);
	}

	public function equals(other:Color):Bool
	{
		return r == other.r && g == other.g && b == other.b && a == other.a;
	}

	public function toString():String
	{
		return 'Color($r,$g,$b,$a)';
	}
}