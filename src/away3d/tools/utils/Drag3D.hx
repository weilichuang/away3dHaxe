package away3d.tools.utils;


import flash.errors.Error;
import flash.geom.Vector3D;
import flash.Vector.Vector;

import away3d.entities.lenses.PerspectiveLens;
import away3d.entities.Mesh;
import away3d.entities.ObjectContainer3D;
import away3d.entities.View3D;
import away3d.materials.ColorMaterial;
import away3d.entities.primitives.PlaneGeometry;

using away3d.math.FVector3D;
/**
* Class Drag3D allows free dragging of an ObjectContainer3D onto a given plane.
*
* locks on world planes
* locks on ObjectContainer3D planes
* locks on ObjectContainer3D rotations planes
*/

class Drag3D
{
	public static inline var PLANE_XZ:String = "xz";
	public static inline var PLANE_XY:String = "xy";
	public static inline var PLANE_ZY:String = "zy";
	
	public var object3d(get,set):ObjectContainer3D;
	/**
	* Defines if the target object3d plane will be aligned to object rotations or not
	*
	* @param	b		Bool. Defines if the target object3d planes will be aligned to object rotations or not. Default is false.
	*/
	public var useRotations(get,set):Bool;
	/**
	* Defines an offset for the drag from center mesh to mouse position.
	* object3d must have been set previously for this setter. if not an error is triggered
	* Since the offset is set from center to mouse projection, its usually a good practice to set it during firt mouse down
	* prior to drag.
	*/
	public var offsetCenter(get,set):Bool;
	/**
	* getIntersect method returns the 3d point in space (Vector3D) where mouse hits the given plane.
	*@return Vector3D the difference mouse mouse hit to object center
	*/
	public var offsetMouseCenter(get,null):Vector3D;
	/**
	* Displays the planes for debug/visual aid purposes
	*
	* @param	b				Bool. Display the planes of the dragged object3d. Default is false;
	*/
	public var debug(get,set):Bool;
	/**
	* Changes the plane the object will be considered on.
	* If class debug is set to true. It display the selected plane for debug/visual aid purposes with a brighter color.
	* @param	planeid				String. Plane to drag the object3d on.
	* Possible strings are Drag3D.PLANE_XZ ("xz"), Drag3D.PLANE_XY ("xy") or Drag3D.PLANE_ZY ("zy"). Default is Drag3D.PLANE_XZ;
	*/
	public var plane(null, set):String;
	
	/**
	* Defines planes as the position of a given ObjectContainer3D
	*
	* @param	object3d		ObjectContainer3D. The object3d that will be used to define the planes
	*/
	public var planeObject3d(null,set):ObjectContainer3D;
	/**
	* Defines planes position by a postion Vector3D
	*
	* @param	pos		Vector3D. The Vector3D that will be used to define the planes position
	*/
	public var planePosition(null,set):Vector3D;

	private var EPS:Float = 0.000001;

	private var _view:View3D;
	private var _debug:Bool;
	private var _object3d:ObjectContainer3D;
	private var _planeXZ:Mesh;
	private var _planeXY:Mesh;
	private var _planeZY:Mesh;
	private var _red:ColorMaterial;
	private var _green:ColorMaterial;
	private var _blue:ColorMaterial;
	private var _planesContainer:ObjectContainer3D;

	private var _np:Vector3D;
	private var _intersect:Vector3D;
	private var _rotations:Vector3D;
	private var _baserotations:Vector3D;
	private var _offsetCenter:Vector3D;
	private var _bSetOffset:Bool;

	private var _a:Float = 0;
	private var _b:Float = 0;
	private var _c:Float = 0;
	private var _d:Float = 1;

	private var _planeid:String;
	private var _useRotations:Bool;

	/**
	 * Class Drag3D allows to drag 3d objects with the mouse.<code>Drag3D</code>
	* @param	view			View3D. The view3d where the object to drag is or will be addChilded.
	* @param	object3d	[optional] ObjectContainer3D. The object3D to drag.
	* @param	plane			[optional] String. The plane to drag on.
	*/
	public function new(view:View3D, object3d:ObjectContainer3D = null, plane:String = PLANE_XZ)
	{
		 _np = new Vector3D(0.0, 0.0, 0.0);
		_intersect = new Vector3D(0.0, 0.0, 0.0);
		_offsetCenter = new Vector3D(0.0, 0.0, 0.0);
		_view = view;
		_object3d = object3d;
		_planeid = plane;
		updateNormalPlanes();
		init();
	}

	
	private function get_object3d():ObjectContainer3D
	{
		return _object3d;
	}

	
	private function set_useRotations(b:Bool):Bool
	{
		_useRotations = b;

		if (!b && _rotations != null)
			_baserotations = null;
		_rotations = null;

		if (_planesContainer != null)
			updateDebug();
			
		return b;
	}

	private function get_useRotations():Bool
	{
		return _useRotations;
	}

	
	private function set_offsetCenter(b:Bool):Bool
	{
		if (b && _object3d == null)
			throw new Error("offsetCenter requires that an object3d as been assigned to the Drag3D class first!");

		if (b)
		{
			_offsetCenter.fastCopyFrom(_object3d.scenePosition);
			if (_offsetCenter.x == 0 && _offsetCenter.y == 0 && _offsetCenter.z == 0)
			{
				_offsetCenter.fastSetTo(EPS, EPS, EPS);
			}
		}
		else
		{
			_offsetCenter.fastSetTo(EPS, EPS, EPS);
		}
		return _bSetOffset = b;
	}

	private function get_offsetCenter():Bool
	{
		return _bSetOffset;
	}

	
	private function get_offsetMouseCenter():Vector3D
	{
		return _offsetCenter;
	}

	
	private function set_debug(b:Bool):Bool
	{
		_debug = b;
		if (_debug && _planesContainer == null)
		{

			var size:Float = 1000;
			_red = new ColorMaterial(0xFF0000);
			_red.bothSides = true;
			_green = new ColorMaterial(0x00FF00);
			_green.bothSides = true;
			_blue = new ColorMaterial(0x0000FF);
			_blue.bothSides = true;
			_red.alpha = _green.alpha = _blue.alpha = .5;

			_planeXZ = new Mesh(new PlaneGeometry(size, size, 2, 2, true), _red);
			_planeXY = new Mesh(new PlaneGeometry(size, size, 2, 2, false), _green);
			_planeZY = new Mesh(new PlaneGeometry(size, size, 2, 2, false), _blue);

			_planeZY.rotationY = 90;
			_planesContainer = new ObjectContainer3D();
			_planesContainer.addChild(_planeXZ);
			_planesContainer.addChild(_planeXY);
			_planesContainer.addChild(_planeZY);

			_view.scene.addChild(_planesContainer);

			toggleDebug();
			updateDebug();

		}
		else
		{
			if (_planesContainer != null)
			{
				_planesContainer.removeChild(_planeXZ);
				_planesContainer.removeChild(_planeXY);
				_planesContainer.removeChild(_planeZY);
				_view.scene.removeChild(_planesContainer);
				_planesContainer = null;
				_planeXZ = _planeXY = _planeZY = null;
				_red = _green = _blue = null;
			}

		}
		
		return _debug;
	}

	private function get_debug():Bool
	{
		return _debug;
	}

	
	private function set_plane(planeid:String):String
	{
		_planeid = planeid.toLowerCase();

		if (_planeid != PLANE_XZ && _planeid != PLANE_XY && _planeid != PLANE_ZY)
			throw new Error("Unvalid plane description, use: Drag3D.PLANE_XZ, Drag3D.PLANE_XY, or Drag3D.PLANE_ZY");

		planeObject3d = null;
		updateNormalPlanes();

		toggleDebug();
		
		return _planeid;
	}

	/**
	* Returns the Vector3D where mouse to scene ray hits the plane set for the class.
	*
	*	@return Vector3D 	The intersection Vector3D
	*  If both x and y params are NaN, the class will return the hit from mouse coordinates
	*	@param	 x		[optional] Number. x coordinate.
	*	@param	 y		[optional] Number. y coordinate.
	*/
	public function getIntersect(x:Float = null, y:Float = null):Vector3D
	{
		intersect(x, y);

		return _intersect;
	}

	/**
	* if an ObjectContainer3D is set this handler will calculate the mouse intersection on given plane and will update position
	* and rotations of the ObjectContainer3D set accordingly
	*/
	public function updateDrag():Void
	{
		var localIntersect:Vector3D;

		if (_object3d == null)
			throw new Error("Drag3D error: no ObjectContainer3D or world planes specified");

		if (_debug)
			updateDebug();

		intersect();

		// TODO: Optimize this? Matrix3D.transformVector() creates a new vector - unnuecessary.
		localIntersect = _object3d.parent.inverseSceneTransform.transformVector(_intersect);

		if (_offsetCenter == null)
		{
			_object3d.setXYZ(localIntersect.x, localIntersect.y, localIntersect.z);
		}
		else
		{
			_object3d.setXYZ(localIntersect.x + _offsetCenter.x, 
							localIntersect.y + _offsetCenter.y, 
							localIntersect.z + _offsetCenter.z);
		}
	}

	/**
	* Sets the target ObjectContainer3D to the class. The ObjectContainer3D that will be dragged
	*
	* @param	object3d		ObjectContainer3D. The ObjectContainer3D that will be dragged. Default is null. When null planes will be considered at 0,0,0 world
	*/
	private function set_object3d(object3d:ObjectContainer3D):ObjectContainer3D
	{
		_object3d = object3d;
		if (_debug)
			updateDebug();
			
		return _object3d;
	}

	
	private function set_planeObject3d(object3d:ObjectContainer3D):ObjectContainer3D
	{
		updateNormalPlanes(object3d);

		if (_debug)
			updateDebug();
			
		return object3d;
	}

	
	private function set_planePosition(pos:Vector3D):Vector3D
	{
		switch (_planeid)
		{
			//XZ
			case PLANE_XZ:
				_np.fastSetTo(0, 1, 0);
			//XY
			case PLANE_XY:
				_np.fastSetTo(0, 0, 1);
			//ZY
			case PLANE_ZY:
				_np.fastSetTo(1, 0, 0);
		}

		_a = -pos.x;
		_b = -pos.y;
		_c = -pos.z;

		_d = -(_a * _np.x + _b * _np.y + _c * _np.z);

		if (_debug)
			updateDebug();
			
		return pos;
	}

	private function init():Void
	{
		if (!Std.is(_view.camera.lens,PerspectiveLens))
			_view.camera.lens = new PerspectiveLens();
	}

	private function updateDebug():Void
	{
		if (_a == 0 && _b == 0 && _c == 0)
		{
			_planesContainer.x = _planesContainer.y = _planesContainer.z = 0;
			_planesContainer.rotationX = _planesContainer.rotationY = _planesContainer.rotationZ = 0;

		}
		else
		{
			_planesContainer.setXYZ( -_a, -_b, -_c);

			if (_useRotations && _rotations != null)
			{
				_planesContainer.setRotationXYZ(_rotations.x, _rotations.y, _rotations.z);
			}
		}
	}

	private function toggleDebug():Void
	{

		if (_planeXZ != null)
		{
			var lowA:Float = .05;
			var highA:Float = .4;
			switch (_planeid)
			{
				case "zx":
					_planeid = PLANE_XZ;
				case PLANE_XZ:
					_red.alpha = highA;
					_green.alpha = _blue.alpha = lowA;
				
				case "yx":
					_planeid = PLANE_XY;
				case PLANE_XY:
					_red.alpha = _blue.alpha = lowA;
					_green.alpha = highA;
				
				case "yz":
					_planeid = PLANE_ZY;
				case PLANE_ZY:
					_red.alpha = _green.alpha = lowA;
					_blue.alpha = highA;
				default:
					throw new Error("Unvalid plane description, use: Drag3D.PLANE_XZ, Drag3D.PLANE_XY, or Drag3D.PLANE_ZY");
			}
		}
	}

	private function intersect(x:Float = null, y:Float = null):Void
	{
		var pMouse:Vector3D = (Math.isNaN(x) && Math.isNaN(y)) ? _view.unproject(_view.mouseX, _view.mouseY, 1) : _view.unproject(x, y, 1);

		var cam:Vector3D = _view.camera.position;
		var d0:Float = _np.x * cam.x + _np.y * cam.y + _np.z * cam.z - _d;
		var d1:Float = _np.x * pMouse.x + _np.y * pMouse.y + _np.z * pMouse.z - _d;
		var m:Float = d1 / (d1 - d0);

		_intersect.x = pMouse.x + (cam.x - pMouse.x) * m;
		_intersect.y = pMouse.y + (cam.y - pMouse.y) * m;
		_intersect.z = pMouse.z + (cam.z - pMouse.z) * m;

		if (_bSetOffset)
		{
			_bSetOffset = false;
			_offsetCenter.fastDecrementBy(_intersect);
		}
	}

	private function updateNormalPlanes(obj:ObjectContainer3D = null):Void
	{
		var world:Bool = (obj == null) ? true : false;

		if (_useRotations && !world)
		{
			var rawData:Vector<Float> = obj.transform.rawData;
			switch (_planeid)
			{
				case PLANE_XZ:
					_np.fastSetTo(rawData[4], rawData[5], rawData[6]);

				case PLANE_XY:
					_np.fastSetTo(rawData[8], rawData[9], rawData[10]);
				case PLANE_ZY:
					_np.fastSetTo(rawData[0], rawData[1], rawData[2]);
			}

			if (_rotations == null)
			{
				_rotations = new Vector3D();
				_baserotations = new Vector3D();
			}
			
			_rotations.fastSetTo(obj.rotationX, obj.rotationY, obj.rotationZ);
			_baserotations.fastSetTo(obj.rotationX, obj.rotationY, obj.rotationZ);

			_np.normalize();

		}
		else
		{

			if (_rotations != null && _baserotations != null)
			{
				_baserotations.fastSetTo(0, 0, 0);
				_rotations.fastSetTo(0, 0, 0);
			}

			switch (_planeid)
			{

				case PLANE_XZ:
					_np.fastSetTo(0, 1, 0);

				case PLANE_XY:
					_np.fastSetTo(0, 0, 1);
					
				case PLANE_ZY:
					_np.fastSetTo(1, 0, 0);
			}
		}

		_a = (world) ? 0 : -obj.scenePosition.x;
		_b = (world) ? 0 : -obj.scenePosition.y;
		_c = (world) ? 0 : -obj.scenePosition.z;

		_d = -(_a * _np.x + _b * _np.y + _c * _np.z);
	}

}
