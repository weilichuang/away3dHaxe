package a3d.entities.primitives;


import a3d.animators.IAnimator;
import a3d.utils.VectorUtil.VectorUtil;
import flash.Vector;

import a3d.bounds.BoundingVolumeBase;
import a3d.bounds.NullBounds;
import a3d.entities.Camera3D;
import a3d.core.base.IRenderable;
import a3d.core.base.SubGeometry;
import a3d.core.managers.Stage3DProxy;
import a3d.core.partition.EntityNode;
import a3d.core.partition.SkyBoxNode;
import a3d.entities.Entity;
import a3d.errors.AbstractMethodError;
import a3d.io.library.assets.AssetType;
import a3d.materials.MaterialBase;
import a3d.materials.SkyBoxMaterial;
import a3d.textures.CubeTextureBase;

import flash.display3D.IndexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;



/**
 * A SkyBox class is used to render a sky in the scene. It's always considered static and 'at infinity', and as
 * such it's always centered at the camera's position and sized to exactly fit within the camera's frustum, ensuring
 * the sky box is always as large as possible without being clipped.
 */
class SkyBox extends Entity implements IRenderable
{
	// todo: remove SubGeometry, use a simple single buffer with offsets
	private var _geometry:SubGeometry;
	private var _material:SkyBoxMaterial;
	private var _uvTransform:Matrix;
	private var _animator:IAnimator;

	
	/**
	 * Create a new SkyBox object.
	 * @param cubeMap The CubeMap to use for the sky box's texture.
	 */
	public function new(cubeMap:CubeTextureBase)
	{
		super();
		
		_uvTransform = new Matrix();
		
		_material = new SkyBoxMaterial(cubeMap);
		_material.addOwner(this);
		_geometry = new SubGeometry();
		buildGeometry(_geometry);
	}

	public var animator(get, null):IAnimator;
	private function get_animator():IAnimator
	{
		return _animator;
	}

	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		return new NullBounds();
	}

	
	/**
	 * @inheritDoc
	 */
	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		_geometry.activateVertexBuffer(index, stage3DProxy);
	}

	/**
	 * @inheritDoc
	 */
	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		return _geometry.getIndexBuffer(stage3DProxy);
	}

	/**
	 * The amount of triangles that comprise the SkyBox geometry.
	 */
	public var numTriangles(get, null):Int;
	private function get_numTriangles():Int
	{
		return _geometry.numTriangles;
	}

	/**
	 * The entity that that initially provided the IRenderable to the render pipeline.
	 */
	public var sourceEntity(get, null):Entity;
	private function get_sourceEntity():Entity
	{
		return null;
	}

	/**
	 * The material with which to render the object.
	 */
	public var material(get, set):MaterialBase;
	private function get_material():MaterialBase
	{
		return _material;
	}

	private function set_material(value:MaterialBase):MaterialBase
	{
		throw new AbstractMethodError("Unsupported method!");
		return _material;
	}

	override private function get_assetType():String
	{
		return AssetType.SKYBOX;
	}

	/**
	 * @inheritDoc
	 */
	override private function invalidateBounds():Void
	{
		// dead end
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new SkyBoxNode(this);
	}

	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		_boundsInvalid = false;
	}

	/**
	 * Builds the geometry that forms the SkyBox
	 */
	private function buildGeometry(target:SubGeometry):Void
	{
		var vertices:Vector<Float> = Vector.ofArray([
			-1., 1, -1, 1, 1, -1,
			1, 1, 1, -1, 1, 1,
			-1, -1, -1, 1, -1, -1,
			1, -1, 1, -1, -1, 1
			]);
		vertices.fixed = true;

		var indices:Vector<UInt> = VectorUtil.toUIntVector([
			0, 1, 2, 2, 3, 0,
			6, 5, 4, 4, 7, 6,
			2, 6, 7, 7, 3, 2,
			4, 5, 1, 1, 0, 4,
			4, 0, 3, 3, 7, 4,
			2, 1, 5, 5, 6, 2
			]);

		target.updateVertexData(vertices);
		target.updateIndexData(indices);
	}

	public var castsShadows(get,null):Bool;
	private function get_castsShadows():Bool
	{
		return false;
	}

	public var uvTransform(get,null):Matrix;
	private function get_uvTransform():Matrix
	{
		return _uvTransform;
	}

	public var vertexData(get,null):Vector<Float>;
	private function get_vertexData():Vector<Float>
	{
		return _geometry.vertexData;
	}

	public var indexData(get,null):Vector<UInt>;
	private function get_indexData():Vector<UInt>
	{
		return _geometry.indexData;
	}

	public var UVData(get,null):Vector<Float>;
	private function get_UVData():Vector<Float>
	{
		return _geometry.UVData;
	}

	public var numVertices(get,null):Int;
	private function get_numVertices():Int
	{
		return _geometry.numVertices;
	}

	public var vertexStride(get,null):Int;
	private function get_vertexStride():Int
	{
		return _geometry.vertexStride;
	}

	public var vertexNormalData(get,null):Vector<Float>;
	private function get_vertexNormalData():Vector<Float>
	{
		return _geometry.vertexNormalData;
	}

	public var vertexTangentData(get,null):Vector<Float>;
	private function get_vertexTangentData():Vector<Float>
	{
		return _geometry.vertexTangentData;
	}

	public var vertexOffset(get,null):Int;
	private function get_vertexOffset():Int
	{
		return _geometry.vertexOffset;
	}

	public var vertexNormalOffset(get,null):Int;
	private function get_vertexNormalOffset():Int
	{
		return _geometry.vertexNormalOffset;
	}

	public var vertexTangentOffset(get,null):Int;
	private function get_vertexTangentOffset():Int
	{
		return _geometry.vertexTangentOffset;
	}

	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _sceneTransform;
	}
}
