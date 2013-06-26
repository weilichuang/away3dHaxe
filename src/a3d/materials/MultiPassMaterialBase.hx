package a3d.materials;

import flash.display.BlendMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.events.Event;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.lightpickers.LightPickerBase;
import a3d.materials.lightpickers.StaticLightPicker;
import a3d.materials.methods.BasicAmbientMethod;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicNormalMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.methods.EffectMethodBase;
import a3d.materials.methods.ShadowMapMethodBase;
import a3d.materials.passes.CompiledPass;
import a3d.materials.passes.LightingPass;
import a3d.materials.passes.ShadowCasterPass;
import a3d.materials.passes.SuperShaderPass;
import a3d.textures.Texture2DBase;



/**
 * MultiPassMaterialBase forms an abstract base class for the default multi-pass materials provided by Away3D, using material methods
 * to define their appearance.
 */
class MultiPassMaterialBase extends MaterialBase
{
	private var _casterLightPass:ShadowCasterPass;
	private var _nonCasterLightPasses:Vector<LightingPass>;
	private var _effectsPass:SuperShaderPass;

	private var _alphaThreshold:Float = 0;
	private var _specularLightSources:UInt = 0x01;
	private var _diffuseLightSources:UInt = 0x03;

	private var _ambientMethod:BasicAmbientMethod = new BasicAmbientMethod();
	private var _shadowMethod:ShadowMapMethodBase;
	private var _diffuseMethod:BasicDiffuseMethod = new BasicDiffuseMethod();
	private var _normalMethod:BasicNormalMethod = new BasicNormalMethod();
	private var _specularMethod:BasicSpecularMethod = new BasicSpecularMethod();

	private var _screenPassesInvalid:Bool = true;
	private var _enableLightFallOff:Bool = true;

	/**
	 * Creates a new MultiPassMaterialBase object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * Whether or not to use fallOff and radius properties for lights.
	 */
	private inline function get_enableLightFallOff():Bool
	{
		return _enableLightFallOff;
	}

	private inline function set_enableLightFallOff(value:Bool):Void
	{
		if (_enableLightFallOff != value)
			invalidateScreenPasses();
		_enableLightFallOff = value;
	}

	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	private inline function get_alphaThreshold():Float
	{
		return _alphaThreshold;
	}

	private inline function set_alphaThreshold(value:Float):Void
	{
		_alphaThreshold = value;
		_diffuseMethod.alphaThreshold = value;
		_depthPass.alphaThreshold = value;
		_distancePass.alphaThreshold = value;
	}

	override private inline function set_depthCompareMode(value:String):Void
	{
		super.depthCompareMode = value;
		invalidateScreenPasses();
	}

	override private inline function set_blendMode(value:String):Void
	{
		super.blendMode = value;
		invalidateScreenPasses();
	}

	override public function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		if (distanceBased)
			_distancePass.alphaMask = _diffuseMethod.texture;
		else
			_depthPass.alphaMask = _diffuseMethod.texture;

		super.activateForDepth(stage3DProxy, camera, distanceBased);
	}

	private inline function get_specularLightSources():UInt
	{
		return _specularLightSources;
	}

	private inline function set_specularLightSources(value:UInt):Void
	{
		_specularLightSources = value;
	}

	private inline function get_diffuseLightSources():UInt
	{
		return _diffuseLightSources;
	}

	private inline function set_diffuseLightSources(value:UInt):Void
	{
		_diffuseLightSources = value;
	}

	override private inline function set_lightPicker(value:LightPickerBase):Void
	{
		if (_lightPicker)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
		super.lightPicker = value;
		if (_lightPicker)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
		invalidateScreenPasses();
	}

	/**
	 * @inheritDoc
	 */
	override private inline function get_requiresBlending():Bool
	{
		return false;
	}

	/**
	 * The method to perform ambient shading. Note that shading methods cannot
	 * be reused across materials.
	 */
	private inline function get_ambientMethod():BasicAmbientMethod
	{
		return _ambientMethod;
	}

	private inline function set_ambientMethod(value:BasicAmbientMethod):Void
	{
		value.copyFrom(_ambientMethod);
		_ambientMethod = value;
		invalidateScreenPasses();
	}

	/**
	 * The method to render shadows cast on this surface. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_shadowMethod():ShadowMapMethodBase
	{
		return _shadowMethod;
	}

	private inline function set_shadowMethod(value:ShadowMapMethodBase):Void
	{
		if (value && _shadowMethod)
			value.copyFrom(_shadowMethod);
		_shadowMethod = value;
		invalidateScreenPasses();
	}

	/**
	 * The method to perform diffuse shading. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_diffuseMethod():BasicDiffuseMethod
	{
		return _diffuseMethod;
	}

	private inline function set_diffuseMethod(value:BasicDiffuseMethod):Void
	{
		value.copyFrom(_diffuseMethod);
		_diffuseMethod = value;
		invalidateScreenPasses();
	}

	/**
	 * The method to generate the (tangent-space) normal. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_normalMethod():BasicNormalMethod
	{
		return _normalMethod;
	}

	private inline function set_normalMethod(value:BasicNormalMethod):Void
	{
		value.copyFrom(_normalMethod);
		_normalMethod = value;
		invalidateScreenPasses();
	}

	/**
	 * The method to perform specular shading. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_specularMethod():BasicSpecularMethod
	{
		return _specularMethod;
	}

	private inline function set_specularMethod(value:BasicSpecularMethod):Void
	{
		if (value && _specularMethod)
			value.copyFrom(_specularMethod);
		_specularMethod = value;
		invalidateScreenPasses();
	}

	/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		*/
	public function addMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethod(method);
		invalidateScreenPasses();
	}

	private inline function get_numMethods():Int
	{
		return _effectsPass ? _effectsPass.numMethods : 0;
	}

	public function hasMethod(method:EffectMethodBase):Bool
	{
		return _effectsPass ? _effectsPass.hasMethod(method) : false;
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return _effectsPass.getMethodAt(index);
	}

	/**
	 * Adds a shading method to the end of a shader, at the specified index amongst
	 * the methods in that section of the shader. Note that shading methods can not
	 * be reused across materials.
	*/
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.addMethodAt(method, index);
		invalidateScreenPasses();
	}

	public function removeMethod(method:EffectMethodBase):Void
	{
		if (_effectsPass)
			return;
		_effectsPass.removeMethod(method);

		// reconsider
		if (_effectsPass.numMethods == 0)
			invalidateScreenPasses();
	}

	/**
	 * @inheritDoc
	 */
	override private inline function set_mipmap(value:Bool):Void
	{
		if (_mipmap == value)
			return;
		super.mipmap = value;
	}

	/**
	 * The tangent space normal map to influence the direction of the surface for each texel.
	 */
	private inline function get_normalMap():Texture2DBase
	{
		return _normalMethod.normalMap;
	}

	private inline function set_normalMap(value:Texture2DBase):Void
	{
		_normalMethod.normalMap = value;
	}

	/**
	 * A specular map that defines the strength of specular reflections for each texel in the red channel, and the gloss factor in the green channel.
	 * You can use SpecularBitmapTexture if you want to easily set specular and gloss maps from greyscale images, but prepared images are preffered.
	 */
	private inline function get_specularMap():Texture2DBase
	{
		return _specularMethod.texture;
	}

	private inline function set_specularMap(value:Texture2DBase):Void
	{
		if (_specularMethod)
			_specularMethod.texture = value;
		else
			throw new Error("No specular method was set to assign the specularGlossMap to");
	}

	/**
	 * The sharpness of the specular highlight.
	 */
	private inline function get_gloss():Float
	{
		return _specularMethod ? _specularMethod.gloss : 0;
	}

	private inline function set_gloss(value:Float):Void
	{
		if (_specularMethod)
			_specularMethod.gloss = value;
	}

	/**
	 * The strength of the ambient reflection.
	 */
	private inline function get_ambient():Float
	{
		return _ambientMethod.ambient;
	}

	private inline function set_ambient(value:Float):Void
	{
		_ambientMethod.ambient = value;
	}

	/**
	 * The overall strength of the specular reflection.
	 */
	private inline function get_specular():Float
	{
		return _specularMethod ? _specularMethod.specular : 0;
	}

	private inline function set_specular(value:Float):Void
	{
		if (_specularMethod)
			_specularMethod.specular = value;
	}

	/**
	 * The colour of the ambient reflection.
	 */
	private inline function get_ambientColor():UInt
	{
		return _ambientMethod.ambientColor;
	}

	private inline function set_ambientColor(value:UInt):Void
	{
		_ambientMethod.ambientColor = value;
	}

	/**
	 * The colour of the specular reflection.
	 */
	private inline function get_specularColor():UInt
	{
		return _specularMethod.specularColor;
	}

	private inline function set_specularColor(value:UInt):Void
	{
		_specularMethod.specularColor = value;
	}

	/**
	 * @inheritDoc
	 */
	override public function updateMaterial(context:Context3D):Void
	{
		var passesInvalid:Bool;

		if (_screenPassesInvalid)
		{
			updateScreenPasses();
			passesInvalid = true;
		}

		if (passesInvalid || isAnyScreenPassInvalid())
		{
			clearPasses();

			addChildPassesFor(_casterLightPass);
			if (_nonCasterLightPasses)
				for (i in 0..._nonCasterLightPasses.length)
					addChildPassesFor(_nonCasterLightPasses[i]);
			addChildPassesFor(_effectsPass);

			addScreenPass(_casterLightPass);
			if (_nonCasterLightPasses)
				for (i in 0..._nonCasterLightPasses.length)
					addScreenPass(_nonCasterLightPasses[i]);
			addScreenPass(_effectsPass);
		}
	}

	private function addScreenPass(pass:CompiledPass):Void
	{
		if (pass)
		{
			addPass(pass);
			pass.passesDirty = false;
		}
	}

	private function isAnyScreenPassInvalid():Bool
	{
		if ((_casterLightPass && _casterLightPass.passesDirty) ||
			(_effectsPass && _effectsPass.passesDirty))
			return true;

		if (_nonCasterLightPasses)
			for (i in 0..._nonCasterLightPasses.length)
				if (_nonCasterLightPasses[i].passesDirty)
					return true;

		return false;
	}

	private function addChildPassesFor(pass:CompiledPass):Void
	{
		if (!pass)
			return;

		if (pass.passes)
		{
			var len:UInt = pass.passes.length;
			for (i in 0...len)
				addPass(pass.passes[i]);
		}
	}

	override public function activatePass(index:UInt, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		if (index == 0)
			stage3DProxy.context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		super.activatePass(index, stage3DProxy, camera);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		super.deactivate(stage3DProxy);
		stage3DProxy.context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
	}

	private function updateScreenPasses():Void
	{
		initPasses();
		setBlendAndCompareModes();

		_screenPassesInvalid = false;
	}

	private function initPasses():Void
	{
// effects pass will be used to render unshaded diffuse
		if (numLights == 0 || numMethods > 0)
			initEffectsPass();
		else if (_effectsPass && numMethods == 0)
			removeEffectsPass();

		if (_shadowMethod)
			initCasterLightPass();
		else
			removeCasterLightPass();

		if (numNonCasters > 0)
			initNonCasterLightPasses();
		else
			removeNonCasterLightPasses();
	}

	private function setBlendAndCompareModes():Void
	{
		var forceSeparateMVP:Bool = Bool(_casterLightPass || _effectsPass);

		if (_casterLightPass)
		{
			_casterLightPass.setBlendMode(BlendMode.NORMAL);
			_casterLightPass.depthCompareMode = depthCompareMode;
			_casterLightPass.forceSeparateMVP = forceSeparateMVP;
		}

		if (_nonCasterLightPasses)
		{
			var firstAdditiveIndex:Int = 0;
			if (!_casterLightPass)
			{
				_nonCasterLightPasses[0].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[0].setBlendMode(BlendMode.NORMAL);
				_nonCasterLightPasses[0].depthCompareMode = depthCompareMode;
				firstAdditiveIndex = 1;
			}
			for (i in firstAdditiveIndex..._nonCasterLightPasses.length)
			{
				_nonCasterLightPasses[i].forceSeparateMVP = forceSeparateMVP;
				_nonCasterLightPasses[i].setBlendMode(BlendMode.ADD);
				_nonCasterLightPasses[i].depthCompareMode = Context3DCompareMode.LESS_EQUAL;
			}
		}

		if (_casterLightPass || _nonCasterLightPasses)
		{
			if (_effectsPass)
			{
				_effectsPass.ignoreLights = true;
				_effectsPass.depthCompareMode = Context3DCompareMode.LESS_EQUAL;
				_effectsPass.setBlendMode(BlendMode.LAYER);
				_effectsPass.forceSeparateMVP = forceSeparateMVP;
			}
		}
		else if (_effectsPass)
		{
			_effectsPass.ignoreLights = false;
			_effectsPass.depthCompareMode = depthCompareMode;
			_effectsPass.setBlendMode(BlendMode.NORMAL);
			_effectsPass.forceSeparateMVP = false;
		}
	}

	private function initCasterLightPass():Void
	{
		if (_casterLightPass == null)
			_casterLightPass = new ShadowCasterPass(this);
		_casterLightPass.diffuseMethod = null;
		_casterLightPass.ambientMethod = null;
		_casterLightPass.normalMethod = null;
		_casterLightPass.specularMethod = null;
		_casterLightPass.shadowMethod = null;
		_casterLightPass.enableLightFallOff = _enableLightFallOff;
		_casterLightPass.lightPicker = new StaticLightPicker([_shadowMethod.castingLight]);
		_casterLightPass.shadowMethod = _shadowMethod;
		_casterLightPass.diffuseMethod = _diffuseMethod;
		_casterLightPass.ambientMethod = _ambientMethod;
		_casterLightPass.normalMethod = _normalMethod;
		_casterLightPass.specularMethod = _specularMethod;
		_casterLightPass.diffuseLightSources = _diffuseLightSources;
		_casterLightPass.specularLightSources = _specularLightSources;
	}

	private function removeCasterLightPass():Void
	{
		if (!_casterLightPass)
			return;
		_casterLightPass.dispose();
		removePass(_casterLightPass);
		_casterLightPass = null;
	}

	private function initNonCasterLightPasses():Void
	{
		removeNonCasterLightPasses();
		var pass:LightingPass;
		var numDirLights:Int = _lightPicker.numDirectionalLights;
		var numPointLights:Int = _lightPicker.numPointLights;
		var numLightProbes:Int = _lightPicker.numLightProbes;
		var dirLightOffset:Int = 0;
		var pointLightOffset:Int = 0;
		var probeOffset:Int = 0;

		if (!_casterLightPass)
		{
			numDirLights += _lightPicker.numCastingDirectionalLights;
			numPointLights += _lightPicker.numCastingPointLights;
		}

		_nonCasterLightPasses = new Vector<LightingPass>();
		while (dirLightOffset < numDirLights || pointLightOffset < numPointLights || probeOffset < numLightProbes)
		{
			pass = new LightingPass(this);
			pass.enableLightFallOff = _enableLightFallOff;
			pass.includeCasters = _shadowMethod == null;
			pass.directionalLightsOffset = dirLightOffset;
			pass.pointLightsOffset = pointLightOffset;
			pass.lightProbesOffset = probeOffset;
			pass.diffuseMethod = null;
			pass.ambientMethod = null;
			pass.normalMethod = null;
			pass.specularMethod = null;
			pass.lightPicker = _lightPicker;
			pass.diffuseMethod = _diffuseMethod;
			pass.ambientMethod = _ambientMethod;
			pass.normalMethod = _normalMethod;
			pass.specularMethod = _specularMethod;
			pass.diffuseLightSources = _diffuseLightSources;
			pass.specularLightSources = _specularLightSources;
			_nonCasterLightPasses.push(pass);

			dirLightOffset += pass.numDirectionalLights;
			pointLightOffset += pass.numPointLights;
			probeOffset += pass.numLightProbes;
		}
	}

	private function removeNonCasterLightPasses():Void
	{
		if (!_nonCasterLightPasses)
			return;
		for (i in 0..._nonCasterLightPasses.length)
		{
			removePass(_nonCasterLightPasses[i]);
			_nonCasterLightPasses[i].dispose();
		}
		_nonCasterLightPasses = null;
	}

	private function removeEffectsPass():Void
	{
		if (_effectsPass.diffuseMethod != _diffuseMethod)
			_effectsPass.diffuseMethod.dispose();
		removePass(_effectsPass);
		_effectsPass.dispose();
		_effectsPass = null;
	}

	private function initEffectsPass():SuperShaderPass
	{
		if (_effectsPass == null)
			_effectsPass = new SuperShaderPass(this);
		_effectsPass.enableLightFallOff = _enableLightFallOff;
		if (numLights == 0)
		{
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = _diffuseMethod;
		}
		else
		{
			_effectsPass.diffuseMethod = null;
			_effectsPass.diffuseMethod = new BasicDiffuseMethod();
			_effectsPass.diffuseMethod.diffuseColor = 0x000000;
			_effectsPass.diffuseMethod.diffuseAlpha = 0;
		}
		_effectsPass.preserveAlpha = false;
		_effectsPass.normalMethod = null;
		_effectsPass.normalMethod = _normalMethod;

		return _effectsPass;
	}

	private function get_numLights():Int
	{
		return _lightPicker ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights +
			_lightPicker.numCastingDirectionalLights + _lightPicker.numCastingPointLights : 0;
	}

	private function get_numNonCasters():Int
	{
		return _lightPicker ? _lightPicker.numLightProbes + _lightPicker.numDirectionalLights + _lightPicker.numPointLights : 0;
	}

	private function invalidateScreenPasses():Void
	{
		_screenPassesInvalid = true;
	}

	private function onLightsChange(event:Event):Void
	{
		invalidateScreenPasses();
	}
}
