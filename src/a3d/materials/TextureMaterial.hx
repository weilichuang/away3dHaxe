package a3d.materials;

import flash.display.BlendMode;
import flash.geom.ColorTransform;


import a3d.textures.Texture2DBase;



/**
 * TextureMaterial is a material that uses a texture as the surface's diffuse colour.
 */
class TextureMaterial extends SinglePassMaterialBase
{
	/**
	 * Creates a new TextureMaterial.
	 */
	public function new(texture:Texture2DBase = null, smooth:Bool = true, repeat:Bool = false, mipmap:Bool = true)
	{
		super();
		this.texture = texture;
		this.smooth = smooth;
		this.repeat = repeat;
		this.mipmap = mipmap;

	}

	private inline function get_animateUVs():Bool
	{
		return _screenPass.animateUVs;
	}

	private inline function set_animateUVs(value:Bool):Void
	{
		_screenPass.animateUVs = value;
	}

	/**
	 * The alpha of the surface.
	 */
	private inline function get_alpha():Float
	{
		return _screenPass.colorTransform ? _screenPass.colorTransform.alphaMultiplier : 1;
	}

	private inline function set_alpha(value:Float):Void
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;
		
		if (colorTransform == null)
			colorTransform = new ColorTransform();
		colorTransform.alphaMultiplier = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
	}

	/**
	 * The texture object to use for the albedo colour.
	 */
	private inline function get_texture():Texture2DBase
	{
		return _screenPass.diffuseMethod.texture;
	}

	private inline function set_texture(value:Texture2DBase):Void
	{
		_screenPass.diffuseMethod.texture = value;
	}

	/**
	 * The texture object to use for the ambient colour.
	 */
	private inline function get_ambientTexture():Texture2DBase
	{
		return _screenPass.ambientMethod.texture;
	}

	private inline function set_ambientTexture(value:Texture2DBase):Void
	{
		_screenPass.ambientMethod.texture = value;
		_screenPass.diffuseMethod.useAmbientTexture = Bool(value);
	}
}
