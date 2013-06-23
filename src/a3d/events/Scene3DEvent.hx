package a3d.events;

import flash.events.Event;

import a3d.entities.ObjectContainer3D;

class Scene3DEvent extends Event
{
	public static inline var ADDED_TO_SCENE:String = "addedToScene";
	public static inline var REMOVED_FROM_SCENE:String = "removedFromScene";
	public static inline var PARTITION_CHANGED:String = "partitionChanged";

	public var objectContainer3D:ObjectContainer3D;

	public var target(get, null):ObjectContainer3D;
	override private inline function get_target():ObjectContainer3D
	{
		return objectContainer3D;
	}

	public function new(type:String, objectContainer:ObjectContainer3D)
	{
		objectContainer3D = objectContainer;
		super(type);
	}

	override public function clone():Event
	{
		return new Scene3DEvent(type, objectContainer3D);
	}
}
