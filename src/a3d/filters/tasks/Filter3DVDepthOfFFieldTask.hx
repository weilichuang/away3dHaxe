package a3d.filters.tasks;

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;



class Filter3DVDepthOfFFieldTask extends Filter3DTaskBase
{
	private static var MAX_AUTO_SAMPLES:Int = 10;
	private var _maxBlur:UInt;
	private var _data:Vector<Float>;
	private var _focusDistance:Float;
	private var _range:Float = 1000;
	private var _stepSize:Int;
	private var _realStepSize:Float;

	/**
	 * Creates a new Filter3DHDepthOfFFieldTask
	 * @param amount The maximum amount of blur to apply in pixels at the most out-of-focus areas
	 * @param stepSize The distance between samples. Set to -1 to autodetect with acceptable quality.
	 */
	public function Filter3DVDepthOfFFieldTask(maxBlur:UInt, stepSize:Int = -1)
	{
		super(true);
		_maxBlur = maxBlur;
		_data = Vector<Float>([0, 0, 0, _focusDistance, 0, 0, 0, 0, _range, 0, 0, 0, 1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0]);
		this.stepSize = stepSize;
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

	private inline function get_range():Float
	{
		return _range;
	}

	private inline function set_range(value:Float):Void
	{
		_range = value;
		_data[8] = 1 / value;
	}


	private inline function get_focusDistance():Float
	{
		return _focusDistance;
	}

	private inline function set_focusDistance(value:Float):Void
	{
		_data[3] = _focusDistance = value;
	}

	private inline function get_maxBlur():UInt
	{
		return _maxBlur;
	}

	private inline function set_maxBlur(value:UInt):Void
	{
		if (_maxBlur == value)
			return;
		_maxBlur = value;

		invalidateProgram3D();
		updateBlurData();
		calculateStepSize();
	}

	override private function getFragmentCode():String
	{
		var code:String;
		var numSamples:UInt = 1;

		// sample depth, unpack & get blur amount (offset point + step size)
		code = "tex ft0, v0, fs1 <2d, nearest>	\n" +
			"dp4 ft1.z, ft0, fc3				\n" +
			"sub ft1.z, ft1.z, fc1.z			\n" + // d = d - f
			"rcp ft1.z, ft1.z			\n" + // screenZ = -n*f/(d-f)
			"mul ft1.z, fc1.w, ft1.z			\n" + // screenZ = -n*f/(d-f)
			"sub ft1.z, ft1.z, fc0.w			\n" + // screenZ - dist
			"mul ft1.z, ft1.z, fc2.x			\n" + // (screenZ - dist)/range

			"abs ft1.z, ft1.z					\n" + // abs(screenZ - dist)/range
			"sat ft1.z, ft1.z					\n" + // sat(abs(screenZ - dist)/range)
			"mul ft6.xy, ft1.z, fc0.xy			\n";


		code += "mov ft0, v0	\n" +
			"sub ft0.y, ft0.y, ft6.x\n" +
			"tex ft1, ft0, fs0 <2d,linear,clamp>\n";

		for (var y:Float = _realStepSize; y <= _maxBlur; y += _realStepSize)
		{
			code += "add ft0.y, ft0.y, ft6.y	\n" +
				"tex ft2, ft0, fs0 <2d,linear,clamp>\n" +
				"add ft1, ft1, ft2 \n";

			++numSamples;
		}

		code += "mul oc, ft1, fc0.z";

		_data[2] = 1 / numSamples;

		return code;
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D, depthTexture:Texture):Void
	{
		var context:Context3D = stage3DProxy._context3D;
		var n:Float = camera.lens.near;
		var f:Float = camera.lens.far;

		_data[6] = f / (f - n);
		_data[7] = -n * _data[6];

		context.setTextureAt(1, depthTexture);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 4);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy._context3D.setTextureAt(1, null);
	}

	override private function updateTextures(stage:Stage3DProxy):Void
	{
		super.updateTextures(stage);

		updateBlurData();
	}

	private function updateBlurData():Void
	{
		// todo: replace with view width once texture rendering is scissored?
		var invH:Float = 1 / _textureHeight;

		_data[0] = _maxBlur * .5 * invH;
		_data[1] = _realStepSize * invH;
	}

	private function calculateStepSize():Void
	{
		_realStepSize = _stepSize > 0 ? _stepSize :
			_maxBlur > MAX_AUTO_SAMPLES ? _maxBlur / MAX_AUTO_SAMPLES :
			1;
	}
}
