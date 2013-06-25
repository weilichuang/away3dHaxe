package a3d.entities;

import flash.display3D.Context3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.utils.Dictionary;


import a3d.animators.IAnimator;
import a3d.bounds.BoundingSphere;
import a3d.bounds.BoundingVolumeBase;
import a3d.core.base.IRenderable;
import a3d.core.managers.Stage3DProxy;
import a3d.core.partition.EntityNode;
import a3d.core.partition.RenderableNode;
import a3d.io.library.assets.AssetType;
import a3d.materials.MaterialBase;
import a3d.materials.SegmentMaterial;
import a3d.entities.primitives.data.Segment;



class SegmentSet extends Entity implements IRenderable
{
	private const LIMIT:UInt = 3 * 0xFFFF;
	private var _activeSubSet:SubSet;
	private var _subSets:Vector<SubSet>;
	private var _subSetCount:UInt;
	private var _numIndices:UInt;
	private var _material:MaterialBase;
	private var _animator:IAnimator;
	private var _hasData:Bool;

	private var _segments:Dictionary;
	private var _indexSegments:UInt;

	/**
	 * Creates a new SegmentSet object.
	 */
	public function new()
	{
		super();

		_subSetCount = 0;
		_subSets = new Vector<SubSet>();
		addSubSet();

		_segments = new Dictionary();
		material = new SegmentMaterial();
	}

	/**
	* Adds a new segment to the SegmentSet.
	*
	* @param segment  the segment to add
	*/
	public function addSegment(segment:Segment):Void
	{
		segment.segmentsBase = this;

		_hasData = true;

		var subSetIndex:UInt = _subSets.length - 1;
		var subSet:SubSet = _subSets[subSetIndex];

		if (subSet.vertices.length + 44 > LIMIT)
		{
			subSet = addSubSet();
			subSetIndex++;
		}

		segment.index = subSet.vertices.length;
		segment.subSetIndex = subSetIndex;

		updateSegment(segment);

		var index:UInt = subSet.lineCount << 2;

		subSet.indices.push(index, index + 1, index + 2, index + 3, index + 2, index + 1);
		subSet.numVertices = subSet.vertices.length / 11;
		subSet.numIndices = subSet.indices.length;
		subSet.lineCount++;

		var segRef:SegRef = new SegRef();
		segRef.index = index;
		segRef.subSetIndex = subSetIndex;
		segRef.segment = segment;

		_segments[_indexSegments] = segRef;

		_indexSegments++;
	}

	/**
	* Removes a segment from the SegmentSet by its index in the set.
	*
	* @param index  		The index of the segment to remove
	* @param dispose  	If the segment must be disposed as well. Default is false;
	*
	*	Removing a Segment by an index when segment is unknown
	*	index of the segment is relative to the order it was added to the segmentSet.
	*	If a segment was removed from or added to the segmentSet, a segment index may have changed.
	*	The index of each Segment is updated when one is added or removed.
	*	If 2 segments are added, segment #1 has index 0, segment #2 has index 1
	*	if segment #1 is removed, segment#2 will get index 0 instead of 1.
	*/
	public function removeSegmentByIndex(index:UInt, dispose:Bool = false):Void
	{
		var segRef:SegRef;
		if (index >= _indexSegments)
			return;

		if (_segments[index])
		{
			segRef = _segments[index];
		}
		else
		{
			return;
		}

		var subSet:SubSet;
		if (!_subSets[segRef.subSetIndex])
			return;
		var subSetIndex:Int = segRef.subSetIndex;
		subSet = _subSets[segRef.subSetIndex];

		var segment:Segment = segRef.segment;
		var indices:Vector<UInt> = subSet.indices;

		var ind:UInt = index * 6;
		for (var i:UInt = ind; i < indices.length; ++i)
			indices[i] -= 4;

		subSet.indices.splice(index * 6, 6);
		subSet.vertices.splice(index * 44, 44);
		subSet.numVertices = subSet.vertices.length / 11;
		subSet.numIndices = indices.length;
		subSet.vertexBufferDirty = true;
		subSet.indexBufferDirty = true;
		subSet.lineCount--;

		if (dispose)
		{
			segment.dispose();
			segment = null;

		}
		else
		{
			segment.index = -1;
			segment.segmentsBase = null;
		}

		if (subSet.lineCount == 0)
		{

			if (subSetIndex == 0)
			{
				_hasData = false;

			}
			else
			{
				subSet.dispose();
				_subSets[subSetIndex] = null;
				_subSets.splice(subSetIndex, 1);
			}
		}

		reOrderIndices(subSetIndex, index);

		segRef = null;
		_segments[_indexSegments] = null;
		_indexSegments--;
	}

	/**
	* Removes a segment from the SegmentSet.
	*
	* @param segment  		The segment to remove
	* @param dispose  		If the segment must be disposed as well. Default is false;
	*/
	public function removeSegment(segment:Segment, dispose:Bool = false):Void
	{
		if (segment.index == -1)
			return;
		removeSegmentByIndex(segment.index / 44);
	}

	/**
	* Empties the segmentSet from all its segments data
	*/
	public function removeAllSegments():Void
	{
		var subSet:SubSet;
		for (var i:UInt = 0; i < _subSetCount; ++i)
		{
			subSet = _subSets[i];
			subSet.vertices = null;
			subSet.indices = null;
			if (subSet.vertexBuffer)
				subSet.vertexBuffer.dispose();
			if (subSet.indexBuffer)
				subSet.indexBuffer.dispose();
			subSet = null;
		}

		for each (var segRef:SegRef in _segments)
		{
			segRef = null;
		}
		_segments = null;

		_subSetCount = 0;
		_activeSubSet = null;
		_indexSegments = 0;
		_subSets = new Vector<SubSet>();
		_segments = new Dictionary();

		addSubSet();

		_hasData = false;
	}

	/**
	* @returns a segment object from a given index.
	*/
	public function getSegment(index:UInt):Segment
	{
		if (index > _indexSegments - 1)
			return null;

		return _segments[index].segment;
	}

	/**
	* @returns howmany segments are in the SegmentSet
	*/
	private inline function get_segmentCount():UInt
	{
		return _indexSegments;
	}

	private inline function get_subSetCount():UInt
	{
		return _subSetCount;
	}

	public function updateSegment(segment:Segment):Void
	{
		//to do: add support for curve segment
		var start:Vector3D = segment.start;
		var end:Vector3D = segment.end;
		var startX:Float = start.x, startY:Float = start.y, startZ:Float = start.z;
		var endX:Float = end.x, endY:Float = end.y, endZ:Float = end.z;
		var startR:Float = segment.startR, startG:Float = segment.startG, startB:Float = segment.startB;
		var endR:Float = segment.endR, endG:Float = segment.endG, endB:Float = segment.endB;
		var index:UInt = segment.index;
		var t:Float = segment.thickness;

		var subSet:SubSet = _subSets[segment.subSetIndex];
		var vertices:Vector<Float> = subSet.vertices;

		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = t;
		vertices[index++] = startR;
		vertices[index++] = startG;
		vertices[index++] = startB;
		vertices[index++] = 1;

		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = -t;
		vertices[index++] = endR;
		vertices[index++] = endG;
		vertices[index++] = endB;
		vertices[index++] = 1;

		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = -t;
		vertices[index++] = startR;
		vertices[index++] = startG;
		vertices[index++] = startB;
		vertices[index++] = 1;

		vertices[index++] = endX;
		vertices[index++] = endY;
		vertices[index++] = endZ;
		vertices[index++] = startX;
		vertices[index++] = startY;
		vertices[index++] = startZ;
		vertices[index++] = t;
		vertices[index++] = endR;
		vertices[index++] = endG;
		vertices[index++] = endB;
		vertices[index++] = 1;

		subSet.vertexBufferDirty = true;

		_boundsInvalid = true;
	}

	private inline function get_hasData():Bool
	{
		return _hasData;
	}

	public function getIndexBuffer(stage3DProxy:Stage3DProxy):IndexBuffer3D
	{
		if (_activeSubSet.indexContext3D != stage3DProxy.context3D || _activeSubSet.indexBufferDirty)
		{
			_activeSubSet.indexBuffer = stage3DProxy.context3D.createIndexBuffer(_activeSubSet.numIndices);
			_activeSubSet.indexBuffer.uploadFromVector(_activeSubSet.indices, 0, _activeSubSet.numIndices);
			_activeSubSet.indexBufferDirty = false;
			_activeSubSet.indexContext3D = stage3DProxy.context3D;
		}

		return _activeSubSet.indexBuffer;
	}

	public function activateVertexBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
		var subSet:SubSet = _subSets[index];

		_activeSubSet = subSet;
		_numIndices = subSet.numIndices;

		var vertexBuffer:VertexBuffer3D = subSet.vertexBuffer;

		if (subSet.vertexContext3D != stage3DProxy.context3D || subSet.vertexBufferDirty)
		{
			subSet.vertexBuffer = stage3DProxy.context3D.createVertexBuffer(subSet.numVertices, 11);
			subSet.vertexBuffer.uploadFromVector(subSet.vertices, 0, subSet.numVertices);
			subSet.vertexBufferDirty = false;
			subSet.vertexContext3D = stage3DProxy.context3D;
		}

		var context3d:Context3D = stage3DProxy.context3D;
		context3d.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		context3d.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3);
		context3d.setVertexBufferAt(2, vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_1);
		context3d.setVertexBufferAt(3, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4);
	}

	public function activateUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	public function activateVertexNormalBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	public function activateVertexTangentBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	public function activateSecondaryUVBuffer(index:Int, stage3DProxy:Stage3DProxy):Void
	{
	}

	private function reOrderIndices(subSetIndex:UInt, index:Int):Void
	{
		var segRef:SegRef;

		for (var i:UInt = index; i < _indexSegments - 1; ++i)
		{
			segRef = _segments[i + 1];
			segRef.index = i;
			if (segRef.subSetIndex == subSetIndex)
			{
				segRef.segment.index -= 44;
			}
			_segments[i] = segRef;
		}

	}

	private function addSubSet():SubSet
	{
		var subSet:SubSet = new SubSet();
		_subSets.push(subSet);

		subSet.vertices = new Vector<Float>();
		subSet.numVertices = 0;
		subSet.indices = new Vector<UInt>();
		subSet.numIndices = 0;
		subSet.vertexBufferDirty = true;
		subSet.indexBufferDirty = true;
		subSet.lineCount = 0;

		_subSetCount++;

		return subSet;
	}

	/**
	 * @inheritDoc
	 */
	override public function dispose():Void
	{
		super.dispose();
		removeAllSegments();
		_segments = null
		_material = null;
		var subSet:SubSet = _subSets[0];
		subSet.vertices = null;
		subSet.indices = null;
		_subSets = null;
	}

	/**
	 * @inheritDoc
	 */
	override private inline function get_mouseEnabled():Bool
	{
		return false;
	}

	/**
		 * @inheritDoc
		 */
	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		return new BoundingSphere();
	}

	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
		var subSet:SubSet;
		var len:UInt;
		var v:Float;
		var index:UInt;

		var minX:Float = Infinity;
		var minY:Float = Infinity;
		var minZ:Float = Infinity;
		var maxX:Float = -Infinity;
		var maxY:Float = -Infinity;
		var maxZ:Float = -Infinity;
		var vertices:Vector<Float>;

		for (var i:UInt = 0; i < _subSetCount; ++i)
		{
			subSet = _subSets[i];
			index = 0;
			vertices = subSet.vertices;
			len = vertices.length;

			if (len == 0)
				continue;

			while (index < len)
			{

				v = vertices[index++];
				if (v < minX)
					minX = v;
				else if (v > maxX)
					maxX = v;

				v = vertices[index++];
				if (v < minY)
					minY = v;
				else if (v > maxY)
					maxY = v;

				v = vertices[index++];
				if (v < minZ)
					minZ = v;
				else if (v > maxZ)
					maxZ = v;

				index += 8;
			}
		}

		if (minX != Infinity)
		{
			_bounds.fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);

		}
		else
		{
			var min:Float = .5;
			_bounds.fromExtremes(-min, -min, -min, min, min, min);
		}

		_boundsInvalid = false;
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new RenderableNode(this);
	}

	private inline function get_numTriangles():UInt
	{
		return _numIndices / 3;
	}

	private inline function get_sourceEntity():Entity
	{
		return this;
	}

	private inline function get_castsShadows():Bool
	{
		return false;
	}

	private inline function get_material():MaterialBase
	{
		return _material;
	}

	private inline function get_animator():IAnimator
	{
		return _animator;
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

	private inline function get_uvTransform():Matrix
	{
		return null;
	}

	private inline function get_vertexData():Vector<Float>
	{
		return null;
	}

	private inline function get_indexData():Vector<UInt>
	{
		return null;
	}

	private inline function get_UVData():Vector<Float>
	{
		return null;
	}

	private inline function get_numVertices():UInt
	{
		return null;
	}

	private inline function get_vertexStride():UInt
	{
		return 11;
	}

	private inline function get_vertexNormalData():Vector<Float>
	{
		return null;
	}

	private inline function get_vertexTangentData():Vector<Float>
	{
		return null;
	}

	private inline function get_vertexOffset():Int
	{
		return 0;
	}

	private inline function get_vertexNormalOffset():Int
	{
		return 0;
	}

	private inline function get_vertexTangentOffset():Int
	{
		return 0;
	}

	override private inline function get_assetType():String
	{
		return AssetType.SEGMENT_SET;
	}

	public function getRenderSceneTransform(camera:Camera3D):Matrix3D
	{
		return _sceneTransform;
	}
}

 class SegRef
{

	public var index:UInt;
	public var subSetIndex:UInt;
	public var segment:Segment;
}

 class SubSet
{


	public var vertices:Vector<Float>;
	public var numVertices:UInt;

	public var indices:Vector<UInt>;
	public var numIndices:UInt;

	public var vertexBufferDirty:Bool;
	public var indexBufferDirty:Bool;

	public var vertexContext3D:Context3D;
	public var indexContext3D:Context3D;

	public var vertexBuffer:VertexBuffer3D;
	public var indexBuffer:IndexBuffer3D;
	public var lineCount:UInt;

	public function dispose():Void
	{
		vertices = null;
		if (vertexBuffer)
			vertexBuffer.dispose();
		if (indexBuffer)
			indexBuffer.dispose();
	}
}

