package a3d.core.partition;





class Octree extends Partition3D
{
	public function Octree(maxDepth:Int, size:Float)
	{
		super(new OctreeNode(maxDepth, size));
	}
}

