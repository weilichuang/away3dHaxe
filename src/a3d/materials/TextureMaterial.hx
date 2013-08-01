package a3d.materials;

import a3d.math.FMath;
import a3d.textures.Texture2DBase;
import flash.geom.ColorTransform;





/**
 * TextureMaterial is a single-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
class TextureMaterial extends SinglePassMaterialBase
{
	/**
	 * Specifies whether or not the UV coordinates should be animated using IRenderable's uvTransform matrix.
	 *
	 * @see IRenderable.uvTransform
	 */
	public var animateUVs(get, set):Bool;
	/**
	 * The alpha of the surface.
	 */
	public var alpha(get, set):Float;
	/**
	 * The texture object to use for the albedo colour.
	 */
	public var texture(get, set):Texture2DBase;
	/**
	 * The texture object to use for the ambient colour.
	 */
	public var ambientTexture(get, set):Texture2DBase;
	
	/**
	 * Creates a new TextureMaterial.
	 * @param texture The texture used for the material's albedo color.
	 * @param smooth Indicates whether the texture should be filtered when sampled. Defaults to true.
	 * @param repeat Indicates whether the texture should be tiled when sampled. Defaults to true.
	 * @param mipmap Indicates whether or not any used textures should use mipmapping. Defaults to true.
	 */
	public function new(texture:Texture2DBase = null, smooth:Bool = true, repeat:Bool = false, mipmap:Bool = true)
	{
		super();
		this.texture = texture;
		this.smooth = smooth;
		this.repeat = repeat;
		this.mipmap = mipmap;

	}

	
	private function get_animateUVs():Bool
	{
		return _screenPass.animateUVs;
	}

	private function set_animateUVs(value:Bool):Bool
	{
		return _screenPass.animateUVs = value;
	}

	
	private function get_alpha():Float
	{
		return _screenPass.colorTransform != null ? _screenPass.colorTransform.alphaMultiplier : 1;
	}

	private function set_alpha(value:Float):Float
	{
		value = FMath.fclamp(value, 0, 1);
		
		if (colorTransform == null)
			colorTransform = new ColorTransform();
		colorTransform.alphaMultiplier = value;
		_screenPass.preserveAlpha = requiresBlending;
		_screenPass.setBlendMode(blendMode == BlendMode.NORMAL && requiresBlending ? BlendMode.LAYER : blendMode);
		
		return value;
	}
	
	private function get_texture():Texture2DBase
	{
		return _screenPass.diffuseMethod.texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		return _screenPass.diffuseMethod.texture = value;
	}

	
	private function get_ambientTexture():Texture2DBase
	{
		return _screenPass.ambientMethod.texture;
	}

	private function set_ambientTexture(value:Texture2DBase):Texture2DBase
	{
		_screenPass.ambientMethod.texture = value;
		_screenPass.diffuseMethod.useAmbientTexture = (value != null);
		
		return value;
	}
}
