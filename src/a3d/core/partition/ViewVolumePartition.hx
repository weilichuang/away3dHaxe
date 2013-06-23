package a3d.core.partition
{
	
	import a3d.entities.Entity;

	

	class ViewVolumePartition extends Partition3D
	{
		public function ViewVolumePartition()
		{
			super(new ViewVolumeRootNode());
		}

		override public function markForUpdate(entity:Entity):Void
		{
			// ignore if static, will be handled separately by visibility list
			if (!entity.staticNode)
				super.markForUpdate(entity);
		}

		/**
		 * Adds a view volume to provide visibility info for a given region.
		 */
		public function addViewVolume(viewVolume:ViewVolume):Void
		{
			ViewVolumeRootNode(_rootNode).addViewVolume(viewVolume);
		}

		public function removeViewVolume(viewVolume:ViewVolume):Void
		{
			ViewVolumeRootNode(_rootNode).removeViewVolume(viewVolume);
		}

		/**
		 * A dynamic grid to be able to determine visibility of dynamic objects. If none is provided, dynamic objects are only frustum-culled.
		 * If provided, ViewVolumes need to have visible grid cells assigned from the same DynamicGrid instance.
		 */
		private inline function get_dynamicGrid():DynamicGrid
		{
			return ViewVolumeRootNode(_rootNode).dynamicGrid;
		}

		private inline function set_dynamicGrid(value:DynamicGrid):Void
		{
			ViewVolumeRootNode(_rootNode).dynamicGrid = value;
		}
	}
}
