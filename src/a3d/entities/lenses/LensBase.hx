package a3d.entities.lenses;

import a3d.errors.AbstractMethodError;
import a3d.events.LensEvent;
import a3d.math.FMatrix3D;
import flash.events.EventDispatcher;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.Vector;


/**
 * An abstract base class for all lens classes. 
 * Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
 */
class LensBase extends EventDispatcher
{
	/**
	 * Retrieves the corner points of the lens frustum.
	 */
	public var frustumCorners(get, set):Vector<Float>;
	/**
	 * The projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */
	public var matrix(get, set):Matrix3D;
	/**
	 * The distance to the near plane of the frustum. Anything behind near plane will not be rendered.
	 */
	public var near(get, set):Float;
	/**
	 * The distance to the far plane of the frustum. Anything beyond the far plane will not be rendered.
	 */
	public var far(get, set):Float;
	
	public var unprojectionMatrix(get, null):Matrix3D;
	/**
	 * The aspect ratio (width/height) of the view. Set by the renderer.
	 * @private
	 */
	public var aspectRatio(get, set):Float;
	
	private var _matrix:Matrix3D;
	private var _scissorRect:Rectangle;
	private var _viewPort:Rectangle;
	private var _near:Float = 20;
	private var _far:Float = 3000;
	private var _aspectRatio:Float = 1;

	private var _matrixInvalid:Bool = true;
	private var _frustumCorners:Vector<Float>;

	private var _unprojection:Matrix3D;
	private var _unprojectionInvalid:Bool = true;

	/**
	 * Creates a new LensBase object.
	 */
	public function new()
	{
		super();
		
		_matrix = new Matrix3D();
		_scissorRect = new Rectangle();
		_viewPort = new Rectangle();

		_frustumCorners = new Vector<Float>(8 * 3, true);
	}

	
	private function get_frustumCorners():Vector<Float>
	{
		return _frustumCorners;
	}

	private function set_frustumCorners(frustumCorners:Vector<Float>):Vector<Float>
	{
		return _frustumCorners = frustumCorners;
	}

	
	private function get_matrix():Matrix3D
	{
		if (_matrixInvalid)
		{
			updateMatrix();
			_matrixInvalid = false;
		}
		return _matrix;
	}

	private function set_matrix(value:Matrix3D):Matrix3D
	{
		_matrix = value;
		invalidateMatrix();
		return _matrix;
	}

	
	private function get_near():Float
	{
		return _near;
	}

	private function set_near(value:Float):Float
	{
		if (value == _near)
			return _near;
			
		_near = value;
		invalidateMatrix();
		return _near;
	}

	
	private function get_far():Float
	{
		return _far;
	}

	private function set_far(value:Float):Float
	{
		if (value == _far)
			return _far;
			
		_far = value;
		invalidateMatrix();
		return _far;
	}

	/**
	 * Calculates the normalised position in screen space of the given scene position relative to the camera.
	 *
	 * @param point3d the position vector of the scene coordinates to be projected.
	 * @param v The destination Vector3D object
	 * @return The normalised screen position of the given scene coordinates relative to the camera.
	 */
	public function project(point3d:Vector3D, v:Vector3D = null):Vector3D
	{
		if (v == null) 
			v = new Vector3D();
		FMatrix3D.transformVector(matrix, point3d, v);

		v.x = v.x / v.w;
		v.y = -v.y / v.w;

		//z is unaffected by transform
		v.z = point3d.z;

		return v;
	}

	
	private function get_unprojectionMatrix():Matrix3D
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
	 * @param v The destination Vector3D object
	 * @return The scene position relative to the camera of the given screen coordinates.
	 */
	public function unproject(nX:Float, nY:Float, sZ:Float, v:Vector3D = null):Vector3D
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

	
	private function get_aspectRatio():Float
	{
		return _aspectRatio;
	}

	private function set_aspectRatio(value:Float):Float
	{
		if (_aspectRatio == value || (value * 0) != 0)
			return _aspectRatio;
			
		_aspectRatio = value;
		invalidateMatrix();
		return _aspectRatio;
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
