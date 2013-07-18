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
	public var index:Int;

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

	public var shaderPickingDetails(get, null):Bool;
	private function get_shaderPickingDetails():Bool
	{
		return sourceEntity.shaderPickingDetails;
	}

	public var offsetU(get, set):Float;
	private function get_offsetU():Float
	{
		return _offsetU;
	}

	private function set_offsetU(value:Float):Float
	{
		if (value == _offsetU)
			return _offsetU;
		_offsetU = value;
		_uvTransformDirty = true;
		
		return _offsetU;
	}

	public var offsetV(get, set):Float;
	private function get_offsetV():Float
	{
		return _offsetV;
	}

	private function set_offsetV(value:Float):Float
	{
		if (value == _offsetV)
			return _offsetV;
		_offsetV = value;
		_uvTransformDirty = true;
		
		return _offsetV;
	}

	public var scaleU(get, set):Float;
	private function get_scaleU():Float
	{
		return _scaleU;
	}

	private function set_scaleU(value:Float):Float
	{
		if (value == _scaleU)
			return _scaleU;
		_scaleU = value;
		_uvTransformDirty = true;
		return _scaleU;
	}

	public var scaleV(get, set):Float;
	private function get_scaleV():Float
	{
		return _scaleV;
	}

	private function set_scaleV(value:Float):Float
	{
		if (value == _scaleV)
			return _scaleV;
		_scaleV = value;
		_uvTransformDirty = true;
		
		return _scaleV;
	}

	public var uvRotation(get, set):Float;
	private function get_uvRotation():Float
	{
		return _uvRotation;
	}

	private function set_uvRotation(value:Float):Float
	{
		if (value == _uvRotation)
			return _uvRotation;
		_uvRotation = value;
		_uvTransformDirty = true;
		
		return _uvRotation;
	}

	/**
	 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
	 */
	public var sourceEntity(get, null):Entity;
	private function get_sourceEntity():Entity
	{
		return _parentMesh;
	}

	/**
	 * The SubGeometry object which provides the geometry data for this SubMesh.
	 */
	public var subGeometry(get, set):ISubGeometry;
	private function get_subGeometry():ISubGeometry
	{
		return _subGeometry;
	}

	private function set_subGeometry(value:ISubGeometry):ISubGeometry
	{
		return _subGeometry = value;
	}

	/**
	 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
	 */
	public var material(get, set):MaterialBase;
	private function get_material():MaterialBase
	{
		if (_material != null)
			return _material;
		return _parentMesh.material;
	}

	private function set_material(value:MaterialBase):MaterialBase
	{
		if (_material != null)
			_material.removeOwner(this);

		_material = value;

		if (_material != null)
			_material.addOwner(this);
			
		return material;
	}

	/**
	 * The scene transform object that transforms from model to world space.
	 */
	public var sceneTransform(get, null):Matrix3D;
	private function get_sceneTransform():Matrix3D
	{
		return _parentMesh.sceneTransform;
	}

	/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
	public var inverseSceneTransform(get, null):Matrix3D;
	private function get_inverseSceneTransform():Matrix3D
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
	public var numTriangles(get, null):Int;
	private function get_numTriangles():Int
	{
		return _subGeometry.numTriangles;
	}

	/**
	 * The animator object that provides the state for the SubMesh's animation.
	 */
	public var animator(get, null):IAnimator;
	private function get_animator():IAnimator
	{
		return _parentMesh.animator;
	}

	/**
	 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
	 */
	public var mouseEnabled(get, null):Bool;
	private function get_mouseEnabled():Bool
	{
		return _parentMesh.mouseEnabled || _parentMesh.ancestorsAllowMouseEnabled;
	}

	public var castsShadows(get, null):Bool;
	private function get_castsShadows():Bool
	{
		return _parentMesh.castsShadows;
	}

	/**
	 * A reference to the owning Mesh object
	 *
	 * @private
	 */
	public var parentMesh(get, set):Mesh;
	private function get_parentMesh():Mesh
	{
		return _parentMesh;
	}

	private function set_parentMesh(value:Mesh):Mesh
	{
		return _parentMesh = value;
	}

	public var uvTransform(get, null):Matrix;
	private function get_uvTransform():Matrix
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

	public var vertexData(get, null):Vector<Float>;
	private function get_vertexData():Vector<Float>
	{
		return _subGeometry.vertexData;
	}

	public var indexData(get, null):Vector<UInt>;
	private function get_indexData():Vector<UInt>
	{
		return _subGeometry.indexData;
	}

	public var UVData(get, null):Vector<Float>;
	private function get_UVData():Vector<Float>
	{
		return _subGeometry.UVData;
	}

	public var bounds(get, null):BoundingVolumeBase;
	private function get_bounds():BoundingVolumeBase
	{
		return _parentMesh.bounds; // TODO: return smaller, sub mesh bounds instead
	}

	public var visible(get, null):Bool;
	private function get_visible():Bool
	{
		return _parentMesh.visible;
	}

	public var numVertices(get, null):Int;
	private function get_numVertices():Int
	{
		return _subGeometry.numVertices;
	}

	public var vertexStride(get, null):Int;
	private function get_vertexStride():Int
	{
		return _subGeometry.vertexStride;
	}

	public var UVStride(get, null):Int;
	private function get_UVStride():Int
	{
		return _subGeometry.UVStride;
	}

	public var vertexNormalData(get, null):Vector<Float>;
	private function get_vertexNormalData():Vector<Float>
	{
		return _subGeometry.vertexNormalData;
	}

	public var vertexTangentData(get, null):Vector<Float>;
	private function get_vertexTangentData():Vector<Float>
	{
		return _subGeometry.vertexTangentData;
	}

	public var UVOffset(get, null):Int;
	private function get_UVOffset():Int
	{
		return _subGeometry.UVOffset;
	}

	public var vertexOffset(get, null):Int;
	private function get_vertexOffset():Int
	{
		return _subGeometry.vertexOffset;
	}

	public var vertexNormalOffset(get, null):Int;
	private function get_vertexNormalOffset():Int
	{
		return _subGeometry.vertexNormalOffset;
	}

	public var vertexTangentOffset(get, null):Int;
	private function get_vertexTangentOffset():Int
	{
		return _subGeometry.vertexTangentOffset;
	}

	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _parentMesh.sceneTransform;
	}
}
