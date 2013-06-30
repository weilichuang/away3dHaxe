package a3d.filters.tasks;

import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import flash.Vector;

import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;

class Filter3DHueSaturationTask extends Filter3DTaskBase
{
	private var _rgbData:Vector<Float>;
	private var _saturation:Float = 0.6;
	private var _r:Float = 1;
	private var _b:Float = 1;
	private var _g:Float = 1;

	public function new()
	{
		super();
		updateConstants();
	}

	private function get_saturation():Float
	{
		return _saturation;
	}

	private function set_saturation(value:Float):Void
	{
		if (_saturation == value)
			return;
		_saturation = value;

		updateConstants();
	}

	private function get_r():Float
	{
		return _r;
	}

	private function set_r(value:Float):Void
	{
		if (_r == value)
			return;
		_r = value;

		updateConstants();
	}

	private function get_b():Float
	{
		return _b;
	}

	private function set_b(value:Float):Void
	{
		if (_b == value)
			return;
		_b = value;

		updateConstants();
	}

	private function get_g():Float
	{
		return _g;
	}

	private function set_g(value:Float):Void
	{
		if (_g == value)
			return;
		_g = value;

		updateConstants();
	}

	override private function getFragmentCode():String
	{
		/**
		 * Some reference so I don't go crazy
		 *
		 * ft0-7 : Fragment temp
		 * v0-7 : varying buffer (passed from vertex shader)
		 * fs0-7 : Sampler?
		 *
		 * oc : output color
		 *
		 * Constants
		 * fc0 = Color Constants
		 * fc1 = Desaturation factor
		 *
		 * ft0 - Pixel Color
		 * ft1 - Intensity*Saturation
		 *
		 */
		//_____________________________________________________________________
		//	Texture
		//_____________________________________________________________________
		return "tex ft0, v0, fs0 <2d,linear,clamp>	\n" +

			//_____________________________________________________________________
			//	Color Multiplier
			//_____________________________________________________________________
			"mul ft0.xyz, ft0.xyz, fc2.xyz  \n" + // brightness

			//_____________________________________________________________________
			//	Intensity * Saturation
			//_____________________________________________________________________
			"mul ft1, ft0.x, fc0.x          \n" + // 0.3 * red
			"mul ft2, ft0.y, fc0.y          \n" + // 0.59 * green
			"add ft1, ft1, ft2              \n" + // add red and green results
			"mul ft2, ft0.z, fc0.z          \n" + // 0.11 * blue
			"add ft1, ft1, ft2              \n" + // add (red*green) and blue results
			"mul ft1, ft1, fc1.x            \n" + // multiply intensity and saturation

			//_____________________________________________________________________
			//	RGB Value
			//_____________________________________________________________________
			"mul ft0.xyz, ft0.xyz, fc1.y    \n" + // rgb * (1-saturation)
			"add ft0.xyz, ft0.xyz, ft1      \n" + // rgb + intensity

			// output the color
			"mov oc, ft0			        \n";
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _rgbData, 2);
	}

	private function updateConstants():Void
	{
		_rgbData = Vector<Float>([
			0.3, 0.59, 0.11, 0,
			1 - _saturation, _saturation, 0, 0,
			r, g, b, 0
			]);
	}
}
