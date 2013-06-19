package away3d.core.partition
{
	

	

	public class Octree extends Partition3D
	{
		public function Octree(maxDepth:int, size:Number)
		{
			super(new OctreeNode(maxDepth, size));
		}
	}
}
