package away3d.events;

import away3d.entities.ObjectContainer3D;
import flash.events.Event;
import flash.utils.Object;


class Scene3DEvent extends Event
{
	public static inline var ADDED_TO_SCENE:String = "addedToScene";
	public static inline var REMOVED_FROM_SCENE:String = "removedFromScene";
	public static inline var PARTITION_CHANGED:String = "partitionChanged";

	public var objectContainer3D:ObjectContainer3D;

	@:getter(target) public function get_target():Object
	{
		return objectContainer3D;
	}

	public function new(type:String, objectContainer:ObjectContainer3D)
	{
		this.objectContainer3D = objectContainer;
		super(type);
	}

	override public function clone():Event
	{
		return new Scene3DEvent(type, objectContainer3D);
	}
}
