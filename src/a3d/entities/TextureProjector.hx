package a3d.entities
{
	import flash.geom.Matrix3D;
	
	
	import a3d.entities.lenses.PerspectiveLens;
	import a3d.events.LensEvent;
	import a3d.io.library.assets.AssetType;
	import a3d.textures.Texture2DBase;

	

	/**
	 * TextureProjector is an object in the scene that can be used to project textures onto geometry. To do so,
	 * the object's material must have a ProjectiveTextureMethod method added to it with a TextureProjector object
	 * passed in the constructor.
	 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
	 * unto a surface, the impact of light coming through a stained glass window, ...
	 *
	 * @see a3d.materials.methods.ProjectiveTextureMethod
	 */
	class TextureProjector extends ObjectContainer3D
	{
		private var _lens:PerspectiveLens;
		private var _viewProjectionInvalid:Bool = true;
		private var _viewProjection:Matrix3D = new Matrix3D();
		private var _texture:Texture2DBase;

		/**
		 * Creates a new TextureProjector object.
		 * @param texture The texture to be projected on the geometry. Since any point that is projected out of the range
		 * of the projector's cone is clamped to the texture's edges, the edges should be entirely neutral.
		 */
		public function TextureProjector(texture:Texture2DBase)
		{
			_lens = new PerspectiveLens();
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onInvalidateLensMatrix, false, 0, true);
			_texture = texture;
			_lens.aspectRatio = texture.width / texture.height;
			rotationX = -90;
		}

		/**
		 * The aspect ratio of the texture or projection. By default this is the same aspect ratio of the texture (width/height)
		 */
		private inline function get_aspectRatio():Float
		{
			return _lens.aspectRatio;
		}

		private inline function set_aspectRatio(value:Float):Void
		{
			_lens.aspectRatio = value;
		}

		/**
		 * The vertical field of view of the projection, or the angle of the cone.
		 */
		private inline function get_fieldOfView():Float
		{
			return _lens.fieldOfView;
		}

		private inline function set_fieldOfView(value:Float):Void
		{
			_lens.fieldOfView = value;
		}

		override private inline function get_assetType():String
		{
			return AssetType.TEXTURE_PROJECTOR;
		}

		/**
		 * The texture to be projected on the geometry.
		 * IMPORTANT: Since any point that is projected out of the range of the projector's cone is clamped to the texture's edges,
		 * the edges should be entirely neutral. Depending on the blend mode, the neutral color is:
		 * White for MULTIPLY,
		 * Black for ADD,
		 * Transparent for MIX
		 */
		private inline function get_texture():Texture2DBase
		{
			return _texture;
		}

		private inline function set_texture(value:Texture2DBase):Void
		{
			if (value == _texture)
				return;
			_texture = value;
		}

		/**
		 * The matrix that projects a point in scene space into the texture coordinates.
		 */
		private inline function get_viewProjection():Matrix3D
		{
			if (_viewProjectionInvalid)
			{
				_viewProjection.copyFrom(inverseSceneTransform);
				_viewProjection.append(_lens.matrix);
				_viewProjectionInvalid = false;
			}
			return _viewProjection;
		}

		/**
		 * @inheritDoc
		 */
		override private function invalidateSceneTransform():Void
		{
			super.invalidateSceneTransform();
			_viewProjectionInvalid = true;
		}

		private function onInvalidateLensMatrix(event:LensEvent):Void
		{
			_viewProjectionInvalid = true;
		}
	}
}
