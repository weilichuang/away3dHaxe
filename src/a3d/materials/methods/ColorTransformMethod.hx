package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;

import flash.geom.ColorTransform;



/**
 * ColorTransformMethod provides a shading method that changes the colour of a material according to a ColorTransform
 * object.
 */
class ColorTransformMethod extends EffectMethodBase
{
	private var _colorTransform:ColorTransform;

	/**
	 * Creates a new ColorTransformMethod.
	 */
	public function new()
	{
		super();
	}

	/**
	 * The ColorTransform object to transform the colour of the material with.
	 */
	private inline function get_colorTransform():ColorTransform
	{
		return _colorTransform;
	}

	private inline function set_colorTransform(value:ColorTransform):Void
	{
		_colorTransform = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		var code:String = "";
		var colorMultReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		var colorOffsReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
		vo.fragmentConstantsIndex = colorMultReg.index * 4;
		code += "mul " + targetReg + ", " + targetReg.toString() + ", " + colorMultReg + "\n" +
			"add " + targetReg + ", " + targetReg.toString() + ", " + colorOffsReg + "\n";
		return code;
	}

	/**
	 * @inheritDoc
	 */
	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
		var inv:Float = 1 / 0xff;
		var index:Int = vo.fragmentConstantsIndex;
		var data:Vector<Float> = vo.fragmentData;
		data[index] = _colorTransform.redMultiplier;
		data[index + 1] = _colorTransform.greenMultiplier;
		data[index + 2] = _colorTransform.blueMultiplier;
		data[index + 3] = _colorTransform.alphaMultiplier;
		data[index + 4] = _colorTransform.redOffset * inv;
		data[index + 5] = _colorTransform.greenOffset * inv;
		data[index + 6] = _colorTransform.blueOffset * inv;
		data[index + 7] = _colorTransform.alphaOffset * inv;
	}
}
