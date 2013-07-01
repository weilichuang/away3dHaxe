package a3d.events;

import a3d.core.base.IRenderable;
import a3d.entities.ObjectContainer3D;
import a3d.entities.View3D;
import a3d.materials.MaterialBase;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.Lib;


/**
 * A MouseEvent3D is dispatched when a mouse event occurs over a mouseEnabled object in View3D.
 * todo: we don't have screenZ data, tho this should be easy to implement
 */
class MouseEvent3D extends Event
{
	/**
	 *internal use
	 */
	public var allowedToPropagate:Bool = true;
	/**
	 *internal use
	 */
	public var parentEvent:MouseEvent3D;

	/**
	 * Defines the value of the type property of a mouseOver3d event object.
	 */
	public static inline var MOUSE_OVER:String = "mouseOver3d";

	/**
	 * Defines the value of the type property of a mouseOut3d event object.
	 */
	public static inline var MOUSE_OUT:String = "mouseOut3d";

	/**
	 * Defines the value of the type property of a mouseUp3d event object.
	 */
	public static inline var MOUSE_UP:String = "mouseUp3d";

	/**
	 * Defines the value of the type property of a mouseDown3d event object.
	 */
	public static inline var MOUSE_DOWN:String = "mouseDown3d";

	/**
	 * Defines the value of the type property of a mouseMove3d event object.
	 */
	public static inline var MOUSE_MOVE:String = "mouseMove3d";

	/**
	 * Defines the value of the type property of a rollOver3d event object.
	 */
//		public static inline var ROLL_OVER : String = "rollOver3d";

	/**
	 * Defines the value of the type property of a rollOut3d event object.
	 */
//		public static inline var ROLL_OUT : String = "rollOut3d";

	/**
	 * Defines the value of the type property of a click3d event object.
	 */
	public static inline var CLICK:String = "click3d";

	/**
	 * Defines the value of the type property of a doubleClick3d event object.
	 */
	public static inline var DOUBLE_CLICK:String = "doubleClick3d";

	/**
	 * Defines the value of the type property of a mouseWheel3d event object.
	 */
	public static inline var MOUSE_WHEEL:String = "mouseWheel3d";

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

	/**
	 * Indicates how many lines should be scrolled for each unit the user rotates the mouse wheel.
	 */
	public var delta:Int;

	/**
	 * Create a new MouseEvent3D object.
	 * @param type The type of the MouseEvent3D.
	 */
	public function new(type:String)
	{
		super(type, true, true);
	}

	/**
	 * @inheritDoc
	 */
	@:getter(bubbles) function get_bubbles():Bool
	{
		var doesBubble:Bool = super.bubbles && allowedToPropagate;
		allowedToPropagate = true;
		// Don't bubble if propagation has been stopped.
		return doesBubble;
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
			parentEvent.stopPropagation();
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
			parentEvent.stopImmediatePropagation();
		}
	}


	/**
	 * Creates a copy of the MouseEvent3D object and sets the value of each property to match that of the original.
	 */
	override public function clone():Event
	{
		var result:MouseEvent3D = new MouseEvent3D(type);

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
		result.delta = delta;

		result.ctrlKey = ctrlKey;
		result.shiftKey = shiftKey;

		result.parentEvent = this;
		result.allowedToPropagate = allowedToPropagate;

		return result;
	}

	/**
	 * The position in scene space where the event took place
	 */
	public var scenePosition(get, null):Vector3D;
	private function get_scenePosition():Vector3D
	{
		if (Std.is(object,ObjectContainer3D))
		{
			return Std.instance(object,ObjectContainer3D).sceneTransform.transformVector(localPosition);
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
	private function get_sceneNormal():Vector3D
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
