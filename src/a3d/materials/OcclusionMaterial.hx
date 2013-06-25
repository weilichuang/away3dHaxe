package a3d.materials;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;



/**
 * OcclusionMaterial is a ColorMaterial for an object, that hides all other objects behind itself.
 */
class OcclusionMaterial extends ColorMaterial
{
	private var _occlude:Bool = true;

	/**
	 * Creates a new OcclusionMaterial object.
	 * @param occlude Whether or not to occlude other objects.
	 * @param color The material's diffuse surface color.
	 * @param alpha The material's surface alpha.
	 */
	public function new(occlude:Bool = true, color:UInt = 0xcccccc, alpha:Float = 1)
	{
		super(color, alpha);
		this.occlude = occlude;
	}

	/**
	 * Whether or not an object with this material applied hides other objects.
	 */
	private inline function get_occlude():Bool
	{
		return _occlude;
	}

	private inline function set_occlude(value:Bool):Void
	{
		_occlude = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function activatePass(index:UInt, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (occlude)
		{
			stage3DProxy._context3D.setColorMask(false, false, false, false);
		}
		super.activatePass(index, stage3DProxy, camera);
	}

	/**
	 * @inheritDoc
	 */
	override public function deactivatePass(index:UInt, stage3DProxy:Stage3DProxy):Void
	{
		super.deactivatePass(index, stage3DProxy);
		stage3DProxy._context3D.setColorMask(true, true, true, true);
	}
}
