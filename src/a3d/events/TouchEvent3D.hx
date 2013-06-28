package a3d.events;

import flash.events.Event;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.Lib;

import a3d.core.base.IRenderable;
import a3d.entities.ObjectContainer3D;
import a3d.entities.View3D;
import a3d.materials.MaterialBase;

class TouchEvent3D extends Event
{
	// Private.
	public var allowedToPropagate:Bool = true;
	public var parentEvent:TouchEvent3D;

	public static inline var TOUCH_END:String = "touchEnd3d";
	public static inline var TOUCH_BEGIN:String = "touchBegin3d";
	public static inline var TOUCH_MOVE:String = "touchMove3d";
	public static inline var TOUCH_OUT:String = "touchOut3d";
	public static inline var TOUCH_OVER:String = "touchOver3d";

	/**
	 * The horizontal coordinate at which the event occurred in view coordinates.
	 */
	public var screenX:Float;

	/**
	 * The vertical coordinate at which the event occurred in view coordinates.
	 */
	public var screenY:Float;

	/**
	 * The view object inside which the event took place.
	 */
	public var view:View3D;

	/**
	 * The 3d object inside which the event took place.
	 */
	public var object:ObjectContainer3D;

	/**
	 * The renderable inside which the event took place.
	 */
	public var renderable:IRenderable;

	/**
	 * The material of the 3d element inside which the event took place.
	 */
	public var material:MaterialBase;

	/**
	 * The uv coordinate inside the draw primitive where the event took place.
	 */
	public var uv:Point;

	/**
	 * The index of the face where the event took place.
	 */
	public var index:UInt;

	/**
	 * The index of the subGeometry where the event took place.
	 */
	public var subGeometryIndex:UInt;

	/**
	 * The position in object space where the event took place
	 */
	public var localPosition:Vector3D;

	/**
	 * The normal in object space where the event took place
	 */
	public var localNormal:Vector3D;

	/**
	 * Indicates whether the Control key is active (true) or inactive (false).
	 */
	public var ctrlKey:Bool;

	/**
	 * Indicates whether the Alt key is active (true) or inactive (false).
	 */
	public var altKey:Bool;

	/**
	 * Indicates whether the Shift key is active (true) or inactive (false).
	 */
	public var shiftKey:Bool;

	public var touchPointID:Int;

	/**
	 * Create a new TouchEvent3D object.
	 * @param type The type of the TouchEvent3D.
	 */
	public function new(type:String)
	{
		super(type, true, true);
	}

	/**
	 * @inheritDoc
	 */
	override private function get_bubbles():Bool
	{
		// Don't bubble if propagation has been stopped.
		return super.bubbles && allowedToPropagate;
	}

	/**
	 * @inheritDoc
	 */
	override public function stopPropagation():Void
	{
		super.stopPropagation();
		allowedToPropagate = false;
		if (parentEvent != null)
		{
			parentEvent.allowedToPropagate = false;
		}
	}

	/**
	 * @inheritDoc
	 */
	override public function stopImmediatePropagation():Void
	{
		super.stopImmediatePropagation();
		allowedToPropagate = false;
		if (parentEvent != null)
		{
			parentEvent.allowedToPropagate = false;
		}
	}

	/**
	 * Creates a copy of the TouchEvent3D object and sets the value of each property to match that of the original.
	 */
	override public function clone():Event
	{
		var result:TouchEvent3D = new TouchEvent3D(type);

		if (isDefaultPrevented())
			result.preventDefault();

		result.screenX = screenX;
		result.screenY = screenY;

		result.view = view;
		result.object = object;
		result.renderable = renderable;
		result.material = material;
		result.uv = uv;
		result.localPosition = localPosition;
		result.localNormal = localNormal;
		result.index = index;
		result.subGeometryIndex = subGeometryIndex;

		result.ctrlKey = ctrlKey;
		result.shiftKey = shiftKey;

		result.parentEvent = this;

		return result;
	}

	/**
	 * The position in scene space where the event took place
	 */
	public var scenePosition(get, null):Vector3D;
	private inline function get_scenePosition():Vector3D
	{
		if (Std.is(object,ObjectContainer3D))
		{
			return Lib.as(object,ObjectContainer3D).sceneTransform.transformVector(localPosition);
		}
		else
		{
			return localPosition;
		}
	}

	/**
	 * The normal in scene space where the event took place
	 */
	public var sceneNormal(get, null):Vector3D;
	private inline function get_sceneNormal():Vector3D
	{
		if (Std.is(object,ObjectContainer3D))
		{
			var sceneNormal:Vector3D = Lib.as(object,ObjectContainer3D).sceneTransform.deltaTransformVector(localNormal);
			sceneNormal.normalize();
			return sceneNormal;
		}
		else
		{
			return localNormal;
		}
	}
}
