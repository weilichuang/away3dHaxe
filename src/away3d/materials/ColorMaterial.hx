package away3d.materials;
import away3d.materials.BlendMode;
import away3d.math.FMath;



/**
 * ColorMaterial is a single-pass material that uses a flat color as the surface's diffuse reflection value.
 */
class ColorMaterial extends SinglePassMaterialBase
{
	/**
	 * The alpha of the surface.
	 */
	public var alpha(get, set):Float;
	/**
	 * The diffuse reflectivity color of the surface.
	 */
	public var color(get, set):UInt;
	
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

	
	private function get_alpha():Float
	{
		return _screenPass.diffuseMethod.diffuseAlpha;
	}

	private function set_alpha(value:Float):Float
	{
		value = FMath.fclamp(value, 0, 1);
		
		_screenPass.diffuseMethod.diffuseAlpha = _diffuseAlpha = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
		
		return alpha;
	}

	
	private function get_color():UInt
	{
		return _screenPass.diffuseMethod.diffuseColor;
	}

	private function set_color(value:UInt):UInt
	{
		return _screenPass.diffuseMethod.diffuseColor = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return super.requiresBlending || _diffuseAlpha < 1;
	}
}
