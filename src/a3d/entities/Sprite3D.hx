package a3d.entities
{
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	
	import a3d.animators.IAnimator;
	import a3d.bounds.AxisAlignedBoundingBox;
	import a3d.bounds.BoundingVolumeBase;
	import a3d.core.base.IRenderable;
	import a3d.core.base.SubGeometry;
	import a3d.core.base.SubMesh;
	import a3d.core.managers.Stage3DProxy;
	import a3d.core.partition.EntityNode;
	import a3d.core.partition.RenderableNode;
	import a3d.core.pick.IPickingCollider;
	import a3d.materials.MaterialBase;
	import a3d.math.Matrix3DUtils;

	

	/**
	 * Sprite3D is a 3D billboard, a renderable rectangular area that is always aligned with the projection plane.
	 * As a result, no perspective transformation occurs on a Sprite3D object.
	 *
	 * todo: mvp generation or vertex shader code can be optimized
	 */
	class Sprite3D extends Entity implements IRenderable
	{
		// TODO: Replace with CompactSubGeometry
		private static var _geometry:SubGeometry;
		//private static var _pickingSubMesh:SubGeometry;

		private var _material:MaterialBase;
		private var _spriteMatrix:Matrix3D;
		private var _animator:IAnimator;

		private var _pickingSubMesh:SubMesh;
		private var _pickingTransform:Matrix3D;
		private var _camera:Camera3D;

		private var _width:Float;
		private var _height:Float;
		private var _shadowCaster:Bool = false;

		public function Sprite3D(material:MaterialBase, width:Float, height:Float)
		{
			super();
			this.material = material;
			_width = width;
			_height = height;
			_spriteMatrix = new Matrix3D();
			if (_geometry == null)
			{
				_geometry = new SubGeometry();
				_geometry.updateVertexData(Vector<Float>([-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
				_geometry.updateUVData(Vector<Float>([.0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
				_geometry.updateIndexData(Vector<UInt>([0, 1, 2, 0, 2, 3]));
				_geometry.updateVertexTangentData(Vector<Float>([1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
				_geometry.updateVertexNormalData(Vector<Float>([.0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
			}
		}


		override private inline function set_pickingCollider(value:IPickingCollider):Void
		{
			super.pickingCollider = value;
			if (value)
			{ // bounds collider is the only null value
				_pickingSubMesh = new SubMesh(_geometry, null);
				_pickingTransform = new Matrix3D();
			}
		}

		private inline function get_width():Float
		{
			return _width;
		}

		private inline function set_width(value:Float):Void
		{
			if (_width == value)
				return;
			_width = value;
			invalidateTransform();
		}

		private inline function get_height():Float
		{
			return _height;
		}

		private inline function set_height(value:Float):Void
		{
			if (_height == value)
				return;
			_height = value;
			invalidateTransform();
		}

		public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexBuffer(index, stage3DProxy);
		}

		public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateUVBuffer(index, stage3DProxy);
		}

		public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateSecondaryUVBuffer(index, stage3DProxy);
		}

		public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexNormalBuffer(index, stage3DProxy);
		}

		public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
		{
			_geometry.activateVertexTangentBuffer(index, stage3DProxy);
		}

		public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
		{
			return _geometry.getIndexBuffer(stage3DProxy);
		}

		private inline function get_numTriangles():UInt
		{
			return 2;
		}

		private inline function get_sourceEntity():Entity
		{
			return this;
		}

		private inline function get_material():MaterialBase
		{
			return _material;
		}


		private inline function set_material(value:MaterialBase):Void
		{
			if (value == _material)
				return;
			if (_material)
				_material.removeOwner(this);
			_material = value;
			if (_material)
				_material.addOwner(this);
		}

		/**
		 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
		 */
		private inline function get_animator():IAnimator
		{
			return _animator;
		}

		private inline function get_castsShadows():Bool
		{
			return _shadowCaster;
		}

		override private function getDefaultBoundingVolume():BoundingVolumeBase
		{
			return new AxisAlignedBoundingBox();
		}


		override private function updateBounds():Void
		{
			_bounds.fromExtremes(-.5 * _scaleX, -.5 * _scaleY, -.5 * _scaleZ, .5 * _scaleX, .5 * _scaleY, .5 * _scaleZ);
			_boundsInvalid = false;
		}

		override private function createEntityPartitionNode():EntityNode
		{
			return new RenderableNode(this);
		}

		override private function updateTransform():Void
		{
			super.updateTransform();
			_transform.prependScale(_width, _height, Math.max(_width, _height));
		}

		private inline function get_uvTransform():Matrix
		{
			return null;
		}

		private inline function get_vertexData():Vector<Float>
		{
			return _geometry.vertexData;
		}

		private inline function get_indexData():Vector<UInt>
		{
			return _geometry.indexData;
		}

		private inline function get_UVData():Vector<Float>
		{
			return _geometry.UVData;
		}

		private inline function get_numVertices():UInt
		{
			return _geometry.numVertices;
		}

		private inline function get_vertexStride():UInt
		{
			return _geometry.vertexStride;
		}

		private inline function get_vertexNormalData():Vector<Float>
		{
			return _geometry.vertexNormalData;
		}

		private inline function get_vertexTangentData():Vector<Float>
		{
			return _geometry.vertexTangentData;
		}

		private inline function get_vertexOffset():Int
		{
			return _geometry.vertexOffset;
		}

		private inline function get_vertexNormalOffset():Int
		{
			return _geometry.vertexNormalOffset;
		}

		private inline function get_vertexTangentOffset():Int
		{
			return _geometry.vertexTangentOffset;
		}

		override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
		{
			findClosest = findClosest;
			var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
			viewTransform.transpose();
			var rawViewTransform:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			viewTransform.copyRawDataTo(rawViewTransform);
			rawViewTransform[3] = 0;
			rawViewTransform[7] = 0;
			rawViewTransform[11] = 0;
			rawViewTransform[12] = 0;
			rawViewTransform[13] = 0;
			rawViewTransform[14] = 0;

			_pickingTransform.copyRawDataFrom(rawViewTransform);
			_pickingTransform.prependScale(_width, _height, Math.max(_width, _height));
			_pickingTransform.appendTranslation(scenePosition.x, scenePosition.y, scenePosition.z);
			_pickingTransform.invert();

			var localRayPosition:Vector3D = _pickingTransform.transformVector(pickingCollisionVO.rayPosition);
			var localRayDirection:Vector3D = _pickingTransform.deltaTransformVector(pickingCollisionVO.rayDirection);

			_pickingCollider.setLocalRay(localRayPosition, localRayDirection);

			pickingCollisionVO.renderable = null;
			if (_pickingCollider.testSubMeshCollision(_pickingSubMesh, pickingCollisionVO, shortestCollisionDistance))
			{
				pickingCollisionVO.renderable = _pickingSubMesh;
			}

			return pickingCollisionVO.renderable != null;
		}

		public function getRenderSceneTransform(camera:Camera3D):Matrix3D
		{
			var comps:Vector<Vector3D> = camera.sceneTransform.decompose();
			var scale:Vector3D = comps[2];
			comps[0] = scenePosition;
			scale.x = _width * _scaleX;
			scale.y = _height * _scaleY;
			_spriteMatrix.recompose(comps);
			return _spriteMatrix;
		}
	}
}
