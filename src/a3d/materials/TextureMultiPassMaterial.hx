package a3d.materials;


import a3d.textures.Texture2DBase;


/**
 * TextureMultiPassMaterial is a multi-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
class TextureMultiPassMaterial extends MultiPassMaterialBase
{
	/**
	 * Specifies whether or not the UV coordinates should be animated using a transformation matrix.
	 */
	public var animateUVs(get, set):Bool;
	/**
	 * The texture object to use for the albedo colour.
	 */
	public var texture(get, set):Texture2DBase;
	/**
	 * The texture object to use for the ambient colour.
	 */
	public var ambientTexture(get, set):Texture2DBase;
	
	private var _animateUVs:Bool;

	/**
	 * Creates a new TextureMultiPassMaterial.
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
		return _animateUVs;
	}

	private function set_animateUVs(value:Bool):Bool
	{
		_animateUVs = value;
		invalidateScreenPasses();
		return _animateUVs;	
	}

	
	private function get_texture():Texture2DBase
	{
		return diffuseMethod.texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		return diffuseMethod.texture = value;
	}

	
	private function get_ambientTexture():Texture2DBase
	{
		return ambientMethod.texture;
	}

	private function set_ambientTexture(value:Texture2DBase):Texture2DBase
	{
		ambientMethod.texture = value;
		diffuseMethod.useAmbientTexture = value != null;
		
		return value;
	}


	override private function updateScreenPasses():Void
	{
		super.updateScreenPasses();
		
		if (_effectsPass != null && numLights == 0) 
		{
			_effectsPass.animateUVs = _animateUVs;
		}
		
		if (_casterLightPass != null)
		{
			_casterLightPass.animateUVs = _animateUVs;
		}
		
		if (_nonCasterLightPasses != null) 
		{
			var length:Int = _nonCasterLightPasses.length;
			for (i in 0...length)
			{
				_nonCasterLightPasses[i].animateUVs = _animateUVs;
			}
		}
	}
}
