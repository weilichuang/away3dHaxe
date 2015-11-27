package away3d.materials;

/**
 * ColorMultiPassMaterial is a material that uses a flat colour as the surfaces diffuse.
 */
class ColorMultiPassMaterial extends MultiPassMaterialBase
{
	/**
	 * The diffuse reflectivity color of the surface.
	 */
	public var color(get, set):UInt;
	
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
	
	private function get_color():UInt
	{
		return diffuseMethod.diffuseColor;
	}

	private function set_color(value:UInt):UInt
	{
		return diffuseMethod.diffuseColor = value;
	}
}
