package a3d.core.base;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;


import a3d.controllers.ControllerBase;
import a3d.events.Object3DEvent;
import a3d.io.library.assets.NamedAssetBase;
import a3d.math.FMath;
import a3d.math.Matrix3DUtils;

using a3d.math.FVector3D;


/**
 * Dispatched when the position of the 3d object changes.
 *
 * @eventType a3d.events.Object3DEvent
 */
@:meta(Event(name = "positionChanged", type = "a3d.events.Object3DEvent"))

/**
 * Dispatched when the scale of the 3d object changes.
 *
 * @eventType a3d.events.Object3DEvent
 */
@:meta(Event(name = "scaleChanged", type = "a3d.events.Object3DEvent"))

/**
 * Dispatched when the rotation of the 3d object changes.
 *
 * @eventType a3d.events.Object3DEvent
 */
@:meta(Event(name = "rotationChanged", type = "a3d.events.Object3DEvent"))


/**
 * Object3D provides a base class for any 3D object that has a (local) transformation.<br/><br/>
 *
 * Standard Transform:
 * <ul>
 *     <li> The standard order for transformation is [parent transform] * (Translate+Pivot) * (Rotate) * (-Pivot) * (Scale) * [child transform] </li>
 *     <li> This is the order of matrix multiplications, left-to-right. </li>
 *     <li> The order of transformation is right-to-left, however!
 *          (Scale) happens before (-Pivot) happens before (Rotate) happens before (Translate+Pivot)
 *          with no pivot, the above transform works out to [parent transform] * Translate * Rotate * Scale * [child transform]
 *          (Scale) happens before (Rotate) happens before (Translate) </li>
 *     <li> This is based on code in updateTransform and ObjectContainer3D.updateSceneTransform(). </li>
 *     <li> Matrix3D prepend = operator on rhs - e.g. transform' = transform * rhs; </li>
 *     <li> Matrix3D append =  operator on lhr - e.g. transform' = lhs * transform; </li>
 * </ul>
 *
 * To affect Scale:
 * <ul>
 *     <li> set scaleX/Y/Z directly, or call scale(delta) </li>
 * </ul>
 *
 * To affect Pivot:
 * <ul>
 *     <li> set pivotPoint directly, or call movePivot() </li>
 * </ul>
 *
 * To affect Rotate:
 * <ul>
 *    <li> set rotationX/Y/Z individually (using degrees), set eulers [all 3 angles] (using radians), or call rotateTo()</li>
 *    <li> call pitch()/yaw()/roll()/rotate() to add an additional rotation *before* the current transform.
 *         rotationX/Y/Z will be reset based on these operations. </li>
 * </ul>
 *
 * To affect Translate (post-rotate translate):
 *
 * <ul>
 *    <li> set x/y/z/position or call moveTo(). </li>
 *    <li> call translate(), which modifies x/y/z based on a delta vector. </li>
 *    <li> call moveForward()/moveBackward()/moveLeft()/moveRight()/moveUp()/moveDown()/translateLocal() to add an
 *         additional translate *before* the current transform. x/y/z will be reset based on these operations. </li>
 * </ul>
 */

class Object3D extends NamedAssetBase
{
	/**
	 * Defines the x coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var x(get, set):Float;
	/**
	 * Defines the y coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var y(get, set):Float;
	/**
	 * Defines the z coordinate of the 3d object relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var z(get, set):Float;
	
	/**
	 * Defines the euler angle of rotation of the 3d object around the x-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var rotationX(get, set):Float;
	/**
	 * Defines the euler angle of rotation of the 3d object around the y-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var rotationY(get, set):Float;
	/**
	 * Defines the euler angle of rotation of the 3d object around the z-axis, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var rotationZ(get, set):Float;
	
	/**
	 * Defines the scale of the 3d object along the x-axis, relative to local coordinates.
	 */
	public var scaleX(get, set):Float;
	/**
	 * Defines the scale of the 3d object along the y-axis, relative to local coordinates.
	 */
	public var scaleY(get, set):Float;
	/**
	 * Defines the scale of the 3d object along the z-axis, relative to local coordinates.
	 */
	public var scaleZ(get, set):Float;
	
	/**
	 * The transformation of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var transform(get, set):Matrix3D;
	/**
	 * Defines the rotation of the 3d object as a <code>Vector3D</code> object containing euler angles for rotation around x, y and z axis.
	 */
	public var eulers(get, set):Vector3D;
	
	/**
	 * Defines the local point around which the object rotates.
	 */
	public var pivotPoint(get, set):Vector3D;
	/**
	 * Defines the position of the 3d object, relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 */
	public var position(get, set):Vector3D;
	/**
	 *
	 */
	public var forwardVector(get, null):Vector3D;
	/**
	 *
	 */
	public var upVector(get, null):Vector3D;
	/**
	 *
	 */
	public var backVector(get, null):Vector3D;
	/**
	 *
	 */
	public var leftVector(get, null):Vector3D;
	/**
	 *
	 */
	public var downVector(get, null):Vector3D;
	
	/**
	 *
	 */
	public var rightVector(get, null):Vector3D;
	
	public var zOffset(get, set):Int;
	
	/** @private */
	public var controller:ControllerBase;
	
	/**
	 * An object that can contain any extra data.
	 */
	public var extra:Dynamic;

	private var _smallestNumber:Float = 0.0000000000000000000001;
	private var _transformDirty:Bool = true;

	private var _positionDirty:Bool;
	private var _rotationDirty:Bool;
	private var _scaleDirty:Bool;

	// TODO: not used
	// private var _positionValuesDirty:Bool;
	// private var _rotationValuesDirty:Bool;
	// private var _scaleValuesDirty:Bool;

	private var _positionChanged:Object3DEvent;
	private var _rotationChanged:Object3DEvent;
	private var _scaleChanged:Object3DEvent;

	private var _rotationX:Float = 0;
	private var _rotationY:Float = 0;
	private var _rotationZ:Float = 0;
	private var _eulers:Vector3D;

	private var _flipY:Matrix3D;
	private var _listenToPositionChanged:Bool;
	private var _listenToRotationChanged:Bool;
	private var _listenToScaleChanged:Bool;

	private var _zOffset:Int = 0;
	
	private var _transform:Matrix3D;
	private var _scaleX:Float = 1;
	private var _scaleY:Float = 1;
	private var _scaleZ:Float = 1;
	private var _x:Float = 0;
	private var _y:Float = 0;
	private var _z:Float = 0;
	private var _pivotPoint:Vector3D;
	private var _pivotZero:Bool = true;
	private var _pos:Vector3D;
	private var _rot:Vector3D;
	private var _sca:Vector3D;
	private var _transformComponents:Vector<Vector3D>;

	/**
	 * Creates an Object3D object.
	 */
	public function new()
	{
		super();
		
		_eulers = new Vector3D();
		_flipY = new Matrix3D();

		_transform = new Matrix3D();
		_pivotPoint = new Vector3D();
		_pos = new Vector3D();
		_rot = new Vector3D();
		_sca = new Vector3D();
	
		// Cached vector of transformation components used when
		// recomposing the transform matrix in updateTransform()
		_transformComponents = new Vector<Vector3D>(3, true);
		_transformComponents[0] = _pos;
		_transformComponents[1] = _rot;
		_transformComponents[2] = _sca;

		_transform.identity();

		_flipY.appendScale(1, -1, 1);
	}
	
	private function invalidatePivot():Void
	{
		_pivotZero = (_pivotPoint.x == 0) && (_pivotPoint.y == 0) && (_pivotPoint.z == 0);

		invalidateTransform();
	}

	private function invalidatePosition():Void
	{
		if (_positionDirty)
			return;

		_positionDirty = true;

		invalidateTransform();

		if (_listenToPositionChanged)
			notifyPositionChanged();
	}

	private function notifyPositionChanged():Void
	{
		if (_positionChanged == null)
			_positionChanged = new Object3DEvent(Object3DEvent.POSITION_CHANGED, this);

		dispatchEvent(_positionChanged);
	}

	override public function addEventListener(type:String, listener:Dynamic -> Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
	{
		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		switch (type)
		{
			case Object3DEvent.POSITION_CHANGED:
				_listenToPositionChanged = true;
				
			case Object3DEvent.ROTATION_CHANGED:
				_listenToRotationChanged = true;
				
			case Object3DEvent.SCALE_CHANGED:
				_listenToRotationChanged = true;
		}
	}


	override public function removeEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false):Void
	{
		super.removeEventListener(type, listener, useCapture);

		if (hasEventListener(type))
			return;

		switch (type)
		{
			case Object3DEvent.POSITION_CHANGED:
				_listenToPositionChanged = false;
				
			case Object3DEvent.ROTATION_CHANGED:
				_listenToRotationChanged = false;
				
			case Object3DEvent.SCALE_CHANGED:
				_listenToScaleChanged = false;
				
		}
	}

	private function invalidateRotation():Void
	{
		if (_rotationDirty)
			return;

		_rotationDirty = true;

		invalidateTransform();

		if (_listenToRotationChanged)
			notifyRotationChanged();
	}

	private function notifyRotationChanged():Void
	{
		if (_rotationChanged == null)
			_rotationChanged = new Object3DEvent(Object3DEvent.ROTATION_CHANGED, this);

		dispatchEvent(_rotationChanged);
	}

	private function invalidateScale():Void
	{
		if (_scaleDirty)
			return;

		_scaleDirty = true;

		invalidateTransform();

		if (_listenToScaleChanged)
			notifyScaleChanged();
	}

	private function notifyScaleChanged():Void
	{
		if (_scaleChanged == null)
			_scaleChanged = new Object3DEvent(Object3DEvent.SCALE_CHANGED, this);

		dispatchEvent(_scaleChanged);
	}

	
	private inline function get_x():Float
	{
		return _x;
	}

	private function set_x(val:Float):Float
	{
		if (_x == val)
			return _x;

		_x = val;

		invalidatePosition();
		
		return _x;
	}

	
	private inline function get_y():Float
	{
		return _y;
	}

	private function set_y(val:Float):Float
	{
		if (_y == val)
			return _y;

		_y = val;

		invalidatePosition();
		
		return _y;
	}

	private inline function get_z():Float
	{
		return _z;
	}

	private function set_z(val:Float):Float
	{
		if (_z == val)
			return _z;

		_z = val;

		invalidatePosition();
		
		return _z;
	}
	
	public function setXYZ(x:Float, y:Float, z:Float):Void
	{
		_x = x;
		_y = y;
		_z = z;
		invalidatePosition();
	}

	
	private function get_rotationX():Float
	{
		return _rotationX * FMath.RADIANS_TO_DEGREES();
	}

	private function set_rotationX(val:Float):Float
	{
		if (rotationX == val)
			return rotationX;

		_rotationX = val * FMath.DEGREES_TO_RADIANS();

		invalidateRotation();
		
		return rotationX;
	}

	
	private function get_rotationY():Float
	{
		return _rotationY * FMath.RADIANS_TO_DEGREES();
	}

	private function set_rotationY(val:Float):Float
	{
		if (rotationY == val)
			return rotationY;

		_rotationY = val * FMath.DEGREES_TO_RADIANS();

		invalidateRotation();
		
		return rotationY;
	}

	
	private function get_rotationZ():Float
	{
		return _rotationZ * FMath.RADIANS_TO_DEGREES();
	}

	private function set_rotationZ(val:Float):Float
	{
		if (rotationZ == val)
			return rotationZ;

		_rotationZ = val * FMath.DEGREES_TO_RADIANS();

		invalidateRotation();
		
		return rotationZ;
	}
	
	public function setRotationXYZ(rx:Float, ry:Float, rz:Float):Void
	{
		_rotationX = rx * FMath.DEGREES_TO_RADIANS();
		_rotationY = ry * FMath.DEGREES_TO_RADIANS();
		_rotationZ = rz * FMath.DEGREES_TO_RADIANS();
		invalidateRotation();
	}

	
	private inline function get_scaleX():Float
	{
		return _scaleX;
	}

	private function set_scaleX(val:Float):Float
	{
		if (_scaleX == val)
			return _scaleX;

		_scaleX = val;

		invalidateScale();
		
		return _scaleX;
	}

	
	private inline function get_scaleY():Float
	{
		return _scaleY;
	}

	private function set_scaleY(val:Float):Float
	{
		if (_scaleY == val)
			return _scaleY;

		_scaleY = val;

		invalidateScale();
		
		return _scaleY;
	}

	
	private inline function get_scaleZ():Float
	{
		return _scaleZ;
	}

	private function set_scaleZ(val:Float):Float
	{
		if (_scaleZ == val)
			return _scaleZ;

		_scaleZ = val;

		invalidateScale();
		
		return _scaleZ;
	}

	public function setScaleXYZ(sx:Float, sy:Float, sz:Float):Void
	{
		_scaleX = sx;
		_scaleY = sy;
		_scaleZ = sz;
		invalidateScale();
	}
	
	private function get_eulers():Vector3D
	{
		_eulers.x = _rotationX * FMath.RADIANS_TO_DEGREES();
		_eulers.y = _rotationY * FMath.RADIANS_TO_DEGREES();
		_eulers.z = _rotationZ * FMath.RADIANS_TO_DEGREES();

		return _eulers;
	}

	private function set_eulers(value:Vector3D):Vector3D
	{
		_rotationX = value.x * FMath.DEGREES_TO_RADIANS();
		_rotationY = value.y * FMath.DEGREES_TO_RADIANS();
		_rotationZ = value.z * FMath.DEGREES_TO_RADIANS();

		invalidateRotation();
		
		return _eulers;
	}

	
	private function get_transform():Matrix3D
	{
		if (_transformDirty)
			updateTransform();

		return _transform;
	}

	private function set_transform(val:Matrix3D):Matrix3D
	{
		//ridiculous matrix error
		if (val.rawData[0] == 0)
		{
			var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			val.copyRawDataTo(raw);
			raw[0] = _smallestNumber;
			val.copyRawDataFrom(raw);
		}

		var elements:Vector<Vector3D> = val.decompose();
		var vec:Vector3D;

		vec = elements[0];
		if (_x != vec.x || _y != vec.y || _z != vec.z)
		{
			setXYZ(vec.x, vec.y, vec.z);
		}

		vec = elements[1];
		if (_rotationX != vec.x || _rotationY != vec.y || _rotationZ != vec.z)
		{
			setRotationXYZ(vec.x, vec.y, vec.z);
		}

		vec = elements[2];
		if (_scaleX != vec.x || _scaleY != vec.y || _scaleZ != vec.z)
		{
			setScaleXYZ(vec.x, vec.y, vec.z);
		}
		
		return _transform;
	}

	
	private inline function get_pivotPoint():Vector3D
	{
		return _pivotPoint;
	}

	private function set_pivotPoint(pivot:Vector3D):Vector3D
	{
		_pivotPoint = pivot.clone();

		invalidatePivot();
		
		return _pivotPoint;
	}

	private function get_position():Vector3D
	{
		transform.copyColumnTo(3, _pos);

		return _pos.clone();
	}

	private function set_position(value:Vector3D):Vector3D
	{
		_x = value.x;
		_y = value.y;
		_z = value.z;

		invalidatePosition();
		
		return value;
	}

	
	private function get_forwardVector():Vector3D
	{
		return Matrix3DUtils.getForward(transform);
	}

	
	private function get_rightVector():Vector3D
	{
		return Matrix3DUtils.getRight(transform);
	}

	
	private function get_upVector():Vector3D
	{
		return Matrix3DUtils.getUp(transform);
	}

	
	private function get_backVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getForward(transform);
		director.negate();

		return director;
	}

	
	private function get_leftVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getRight(transform);
		director.negate();

		return director;
	}

	
	private function get_downVector():Vector3D
	{
		var director:Vector3D = Matrix3DUtils.getUp(transform);
		director.negate();

		return director;
	}

	/**
	 * Appends a uniform scale to the current transformation.
	 * @param value The amount by which to scale.
	 */
	public function scale(value:Float):Void
	{
		_scaleX *= value;
		_scaleY *= value;
		_scaleZ *= value;

		invalidateScale();
	}

	/**
	 * Moves the 3d object forwards along it's local z axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveForward(distance:Float):Void
	{
		translateLocal(Vector3D.Z_AXIS, distance);
	}

	/**
	 * Moves the 3d object backwards along it's local z axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveBackward(distance:Float):Void
	{
		translateLocal(Vector3D.Z_AXIS, -distance);
	}

	/**
	 * Moves the 3d object backwards along it's local x axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveLeft(distance:Float):Void
	{
		translateLocal(Vector3D.X_AXIS, -distance);
	}

	/**
	 * Moves the 3d object forwards along it's local x axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveRight(distance:Float):Void
	{
		translateLocal(Vector3D.X_AXIS, distance);
	}

	/**
	 * Moves the 3d object forwards along it's local y axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveUp(distance:Float):Void
	{
		translateLocal(Vector3D.Y_AXIS, distance);
	}

	/**
	 * Moves the 3d object backwards along it's local y axis
	 *
	 * @param	distance	The length of the movement
	 */
	public function moveDown(distance:Float):Void
	{
		translateLocal(Vector3D.Y_AXIS, -distance);
	}

	/**
	 * Moves the 3d object directly to a point in space
	 *
	 * @param	dx		The amount of movement along the local x axis.
	 * @param	dy		The amount of movement along the local y axis.
	 * @param	dz		The amount of movement along the local z axis.
	 */
	public function moveTo(dx:Float, dy:Float, dz:Float):Void
	{
		if (_x == dx && _y == dy && _z == dz)
			return;
			
		setXYZ(dx, dy, dz);
	}

	/**
	 * Moves the local point around which the object rotates.
	 *
	 * @param	dx		The amount of movement along the local x axis.
	 * @param	dy		The amount of movement along the local y axis.
	 * @param	dz		The amount of movement along the local z axis.
	 */
	public function movePivot(dx:Float, dy:Float, dz:Float):Void
	{
		if (_pivotPoint == null)
			_pivotPoint = new Vector3D();
		_pivotPoint.x += dx;
		_pivotPoint.y += dy;
		_pivotPoint.z += dz;

		invalidatePivot();
	}

	/**
	 * Moves the 3d object along a vector by a defined length
	 *
	 * @param	axis		The vector defining the axis of movement
	 * @param	distance	The length of the movement
	 */
	public function translate(axis:Vector3D, distance:Float):Void
	{
		var x:Float = axis.x, y:Float = axis.y, z:Float = axis.z;
		var len:Float = distance / Math.sqrt(x * x + y * y + z * z);

		_x += x * len;
		_y += y * len;
		_z += z * len;

		invalidatePosition();
	}

	/**
	 * Moves the 3d object along a vector by a defined length
	 *
	 * @param	axis		The vector defining the axis of movement
	 * @param	distance	The length of the movement
	 */
	public function translateLocal(axis:Vector3D, distance:Float):Void
	{
		var x:Float = axis.x, y:Float = axis.y, z:Float = axis.z;
		var len:Float = distance / Math.sqrt(x * x + y * y + z * z);

		transform.prependTranslation(x * len, y * len, z * len);

		_transform.copyColumnTo(3, _pos);

		_x = _pos.x;
		_y = _pos.y;
		_z = _pos.z;

		invalidatePosition();
	}

	/**
	 * Rotates the 3d object around it's local x-axis
	 *
	 * @param	angle		The amount of rotation in degrees
	 */
	public function pitch(angle:Float):Void
	{
		rotate(Vector3D.X_AXIS, angle);
	}

	/**
	 * Rotates the 3d object around it's local y-axis
	 *
	 * @param	angle		The amount of rotation in degrees
	 */
	public function yaw(angle:Float):Void
	{
		rotate(Vector3D.Y_AXIS, angle);
	}

	/**
	 * Rotates the 3d object around it's local z-axis
	 *
	 * @param	angle		The amount of rotation in degrees
	 */
	public function roll(angle:Float):Void
	{
		rotate(Vector3D.Z_AXIS, angle);
	}

	public function clone():Object3D
	{
		var clone:Object3D = new Object3D();
		clone.pivotPoint = pivotPoint;
		clone.transform = transform;
		clone.name = name;
		// todo: implement for all subtypes
		return clone;
	}

	/**
	 * Rotates the 3d object directly to a euler angle
	 *
	 * @param	ax		The angle in degrees of the rotation around the x axis.
	 * @param	ay		The angle in degrees of the rotation around the y axis.
	 * @param	az		The angle in degrees of the rotation around the z axis.
	 */
	public function rotateTo(ax:Float, ay:Float, az:Float):Void
	{
		_rotationX = ax * FMath.DEGREES_TO_RADIANS();
		_rotationY = ay * FMath.DEGREES_TO_RADIANS();
		_rotationZ = az * FMath.DEGREES_TO_RADIANS();

		invalidateRotation();
	}

	/**
	 * Rotates the 3d object around an axis by a defined angle
	 *
	 * @param	axis		The vector defining the axis of rotation
	 * @param	angle		The amount of rotation in degrees
	 */
	public function rotate(axis:Vector3D, angle:Float):Void
	{
		transform.prependRotation(angle, axis);

		transform = transform;
	}

	/**
	 * Rotates the 3d object around to face a point defined relative to the local coordinates of the parent <code>ObjectContainer3D</code>.
	 *
	 * @param	target		The vector defining the point to be looked at
	 * @param	upAxis		An optional vector used to define the desired up orientation of the 3d object after rotation has occurred
	 */
	public function lookAt(target:Vector3D, upAxis:Vector3D = null):Void
	{
		var yAxis:Vector3D, zAxis:Vector3D, xAxis:Vector3D;
		var raw:Vector<Float>;

		if (upAxis == null)
			upAxis = Vector3D.Y_AXIS;

		zAxis = target.subtract(position);
		zAxis.normalize();

		xAxis = upAxis.crossProduct(zAxis);
		xAxis.normalize();

		if (xAxis.length < .05)
		{
			xAxis = upAxis.crossProduct(Vector3D.Z_AXIS);
		}

		yAxis = zAxis.crossProduct(xAxis);

		raw = Matrix3DUtils.RAW_DATA_CONTAINER;

		raw[0] = _scaleX * xAxis.x;
		raw[1] = _scaleX * xAxis.y;
		raw[2] = _scaleX * xAxis.z;
		raw[3] = 0;

		raw[4] = _scaleY * yAxis.x;
		raw[5] = _scaleY * yAxis.y;
		raw[6] = _scaleY * yAxis.z;
		raw[7] = 0;

		raw[8] = _scaleZ * zAxis.x;
		raw[9] = _scaleZ * zAxis.y;
		raw[10] = _scaleZ * zAxis.z;
		raw[11] = 0;

		raw[12] = _x;
		raw[13] = _y;
		raw[14] = _z;
		raw[15] = 1;

		_transform.copyRawDataFrom(raw);

		this.transform = transform;

		if (zAxis.z < 0)
		{
			rotationY = (180 - rotationY);
			rotationX -= 180;
			rotationZ -= 180;
		}
	}

	/**
	 * Cleans up any resources used by the current object.
	 */
	public function dispose():Void
	{
	}


	/**
	 * @inheritDoc
	 */
	public function disposeAsset():Void
	{
		dispose();
	}

	/**
	 * Invalidates the transformation matrix, causing it to be updated upon the next request
	 */
	public function invalidateTransform():Void
	{
		_transformDirty = true;
	}

	private function updateTransform():Void
	{
		_pos.fastSetTo(_x, _y, _z);
		_rot.fastSetTo(_rotationX, _rotationY, _rotationZ);
		_sca.fastSetTo(_scaleX, _scaleY, _scaleZ);

		_transform.recompose(_transformComponents);

		if (!_pivotZero)
		{
			_transform.prependTranslation(-_pivotPoint.x, -_pivotPoint.y, -_pivotPoint.z);
			_transform.appendTranslation(_pivotPoint.x, _pivotPoint.y, _pivotPoint.z);
		}

		_transformDirty = false;
		_positionDirty = false;
		_rotationDirty = false;
		_scaleDirty = false;
	}

	
	private inline function get_zOffset():Int
	{
		return _zOffset;
	}

	private inline function set_zOffset(value:Int):Int
	{
		return _zOffset = value;
	}
}
