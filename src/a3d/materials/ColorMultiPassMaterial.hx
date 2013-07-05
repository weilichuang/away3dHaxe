package a3d.materials;

/**
 * ColorMultiPassMaterial is a material that uses a flat colour as the surfaces diffuse.
 */
class ColorMultiPassMaterial extends MultiPassMaterialBase
{
	/**
	 * Creates a new ColorMultiPassMaterial object.
	 *
	 * @param color The material's diffuse surface color.
	 */
	public function new(color:UInt = 0xcccccc)
	{
		super();
		this.color = color;
	}

	/**
	 * The diffuse color of the surface.
	 */
	public var color(get,set):UInt;
	private function get_color():UInt
	{
		return diffuseMethod.diffuseColor;
	}

	private function set_color(value:UInt):UInt
	{
		return diffuseMethod.diffuseColor = value;
	}
}
