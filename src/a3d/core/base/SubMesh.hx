package a3d.core.base;

import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.Vector;


import a3d.animators.IAnimator;
import a3d.animators.data.AnimationSubGeometry;
import a3d.bounds.BoundingVolumeBase;
import a3d.entities.Camera3D;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Entity;
import a3d.entities.Mesh;
import a3d.materials.MaterialBase;



/**
 * SubMesh wraps a SubGeometry as a scene graph instantiation. A SubMesh is owned by a Mesh object.
 *
 * @see a3d.core.base.SubGeometry
 * @see a3d.scenegraph.Mesh
 */
class SubMesh implements IRenderable
{
	private var _material:MaterialBase;
	private var _parentMesh:Mesh;
	private var _subGeometry:ISubGeometry;
	/**
	 *internal use
	 */
	public var index:UInt;

	private var _uvTransform:Matrix;
	private var _uvTransformDirty:Bool;
	private var _uvRotation:Float = 0;
	private var _scaleU:Float = 1;
	private var _scaleV:Float = 1;
	private var _offsetU:Float = 0;
	private var _offsetV:Float = 0;

	public var animationSubGeometry:AnimationSubGeometry;

	public var animatorSubGeometry:AnimationSubGeometry;

	/**
	 * Creates a new SubMesh object
	 * @param subGeometry The SubGeometry object which provides the geometry data for this SubMesh.
	 * @param parentMesh The Mesh object to which this SubMesh belongs.
	 * @param material An optional material used to render this SubMesh.
	 */
	public function new(subGeometry:ISubGeometry, parentMesh:Mesh, material:MaterialBase = null)
	{
		_parentMesh = parentMesh;
		_subGeometry = subGeometry;
		this.material = material;
	}

	private inline function get_shaderPickingDetails():Bool
	{
		return sourceEntity.shaderPickingDetails;
	}

	private inline function get_offsetU():Float
	{
		return _offsetU;
	}

	private inline function set_offsetU(value:Float):Void
	{
		if (value == _offsetU)
			return;
		_offsetU = value;
		_uvTransformDirty = true;
	}

	private inline function get_offsetV():Float
	{
		return _offsetV;
	}

	private inline function set_offsetV(value:Float):Void
	{
		if (value == _offsetV)
			return;
		_offsetV = value;
		_uvTransformDirty = true;
	}

	private inline function get_scaleU():Float
	{
		return _scaleU;
	}

	private inline function set_scaleU(value:Float):Void
	{
		if (value == _scaleU)
			return;
		_scaleU = value;
		_uvTransformDirty = true;
	}

	private inline function get_scaleV():Float
	{
		return _scaleV;
	}

	private inline function set_scaleV(value:Float):Void
	{
		if (value == _scaleV)
			return;
		_scaleV = value;
		_uvTransformDirty = true;
	}

	private inline function get_uvRotation():Float
	{
		return _uvRotation;
	}

	private inline function set_uvRotation(value:Float):Void
	{
		if (value == _uvRotation)
			return;
		_uvRotation = value;
		_uvTransformDirty = true;
	}

	/**
	 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
	 */
	private inline function get_sourceEntity():Entity
	{
		return _parentMesh;
	}

	/**
	 * The SubGeometry object which provides the geometry data for this SubMesh.
	 */
	private inline function get_subGeometry():ISubGeometry
	{
		return _subGeometry;
	}

	private inline function set_subGeometry(value:ISubGeometry):Void
	{
		_subGeometry = value;
	}

	/**
	 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
	 */
	private inline function get_material():MaterialBase
	{
		return _material || _parentMesh.material;
	}

	private inline function set_material(value:MaterialBase):Void
	{
		if (_material)
			_material.removeOwner(this);

		_material = value;

		if (_material)
			_material.addOwner(this);
	}

	/**
	 * The scene transform object that transforms from model to world space.
	 */
	private inline function get_sceneTransform():Matrix3D
	{
		return _parentMesh.sceneTransform;
	}

	/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
	private inline function get_inverseSceneTransform():Matrix3D
	{
		return _parentMesh.inverseSceneTransform;
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexNormalBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexTangentBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateUVBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateSecondaryUVBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		return _subGeometry.getIndexBuffer(stage3DProxy);
	}

	/**
	 * The amount of triangles that make up this SubMesh.
	 */
	private inline function get_numTriangles():UInt
	{
		return _subGeometry.numTriangles;
	}

	/**
	 * The animator object that provides the state for the SubMesh's animation.
	 */
	private inline function get_animator():IAnimator
	{
		return _parentMesh.animator;
	}

	/**
	 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
	 */
	private inline function get_mouseEnabled():Bool
	{
		return _parentMesh.mouseEnabled || _parentMesh.ancestorsAllowMouseEnabled;
	}

	private inline function get_castsShadows():Bool
	{
		return _parentMesh.castsShadows;
	}

	/**
	 * A reference to the owning Mesh object
	 *
	 * @private
	 */
	private inline function get_parentMesh():Mesh
	{
		return _parentMesh;
	}

	private inline function set_parentMesh(value:Mesh):Void
	{
		_parentMesh = value;
	}

	private inline function get_uvTransform():Matrix
	{
		if (_uvTransformDirty)
			updateUVTransform();
		return _uvTransform;
	}

	private function updateUVTransform():Void
	{
		if (_uvTransform == null)
			_uvTransform = new Matrix();
		_uvTransform.identity();
		if (_uvRotation != 0)
			_uvTransform.rotate(_uvRotation);
		if (_scaleU != 1 || _scaleV != 1)
			_uvTransform.scale(_scaleU, _scaleV);
		_uvTransform.translate(_offsetU, _offsetV);
		_uvTransformDirty = false;
	}

	public function dispose():Void
	{
		material = null;
	}

	private inline function get_vertexData():Vector<Float>
	{
		return _subGeometry.vertexData;
	}

	private inline function get_indexData():Vector<UInt>
	{
		return _subGeometry.indexData;
	}

	private inline function get_UVData():Vector<Float>
	{
		return _subGeometry.UVData;
	}

	private inline function get_bounds():BoundingVolumeBase
	{
		return _parentMesh.bounds; // TODO: return smaller, sub mesh bounds instead
	}

	private inline function get_visible():Bool
	{
		return _parentMesh.visible;
	}

	private inline function get_numVertices():UInt
	{
		return _subGeometry.numVertices;
	}

	private inline function get_vertexStride():UInt
	{
		return _subGeometry.vertexStride;
	}

	private inline function get_UVStride():UInt
	{
		return _subGeometry.UVStride;
	}

	private inline function get_vertexNormalData():Vector<Float>
	{
		return _subGeometry.vertexNormalData;
	}

	private inline function get_vertexTangentData():Vector<Float>
	{
		return _subGeometry.vertexTangentData;
	}

	private inline function get_UVOffset():UInt
	{
		return _subGeometry.UVOffset;
	}

	private inline function get_vertexOffset():UInt
	{
		return _subGeometry.vertexOffset;
	}

	private inline function get_vertexNormalOffset():UInt
	{
		return _subGeometry.vertexNormalOffset;
	}

	private inline function get_vertexTangentOffset():UInt
	{
		return _subGeometry.vertexTangentOffset;
	}

	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _parentMesh.sceneTransform;
	}
}
