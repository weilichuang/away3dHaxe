package away3d.materials;


import away3d.textures.Texture2DBase;


/**
 * TextureMultiPassMaterial is a multi-pass material that uses a texture to define the surface's diffuse reflection colour (albedo).
 */
class TextureMultiPassMaterial extends MultiPassMaterialBase
{
	private var _animateUVs:Boolean;

	public function new(texture:Texture2DBase = null, smooth:Boolean = true, repeat:Boolean = true, mipmap:Boolean = true)
	{
		super();
		this.texture = texture;
		this.smooth = smooth;
		this.repeat = repeat;
		this.mipmap = mipmap;
	}

	public function get animateUVs():Boolean
	{
		return _animateUVs;
	}

	public function set animateUVs(value:Boolean):void
	{
		_animateUVs = value;
	}

	/**
	 * The texture object to use for the albedo colour.
	 */
	public function get texture():Texture2DBase
	{
		return diffuseMethod.texture;
	}

	public function set texture(value:Texture2DBase):void
	{
		diffuseMethod.texture = value;
	}

	/**
	 * The texture object to use for the ambient colour.
	 */
	public function get ambientTexture():Texture2DBase
	{
		return ambientMethod.texture;
	}

	public function set ambientTexture(value:Texture2DBase):void
	{
		ambientMethod.texture = value;
		diffuseMethod.useAmbientTexture = Boolean(value);
	}


	override protected function updateScreenPasses():void
	{
		super.updateScreenPasses();
		if (_effectsPass)
			_effectsPass.animateUVs = _animateUVs;
	}
}
