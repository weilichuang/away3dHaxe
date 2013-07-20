package a3d.entities;

import flash.events.EventDispatcher;
import flash.Vector;

import a3d.core.partition.NodeBase;
import a3d.core.partition.Partition3D;
import a3d.core.traverse.PartitionTraverser;
import a3d.events.Scene3DEvent;



/**
 * The Scene3D class represents an independent 3D scene in which 3D objects can be created and manipulated.
 * Multiple Scene3D instances can be created in the same SWF file.
 *
 * Scene management happens through the scene graph, which is exposed using addChild and removeChild methods.
 * Internally, the Scene3D object also manages any space partition objects that have been assigned to objects in
 * the scene graph, of which there is at least 1.
 */
class Scene3D extends EventDispatcher
{
	public var sceneGraphRoot(get, set):ObjectContainer3D;
	/**
	 * The root partition to be used by the Scene3D.
	 */
	public var partition(get, set):Partition3D;
	
	/**
	 * The amount of children directly contained by the scene.
	 */
	public var numChildren(get, null):Int;
	
	private var _sceneGraphRoot:ObjectContainer3D;
	private var _partitions:Vector<Partition3D>;

	/**
	 * Creates a new Scene3D object.
	 */
	public function new()
	{
		super();
		
		_partitions = new Vector<Partition3D>();
		_sceneGraphRoot = new ObjectContainer3D();
		_sceneGraphRoot.scene = this;
		_sceneGraphRoot.isRoot = true;
		_sceneGraphRoot.partition = new Partition3D(new NodeBase());
	}

	
	private inline function set_sceneGraphRoot(value:ObjectContainer3D):ObjectContainer3D
	{
		return _sceneGraphRoot = value;
	}

	private inline function get_sceneGraphRoot():ObjectContainer3D
	{
		return _sceneGraphRoot;
	}

	/**
	 * Sends a PartitionTraverser object down the scene partitions
	 * @param traverser The traverser which will pass through the partitions.
	 *
	 * @see a3d.core.traverse.PartitionTraverser
	 * @see a3d.core.traverse.EntityCollector
	 */
	public function traversePartitions(traverser:PartitionTraverser):Void
	{
		traverser.scene = this;
		var len:Int = _partitions.length;
		for(i in 0...len)
			_partitions[i].traverse(traverser);
	}

	
	private inline function get_partition():Partition3D
	{
		return _sceneGraphRoot.partition;
	}

	private function set_partition(value:Partition3D):Partition3D
	{
		_sceneGraphRoot.partition = value;

		dispatchEvent(new Scene3DEvent(Scene3DEvent.PARTITION_CHANGED, _sceneGraphRoot));
		
		return _sceneGraphRoot.partition;
	}

	public inline function contains(child:ObjectContainer3D):Bool
	{
		return _sceneGraphRoot.contains(child);
	}

	/**
	 * Adds a child to the scene's root.
	 * @param child The child to be added to the scene
	 * @return A reference to the added child.
	 */
	public inline function addChild(child:ObjectContainer3D):ObjectContainer3D
	{
		return _sceneGraphRoot.addChild(child);
	}

	/**
	 * Removes a child from the scene's root.
	 * @param child The child to be removed from the scene.
	 */
	public inline function removeChild(child:ObjectContainer3D):Void
	{
		_sceneGraphRoot.removeChild(child);
	}

	/**
	 * Removes a child from the scene's root.
	 * @param index Index of child to be removed from the scene.
	 */
	public inline function removeChildAt(index:UInt):Void
	{
		_sceneGraphRoot.removeChildAt(index);
	}


	/**
	 * Retrieves the child with the given index
	 * @param index The index for the child to be retrieved.
	 * @return The child with the given index
	 */
	public inline function getChildAt(index:UInt):ObjectContainer3D
	{
		return _sceneGraphRoot.getChildAt(index);
	}

	
	private inline function get_numChildren():Int
	{
		return _sceneGraphRoot.numChildren;
	}

	/**
	 * When an entity is added to the scene, or to one of its children, add it to the partition tree.
	 * @private
	 */
	public function registerEntity(entity:Entity):Void
	{
		var partition:Partition3D = entity.implicitPartition;
		addPartitionUnique(partition);

		partition.markForUpdate(entity);
	}

	/**
	 * When an entity is removed from the scene, or from one of its children, remove it from its former partition tree.
	 * @private
	 */
	public function unregisterEntity(entity:Entity):Void
	{
		entity.implicitPartition.removeEntity(entity);
	}

	/**
	 * When an entity has moved or changed size, update its position in its partition tree.
	 */
	public function invalidateEntityBounds(entity:Entity):Void
	{
		entity.implicitPartition.markForUpdate(entity);
	}

	/**
	 * When a partition is assigned to an object somewhere in the scene graph, add the partition to the list if it isn't in there yet
	 */
	public function registerPartition(entity:Entity):Void
	{
		addPartitionUnique(entity.implicitPartition);
	}

	/**
	 * When a partition is removed from an object somewhere in the scene graph, remove the partition from the list
	 */
	public function unregisterPartition(entity:Entity):Void
	{
		// todo: wait... is this even correct?
		// shouldn't we check the number of children in implicitPartition and remove partition if 0?
		entity.implicitPartition.removeEntity(entity);
	}

	/**
	 * Add a partition if it's not in the list
	 */
	private function addPartitionUnique(partition:Partition3D):Void
	{
		if (_partitions.indexOf(partition) == -1)
			_partitions.push(partition);
	}
}
