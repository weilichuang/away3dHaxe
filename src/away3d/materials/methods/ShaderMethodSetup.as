package away3d.materials.methods
{
	import flash.events.EventDispatcher;

	import away3d.events.ShadingMethodEvent;


	public class ShaderMethodSetup extends EventDispatcher
	{
		protected var _colorTransformMethod:ColorTransformMethod;
		protected var _colorTransformMethodVO:MethodVO;

		protected var _normalMethod:BasicNormalMethod;
		protected var _normalMethodVO:MethodVO;
		protected var _ambientMethod:BasicAmbientMethod;
		protected var _ambientMethodVO:MethodVO;
		protected var _shadowMethod:ShadowMapMethodBase;
		protected var _shadowMethodVO:MethodVO;
		protected var _diffuseMethod:BasicDiffuseMethod;
		protected var _diffuseMethodVO:MethodVO;
		protected var _specularMethod:BasicSpecularMethod;
		protected var _specularMethodVO:MethodVO;
		protected var _methods:Vector.<MethodVOSet>;

		public function get colorTransformMethodVO():MethodVO
		{
			return _colorTransformMethodVO;
		}

		public function get normalMethodVO():MethodVO
		{
			return _normalMethodVO;
		}

		public function get ambientMethodVO():MethodVO
		{
			return _ambientMethodVO;
		}

		public function get shadowMethodVO():MethodVO
		{
			return _shadowMethodVO;
		}

		public function get diffuseMethodVO():MethodVO
		{
			return _diffuseMethodVO;
		}

		public function get specularMethodVO():MethodVO
		{
			return _specularMethodVO;
		}

		public function ShaderMethodSetup()
		{
			_methods = new Vector.<MethodVOSet>();
			_normalMethod = new BasicNormalMethod();
			_ambientMethod = new BasicAmbientMethod();
			_diffuseMethod = new BasicDiffuseMethod();
			_specularMethod = new BasicSpecularMethod();
			_normalMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_normalMethodVO = _normalMethod.createMethodVO();
			_ambientMethodVO = _ambientMethod.createMethodVO();
			_diffuseMethodVO = _diffuseMethod.createMethodVO();
			_specularMethodVO = _specularMethod.createMethodVO();
		}

		private function onShaderInvalidated(event:ShadingMethodEvent):void
		{
			invalidateShaderProgram();
		}

		private function invalidateShaderProgram():void
		{
			dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
		}

		public function get normalMethod():BasicNormalMethod
		{
			return _normalMethod;
		}

		public function set normalMethod(value:BasicNormalMethod):void
		{
			if (_normalMethod)
				_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);

			if (value)
			{
				if (_normalMethod)
					value.copyFrom(_normalMethod);
				_normalMethodVO = value.createMethodVO();
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			}

			_normalMethod = value;

			if (value)
				invalidateShaderProgram();
		}

		public function get ambientMethod():BasicAmbientMethod
		{
			return _ambientMethod;
		}

		public function set ambientMethod(value:BasicAmbientMethod):void
		{
			if (_ambientMethod)
				_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (value)
			{
				if (_ambientMethod)
					value.copyFrom(_ambientMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_ambientMethodVO = value.createMethodVO();
			}
			_ambientMethod = value;

			if (value)
				invalidateShaderProgram();
		}

		public function get shadowMethod():ShadowMapMethodBase
		{
			return _shadowMethod;
		}

		public function set shadowMethod(value:ShadowMapMethodBase):void
		{
			if (_shadowMethod)
				_shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_shadowMethod = value;
			if (_shadowMethod)
			{
				_shadowMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_shadowMethodVO = _shadowMethod.createMethodVO();
			}
			else
				_shadowMethodVO = null;
			invalidateShaderProgram();
		}

		/**
		 * The method to perform diffuse shading.
		 */
		public function get diffuseMethod():BasicDiffuseMethod
		{
			return _diffuseMethod;
		}

		public function set diffuseMethod(value:BasicDiffuseMethod):void
		{
			if (_diffuseMethod)
				_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);

			if (value)
			{
				if (_diffuseMethod)
					value.copyFrom(_diffuseMethod);
				value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_diffuseMethodVO = value.createMethodVO();
			}

			_diffuseMethod = value;

			if (value)
				invalidateShaderProgram();
		}

		/**
		 * The method to perform specular shading.
		 */
		public function get specularMethod():BasicSpecularMethod
		{
			return _specularMethod;
		}

		public function set specularMethod(value:BasicSpecularMethod):void
		{
			if (_specularMethod)
			{
				_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				if (value)
					value.copyFrom(_specularMethod);
			}

			_specularMethod = value;
			if (_specularMethod)
			{
				_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_specularMethodVO = _specularMethod.createMethodVO();
			}
			else
				_specularMethodVO = null;

			invalidateShaderProgram();
		}



		/**
		 * @private
		 */
		public function get colorTransformMethod():ColorTransformMethod
		{
			return _colorTransformMethod;
		}

		public function set colorTransformMethod(value:ColorTransformMethod):void
		{
			if (_colorTransformMethod == value)
				return;
			if (_colorTransformMethod)
				_colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (!_colorTransformMethod || !value)
				invalidateShaderProgram();

			_colorTransformMethod = value;
			if (_colorTransformMethod)
			{
				_colorTransformMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				_colorTransformMethodVO = _colorTransformMethod.createMethodVO();
			}
			else
				_colorTransformMethodVO = null;
		}

		public function dispose():void
		{
			clearListeners(_normalMethod);
			clearListeners(_diffuseMethod);
			clearListeners(_shadowMethod);
			clearListeners(_ambientMethod);
			clearListeners(_specularMethod);

			for (var i:int = 0; i < _methods.length; ++i)
				clearListeners(_methods[i].method);

			_methods = null;
		}

		private function clearListeners(method:ShadingMethodBase):void
		{
			if (method)
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		/**
		 * Adds a method to change the material after all lighting is performed.
		 * @param method The method to be added.
		 */
		public function addMethod(method:EffectMethodBase):void
		{
			_methods.push(new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		public function hasMethod(method:EffectMethodBase):Boolean
		{
			return getMethodSetForMethod(method) != null;
		}

		/**
		 * Inserts a method to change the material after all lighting is performed at the given index.
		 * @param method The method to be added.
		 * @param index The index of the method's occurrence
		 */
		public function addMethodAt(method:EffectMethodBase, index:int):void
		{
			_methods.splice(index, 0, new MethodVOSet(method));
			method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}

		public function getMethodAt(index:int):EffectMethodBase
		{
			return EffectMethodBase(_methods[index].method);
		}

		public function get numMethods():int
		{
			return _methods.length;
		}

		public function get methods():Vector.<MethodVOSet>
		{
			return _methods;
		}

		/**
		 * Removes a method from the pass.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method:EffectMethodBase):void
		{
			var methodSet:MethodVOSet = getMethodSetForMethod(method);
			if (methodSet != null)
			{
				var index:int = _methods.indexOf(methodSet);
				_methods.splice(index, 1);
				method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
				invalidateShaderProgram();
			}
		}

		private function getMethodSetForMethod(method:EffectMethodBase):MethodVOSet
		{
			var len:int = _methods.length;
			for (var i:int = 0; i < len; ++i)
				if (_methods[i].method == method)
					return _methods[i];

			return null;
		}
	}
}
