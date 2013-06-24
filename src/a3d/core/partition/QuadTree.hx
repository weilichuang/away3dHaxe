package a3d.core.partition;





class QuadTree extends Partition3D
{
	public function QuadTree(maxDepth:Int, size:Float, height:Float = 1000000)
	{
		super(new QuadTreeNode(maxDepth, size, height));
	}
}

