package a3d.materials;

import flash.display.BlendMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DCompareMode;
import flash.errors.Error;
import flash.geom.ColorTransform;


import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.materials.lightpickers.LightPickerBase;
import a3d.materials.methods.BasicAmbientMethod;
import a3d.materials.methods.BasicDiffuseMethod;
import a3d.materials.methods.BasicNormalMethod;
import a3d.materials.methods.BasicSpecularMethod;
import a3d.materials.methods.EffectMethodBase;
import a3d.materials.methods.ShadowMapMethodBase;
import a3d.materials.passes.SuperShaderPass;
import a3d.textures.Texture2DBase;



/**
 * SinglePassMaterialBase forms an abstract base class for the default single-pass materials provided by Away3D, using material methods
 * to define their appearance.
 */
class SinglePassMaterialBase extends MaterialBase
{
	private var _screenPass:SuperShaderPass;
	private var _alphaBlending:Bool;

	/**
	 * Creates a new DefaultMaterialBase object.
	 */
	public function new()
	{
		super();
		addPass(_screenPass = new SuperShaderPass(this));
	}

	/**
	 * Whether or not to use fallOff and radius properties for lights.
	 */
	public var enableLightFallOff(get, set):Bool;
	private function get_enableLightFallOff():Bool
	{
		return _screenPass.enableLightFallOff;
	}

	private function set_enableLightFallOff(value:Bool):Bool
	{
		return _screenPass.enableLightFallOff = value;
	}

	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	public var alphaThreshold(get, set):Float;
	private function get_alphaThreshold():Float
	{
		return _screenPass.diffuseMethod.alphaThreshold;
	}

	private function set_alphaThreshold(value:Float):Float
	{
		_screenPass.diffuseMethod.alphaThreshold = value;
		_depthPass.alphaThreshold = value;
		_distancePass.alphaThreshold = value;
		
		return value;
	}


	override private function set_blendMode(value:BlendMode):BlendMode
	{
		super.blendMode = value;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
		return blendMode;
	}

	override private function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		super.depthCompareMode = value;
		_screenPass.depthCompareMode = value;
		return super.depthCompareMode;
	}

	override public function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		if (distanceBased)
			_distancePass.alphaMask = _screenPass.diffuseMethod.texture;
		else
			_depthPass.alphaMask = _screenPass.diffuseMethod.texture;
		super.activateForDepth(stage3DProxy, camera, distanceBased);
	}

	public var specularLightSources(get, set):UInt;
	private function get_specularLightSources():UInt
	{
		return _screenPass.specularLightSources;
	}

	private function set_specularLightSources(value:UInt):UInt
	{
		return _screenPass.specularLightSources = value;
	}

	public var diffuseLightSources(get, set):UInt;
	private function get_diffuseLightSources():UInt
	{
		return _screenPass.diffuseLightSources;
	}

	private function set_diffuseLightSources(value:UInt):UInt
	{
		return _screenPass.diffuseLightSources = value;
	}

	/**
	 * The ColorTransform object to transform the colour of the material with.
	 */
	public var colorTransform(get, set):ColorTransform;
	private function get_colorTransform():ColorTransform
	{
		return _screenPass.colorTransform;
	}

	private function set_colorTransform(value:ColorTransform):ColorTransform
	{
		return _screenPass.colorTransform = value;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_requiresBlending():Bool
	{
		return super.requiresBlending || _alphaBlending || (_screenPass.colorTransform != null && _screenPass.colorTransform.alphaMultiplier < 1);
	}

	/**
	 * The method to perform ambient shading. Note that shading methods cannot
	 * be reused across materials.
	 */
	public var ambientMethod(get, set):BasicAmbientMethod;
	private function get_ambientMethod():BasicAmbientMethod
	{
		return _screenPass.ambientMethod;
	}

	private function set_ambientMethod(value:BasicAmbientMethod):BasicAmbientMethod
	{
		return _screenPass.ambientMethod = value;
	}

	/**
	 * The method to render shadows cast on this surface. Note that shading methods can not
	 * be reused across materials.
	 */
	public var shadowMethod(get, set):ShadowMapMethodBase;
	private function get_shadowMethod():ShadowMapMethodBase
	{
		return _screenPass.shadowMethod;
	}

	private function set_shadowMethod(value:ShadowMapMethodBase):ShadowMapMethodBase
	{
		return _screenPass.shadowMethod = value;
	}

	/**
	 * The method to perform diffuse shading. Note that shading methods can not
	 * be reused across materials.
	 */
	public var diffuseMethod(get, set):BasicDiffuseMethod;
	private function get_diffuseMethod():BasicDiffuseMethod
	{
		return _screenPass.diffuseMethod;
	}

	private function set_diffuseMethod(value:BasicDiffuseMethod):BasicDiffuseMethod
	{
		return _screenPass.diffuseMethod = value;
	}

	/**
	 * The method to generate the (tangent-space) normal. Note that shading methods can not
	 * be reused across materials.
	 */
	public var normalMethod(get, set):BasicNormalMethod;
	private function get_normalMethod():BasicNormalMethod
	{
		return _screenPass.normalMethod;
	}

	private function set_normalMethod(value:BasicNormalMethod):BasicNormalMethod
	{
		return _screenPass.normalMethod = value;
	}

	/**
	 * The method to perform specular shading. Note that shading methods can not
	 * be reused across materials.
	 */
	public var specularMethod(get, set):BasicSpecularMethod;
	private function get_specularMethod():BasicSpecularMethod
	{
		return _screenPass.specularMethod;
	}

	private function set_specularMethod(value:BasicSpecularMethod):BasicSpecularMethod
	{
		return _screenPass.specularMethod = value;
	}

	/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		*/
	public function addMethod(method:EffectMethodBase):Void
	{
		_screenPass.addMethod(method);
	}

	public var numMethods(get, null):Int;
	private function get_numMethods():Int
	{
		return _screenPass.numMethods;
	}

	public function hasMethod(method:EffectMethodBase):Bool
	{
		return _screenPass.hasMethod(method);
	}

	public function getMethodAt(index:Int):EffectMethodBase
	{
		return _screenPass.getMethodAt(index);
	}

	/**
	 * Adds a shading method to the end of a shader, at the specified index amongst
	 * the methods in that section of the shader. Note that shading methods can not
	 * be reused across materials.
	*/
	public function addMethodAt(method:EffectMethodBase, index:Int):Void
	{
		_screenPass.addMethodAt(method, index);
	}

	public function removeMethod(method:EffectMethodBase):Void
	{
		_screenPass.removeMethod(method);
	}

	/**
	 * @inheritDoc
	 */
	override private function set_mipmap(value:Bool):Bool
	{
		if (_mipmap == value)
			return _mipmap;
		return super.mipmap = value;
	}

	/**
	 * The tangent space normal map to influence the direction of the surface for each texel.
	 */
	public var normalMap(get, set):Texture2DBase;
	private function get_normalMap():Texture2DBase
	{
		return _screenPass.normalMap;
	}

	private function set_normalMap(value:Texture2DBase):Texture2DBase
	{
		return _screenPass.normalMap = value;
	}

	/**
	 * A specular map that defines the strength of specular reflections for each texel in the red channel, and the gloss factor in the green channel.
	 * You can use SpecularBitmapTexture if you want to easily set specular and gloss maps from greyscale images, but prepared images are preffered.
	 */
	public var specularMap(get, set):Texture2DBase;
	private function get_specularMap():Texture2DBase
	{
		return _screenPass.specularMethod.texture;
	}

	private function set_specularMap(value:Texture2DBase):Texture2DBase
	{
		if (_screenPass.specularMethod != null)
			_screenPass.specularMethod.texture = value;
		else
			throw new Error("No specular method was set to assign the specularGlossMap to");
		
		return _screenPass.specularMethod.texture;
	}

	/**
	 * The sharpness of the specular highlight.
	 */
	public var gloss(get, set):Float;
	private function get_gloss():Float
	{
		return _screenPass.specularMethod != null ? _screenPass.specularMethod.gloss : 0;
	}

	private function set_gloss(value:Float):Float
	{
		if (_screenPass.specularMethod != null)
			_screenPass.specularMethod.gloss = value;
			
		return gloss;
	}

	/**
	 * The strength of the ambient reflection.
	 */
	public var ambient(get, set):Float;
	private function get_ambient():Float
	{
		return _screenPass.ambientMethod.ambient;
	}

	private function set_ambient(value:Float):Float
	{
		return _screenPass.ambientMethod.ambient = value;
	}

	/**
	 * The overall strength of the specular reflection.
	 */
	public var specular(get, set):Float;
	private function get_specular():Float
	{
		return _screenPass.specularMethod != null ? _screenPass.specularMethod.specular : 0;
	}

	private function set_specular(value:Float):Float
	{
		if (_screenPass.specularMethod != null)
			_screenPass.specularMethod.specular = value;
		return specular;
	}

	/**
	 * The colour of the ambient reflection.
	 */
	public var ambientColor(get, set):UInt;
	private function get_ambientColor():UInt
	{
		return _screenPass.ambientMethod.ambientColor;
	}

	private function set_ambientColor(value:UInt):UInt
	{
		return _screenPass.ambientMethod.ambientColor = value;
	}

	/**
	 * The colour of the specular reflection.
	 */
	public var specularColor(get, set):UInt;
	private function get_specularColor():UInt
	{
		return _screenPass.specularMethod.specularColor;
	}

	private function set_specularColor(value:UInt):UInt
	{
		return _screenPass.specularMethod.specularColor = value;
	}

	/**
	 * Indicate whether or not the material has transparency. If binary transparency is sufficient, for
	 * example when using textures of foliage, consider using alphaThreshold instead.
	 */
	public var alphaBlending(get, set):Bool;
	private function get_alphaBlending():Bool
	{
		return _alphaBlending;
	}

	private function set_alphaBlending(value:Bool):Bool
	{
		_alphaBlending = value;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
		_screenPass.preserveAlpha = requiresBlending;
		return _alphaBlending;
	}

	/**
	 * @inheritDoc
	 */
	override public function updateMaterial(context:Context3D):Void
	{
		if (_screenPass.passesDirty)
		{
			clearPasses();
			if (_screenPass.passes != null)
			{
				var len:UInt = _screenPass.passes.length;
				for (i in 0...len)
					addPass(_screenPass.passes[i]);
			}

			addPass(_screenPass);
			_screenPass.passesDirty = false;
		}
	}

	override private function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		super.lightPicker = value;
		return _screenPass.lightPicker = value;
	}
}
