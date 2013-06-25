package a3d.materials;

import flash.display.BlendMode;
import flash.display3D.Context3D;
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
	private inline function get_enableLightFallOff():Bool
	{
		return _screenPass.enableLightFallOff;
	}

	private inline function set_enableLightFallOff(value:Bool):Void
	{
		_screenPass.enableLightFallOff = value;
	}

	/**
	 * The minimum alpha value for which pixels should be drawn. This is used for transparency that is either
	 * invisible or entirely opaque, often used with textures for foliage, etc.
	 * Recommended values are 0 to disable alpha, or 0.5 to create smooth edges. Default value is 0 (disabled).
	 */
	private inline function get_alphaThreshold():Float
	{
		return _screenPass.diffuseMethod.alphaThreshold;
	}

	private inline function set_alphaThreshold(value:Float):Void
	{
		_screenPass.diffuseMethod.alphaThreshold = value;
		_depthPass.alphaThreshold = value;
		_distancePass.alphaThreshold = value;
	}


	override private inline function set_blendMode(value:String):Void
	{
		super.blendMode = value;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
	}

	override private inline function set_depthCompareMode(value:String):Void
	{
		super.depthCompareMode = value;
		_screenPass.depthCompareMode = value;
	}

	override public function activateForDepth(stage3DProxy:Stage3DProxy, camera:Camera3D, distanceBased:Bool = false):Void
	{
		if (distanceBased)
			_distancePass.alphaMask = _screenPass.diffuseMethod.texture;
		else
			_depthPass.alphaMask = _screenPass.diffuseMethod.texture;
		super.activateForDepth(stage3DProxy, camera, distanceBased);
	}

	private inline function get_specularLightSources():UInt
	{
		return _screenPass.specularLightSources;
	}

	private inline function set_specularLightSources(value:UInt):Void
	{
		_screenPass.specularLightSources = value;
	}

	private inline function get_diffuseLightSources():UInt
	{
		return _screenPass.diffuseLightSources;
	}

	private inline function set_diffuseLightSources(value:UInt):Void
	{
		_screenPass.diffuseLightSources = value;
	}

	/**
	 * The ColorTransform object to transform the colour of the material with.
	 */
	private inline function get_colorTransform():ColorTransform
	{
		return _screenPass.colorTransform;
	}

	private inline function set_colorTransform(value:ColorTransform):Void
	{
		_screenPass.colorTransform = value;
	}

	/**
	 * @inheritDoc
	 */
	override private inline function get_requiresBlending():Bool
	{
		return super.requiresBlending || _alphaBlending || (_screenPass.colorTransform && _screenPass.colorTransform.alphaMultiplier < 1);
	}

	/**
	 * The method to perform ambient shading. Note that shading methods cannot
	 * be reused across materials.
	 */
	private inline function get_ambientMethod():BasicAmbientMethod
	{
		return _screenPass.ambientMethod;
	}

	private inline function set_ambientMethod(value:BasicAmbientMethod):Void
	{
		_screenPass.ambientMethod = value;
	}

	/**
	 * The method to render shadows cast on this surface. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_shadowMethod():ShadowMapMethodBase
	{
		return _screenPass.shadowMethod;
	}

	private inline function set_shadowMethod(value:ShadowMapMethodBase):Void
	{
		_screenPass.shadowMethod = value;
	}

	/**
	 * The method to perform diffuse shading. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_diffuseMethod():BasicDiffuseMethod
	{
		return _screenPass.diffuseMethod;
	}

	private inline function set_diffuseMethod(value:BasicDiffuseMethod):Void
	{
		_screenPass.diffuseMethod = value;
	}

	/**
	 * The method to generate the (tangent-space) normal. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_normalMethod():BasicNormalMethod
	{
		return _screenPass.normalMethod;
	}

	private inline function set_normalMethod(value:BasicNormalMethod):Void
	{
		_screenPass.normalMethod = value;
	}

	/**
	 * The method to perform specular shading. Note that shading methods can not
	 * be reused across materials.
	 */
	private inline function get_specularMethod():BasicSpecularMethod
	{
		return _screenPass.specularMethod;
	}

	private inline function set_specularMethod(value:BasicSpecularMethod):Void
	{
		_screenPass.specularMethod = value;
	}

	/**
		 * Adds a shading method to the end of the shader. Note that shading methods can
		 * not be reused across materials.
		*/
	public function addMethod(method:EffectMethodBase):Void
	{
		_screenPass.addMethod(method);
	}

	private inline function get_numMethods():Int
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
		return _screenPass.normalMap;
	}

	private inline function set_normalMap(value:Texture2DBase):Void
	{
		_screenPass.normalMap = value;
	}

	/**
	 * A specular map that defines the strength of specular reflections for each texel in the red channel, and the gloss factor in the green channel.
	 * You can use SpecularBitmapTexture if you want to easily set specular and gloss maps from greyscale images, but prepared images are preffered.
	 */
	private inline function get_specularMap():Texture2DBase
	{
		return _screenPass.specularMethod.texture;
	}

	private inline function set_specularMap(value:Texture2DBase):Void
	{
		if (_screenPass.specularMethod)
			_screenPass.specularMethod.texture = value;
		else
			throw new Error("No specular method was set to assign the specularGlossMap to");
	}

	/**
	 * The sharpness of the specular highlight.
	 */
	private inline function get_gloss():Float
	{
		return _screenPass.specularMethod ? _screenPass.specularMethod.gloss : 0;
	}

	private inline function set_gloss(value:Float):Void
	{
		if (_screenPass.specularMethod)
			_screenPass.specularMethod.gloss = value;
	}

	/**
	 * The strength of the ambient reflection.
	 */
	private inline function get_ambient():Float
	{
		return _screenPass.ambientMethod.ambient;
	}

	private inline function set_ambient(value:Float):Void
	{
		_screenPass.ambientMethod.ambient = value;
	}

	/**
	 * The overall strength of the specular reflection.
	 */
	private inline function get_specular():Float
	{
		return _screenPass.specularMethod ? _screenPass.specularMethod.specular : 0;
	}

	private inline function set_specular(value:Float):Void
	{
		if (_screenPass.specularMethod)
			_screenPass.specularMethod.specular = value;
	}

	/**
	 * The colour of the ambient reflection.
	 */
	private inline function get_ambientColor():UInt
	{
		return _screenPass.ambientMethod.ambientColor;
	}

	private inline function set_ambientColor(value:UInt):Void
	{
		_screenPass.ambientMethod.ambientColor = value;
	}

	/**
	 * The colour of the specular reflection.
	 */
	private inline function get_specularColor():UInt
	{
		return _screenPass.specularMethod.specularColor;
	}

	private inline function set_specularColor(value:UInt):Void
	{
		_screenPass.specularMethod.specularColor = value;
	}

	/**
	 * Indicate whether or not the material has transparency. If binary transparency is sufficient, for
	 * example when using textures of foliage, consider using alphaThreshold instead.
	 */
	private inline function get_alphaBlending():Bool
	{
		return _alphaBlending;
	}

	private inline function set_alphaBlending(value:Bool):Void
	{
		_alphaBlending = value;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
		_screenPass.preserveAlpha = requiresBlending;
	}

	/**
	 * @inheritDoc
	 */
	override public function updateMaterial(context:Context3D):Void
	{
		if (_screenPass.passesDirty)
		{
			clearPasses();
			if (_screenPass.passes)
			{
				var len:UInt = _screenPass.passes.length;
				for (var i:UInt = 0; i < len; ++i)
					addPass(_screenPass.passes[i]);
			}

			addPass(_screenPass);
			_screenPass.passesDirty = false;
		}
	}

	override private inline function set_lightPicker(value:LightPickerBase):Void
	{
		super.lightPicker = value;
		_screenPass.lightPicker = value;
	}
}
