package a3d.materials;

import flash.display.BlendMode;





/**
 * ColorMaterial is a material that uses a flat colour as the surfaces diffuse.
 */
class ColorMaterial extends SinglePassMaterialBase
{
	private var _diffuseAlpha:Float = 1;

	/**
	 * Creates a new ColorMaterial object.
	 * @param color The material's diffuse surface color.
	 * @param alpha The material's surface alpha.
	 */
	public function new(color:UInt = 0xcccccc, alpha:Float = 1)
	{
		super();
		this.color = color;
		this.alpha = alpha;
	}

	/**
	 * The alpha of the surface.
	 */
	private inline function get_alpha():Float
	{
		return _screenPass.diffuseMethod.diffuseAlpha;
	}

	private inline function set_alpha(value:Float):Void
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		_screenPass.diffuseMethod.diffuseAlpha = _diffuseAlpha = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
	}

	/**
	 * The diffuse color of the surface.
	 */
	private inline function get_color():UInt
	{
		return _screenPass.diffuseMethod.diffuseColor;
	}

	private inline function set_color(value:UInt):Void
	{
		_screenPass.diffuseMethod.diffuseColor = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return super.requiresBlending || _diffuseAlpha < 1;
	}
}
