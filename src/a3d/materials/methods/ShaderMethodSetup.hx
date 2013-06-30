package a3d.materials.methods;

import flash.events.EventDispatcher;
import flash.Vector;

import a3d.events.ShadingMethodEvent;

using a3d.utils.VectorUtil;

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

	public var colorTransformMethodVO(get,null):MethodVO;
	private function get_colorTransformMethodVO():MethodVO
	{
		return _colorTransformMethodVO;
	}

	public var normalMethodVO(get,null):MethodVO;
	private function get_normalMethodVO():MethodVO
	{
		return _normalMethodVO;
	}

	public var ambientMethodVO(get,null):MethodVO;
	private function get_ambientMethodVO():MethodVO
	{
		return _ambientMethodVO;
	}

	public var shadowMethodVO(get,null):MethodVO;
	private function get_shadowMethodVO():MethodVO
	{
		return _shadowMethodVO;
	}

	public var diffuseMethodVO(get,null):MethodVO;
	private function get_diffuseMethodVO():MethodVO
	{
		return _diffuseMethodVO;
	}

	public var specularMethodVO(get,null):MethodVO;
	private function get_specularMethodVO():MethodVO
	{
		return _specularMethodVO;
	}

	public function new()
	{
		super();
		
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

	public var normalMethod(get,set):BasicNormalMethod;
	private function get_normalMethod():BasicNormalMethod
	{
		return _normalMethod;
	}

	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		if (_normalMethod != null)
			_normalMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);

		if (value != null)
		{
			if (_normalMethod != null)
				value.copyFrom(_normalMethod);
			_normalMethodVO = value.createMethodVO();
			value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		_normalMethod = value;

		if (value != null)
			invalidateShaderProgram();
		
		return _normalMethod;
	}

	public var ambientMethod(get,set):BasicAmbientMethod;
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _ambientMethod;
	}

	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		if (_ambientMethod != null)
			_ambientMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		if (value != null)
		{
			if (_ambientMethod != null)
				value.copyFrom(_ambientMethod);
			value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_ambientMethodVO = value.createMethodVO();
		}
		_ambientMethod = value;

		if (value != null)
			invalidateShaderProgram();
			
		return _ambientMethod;
	}

	public var shadowMethod(get,set):ShadowMapMethodBase;
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _shadowMethod;
	}

	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		if (_shadowMethod != null)
			_shadowMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		_shadowMethod = value;
		if (_shadowMethod != null)
		{
			_shadowMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_shadowMethodVO = _shadowMethod.createMethodVO();
		}
		else
			_shadowMethodVO = null;
		invalidateShaderProgram();
		return _shadowMethod;
	}

	/**
	 * The method to perform diffuse shading.
	 */
	public var diffuseMethod(get,set):BasicDiffuseMethod;
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _diffuseMethod;
	}

	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		if (_diffuseMethod != null)
			_diffuseMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);

		if (value != null)
		{
			if (_diffuseMethod != null)
				value.copyFrom(_diffuseMethod);
			value.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_diffuseMethodVO = value.createMethodVO();
		}

		_diffuseMethod = value;

		if (value != null)
			invalidateShaderProgram();
			
		return _diffuseMethod;
	}

	/**
	 * The method to perform specular shading.
	 */
	public var specularMethod(get,set):BasicSpecularMethod;
	private function get_specularMethod():BasicSpecularMethod
	{
		return _specularMethod;
	}

	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		if (_specularMethod != null)
		{
			_specularMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			if (value != null)
				value.copyFrom(_specularMethod);
		}

		_specularMethod = value;
		if (_specularMethod != null)
		{
			_specularMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_specularMethodVO = _specularMethod.createMethodVO();
		}
		else
			_specularMethodVO = null;

		invalidateShaderProgram();
		return _specularMethod;
	}



	/**
	 * @private
	 */
	public var colorTransformMethod(get,set):ColorTransformMethod;
	private function get_colorTransformMethod():ColorTransformMethod
	{
		return _colorTransformMethod;
	}

	private function set_colorTransformMethod(value:ColorTransformMethod):ColorTransformMethod
	{
		if (_colorTransformMethod == value)
			return _colorTransformMethod;
		if (_colorTransformMethod != null)
			_colorTransformMethod.removeEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		if (_colorTransformMethod == null || value == null)
			invalidateShaderProgram();

		_colorTransformMethod = value;
		if (_colorTransformMethod != null)
		{
			_colorTransformMethod.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
			_colorTransformMethodVO = _colorTransformMethod.createMethodVO();
		}
		else
			_colorTransformMethodVO = null;
		return _colorTransformMethod;
	}

	public function dispose():Void
	{
		clearListeners(_normalMethod);
		clearListeners(_diffuseMethod);
		clearListeners(_shadowMethod);
		clearListeners(_ambientMethod);
		clearListeners(_specularMethod);

		for (i in 0..._methods.length)
			clearListeners(_methods[i].method);

		_methods = null;
	}

	private function clearListeners(method:ShadingMethodBase):Void
	{
		if (method != null)
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
		_methods.insert(index, new MethodVOSet(method));
		method.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		invalidateShaderProgram();
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return Std.instance(_methods[index].method,EffectMethodBase);
	}

	public var numMethods(get,null):Int;
	private function get_numMethods():Int
	{
		return _methods.length;
	}

	public var methods(get,null):Vector<MethodVOSet>;
	private function get_methods():Vector<MethodVOSet>
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
		for (i in 0...len)
			if (_methods[i].method == method)
				return _methods[i];

		return null;
	}
}
