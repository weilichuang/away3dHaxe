package a3d.entities;

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
import a3d.math.FMatrix3D;
import a3d.utils.VectorUtil.VectorUtil;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.Vector;

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
	
	public var width(get, set):Float;
	public var height(get, set):Float;
	public var numTriangles(get, null):Int;
	public var sourceEntity(get, null):Entity;
	public var material(get, set):MaterialBase;
	/**
	 * Defines the animator of the mesh. Act on the mesh's geometry. Defaults to null
	 */
	public var animator(get, null):IAnimator;
	public var castsShadows(get, null):Bool;
	public var uvTransform(get, null):Matrix;
	public var vertexData(get, null):Vector<Float>;
	public var indexData(get, null):Vector<UInt>;
	public var UVData(get, null):Vector<Float>;
	public var numVertices(get, null):Int;
	public var vertexStride(get, null):Int;
	public var vertexNormalData(get, null):Vector<Float>;
	public var vertexTangentData(get, null):Vector<Float>;
	
	public var vertexOffset(get, null):Int;
	public var vertexNormalOffset(get, null):Int;
	public var vertexTangentOffset(get, null):Int;
	
	

	private var _material:MaterialBase;
	private var _spriteMatrix:Matrix3D;
	private var _animator:IAnimator;

	private var _pickingSubMesh:SubMesh;
	private var _pickingTransform:Matrix3D;
	private var _camera:Camera3D;

	private var _width:Float;
	private var _height:Float;
	private var _shadowCaster:Bool = false;

	public function new(material:MaterialBase, width:Float, height:Float)
	{
		super();
		this.material = material;
		_width = width;
		_height = height;
		_spriteMatrix = new Matrix3D();
		if (_geometry == null)
		{
			_geometry = new SubGeometry();
			_geometry.updateVertexData(Vector.ofArray([-.5, .5, .0, .5, .5, .0, .5, -.5, .0, -.5, -.5, .0]));
			_geometry.updateUVData(Vector.ofArray([.0, .0, 1.0, .0, 1.0, 1.0, .0, 1.0]));
			_geometry.updateIndexData(VectorUtil.toUIntVector([0, 1, 2, 0, 2, 3]));
			_geometry.updateVertexTangentData(Vector.ofArray([1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0]));
			_geometry.updateVertexNormalData(Vector.ofArray([.0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0, .0, .0, -1.0]));
		}
	}


	override private function set_pickingCollider(value:IPickingCollider):IPickingCollider
	{
		super.pickingCollider = value;
		if (value != null)
		{ // bounds collider is the only null value
			_pickingSubMesh = new SubMesh(_geometry, null);
			_pickingTransform = new Matrix3D();
		}
		return pickingCollider;
	}

	
	private function get_width():Float
	{
		return _width;
	}

	private function set_width(value:Float):Float
	{
		if (_width == value)
			return _width;
		_width = value;
		invalidateTransform();
		return _width;
	}

	
	private function get_height():Float
	{
		return _height;
	}

	private function set_height(value:Float):Float
	{
		if (_height == value)
			return _height;
		_height = value;
		invalidateTransform();
		
		return _height;
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

	
	private function get_numTriangles():Int
	{
		return 2;
	}

	
	private function get_sourceEntity():Entity
	{
		return this;
	}

	
	private function get_material():MaterialBase
	{
		return _material;
	}


	private function set_material(value:MaterialBase):MaterialBase
	{
		if (value == _material)
			return _material;
		if (_material != null)
			_material.removeOwner(this);
		_material = value;
		if (_material != null)
			_material.addOwner(this);
		return _material;
	}

	
	private function get_animator():IAnimator
	{
		return _animator;
	}

	
	private function get_castsShadows():Bool
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

	
	private function get_uvTransform():Matrix
	{
		return null;
	}

	
	private function get_vertexData():Vector<Float>
	{
		return _geometry.vertexData;
	}

	
	private function get_indexData():Vector<UInt>
	{
		return _geometry.indexData;
	}

	
	private function get_UVData():Vector<Float>
	{
		return _geometry.UVData;
	}

	
	private function get_numVertices():Int
	{
		return _geometry.numVertices;
	}

	
	private function get_vertexStride():Int
	{
		return _geometry.vertexStride;
	}

	
	private function get_vertexNormalData():Vector<Float>
	{
		return _geometry.vertexNormalData;
	}

	
	private function get_vertexTangentData():Vector<Float>
	{
		return _geometry.vertexTangentData;
	}

	
	private function get_vertexOffset():Int
	{
		return _geometry.vertexOffset;
	}

	
	private function get_vertexNormalOffset():Int
	{
		return _geometry.vertexNormalOffset;
	}

	
	private function get_vertexTangentOffset():Int
	{
		return _geometry.vertexTangentOffset;
	}

	override public function collidesBefore(shortestCollisionDistance:Float, findClosest:Bool):Bool
	{
		var viewTransform:Matrix3D = _camera.inverseSceneTransform.clone();
		viewTransform.transpose();
		var rawViewTransform:Vector<Float> = FMatrix3D.RAW_DATA_CONTAINER;
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
