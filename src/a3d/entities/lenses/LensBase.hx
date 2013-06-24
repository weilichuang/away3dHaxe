package a3d.entities.lenses;

import flash.events.EventDispatcher;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;


import a3d.errors.AbstractMethodError;
import a3d.events.LensEvent;



/**
 * An abstract base class for all lens classes. Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
 */
class LensBase extends EventDispatcher
{
	private var _matrix:Matrix3D;
	private var _scissorRect:Rectangle = new Rectangle();
	private var _viewPort:Rectangle = new Rectangle();
	private var _near:Float = 20;
	private var _far:Float = 3000;
	private var _aspectRatio:Float = 1;

	private var _matrixInvalid:Bool = true;
	private var _frustumCorners:Vector<Float> = new Vector<Float>(8 * 3, true);

	private var _unprojection:Matrix3D;
	private var _unprojectionInvalid:Bool = true;

	/**
	 * Creates a new LensBase object.
	 */
	public function LensBase()
	{
		_matrix = new Matrix3D();
	}

	/**
	 * Retrieves the corner points of the lens frustum.
	 */
	private inline function get_frustumCorners():Vector<Float>
	{
		return _frustumCorners;
	}

	private inline function set_frustumCorners(frustumCorners:Vector<Float>):Void
	{
		_frustumCorners = frustumCorners;
	}

	/**
	 * The projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */
	private inline function get_matrix():Matrix3D
	{
		if (_matrixInvalid)
		{
			updateMatrix();
			_matrixInvalid = false;
		}
		return _matrix;
	}

	private inline function set_matrix(value:Matrix3D):Void
	{
		_matrix = value;
		invalidateMatrix();
	}

	/**
	 * The distance to the near plane of the frustum. Anything behind near plane will not be rendered.
	 */
	private inline function get_near():Float
	{
		return _near;
	}

	private inline function set_near(value:Float):Void
	{
		if (value == _near)
			return;
		_near = value;
		invalidateMatrix();
	}

	/**
	 * The distance to the far plane of the frustum. Anything beyond the far plane will not be rendered.
	 */
	private inline function get_far():Float
	{
		return _far;
	}

	private inline function set_far(value:Float):Void
	{
		if (value == _far)
			return;
		_far = value;
		invalidateMatrix();
	}

	/**
	 * Calculates the normalised position in screen space of the given scene position relative to the camera.
	 *
	 * @param point3d the position vector of the scene coordinates to be projected.
	 * @return The normalised screen position of the given scene coordinates relative to the camera.
	 */
	public function project(point3d:Vector3D):Vector3D
	{
		var v:Vector3D = matrix.transformVector(point3d);
		v.x = v.x / v.w;
		v.y = -v.y / v.w;

		//z is unaffected by transform
		v.z = point3d.z;

		return v;
	}

	private inline function get_unprojectionMatrix():Matrix3D
	{
		if (_unprojectionInvalid)
		{
			if (_unprojection == null)
				_unprojection = new Matrix3D();
			_unprojection.copyFrom(matrix);
			_unprojection.invert();
			_unprojectionInvalid = false;
		}

		return _unprojection;
	}

	/**
	 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
	 *
	 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
	 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
	 * @param sZ The z coordinate in screen space, representing the distance into the screen.
	 * @return The scene position relative to the camera of the given screen coordinates.
	 */
	public function unproject(nX:Float, nY:Float, sZ:Float):Vector3D
	{
		throw new AbstractMethodError();
	}

	/**
	 * Creates an exact duplicate of the lens
	 */
	public function clone():LensBase
	{
		throw new AbstractMethodError();
	}

	/**
	 * The aspect ratio (width/height) of the view. Set by the renderer.
	 * @private
	 */
	private inline function get_aspectRatio():Float
	{
		return _aspectRatio;
	}

	private inline function set_aspectRatio(value:Float):Void
	{
		if (_aspectRatio == value)
			return;
		_aspectRatio = value;
		invalidateMatrix();
	}

	/**
	 * Invalidates the projection matrix, which will cause it to be updated on the next request.
	 */
	private function invalidateMatrix():Void
	{
		_matrixInvalid = true;
		_unprojectionInvalid = true;
		// notify the camera that the lens matrix is changing. this will mark the 
		// viewProjectionMatrix in the camera as invalid, and force the matrix to
		// be re-queried from the lens, and therefore rebuilt.
		dispatchEvent(new LensEvent(LensEvent.MATRIX_CHANGED, this));
	}

	/**
	 * Updates the matrix
	 */
	private function updateMatrix():Void
	{
		throw new AbstractMethodError();
	}

	public function updateScissorRect(x:Float, y:Float, width:Float, height:Float):Void
	{
		_scissorRect.x = x;
		_scissorRect.y = y;
		_scissorRect.width = width;
		_scissorRect.height = height;
		invalidateMatrix();
	}


	public function updateViewport(x:Float, y:Float, width:Float, height:Float):Void
	{
		_viewPort.x = x;
		_viewPort.y = y;
		_viewPort.width = width;
		_viewPort.height = height;
		invalidateMatrix();
	}
}
