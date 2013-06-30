package a3d.tools.commands;

import a3d.core.base.Geometry;
import a3d.core.base.ISubGeometry;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.materials.MaterialBase;
import a3d.tools.utils.GeomUtil;
import flash.Vector;

/**
 *  Class Merge merges two or more static meshes into one.<code>Merge</code>
 */
class Merge
{

	//private const LIMIT:UInt = 196605;
	private var _objectSpace:Bool;
	private var _keepMaterial:Bool;
	private var _disposeSources:Bool;
	private var _geomVOs:Vector<GeometryVO>;

	/**
	 * @param	 keepMaterial		[optional] Bool. Defines if the merged object uses the mesh1 material information or keeps its material(s). Default is false.
	 * If set to false and receiver object has multiple materials, the last material found in mesh1 submeshes is applied to mesh2 submeshes.
	 * @param	 disposeSources	[optional] Bool. Defines if mesh2 (or sources meshes in case applyToContainer is used) are kept untouched or disposed. Default is false.
	 * If keepMaterial is true, only geometry and eventual ObjectContainers3D are cleared from memory.
	 * @param	 objectSpace		[optional] Bool. Defines if mesh2 is merge using its objectSpace or worldspace. Default is false.
	 */
	public function new(keepMaterial:Bool = false, disposeSources:Bool = false, objectSpace:Bool = false):Void
	{
		_keepMaterial = keepMaterial;
		_disposeSources = disposeSources;
		_objectSpace = objectSpace;
	}

	/**
	 * Defines if the mesh(es) sources used for the merging are kept or disposed.
	 */
	private function set_disposeSources(b:Bool):Void
	{
		_disposeSources = b;
	}

	private function get_disposeSources():Bool
	{
		return _disposeSources;
	}

	/**
	 * Defines if mesh2 will be merged using its own material information.
	 */
	private function set_keepMaterial(b:Bool):Void
	{
		_keepMaterial = b;
	}

	private function get_keepMaterial():Bool
	{
		return _keepMaterial;
	}

	/**
	 * Defines if mesh2 is merged using its objectSpace.
	 */
	private function set_objectSpace(b:Bool):Void
	{
		_objectSpace = b;
	}

	private function get_objectSpace():Bool
	{
		return _objectSpace;
	}

	/**
	 * Merges all the children of a container into a single Mesh. If no Mesh object is found, method returns the receiver without modification.
	 *
	 * @param	 receiver 			The Mesh that will receive the merged contents of the container.
	 * @param	 objectContainer	The ObjectContainer3D holding meshes to merge as one mesh.
	 *
	 * @return The merged Mesh instance.
	 */
	public function applyToContainer(receiver:Mesh, objectContainer:ObjectContainer3D):Void
	{
		reset();

		//collect container meshes
		parseContainer(objectContainer);

		if (!_geomVOs.length)
			return;

		//collect receiver
		collect(receiver, true);

		//merge to receiver
		merge(receiver);
	}

	/**
	 * Merges all the meshes found in the Vector.&lt;Mesh&gt; into a single Mesh.
	 *
	 * @param	 receiver 			The Mesh that will receive the merged contents of the meshes.
	 * @param	 meshes				Vector.&lt;Mesh&gt;. A series of Meshes to be merged with the reciever mesh.
	 */
	public function applyToMeshes(receiver:Mesh, meshes:Vector<Mesh>):Void
	{
		reset();

		if (!meshes.length)
			return;

		//collect meshes in vector
		for (var i:UInt = 0; i < meshes.length; i++)
			collect(meshes[i], _disposeSources);

		//collect receiver
		collect(receiver, true);

		//merge to receiver
		merge(receiver);
	}

	/**
	 *  Merge 2 meshes into one. It is recommand to use apply when 2 meshes are to be merged. If more need to be merged, use either applyToMeshes or applyToContainer methods.
	 *
	 * @param	 receiver			The Mesh that will receive the merged contents of both meshes.
	 * @param	 mesh				The Mesh that will be merged with the receiver mesh
	 */
	public function apply(receiver:Mesh, mesh:Mesh):Void
	{
		reset();

		//collect mesh
		collect(mesh, _disposeSources);

		//collect receiver
		collect(receiver, true);

		//merge to receiver
		merge(receiver);
	}

	private function reset():Void
	{
		_geomVOs = new Vector<GeometryVO>();
	}


	private function merge(destMesh:Mesh):Void
	{
		var i:UInt;
		var subIdx:UInt;
		var destGeom:Geometry;
		var useSubMaterials:Bool;

		destGeom = destMesh.geometry;
		subIdx = destMesh.subMeshes.length;

		// Only apply materials directly to sub-meshes if necessary,
		// i.e. if there is more than one material available.
		useSubMaterials = (_geomVOs.length > 1);

		for (i = 0; i < _geomVOs.length; i++)
		{
			var s:UInt;
			var data:GeometryVO;
			var subs:Vector<ISubGeometry>;

			data = _geomVOs[i];
			subs = GeomUtil.fromVectors(data.vertices, data.indices, data.uvs, data.normals, null, null, null);

			for (s = 0; s < subs.length; s++)
			{
				destGeom.addSubGeometry(subs[s]);

				if (_keepMaterial && useSubMaterials)
					destMesh.subMeshes[subIdx].material = data.material;

				subIdx++;
			}
		}

		if (_keepMaterial && !useSubMaterials && _geomVOs.length)
			destMesh.material = _geomVOs[0].material;
	}

	private function collect(mesh:Mesh, dispose:Bool):Void
	{
		if (mesh.geometry)
		{
			var subIdx:UInt;
			var subGeometries:Vector<ISubGeometry> = mesh.geometry.subGeometries;
			var calc:UInt;
			for (subIdx = 0; subIdx < subGeometries.length; subIdx++)
			{
				var i:UInt;
				var len:UInt;
				var iIdx:UInt, vIdx:UInt, nIdx:UInt, uIdx:UInt;
				var indexOffset:UInt;
				var subGeom:ISubGeometry;
				var vo:GeometryVO;
				var vertices:Vector<Float>;
				var normals:Vector<Float>;
				var vStride:UInt, nStride:UInt, uStride:UInt;
				var vOffs:UInt, nOffs:UInt, uOffs:UInt;
				var vd:Vector<Float>, nd:Vector<Float>, ud:Vector<Float>;

				subGeom = subGeometries[subIdx];
				vd = subGeom.vertexData;
				vStride = subGeom.vertexStride;
				vOffs = subGeom.vertexOffset;
				nd = subGeom.vertexNormalData;
				nStride = subGeom.vertexNormalStride;
				nOffs = subGeom.vertexNormalOffset;
				ud = subGeom.UVData;
				uStride = subGeom.UVStride;
				uOffs = subGeom.UVOffset;

				// Get (or create) a VO for this material
				vo = getSubGeomData(mesh.subMeshes[subIdx].material || mesh.material);

				// Vertices and normals are copied to temporary vectors, to be transformed
				// before concatenated onto those of the data. This is unnecessary if no
				// transformation will be performed, i.e. for object space merging.
				vertices = (_objectSpace) ? vo.vertices : new Vector<Float>();
				normals = (_objectSpace) ? vo.normals : new Vector<Float>();

				// Copy over vertex attributes
				vIdx = vertices.length;
				nIdx = normals.length;
				uIdx = vo.uvs.length;
				len = subGeom.numVertices;
				for (i = 0; i < len; i++)
				{
					// Position
					calc = vOffs + i * vStride;
					vertices[vIdx++] = vd[calc];
					vertices[vIdx++] = vd[calc + 1];
					vertices[vIdx++] = vd[calc + 2];

					// Normal
					calc = nOffs + i * nStride;
					normals[nIdx++] = nd[calc];
					normals[nIdx++] = nd[calc + 1];
					normals[nIdx++] = nd[calc + 2];

					// UV
					calc = uOffs + i * uStride;
					vo.uvs[uIdx++] = ud[calc];
					vo.uvs[uIdx++] = ud[calc + 1];
				}

				// Copy over triangle indices
				indexOffset = vo.vertices.length / 3;
				iIdx = vo.indices.length;
				len = subGeom.numTriangles;
				for (i = 0; i < len; i++)
				{
					calc = i * 3;
					vo.indices[iIdx++] = subGeom.indexData[calc] + indexOffset;
					vo.indices[iIdx++] = subGeom.indexData[calc + 1] + indexOffset;
					vo.indices[iIdx++] = subGeom.indexData[calc + 2] + indexOffset;
				}

				if (!_objectSpace)
				{
					mesh.sceneTransform.transformVectors(vertices, vertices);
					mesh.sceneTransform.transformVectors(normals, normals);

					// Copy vertex data from temporary (transformed) vectors
					vIdx = vo.vertices.length;
					nIdx = vo.normals.length;
					len = vertices.length;
					for (i = 0; i < len; i++)
					{
						vo.vertices[vIdx++] = vertices[i];
						vo.normals[nIdx++] = normals[i];
					}
				}
			}

			if (dispose)
			{
				mesh.geometry.dispose();
			}
		}
	}


	private function getSubGeomData(material:MaterialBase):GeometryVO
	{
		var data:GeometryVO;

		if (_keepMaterial)
		{
			var i:UInt;
			var len:UInt;

			len = _geomVOs.length;
			for (i = 0; i < len; i++)
			{
				if (_geomVOs[i].material == material)
				{
					data = _geomVOs[i];
					break;
				}
			}
		}
		else if (_geomVOs.length)
		{
			// If materials are not to be kept, all data can be
			// put into a single VO, so return that one.
			data = _geomVOs[0];
		}

		// No data (for this material) found, create new.
		if (!data)
		{
			data = new GeometryVO();
			data.vertices = new Vector<Float>();
			data.normals = new Vector<Float>();
			data.uvs = new Vector<Float>();
			data.indices = new Vector<UInt>();
			data.material = material;

			_geomVOs.push(data);
		}

		return data;
	}

	private function parseContainer(object:ObjectContainer3D):Void
	{
		var child:ObjectContainer3D;
		var i:UInt;

		if (Std.is(object,Mesh))
			collect(Mesh(object), _disposeSources);

		for (i in 0...object.numChildren)
		{
			child = object.getChildAt(i);
			parseContainer(child);
		}
	}
}


class GeometryVO
{
	public var uvs:Vector<Float>;
	public var vertices:Vector<Float>;
	public var normals:Vector<Float>;
	public var indices:Vector<UInt>;
	public var material:MaterialBase;

	public function new()
	{
	}
}
