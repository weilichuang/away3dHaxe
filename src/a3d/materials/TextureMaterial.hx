package a3d.materials;

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

	public var animateUVs(get, set):Bool;
	private function get_animateUVs():Bool
	{
		return _screenPass.animateUVs;
	}

	private function set_animateUVs(value:Bool):Bool
	{
		return _screenPass.animateUVs = value;
	}

	/**
	 * The alpha of the surface.
	 */
	public var alpha(get, set):Float;
	private function get_alpha():Float
	{
		return _screenPass.colorTransform != null ? _screenPass.colorTransform.alphaMultiplier : 1;
	}

	private function set_alpha(value:Float):Float
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
		
		return alpha;
	}

	/**
	 * The texture object to use for the albedo colour.
	 */
	public var texture(get, set):Texture2DBase;
	private function get_texture():Texture2DBase
	{
		return _screenPass.diffuseMethod.texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		return _screenPass.diffuseMethod.texture = value;
	}

	/**
	 * The texture object to use for the ambient colour.
	 */
	public var ambientTexture(get, set):Texture2DBase;
	private function get_ambientTexture():Texture2DBase
	{
		return _screenPass.ambientMethod.texture;
	}

	private function set_ambientTexture(value:Texture2DBase):Texture2DBase
	{
		_screenPass.ambientMethod.texture = value;
		_screenPass.diffuseMethod.useAmbientTexture = (value != null);
		
		return _screenPass.ambientMethod.texture;
	}
}
