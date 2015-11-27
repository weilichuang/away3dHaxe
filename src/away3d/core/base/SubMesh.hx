package away3d.core.base;

import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.IAnimator;
import away3d.bounds.BoundingVolumeBase;
import away3d.core.managers.Stage3DProxy;
import away3d.entities.Camera3D;
import away3d.entities.Entity;
import away3d.entities.Mesh;
import away3d.materials.MaterialBase;
import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.Vector;


/**
 * SubMesh wraps a SubGeometry as a scene graph instantiation. A SubMesh is owned by a Mesh object.
 *
 * @see away3d.core.base.SubGeometry
 * @see away3d.scenegraph.Mesh
 */
class SubMesh implements IRenderable
{
	public var shaderPickingDetails(get, null):Bool;
	public var offsetU(get, set):Float;
	public var offsetV(get, set):Float;
	public var scaleU(get, set):Float;
	public var scaleV(get, set):Float;
	public var uvRotation(get, set):Float;
	/**
	 * The entity that that initially provided the IRenderable to the render pipeline (ie: the owning Mesh object).
	 */
	public var sourceEntity(get, null):Entity;
	/**
	 * The SubGeometry object which provides the geometry data for this SubMesh.
	 */
	public var subGeometry(get, set):ISubGeometry;
	/**
	 * The material used to render the current SubMesh. If set to null, its parent Mesh's material will be used instead.
	 */
	public var material(get, set):MaterialBase;
	/**
	 * The scene transform object that transforms from model to world space.
	 */
	public var sceneTransform(get, null):Matrix3D;
	/**
	 * The inverse scene transform object that transforms from world to model space.
	 */
	public var inverseSceneTransform(get, null):Matrix3D;
	/**
	 * The amount of triangles that make up this SubMesh.
	 */
	public var numTriangles(get, null):Int;
	/**
	 * The animator object that provides the state for the SubMesh's animation.
	 */
	public var animator(get, null):IAnimator;
	/**
	 * Indicates whether the SubMesh should trigger mouse events, and hence should be rendered for hit testing.
	 */
	public var mouseEnabled(get, null):Bool;
	public var castsShadows(get, null):Bool;
	/**
	 * A reference to the owning Mesh object
	 *
	 * @private
	 */
	public var parentMesh(get, set):Mesh;
	
	public var uvTransform(get, null):Matrix;
	public var vertexData(get, null):Vector<Float>;
	public var indexData(get, null):Vector<UInt>;
	public var UVData(get, null):Vector<Float>;
	public var bounds(get, null):BoundingVolumeBase;
	public var visible(get, null):Bool;
	public var numVertices(get, null):Int;
	public var vertexStride(get, null):Int;
	public var UVStride(get, null):Int;
	public var vertexNormalData(get, null):Vector<Float>;
	public var vertexTangentData(get, null):Vector<Float>;
	public var UVOffset(get, null):Int;
	public var vertexOffset(get, null):Int;
	public var vertexNormalOffset(get, null):Int;
	public var vertexTangentOffset(get, null):Int;
	
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

	
	private inline function get_shaderPickingDetails():Bool
	{
		return sourceEntity.shaderPickingDetails;
	}

	private inline function get_offsetU():Float
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

	private inline function get_offsetV():Float
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

	private inline function get_scaleU():Float
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

	private inline function get_scaleV():Float
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

	private inline function get_uvRotation():Float
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

	
	private inline function get_sourceEntity():Entity
	{
		return _parentMesh;
	}

	
	private inline function get_subGeometry():ISubGeometry
	{
		return _subGeometry;
	}

	private function set_subGeometry(value:ISubGeometry):ISubGeometry
	{
		return _subGeometry = value;
	}

	
	private inline function get_material():MaterialBase
	{
		return _material != null ? _material : _parentMesh.material;
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

	
	private inline function get_sceneTransform():Matrix3D
	{
		return _parentMesh.sceneTransform;
	}

	
	private inline function get_inverseSceneTransform():Matrix3D
	{
		return _parentMesh.inverseSceneTransform;
	}

	/**
	 * @inheritDoc
	 */
	public inline function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public inline function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexNormalBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public inline function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateVertexTangentBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public inline function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateUVBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public inline function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_subGeometry.activateSecondaryUVBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public inline function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		return _subGeometry.getIndexBuffer(stage3DProxy);
	}

	
	private inline function get_numTriangles():Int
	{
		return _subGeometry.numTriangles;
	}

	
	private inline function get_animator():IAnimator
	{
		return _parentMesh.animator;
	}

	
	private inline function get_mouseEnabled():Bool
	{
		return _parentMesh.mouseEnabled || _parentMesh.ancestorsAllowMouseEnabled;
	}

	
	private inline function get_castsShadows():Bool
	{
		return _parentMesh.castsShadows;
	}

	
	private inline function get_parentMesh():Mesh
	{
		return _parentMesh;
	}

	private inline function set_parentMesh(value:Mesh):Mesh
	{
		return _parentMesh = value;
	}

	
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

	
	private function get_vertexData():Vector<Float>
	{
		return _subGeometry.vertexData;
	}

	
	private function get_indexData():Vector<UInt>
	{
		return _subGeometry.indexData;
	}

	
	private function get_UVData():Vector<Float>
	{
		return _subGeometry.UVData;
	}

	
	private function get_bounds():BoundingVolumeBase
	{
		return _parentMesh.bounds; // TODO: return smaller, sub mesh bounds instead
	}

	
	private function get_visible():Bool
	{
		return _parentMesh.visible;
	}

	
	private function get_numVertices():Int
	{
		return _subGeometry.numVertices;
	}

	
	private function get_vertexStride():Int
	{
		return _subGeometry.vertexStride;
	}

	
	private function get_UVStride():Int
	{
		return _subGeometry.UVStride;
	}

	
	private function get_vertexNormalData():Vector<Float>
	{
		return _subGeometry.vertexNormalData;
	}

	
	private function get_vertexTangentData():Vector<Float>
	{
		return _subGeometry.vertexTangentData;
	}

	
	private function get_UVOffset():Int
	{
		return _subGeometry.UVOffset;
	}

	
	private function get_vertexOffset():Int
	{
		return _subGeometry.vertexOffset;
	}

	
	private function get_vertexNormalOffset():Int
	{
		return _subGeometry.vertexNormalOffset;
	}

	
	private function get_vertexTangentOffset():Int
	{
		return _subGeometry.vertexTangentOffset;
	}

	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _parentMesh.sceneTransform;
	}
}
