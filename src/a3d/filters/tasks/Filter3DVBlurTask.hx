package a3d.filters.tasks;

import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;

class Filter3DVBlurTask extends Filter3DTaskBase
{
	private static var MAX_AUTO_SAMPLES:Int = 15;
	private var _amount:UInt;
	private var _data:Vector<Float>;
	private var _stepSize:Int = 1;
	private var _realStepSize:Float;

	/**
	 *
	 * @param amount
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function new(amount:UInt, stepSize:Int = -1)
	{
		super();
		_amount = amount;
		_data = Vector<Float>([0, 0, 0, 1]);
		this.stepSize = stepSize;
	}

	private inline function get_amount():UInt
	{
		return _amount;
	}

	private inline function set_amount(value:UInt):Void
	{
		if (value == _amount)
			return;
		_amount = value;

		invalidateProgram3D();
		updateBlurData();
	}

	private inline function get_stepSize():Int
	{
		return _stepSize;
	}

	private inline function set_stepSize(value:Int):Void
	{
		if (value == _stepSize)
			return;
		_stepSize = value;
		calculateStepSize();
		invalidateProgram3D();
		updateBlurData();
	}

	override private function getFragmentCode():String
	{
		var code:String;
		var numSamples:Int = 1;

		code = "mov ft0, v0	\n" +
			"sub ft0.y, v0.y, fc0.x\n";

		code += "tex ft1, ft0, fs0 <2d,linear,clamp>\n";

		for (var x:Float = _realStepSize; x <= _amount; x += _realStepSize)
		{
			code += "add ft0.y, ft0.y, fc0.y	\n";
			code += "tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
				"add ft1, ft1, ft2 \n";
			++numSamples;
		}

		code += "mul oc, ft1, fc0.z";

		_data[2] = 1 / numSamples;

		return code;
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
	}

	override private function updateTextures(stage:Stage3DProxy):Void
	{
		super.updateTextures(stage);

		updateBlurData();
	}

	private function updateBlurData():Void
	{
		// todo: must be normalized using view size ratio instead of texture
		var invH:Float = 1 / _textureHeight;

		_data[0] = _amount * .5 * invH;
		_data[1] = _realStepSize * invH;
	}

	private function calculateStepSize():Void
	{
		_realStepSize = _stepSize > 0 ? _stepSize :
			_amount > MAX_AUTO_SAMPLES ? _amount / MAX_AUTO_SAMPLES :
			1;
	}
}
