package away3d.filters.tasks;

import away3d.core.managers.Context3DProxy;
import away3d.core.managers.Stage3DProxy;
import away3d.cameras.Camera3D;
import flash.display.BlendMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.errors.Error;
import flash.Vector;





class Filter3DCompositeTask extends Filter3DTaskBase
{
	public var overlayTexture(get, set):TextureBase;
	public var exposure(get, set):Float;
	
	private var _data:Vector<Float>;
	private var _overlayTexture:TextureBase;
	private var _blendMode:BlendMode;

	public function new(blendMode:BlendMode, exposure:Float = 1)
	{
		super();
		_data = Vector.ofArray([exposure, 0, 0, 0]);
		_blendMode = blendMode;
	}

	private function get_overlayTexture():TextureBase
	{
		return _overlayTexture;
	}

	private function set_overlayTexture(value:TextureBase):TextureBase
	{
		return _overlayTexture = value;
	}

	private function get_exposure():Float
	{
		return _data[0];
	}

	private function set_exposure(value:Float):Float
	{
		return _data[0] = value;
	}


	override private function getFragmentCode():String
	{
		var code:String;
		var op:String;
		code = "tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
			"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
			"mul ft0, ft0, fc0.x				\n";
		switch (_blendMode)
		{
			case BlendMode.MULTIPLY:
				op = "mul";
			
			case BlendMode.ADD:
				op = "add";
			
			case BlendMode.SUBTRACT:
				op = "sub";
			
			case BlendMode.NORMAL:
				// for debugging purposes
				op = "mov";
			
			default:
				throw new Error("Unknown blend mode");
		}
		if (op != "mov")
			code += op + " oc, ft0, ft1\n";
		else
			code += "mov oc, ft0\n";
		return code;
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		var context:Context3DProxy = stage3DProxy.context3D;
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		context.setTextureAt(1, _overlayTexture);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(1, null);
	}
}
