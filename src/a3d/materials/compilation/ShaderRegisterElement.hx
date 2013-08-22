package a3d.materials.compilation;


/**
 * A single register element (an entire register or a single register's component) used by the RegisterPool.
 */
class ShaderRegisterElement
{
	private static var COMPONENTS:Array<String> = ["x", "y", "z", "w"];
	
	/**
	 * The register's index.
	 */
	public var index:Int;
	
	/**
	 * The register's name.
	 */
	public var regName:String;
	
	/**
	 * The register's component, if not the entire register is represented.
	 */
	public var component:Int;
	
	private var _toStr:String;

	/**
	 * Creates a new ShaderRegisterElement object.
	 * @param regName The name of the register.
	 * @param index The index of the register.
	 * @param component The register's component, if not the entire register is represented.
	 */
	public function new(regName:String, index:Int, component:Int = -1)
	{
		this.regName = regName;
		this.index = index;
		this.component = component;

		_toStr = regName;

		if (index >= 0)
			_toStr += index;

		if (component > -1)
			_toStr += "." + COMPONENTS[component];
	}

	/**
	 * Converts the register or the components AGAL string representation.
	 */
	public function toString():String
	{
		return _toStr;
	}
}
