package a3d.tools.commands;


import a3d.core.base.Geometry;
import a3d.core.base.ISubGeometry;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.tools.utils.GeomUtil;



/**
* Class Explode make all vertices and uv's of a mesh unic<code>Explode</code>
*/
class Explode
{

	private var _keepNormals:Bool;

	public function new()
	{
	}

	/**
	*  Apply the explode code to a given ObjectContainer3D.
	* @param	 object				ObjectContainer3D. The target Object3d object.
	* @param	 keepNormals		Bool. If the vertexNormals of the object are preserved. Default is true.
	*/
	public function applyToContainer(ctr:ObjectContainer3D, keepNormals:Bool = true):Void
	{
		_keepNormals = keepNormals;
		parse(ctr);
	}


	public function apply(geom:Geometry, keepNormals:Bool = true):Void
	{
		var i:UInt;

		_keepNormals = keepNormals;

		for (i = 0; i < geom.subGeometries.length; i++)
		{
			explodeSubGeom(geom.subGeometries[i], geom);
		}
	}

	/**
	* recursive parsing of a container.
	*/
	private function parse(object:ObjectContainer3D):Void
	{
		var child:ObjectContainer3D;
		if (object is Mesh && object.numChildren == 0)
			apply(Mesh(object).geometry, _keepNormals);

		for (var i:UInt = 0; i < object.numChildren; ++i)
		{
			child = object.getChildAt(i);
			parse(child);
		}
	}

	private function explodeSubGeom(subGeom:ISubGeometry, geom:Geometry):Void
	{
		var i:UInt;
		var len:UInt;
		var inIndices:Vector<UInt>;
		var outIndices:Vector<UInt>;
		var vertices:Vector<Float>;
		var normals:Vector<Float>;
		var uvs:Vector<Float>;
		var vIdx:UInt, uIdx:UInt;
		var outSubGeoms:Vector<ISubGeometry>;

		var vStride:UInt, nStride:UInt, uStride:UInt;
		var vOffs:UInt, nOffs:UInt, uOffs:UInt;
		var vd:Vector<Float>, nd:Vector<Float>, ud:Vector<Float>;

		vd = subGeom.vertexData;
		vStride = subGeom.vertexStride;
		vOffs = subGeom.vertexOffset;
		nd = subGeom.vertexNormalData;
		nStride = subGeom.vertexNormalStride;
		nOffs = subGeom.vertexNormalOffset;
		ud = subGeom.UVData;
		uStride = subGeom.UVStride;
		uOffs = subGeom.UVOffset;

		inIndices = subGeom.indexData;
		outIndices = new Vector<UInt>(inIndices.length, true);
		vertices = new Vector<Float>(inIndices.length * 3, true);
		normals = new Vector<Float>(inIndices.length * 3, true);
		uvs = new Vector<Float>(inIndices.length * 2, true);

		vIdx = 0;
		uIdx = 0;
		len = inIndices.length;
		for (i = 0; i < len; i++)
		{
			var index:Int;

			index = inIndices[i];
			vertices[vIdx + 0] = vd[vOffs + index * vStride + 0];
			vertices[vIdx + 1] = vd[vOffs + index * vStride + 1];
			vertices[vIdx + 2] = vd[vOffs + index * vStride + 2];

			if (_keepNormals)
			{
				normals[vIdx + 0] = vd[nOffs + index * nStride + 0];
				normals[vIdx + 1] = vd[nOffs + index * nStride + 1];
				normals[vIdx + 2] = vd[nOffs + index * nStride + 2];
			}
			else
			{
				normals[vIdx + 0] = normals[vIdx + 1] = normals[vIdx + 2] = 0;
			}

			uvs[uIdx++] = ud[uOffs + index * uStride + 0];
			uvs[uIdx++] = ud[uOffs + index * uStride + 1];

			vIdx += 3;

			outIndices[i] = i;
		}

		outSubGeoms = GeomUtil.fromVectors(vertices, outIndices, uvs, normals, null, null, null);
		geom.removeSubGeometry(subGeom);
		for (i = 0; i < outSubGeoms.length; i++)
		{
			outSubGeoms[i].autoDeriveVertexNormals = !_keepNormals;
			geom.addSubGeometry(outSubGeoms[i]);
		}
	}
}
