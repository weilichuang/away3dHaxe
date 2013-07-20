package a3d.core.traverse;

import flash.geom.Vector3D;


import a3d.core.base.IRenderable;
import a3d.core.partition.NodeBase;
import a3d.entities.lights.LightBase;




/**
 * The RaycastCollector class is a traverser for scene partitions that collects all scene graph entities that are
 * considered intersecting with the defined ray.
 *
 * @see a3d.partition.Partition3D
 * @see a3d.partition.Entity
 */
class RaycastCollector extends EntityCollector
{
	/**
	 * Provides the starting position of the ray.
	 */
	public var rayPosition(get, set):Vector3D;
	/**
	 * Provides the direction vector of the ray.
	 */
	public var rayDirection(get, set):Vector3D;
	
	private var _rayPosition:Vector3D;
	private var _rayDirection:Vector3D;

	/**
	 * Creates a new RaycastCollector object.
	 */
	public function new()
	{
		super();
		_rayPosition = new Vector3D();
		_rayDirection = new Vector3D();
	}

	
	private function get_rayPosition():Vector3D
	{
		return _rayPosition;
	}

	private function set_rayPosition(value:Vector3D):Vector3D
	{
		return _rayPosition = value;
	}

	private function get_rayDirection():Vector3D
	{
		return _rayDirection;
	}

	private function set_rayDirection(value:Vector3D):Vector3D
	{
		return _rayDirection = value;
	}

	/**
	 * Returns true if the current node is at least partly in the frustum. If so, the partition node knows to pass on the traverser to its children.
	 *
	 * @param node The Partition3DNode object to frustum-test.
	 */
	override public function enterNode(node:NodeBase):Bool
	{
		return node.isIntersectingRay(_rayPosition, _rayDirection);
	}

	/**
	 * @inheritDoc
	 */
	override public function applySkyBox(renderable:IRenderable):Void
	{
	}

	/**
	 * Adds an IRenderable object to the potentially visible objects.
	 * @param renderable The IRenderable object to add.
	 */
	override public function applyRenderable(renderable:IRenderable):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	override public function applyUnknownLight(light:LightBase):Void
	{
	}
}
