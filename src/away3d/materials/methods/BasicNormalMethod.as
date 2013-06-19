package away3d.materials.methods
{
	
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.textures.Texture2DBase;

	

	public class BasicNormalMethod extends ShadingMethodBase
	{
		private var _texture:Texture2DBase;
		private var _useTexture:Boolean;
		protected var _normalTextureRegister:ShaderRegisterElement;

		public function BasicNormalMethod()
		{
			super();
		}


		override public function initVO(vo:MethodVO):void
		{
			vo.needsUV = Boolean(_texture);
		}

		public function get tangentSpace():Boolean
		{
			return true;
		}

		/**
		 * Override this is normal method output is not based on a texture (if not, it will usually always return true)
		 */
		public function get hasOutput():Boolean
		{
			return _useTexture;
		}

		override public function copyFrom(method:ShadingMethodBase):void
		{
			normalMap = BasicNormalMethod(method).normalMap;
		}

		public function get normalMap():Texture2DBase
		{
			return _texture;
		}

		public function set normalMap(value:Texture2DBase):void
		{
			if (Boolean(value) != _useTexture ||
				(value && _texture && (value.hasMipMaps != _texture.hasMipMaps || value.format != _texture.format)))
				invalidateShaderProgram();
			_useTexture = Boolean(value);
			_texture = value;
		}

		public override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_normalTextureRegister = null;
		}

		override public function dispose():void
		{
			if (_texture)
				_texture = null;
		}

		public override function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):void
		{
			if (vo.texturesIndex >= 0)
				stage3DProxy.context3D.setTextureAt(vo.texturesIndex, _texture.getTextureForStage3D(stage3DProxy));
		}

		public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			_normalTextureRegister = regCache.getFreeTextureReg();
			vo.texturesIndex = _normalTextureRegister.index;
			return getTex2DSampleCode(vo, targetReg, _normalTextureRegister, _texture) +
				"sub " + targetReg + ".xyz, " + targetReg + ".xyz, " + _sharedRegisters.commons + ".xxx	\n" +
				"nrm " + targetReg + ".xyz, " + targetReg + ".xyz							\n";
		}
	}
}
