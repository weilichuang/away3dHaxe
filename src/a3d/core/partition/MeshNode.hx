package a3d.core.partition;

import a3d.core.base.SubMesh;
import a3d.core.traverse.PartitionTraverser;
import a3d.entities.Mesh;

/**
 * MeshNode is a space partitioning leaf node that contains a Mesh object.
 */
class MeshNode extends EntityNode
{
	private var _mesh:Mesh;

	/**
	 * Creates a new MeshNode object.
	 * @param mesh The mesh to be contained in the node.
	 */
	public function new(mesh:Mesh)
	{
		super(mesh);
		_mesh = mesh; // also keep a stronger typed reference
	}

	/**
	 * The mesh object contained in the partition node.
	 */
	private inline function get_mesh():Mesh
	{
		return _mesh;
	}

	/**
	 * @inheritDoc
	 */
	override public function acceptTraverser(traverser:PartitionTraverser):Void
	{
		if (traverser.enterNode(this))
		{
			super.acceptTraverser(traverser);
			var subs:Vector<SubMesh> = _mesh.subMeshes;
			var i:UInt;
			var len:UInt = subs.length;
			while (i < len)
				traverser.applyRenderable(subs[i++]);
		}
	}

}
