package a3d.filters.tasks
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	
	import a3d.entities.Camera3D;
	import a3d.core.managers.Stage3DProxy;

	

	class Filter3DBloomCompositeTask extends Filter3DTaskBase
	{
		private var _data:Vector<Float>;
		private var _overlayTexture:TextureBase;
		private var _exposure:Float;

		public function Filter3DBloomCompositeTask(exposure:Float)
		{
			super();
			_data = Vector<Float>([0.299, 0.587, 0.114, 1]); // luminance projection, 1
			this.exposure = exposure;
		}

		private inline function get_overlayTexture():TextureBase
		{
			return _overlayTexture;
		}

		private inline function set_overlayTexture(value:TextureBase):Void
		{
			_overlayTexture = value;
		}

		override private function getFragmentCode():String
		{
			var code:String;
			code = "tex ft0, v0, fs0 <2d,linear,clamp>	\n" +
				"tex ft1, v0, fs1 <2d,linear,clamp>	\n" +
				"dp3 ft2.x, ft1, fc0\n" +
				"sub ft2.x, fc0.w, ft2.x\n" +
				"mul ft0, ft0, ft2.x\n";
			code += "add oc, ft0, ft1					\n";
			return code;
		}

		override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
		{
			var context:Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
			context.setTextureAt(1, _overlayTexture);
		}

		override public function deactivate(stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(1, null);
		}

		private inline function get_exposure():Float
		{
			return _exposure;
		}

		private inline function set_exposure(exposure:Float):Void
		{
			_exposure = exposure;
			_data[4] = 1 + _exposure / 10;
		}
	}
}
