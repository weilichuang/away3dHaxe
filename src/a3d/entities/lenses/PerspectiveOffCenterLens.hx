package a3d.entities.lenses;

import flash.geom.Vector3D;

import a3d.math.FMatrix3D;

/**
 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
 */
class PerspectiveOffCenterLens extends LensBase
{
	public var minAngleX(set, set):Float;
	public var maxAngleX(set, set):Float;
	public var minAngleY(set, set):Float;
	public var maxAngleY(set, set):Float;
	
	private var _minAngleX:Float;
	private var _minLengthX:Float;
	private var _tanMinX:Float;
	private var _maxAngleX:Float;
	private var _maxLengthX:Float;
	private var _tanMaxX:Float;
	private var _minAngleY:Float;
	private var _minLengthY:Float;
	private var _tanMinY:Float;
	private var _maxAngleY:Float;
	private var _maxLengthY:Float;
	private var _tanMaxY:Float;

	/**
	 * Creates a new PerspectiveLens object.
	 *
	 * @param fieldOfView The vertical field of view of the projection.
	 */
	public function new(minAngleX:Float = -40, maxAngleX:Float = 40, minAngleY:Float = -40, maxAngleY:Float = 40)
	{
		super();

		this.minAngleX = minAngleX;
		this.maxAngleX = maxAngleX;
		this.minAngleY = minAngleY;
		this.maxAngleY = maxAngleY;
	}

	
	private function get_minAngleX():Float
	{
		return _minAngleX;
	}

	private function set_minAngleX(value:Float):Float
	{
		_minAngleX = value;

		_tanMinX = Math.tan(_minAngleX * Math.PI / 180);

		invalidateMatrix();
		
		return _minAngleX;
	}

	
	private function get_maxAngleX():Float
	{
		return _maxAngleX;
	}

	private function set_maxAngleX(value:Float):Float
	{
		_maxAngleX = value;

		_tanMaxX = Math.tan(_maxAngleX * Math.PI / 180);

		invalidateMatrix();
		
		return _maxAngleX;
	}

	
	private function get_minAngleY():Float
	{
		return _minAngleY;
	}

	private function set_minAngleY(value:Float):Float
	{
		_minAngleY = value;

		_tanMinY = Math.tan(_minAngleY * Math.PI / 180);

		invalidateMatrix();
		
		return _minAngleY;
	}

	
	private function get_maxAngleY():Float
	{
		return _maxAngleY;
	}

	private function set_maxAngleY(value:Float):Float
	{
		_maxAngleY = value;

		_tanMaxY = Math.tan(_maxAngleY * Math.PI / 180);

		invalidateMatrix();
		
		return _maxAngleY;
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
	override public function unproject(nX:Float, nY:Float, sZ:Float, v:Vector3D = null):Vector3D
	{
		if (v == null) 
			v = new Vector3D();
		
		v.x = nX;
		v.y = -nY;
		v.z = sZ;
		v.w = 1;

		v.x *= sZ;
		v.y *= sZ;

		FMatrix3D.transformVector(unprojectionMatrix, v, v);

		//z is unaffected by transform
		v.z = sZ;

		return v;
	}

	override public function clone():LensBase
	{
		var clone:PerspectiveOffCenterLens = new PerspectiveOffCenterLens(_minAngleX, _maxAngleX, _minAngleY, _maxAngleY);
		clone._near = _near;
		clone._far = _far;
		clone._aspectRatio = _aspectRatio;
		return clone;
	}

	/**
	 * @inheritDoc
	 */
	override private function updateMatrix():Void
	{
		var raw:Vector<Float> = FMatrix3D.RAW_DATA_CONTAINER;

		_minLengthX = _near * _tanMinX;
		_maxLengthX = _near * _tanMaxX;
		_minLengthY = _near * _tanMinY;
		_maxLengthY = _near * _tanMaxY;

		var minLengthFracX:Float = -_minLengthX / (_maxLengthX - _minLengthX);
		var minLengthFracY:Float = -_minLengthY / (_maxLengthY - _minLengthY);
		//var _xMax:Float = - _minLengthX;
		//var _yMax:Float = - _minLengthY;

		var left:Float, right:Float, top:Float, bottom:Float;

		// assume scissored frustum
//			var xWidth:Float = _xMax * (_viewPort.width / _scissorRect.width);
//			var yHgt:Float = _yMax * (_viewPort.height / _scissorRect.height);
//			var center:Float = _xMax * (_scissorRect.x * 2 - _viewPort.width) / _scissorRect.width + _xMax;
//			var middle:Float = -_yMax * (_scissorRect.y * 2 - _viewPort.height) / _scissorRect.height - _yMax;
//			
//			left = center - xWidth;
//			right = center + xWidth;
//			top = middle - yHgt;
//			bottom = middle + yHgt;

		//var center:Float = _maxLengthX * (_scissorRect.x * 2 - _viewPort.width) / _scissorRect.width - _minLengthX;

		//var center:Float = _xMax * 2 * (_scissorRect.x * 2 + _scissorRect.width) / (2 * _scissorRect.width) - xWidth;


		var center:Float = -_minLengthX * (_scissorRect.x + _scissorRect.width * minLengthFracX) / (_scissorRect.width * minLengthFracX);
		var middle:Float = _minLengthY * (_scissorRect.y + _scissorRect.height * minLengthFracY) / (_scissorRect.height * minLengthFracY);

		left = center - (_maxLengthX - _minLengthX) * (_viewPort.width / _scissorRect.width);
		right = center;
		top = middle;
		bottom = middle + (_maxLengthY - _minLengthY) * (_viewPort.height / _scissorRect.height);

		raw[0] = 2 * _near / (right - left);
		raw[5] = 2 * _near / (bottom - top);
		raw[8] = (right + left) / (right - left);
		raw[9] = (bottom + top) / (bottom - top);
		raw[10] = (_far + _near) / (_far - _near);
		raw[11] = 1;
		raw[1] = raw[2] = raw[3] = raw[4] =
			raw[6] = raw[7] = raw[12] = raw[13] = raw[15] = 0;
		raw[14] = -2 * _far * _near / (_far - _near);


		_matrix.copyRawDataFrom(raw);

		//var yMaxFar : Number = _far*_focalLengthInv;
		//var xMaxFar : Number = yMaxFar*_aspectRatio;

		_minLengthX = _far * _tanMinX;
		_maxLengthX = _far * _tanMaxX;
		_minLengthY = _far * _tanMinY;
		_maxLengthY = _far * _tanMaxY;

		_frustumCorners[0] = _frustumCorners[9] = left;
		_frustumCorners[3] = _frustumCorners[6] = right;
		_frustumCorners[1] = _frustumCorners[4] = top;
		_frustumCorners[7] = _frustumCorners[10] = bottom;

		_frustumCorners[12] = _frustumCorners[21] = _minLengthX;
		_frustumCorners[15] = _frustumCorners[18] = _maxLengthX;
		_frustumCorners[13] = _frustumCorners[16] = _minLengthY;
		_frustumCorners[19] = _frustumCorners[22] = _maxLengthY;

		_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
		_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;

		_matrixInvalid = false;
	}
}
