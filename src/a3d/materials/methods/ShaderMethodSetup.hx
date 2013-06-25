package a3d.materials.methods;

import flash.events.EventDispatcher;

import a3d.events.ShadingMethodEvent;


class ShaderMethodSetup extends EventDispatcher
{
	private var _colorTransformMethod:ColorTransformMethod;
	private var _colorTransformMethodVO:MethodVO;

	private var _normalMethod:BasicNormalMethod;
	private var _normalMethodVO:MethodVO;
	private var _ambientMethod:BasicAmbientMethod;
	private var _ambientMethodVO:MethodVO;
	private var _shadowMethod:ShadowMapMethodBase;
	private var _shadowMethodVO:MethodVO;
	private var _diffuseMethod:BasicDiffuseMethod;
	private var _diffuseMethodVO:MethodVO;
	private var _specularMethod:BasicSpecularMethod;
	private var _specularMethodVO:MethodVO;
	private var _methods:Vector<MethodVOSet>;

	private inline function get_colorTransformMethodVO():MethodVO
	{
		return _colorTransformMethodVO;
	}

	private inline function get_normalMethodVO():MethodVO
	{
		return _normalMethodVO;
	}

	private inline function get_ambientMethodVO():MethodVO
	{
		return _ambientMethodVO;
	}

	private inline function get_shadowMethodVO():MethodVO
	{
		return _shadowMethodVO;
	}

	private inline function get_diffuseMethodVO():MethodVO
	{
		return _diffuseMethodVO;
	}

	private inline function get_specularMethodVO():MethodVO
	{
		return _specularMethodVO;
	}

	public function new()
	{
		_methods = new Vector<MethodVOSet>();
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

	private function onShaderInvalidated(event:ShadingMethodEvent):Void
	{
		invalidateShaderProgram();
	}

	private function invalidateShaderProgram():Void
	{
		dispatchEvent(new ShadingMethodEvent(ShadingMethodEvent.SHADER_INVALIDATED));
	}

	private inline function get_normalMethod():BasicNormalMethod
	{
		return _normalMethod;
	}

	private inline function set_normalMethod(value:BasicNormalMethod):Void
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

	private inline function get_ambientMethod():BasicAmbientMethod
	{
		return _ambientMethod;
	}

	private inline function set_ambientMethod(value:BasicAmbientMethod):Void
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

	private inline function get_shadowMethod():ShadowMapMethodBase
	{
		return _shadowMethod;
	}

	private inline function set_shadowMethod(value:ShadowMapMethodBase):Void
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
	private inline function get_diffuseMethod():BasicDiffuseMethod
	{
		return _diffuseMethod;
	}

	private inline function set_diffuseMethod(value:BasicDiffuseMethod):Void
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
	private inline function get_specularMethod():BasicSpecularMethod
	{
		return _specularMethod;
	}

	private inline function set_specularMethod(value:BasicSpecularMethod):Void
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
	private inline function get_colorTransformMethod():ColorTransformMethod
	{
		return _colorTransformMethod;
	}

	private inline function set_colorTransformMethod(value:ColorTransformMethod):Void
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

	public function dispose():Void
	{
		clearListeners(_normalMethod);
		clearListeners(_diffuseMethod);
		clearListeners(_shadowMethod);
		clearListeners(_ambientMethod);
		clearListeners(_specularMethod);

		for (var i:Int = 0; i < _methods.length; ++i)
			clearListeners(_methods[i].method);

		_methods = null;
	}

	private function clearListeners(method:ShadingMethodBase):Void
	{
		if (method)
			method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
	}

	/**
	 * Adds a method to change the material after all lighting is performed.
	 * @param method The method to be added.
	 */
	public function addMethod(method:EffectMethodBase):Void
	{
		_methods.push(new MethodVOSet(method));
		method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		invalidateShaderProgram();
	}

	public function hasMethod(method:EffectMethodBase):Bool
	{
		return getMethodSetForMethod(method) != null;
	}

	/**
	 * Inserts a method to change the material after all lighting is performed at the given index.
	 * @param method The method to be added.
	 * @param index The index of the method's occurrence
	 */
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		_methods.splice(index, 0, new MethodVOSet(method));
		method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		invalidateShaderProgram();
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return EffectMethodBase(_methods[index].method);
	}

	private inline function get_numMethods():Int
	{
		return _methods.length;
	}

	private inline function get_methods():Vector<MethodVOSet>
	{
		return _methods;
	}

	/**
	 * Removes a method from the pass.
	 * @param method The method to be removed.
	 */
	public function removeMethod(method:EffectMethodBase):Void
	{
		var methodSet:MethodVOSet = getMethodSetForMethod(method);
		if (methodSet != null)
		{
			var index:Int = _methods.indexOf(methodSet);
			_methods.splice(index, 1);
			method.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			invalidateShaderProgram();
		}
	}

	private function getMethodSetForMethod(method:EffectMethodBase):MethodVOSet
	{
		var len:Int = _methods.length;
		for (var i:Int = 0; i < len; ++i)
			if (_methods[i].method == method)
				return _methods[i];

		return null;
	}
}
