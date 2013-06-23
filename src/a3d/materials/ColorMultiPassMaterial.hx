package a3d.materials
{
	

	

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
		public function ColorMultiPassMaterial(color:UInt = 0xcccccc)
		{
			super();
			this.color = color;
		}

		/**
		 * The diffuse color of the surface.
		 */
		private inline function get_color():UInt
		{
			return diffuseMethod.diffuseColor;
		}

		private inline function set_color(value:UInt):Void
		{
			diffuseMethod.diffuseColor = value;
		}
	}
}
