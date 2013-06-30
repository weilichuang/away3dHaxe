package a3d.entities.extrusions;

import flash.geom.Vector3D;
import flash.Vector;

import a3d.bounds.BoundingVolumeBase;
import a3d.core.base.Geometry;
import a3d.core.base.SubGeometry;
import a3d.core.base.SubMesh;
import a3d.core.base.data.UV;
import a3d.core.base.data.Vertex;
import a3d.entities.Mesh;
import a3d.materials.MaterialBase;
import a3d.tools.helpers.MeshHelper;

class SkinExtrude extends Mesh
{
	private const LIMIT:UInt = 196605;
	private var _tmpVectors:Vector<Float>;
	private var _subGeometry:SubGeometry;
	private var _indice:UInt;
	private var _uva:UV;
	private var _uvb:UV;
	private var _uvc:UV;
	private var _uvd:UV;
	private var _va:Vertex;
	private var _vb:Vertex;
	private var _vc:Vertex;
	private var _vd:Vertex;
	private var _uvs:Vector<Float>;
	private var _vertices:Vector<Float>;
	private var _indices:Vector<UInt>;
	private var _geomDirty:Bool = true;

	private var _profiles:Vector<Vector<Vector3D>>;
	private var _subdivision:UInt;
	private var _centerMesh:Bool;
	private var _closeShape:Bool;
	private var _coverAll:Bool;
	private var _flip:Bool;

	/*
	* Class SkinExtrude generates (and becomes) a mesh from a multidimentional vector of vector3D's . <code>SkinExtrude</code>
	*@param	material			MaterialBase. The SkinExtrude (Mesh) material
	*@param	profiles			Vector.&;t;Vector.&lt;Vector3D&gt;&gt; Multidimentional vector of vectors holding the vector3d's defining the shape. &lt; &lt;va0, va1&gt;, &lt;vb0, vb1&gt; &gt;
	*@param	subdivision		[optional] uint. The _subdivision between vectors. Default is 1.
	*@param	centerMesh	[optional] Bool. If the final mesh must be _centerMeshed. Default is false.
	*@param	closeShape		[optional] Bool. If the last vector must be linked to the first vector. Default is false.
	*@param	coverAll			[optional] Bool. If the mapping is stretched over the entire mesh or from vector to vector. Default is false.
	*@param	flip				[optional] Bool. If the faces need to be inverted. Default is false.
	*/
	public function new(material:MaterialBase, profiles:Vector<Vector<Vector3D>>, subdivision:UInt = 1, centerMesh:Bool = false, closeShape:Bool = false, coverAll:Bool = false, flip:Bool =
		false)
	{
		var geom:Geometry = new Geometry();
		_subGeometry = new SubGeometry();
		geom.addSubGeometry(_subGeometry);
		super(geom, material);

		_profiles = profiles;
		_subdivision = subdivision;
		_centerMesh = centerMesh;
		_closeShape = closeShape;
		_coverAll = coverAll;
		_flip = flip;
	}

	/**
	 * Defines if the texture(s) should be stretched to cover the entire mesh or per step between segments. Defaults to false.
	 */
	private function get_profiles():Vector<Vector<Vector3D>>
	{
		return _profiles;
	}

	private function set_profiles(val:Vector<Vector<Vector3D>>):Void
	{
		_profiles = val;
		invalidateGeometry();
	}

	/**
	 * Defines if the texture(s) should be stretched to cover the entire mesh or per step between segments. Defaults to false.
	 */
	private function get_coverAll():Bool
	{
		return _coverAll;
	}

	private function set_coverAll(val:Bool):Void
	{
		if (_coverAll == val)
			return;

		_coverAll = val;
		invalidateGeometry();
	}

	/**
	* Defines if the last vector of Vector3D are joined to the first one, closing the shape. works from 3 vector.&lt;Vector3D&gt; entered.
	*/
	private function get_closeShape():Bool
	{
		return _closeShape;
	}

	private function set_closeShape(val:Bool):Void
	{
		if (_closeShape == val)
			return;

		_closeShape = val;
		invalidateGeometry();
	}

	/**
	 * Defines if the face orientatio needs to be inverted
	 */
	private function get_flip():Bool
	{
		return _flip;
	}

	private function set_flip(val:Bool):Void
	{
		if (_flip == val)
			return;

		_flip = val;
		invalidateGeometry();
	}

	/**
	 * Defines whether the mesh is _centerMeshed of not after generation
	 */
	private function get_centerMesh():Bool
	{
		return _centerMesh;
	}

	private function set_centerMesh(val:Bool):Void
	{
		if (_centerMesh == val)
			return;

		_centerMesh = val;

		if (_centerMesh && _subGeometry.vertexData.length > 0)
		{
			MeshHelper.applyPosition(this, (this.minX + this.maxX) * .5, (this.minY + this.maxY) * .5, (this.minZ + this.maxZ) * .5);
		}
		else
		{
			invalidateGeometry();
		}
	}

	private function get_subdivision():Float
	{
		return _subdivision;
	}

	private function set_subdivision(val:Float):Void
	{
		if (_subdivision == val)
			return;

		_subdivision = val;
		invalidateGeometry();
	}

	// building
	private function buildExtrude():Void
	{
		_geomDirty = false;
		if (_profiles.length > 1 && _profiles[0].length > 1 && _profiles[1].length > 1)
		{
			initHolders();
			if (_closeShape && _profiles.length < 3)
				_closeShape = false;
			generate();
		}
		else
		{
			throw new Error("SkinExtrude: 1 multidimentional Vector<Vector<Vector3D>> with minimum 2 children Vector<Vector3D>. Each child Vector must hold at least 2 Vector3D.");
		}

		if (_centerMesh)
			MeshHelper.recenter(this);

		_tmpVectors = null;
	}

	private function generate():Void
	{
		var uvlength:Int = (_closeShape) ? _profiles.length : _profiles.length - 1;
		for (var i:Int = 0; i < _profiles.length - 1; ++i)
		{
			_tmpVectors = new Vector<Float>();
			extrude(_profiles[i], _profiles[i + 1], (1 / uvlength) * i, uvlength);
		}

		if (_closeShape)
		{
			_tmpVectors = new Vector<Float>();
			extrude(_profiles[_profiles.length - 1], _profiles[0], (1 / uvlength) * i, uvlength);
		}

		_subGeometry.updateVertexData(_vertices);
		_subGeometry.updateIndexData(_indices);
		_subGeometry.updateUVData(_uvs);
		_uva = _uvb = _uvc = _uvd = null;
		_va = _vb = _vc = _vd = null;
		_uvs = _vertices = null;
		_indices = null;
	}

	private function extrude(vectsA:Vector<Vector3D>, vectsB:Vector<Vector3D>, vscale:Float, indexv:Int):Void
	{
		var i:Int;
		var j:Int;
		var k:Int;
		var stepx:Float;
		var stepy:Float;
		var stepz:Float;

		var u1:Float;
		var u2:Float;
		var index:Int = 0;
		var vertIndice:UInt;

		var bu:Float = 0;
		var bincu:Float = 1 / (vectsA.length - 1);
		var v1:Float = 0;
		var v2:Float = 0;

		for (i = 0; i < vectsA.length; ++i)
		{
			stepx = (vectsB[i].x - vectsA[i].x) / _subdivision;
			stepy = (vectsB[i].y - vectsA[i].y) / _subdivision;
			stepz = (vectsB[i].z - vectsA[i].z) / _subdivision;

			for (j = 0; j < _subdivision + 1; ++j)
				_tmpVectors.push(vectsA[i].x + (stepx * j), vectsA[i].y + (stepy * j), vectsA[i].z + (stepz * j));

		}

		for (i = 0; i < vectsA.length - 1; ++i)
		{

			u1 = bu;
			bu += bincu;
			u2 = bu;

			for (j = 0; j < _subdivision; ++j)
			{

				v1 = (_coverAll) ? vscale + ((j / _subdivision) / indexv) : j / _subdivision;
				v2 = (_coverAll) ? vscale + (((j + 1) / _subdivision) / indexv) : (j + 1) / _subdivision;

				_uva.v = u1;
				_uva.u = v1;
				_uvb.v = u1;
				_uvb.u = v2;
				_uvc.v = u2;
				_uvc.u = v2;
				_uvd.v = u2;
				_uvd.u = v1;

				_va.x = _tmpVectors[vertIndice = (index + j) * 3];
				_va.y = _tmpVectors[vertIndice + 1];
				_va.z = _tmpVectors[vertIndice + 2];

				_vb.x = _tmpVectors[vertIndice = (index + j + 1) * 3];
				_vb.y = _tmpVectors[vertIndice + 1];
				_vb.z = _tmpVectors[vertIndice + 2];

				_vc.x = _tmpVectors[vertIndice = (index + j + _subdivision + 2) * 3];
				_vc.y = _tmpVectors[vertIndice + 1];
				_vc.z = _tmpVectors[vertIndice + 2];

				_vd.x = _tmpVectors[vertIndice = (index + j + _subdivision + 1) * 3];
				_vd.y = _tmpVectors[vertIndice + 1];
				_vd.z = _tmpVectors[vertIndice + 2];

				if (_vertices.length == LIMIT)
				{
					_subGeometry.updateVertexData(_vertices);
					_subGeometry.updateIndexData(_indices);
					_subGeometry.updateUVData(_uvs);

					_subGeometry = new SubGeometry();
					this.geometry.addSubGeometry(_subGeometry);
					_subGeometry.autoDeriveVertexNormals = true;
					_subGeometry.autoDeriveVertexTangents = true;
					_uvs = new Vector<Float>();
					_vertices = new Vector<Float>();
					_indices = new Vector<UInt>();
					_indice = 0;
				}

				if (_flip)
				{

					_vertices.push(_va.x, _va.y, _va.z, _vb.x, _vb.y, _vb.z, _vc.x, _vc.y, _vc.z);
					_uvs.push(_uva.u, _uva.v, _uvb.u, _uvb.v, _uvc.u, _uvc.v);

					_vertices.push(_va.x, _va.y, _va.z, _vc.x, _vc.y, _vc.z, _vd.x, _vd.y, _vd.z);
					_uvs.push(_uva.u, _uva.v, _uvc.u, _uvc.v, _uvd.u, _uvd.v);


				}
				else
				{

					_vertices.push(_vb.x, _vb.y, _vb.z, _va.x, _va.y, _va.z, _vc.x, _vc.y, _vc.z);
					_uvs.push(_uvb.u, _uvb.v, _uva.u, _uva.v, _uvc.u, _uvc.v);

					_vertices.push(_vc.x, _vc.y, _vc.z, _va.x, _va.y, _va.z, _vd.x, _vd.y, _vd.z);
					_uvs.push(_uvc.u, _uvc.v, _uva.u, _uva.v, _uvd.u, _uvd.v);
				}

				for (k = 0; k < 6; ++k)
				{
					_indices[_indice] = _indice;
					_indice++;
				}

			}

			index += _subdivision + 1;
		}
	}

	private function initHolders():Void
	{
		_indice = 0;
		_uva = new UV(0, 0);
		_uvb = new UV(0, 0);
		_uvc = new UV(0, 0);
		_uvd = new UV(0, 0);
		_va = new Vertex(0, 0, 0);
		_vb = new Vertex(0, 0, 0);
		_vc = new Vertex(0, 0, 0);
		_vd = new Vertex(0, 0, 0);
		_uvs = new Vector<Float>();
		_vertices = new Vector<Float>();
		_indices = new Vector<UInt>();

		_subGeometry.autoDeriveVertexNormals = true;
		_subGeometry.autoDeriveVertexTangents = true;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_bounds():BoundingVolumeBase
	{
		if (_geomDirty)
			buildExtrude();

		return super.bounds;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_geometry():Geometry
	{
		if (_geomDirty)
			buildExtrude();

		return super.geometry;
	}

	/**
	 * @inheritDoc
	 */
	override private function get_subMeshes():Vector<SubMesh>
	{
		if (_geomDirty)
			buildExtrude();

		return super.subMeshes;
	}

	/**
	 * Invalidates the geometry, causing it to be rebuillded when requested.
	 */
	private function invalidateGeometry():Void
	{
		_geomDirty = true;
		invalidateBounds();
	}

}
