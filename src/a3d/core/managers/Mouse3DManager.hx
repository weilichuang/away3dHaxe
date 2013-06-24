package a3d.core.managers;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.geom.Vector3D;
import flash.utils.Dictionary;


import a3d.core.pick.IPicker;
import a3d.core.pick.PickingCollisionVO;
import a3d.core.pick.PickingType;
import a3d.entities.ObjectContainer3D;
import a3d.entities.View3D;
import a3d.events.MouseEvent3D;



/**
 * Mouse3DManager enforces a singleton pattern and is not intended to be instanced.
 * it provides a manager class for detecting 3D mouse hits on View3D objects and sending out 3D mouse events.
 */
class Mouse3DManager
{
	private static var _view3Ds:Dictionary;
	private static var _view3DLookup:Vector<View3D>;
	private static var _viewCount:Int = 0;

	private var _activeView:View3D;
	private var _updateDirty:Bool = true;
	private var _nullVector:Vector3D = new Vector3D();
	private static var _collidingObject:PickingCollisionVO;
	private static var _previousCollidingObject:PickingCollisionVO;
	private static var _collidingViewObjects:Vector<PickingCollisionVO>;
	private static var _queuedEvents:Vector<MouseEvent3D> = new Vector<MouseEvent3D>();

	private var _mouseMoveEvent:MouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);

	private static var _mouseUp:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_UP);
	private static var _mouseClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.CLICK);
	private static var _mouseOut:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OUT);
	private static var _mouseDown:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_DOWN);
	private static var _mouseMove:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
	private static var _mouseOver:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_OVER);
	private static var _mouseWheel:MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_WHEEL);
	private static var _mouseDoubleClick:MouseEvent3D = new MouseEvent3D(MouseEvent3D.DOUBLE_CLICK);
	private var _forceMouseMove:Bool;
	private var _mousePicker:IPicker = PickingType.RAYCAST_FIRST_ENCOUNTERED;
	private var _childDepth:Int = 0;
	private static var _previousCollidingView:Int = -1;
	private static var _collidingView:Int = -1;
	private var _collidingDownObject:PickingCollisionVO;
	private var _collidingUpObject:PickingCollisionVO;

	/**
	 * Creates a new <code>Mouse3DManager</code> object.
	 */
	public function new()
	{
		if (_view3Ds == null)
		{
			_view3Ds = new Dictionary();
			_view3DLookup = new Vector<View3D>();
		}
	}

	// ---------------------------------------------------------------------
	// Interface.
	// ---------------------------------------------------------------------

	public function updateCollider(view:View3D):Void
	{
		_previousCollidingView = _collidingView;

		if (view)
		{
			// Clear the current colliding objects for multiple views if backBuffer just cleared
			if (view.stage3DProxy.bufferClear)
			{
				_collidingViewObjects = new Vector<PickingCollisionVO>(_viewCount);
			}

			if (view.shareContext == null)
			{
				if (view == _activeView && (_forceMouseMove || _updateDirty))
				{ // If forceMouseMove is off, and no 2D mouse events dirtied the update, don't update either.
					_collidingObject = _mousePicker.getViewCollision(view.mouseX, view.mouseY, view);
				}
			}
			else
			{
				if (view.getBounds(view.parent).contains(view.mouseX + view.x, view.mouseY + view.y))
				{
					if (_collidingViewObjects == null)
						_collidingViewObjects = new Vector<PickingCollisionVO>(_viewCount);
					_collidingObject = _collidingViewObjects[_view3Ds[view]] = _mousePicker.getViewCollision(view.mouseX, view.mouseY, view);
				}
			}
		}
	}

	public function fireMouseEvents():Void
	{
		var i:UInt;
		var len:UInt;
		var event:MouseEvent3D;
		var dispatcher:ObjectContainer3D;

		// If multiple view are used, determine the best hit based on the depth intersection.
		if (_collidingViewObjects)
		{
			_collidingObject = null;
			// Get the top-most view colliding object
			var distance:Float = Infinity;
			var view:View3D;
			for (var v:Int = _viewCount - 1; v >= 0; v--)
			{
				view = _view3DLookup[v];
				if (_collidingViewObjects[v] && (view.layeredView || _collidingViewObjects[v].rayEntryDistance < distance))
				{
					distance = _collidingViewObjects[v].rayEntryDistance;
					_collidingObject = _collidingViewObjects[v];
					if (view.layeredView)
						break;
				}
			}
		}

		// If colliding object has changed, queue over/out events.
		if (_collidingObject != _previousCollidingObject)
		{
			if (_previousCollidingObject)
				queueDispatch(_mouseOut, _mouseMoveEvent, _previousCollidingObject);
			if (_collidingObject)
				queueDispatch(_mouseOver, _mouseMoveEvent, _collidingObject);
		}

		// Fire mouse move events here if forceMouseMove is on.
		if (_forceMouseMove && _collidingObject)
		{
			queueDispatch(_mouseMove, _mouseMoveEvent, _collidingObject);
		}

		// Dispatch all queued events.
		len = _queuedEvents.length;
		for (i = 0; i < len; ++i)
		{
			// Only dispatch from first implicitly enabled object ( one that is not a child of a mouseChildren = false hierarchy ).
			event = _queuedEvents[i];
			dispatcher = event.object;

			while (dispatcher && !dispatcher.ancestorsAllowMouseEnabled)
				dispatcher = dispatcher.parent;

			if (dispatcher)
				dispatcher.dispatchEvent(event);
		}
		_queuedEvents.length = 0;

		_updateDirty = false;
		_previousCollidingObject = _collidingObject;
	}

	public function addViewLayer(view:View3D):Void
	{
		var stg:Stage = view.stage;

		// Add instance to mouse3dmanager to fire mouse events for multiple views
		if (view.stage3DProxy.mouse3DManager == null)
			view.stage3DProxy.mouse3DManager = this;

		if (!hasKey(view))
		{
			_view3Ds[view] = 0;
		}

		_childDepth = 0;
		traverseDisplayObjects(stg);
		_viewCount = _childDepth;
	}

	public function enableMouseListeners(view:View3D):Void
	{
		view.addEventListener(MouseEvent.CLICK, onClick);
		view.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		view.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		view.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public function disableMouseListeners(view:View3D):Void
	{
		view.removeEventListener(MouseEvent.CLICK, onClick);
		view.removeEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
		view.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		view.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		view.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
	}

	public function dispose():Void
	{
		_mousePicker.dispose();
	}

	// ---------------------------------------------------------------------
	// Private.
	// ---------------------------------------------------------------------

	private function queueDispatch(event:MouseEvent3D, sourceEvent:MouseEvent, collider:PickingCollisionVO = null):Void
	{
		// 2D properties.
		event.ctrlKey = sourceEvent.ctrlKey;
		event.altKey = sourceEvent.altKey;
		event.shiftKey = sourceEvent.shiftKey;
		event.delta = sourceEvent.delta;
		event.screenX = sourceEvent.localX;
		event.screenY = sourceEvent.localY;

		if (collider == null)
			collider = _collidingObject;

		// 3D properties.
		if (collider)
		{
			// Object.
			event.object = collider.entity;
			event.renderable = collider.renderable;
			// UV.
			event.uv = collider.uv;
			// Position.
			event.localPosition = collider.localPosition ? collider.localPosition.clone() : null;
			// Normal.
			event.localNormal = collider.localNormal ? collider.localNormal.clone() : null;
			// Face index.
			event.index = collider.index;
			// SubGeometryIndex.
			event.subGeometryIndex = collider.subGeometryIndex;

		}
		else
		{
			// Set all to null.
			event.uv = null;
			event.object = null;
			event.localPosition = _nullVector;
			event.localNormal = _nullVector;
			event.index = 0;
			event.subGeometryIndex = 0;
		}

		// Store event to be dispatched later.
		_queuedEvents.push(event);
	}

	private function reThrowEvent(event:MouseEvent):Void
	{
		if (!_activeView || (_activeView && _activeView.shareContext))
			return;

		for (var v:* in _view3Ds)
		{
			if (v != _activeView && _view3Ds[v] < _view3Ds[_activeView])
			{
				v.dispatchEvent(event);
			}
		}
	}

	private function hasKey(view:View3D):Bool
	{
		for (var v:* in _view3Ds)
		{
			if (v === view)
			{
				return true;
			}
		}
		return false;
	}

	private function traverseDisplayObjects(container:DisplayObjectContainer):Void
	{
		var childCount:Int = container.numChildren;
		var c:Int = 0;
		var child:DisplayObject;
		for (c = 0; c < childCount; c++)
		{
			child = container.getChildAt(c);
			for (var v:* in _view3Ds)
			{
				if (child == v)
				{
					_view3Ds[child] = _childDepth;
					_view3DLookup[_childDepth] = v;
					_childDepth++;
				}
			}
			if (child is DisplayObjectContainer)
			{
				traverseDisplayObjects(child as DisplayObjectContainer);
			}
		}
	}

	// ---------------------------------------------------------------------
	// Listeners.
	// ---------------------------------------------------------------------

	private function onMouseMove(event:MouseEvent):Void
	{
		if (_collidingObject)
			queueDispatch(_mouseMove, _mouseMoveEvent = event);
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onMouseOut(event:MouseEvent):Void
	{
		_activeView = null;
		if (_collidingObject)
			queueDispatch(_mouseOut, event, _collidingObject);
		_updateDirty = true;
	}

	private function onMouseOver(event:MouseEvent):Void
	{
		_activeView = (event.currentTarget as View3D);
		if (_collidingObject && _previousCollidingObject != _collidingObject)
			queueDispatch(_mouseOver, event, _collidingObject);
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onClick(event:MouseEvent):Void
	{
		if (_collidingObject && _collidingUpObject == _collidingDownObject)
		{
			queueDispatch(_mouseClick, event);
			_collidingUpObject = null;
			_collidingDownObject = null;
		}
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onDoubleClick(event:MouseEvent):Void
	{
		if (_collidingObject && _collidingUpObject == _collidingDownObject)
			queueDispatch(_mouseDoubleClick, event);
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onMouseDown(event:MouseEvent):Void
	{
		_activeView = (event.currentTarget as View3D);
		updateCollider(_activeView); // ensures collision check is done with correct mouse coordinates on mobile
		if (_collidingObject)
		{
			queueDispatch(_mouseDown, event);
			_collidingUpObject = null;
			_collidingDownObject = _collidingObject;
		}
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onMouseUp(event:MouseEvent):Void
	{
		if (_collidingObject)
		{
			queueDispatch(_mouseUp, event);
			_collidingUpObject = _collidingObject;
		}
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	private function onMouseWheel(event:MouseEvent):Void
	{
		if (_collidingObject)
			queueDispatch(_mouseWheel, event);
		else
			reThrowEvent(event);
		_updateDirty = true;
	}

	// ---------------------------------------------------------------------
	// Getters & setters.
	// ---------------------------------------------------------------------

	private inline function get_forceMouseMove():Bool
	{
		return _forceMouseMove;
	}

	private inline function set_forceMouseMove(value:Bool):Void
	{
		_forceMouseMove = value;
	}

	private inline function get_mousePicker():IPicker
	{
		return _mousePicker;
	}

	private inline function set_mousePicker(value:IPicker):Void
	{
		_mousePicker = value;
	}
}