package a3d.entities;

import a3d.entities.lenses.PerspectiveLens;
import a3d.events.LensEvent;
import a3d.io.library.assets.AssetType;
import a3d.textures.Texture2DBase;
import flash.geom.Matrix3D;


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
	
	/**
	 * The aspect ratio of the texture or projection. By default this is the same aspect ratio of the texture (width/height)
	 */
	public var aspectRatio(get,set):Float;
	/**
	 * The vertical field of view of the projection, or the angle of the cone.
	 */
	public var fieldOfView(get, set):Float;
	
	/**
	 * The texture to be projected on the geometry.
	 * IMPORTANT: Since any point that is projected out of the range of the projector's cone is clamped to the texture's edges,
	 * the edges should be entirely neutral. Depending on the blend mode, the neutral color is:
	 * White for MULTIPLY,
	 * Black for ADD,
	 * Transparent for MIX
	 */
	public var texture(get,set):Texture2DBase;
	/**
	 * The matrix that projects a point in scene space into the texture coordinates.
	 */
	public var viewProjection(get,null):Matrix3D;
	
	private var _lens:PerspectiveLens;
	private var _viewProjectionInvalid:Bool = true;
	private var _viewProjection:Matrix3D;
	private var _texture:Texture2DBase;

	/**
	 * Creates a new TextureProjector object.
	 * @param texture The texture to be projected on the geometry. Since any point that is projected out of the range
	 * of the projector's cone is clamped to the texture's edges, the edges should be entirely neutral.
	 */
	public function new(texture:Texture2DBase)
	{
		super();
		
		_viewProjection = new Matrix3D();
		
		_lens = new PerspectiveLens();
		_lens.addEventListener(LensEvent.MATRIX_CHANGED, onInvalidateLensMatrix, false, 0, true);
		_texture = texture;
		_lens.aspectRatio = texture.width / texture.height;
		rotationX = -90;
	}

	
	private function get_aspectRatio():Float
	{
		return _lens.aspectRatio;
	}

	private function set_aspectRatio(value:Float):Float
	{
		return _lens.aspectRatio = value;
	}

	private function get_fieldOfView():Float
	{
		return _lens.fieldOfView;
	}

	private function set_fieldOfView(value:Float):Float
	{
		return _lens.fieldOfView = value;
	}

	override private function get_assetType():String
	{
		return AssetType.TEXTURE_PROJECTOR;
	}

	
	private function get_texture():Texture2DBase
	{
		return _texture;
	}

	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		if (value == _texture)
			return _texture;
		return _texture = value;
	}

	
	private function get_viewProjection():Matrix3D
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
