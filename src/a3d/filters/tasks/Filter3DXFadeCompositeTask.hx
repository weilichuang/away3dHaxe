package a3d.filters.tasks;

import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.Vector;





class Filter3DXFadeCompositeTask extends Filter3DTaskBase
{
	public var overlayTexture(get, set):TextureBase;
	public var amount(get, set):Float;
	
	private var _data:Vector<Float>;
	private var _overlayTexture:TextureBase;

	public function new(amount:Float)
	{
		super();
		if (amount < 0)
			amount = 0;
		else if (amount > 1)
			amount = 1;
		_data = Vector.ofArray([amount, 0., 0, 0]);
	}

	
	private function get_overlayTexture():TextureBase
	{
		return _overlayTexture;
	}

	private function set_overlayTexture(value:TextureBase):TextureBase
	{
		return _overlayTexture = value;
	}

	
	private function get_amount():Float
	{
		return _data[0];
	}

	private function set_amount(value:Float):Float
	{
		return _data[0] = value;
	}


	override private function getFragmentCode():String
	{
		return "tex ft0, v0, fs0 <2d,nearest>	\n" +
			"tex ft1, v0, fs1 <2d,nearest>	\n" +
			"sub ft1, ft1, ft0				\n" +
			"mul ft1, ft1, fc0.x			\n" +
			"add oc, ft1, ft0				\n";
	}

	override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		var context:Context3D = stage3DProxy.context3D;
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		context.setTextureAt(1, _overlayTexture);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		stage3DProxy.context3D.setTextureAt(1, null);
	}
}
