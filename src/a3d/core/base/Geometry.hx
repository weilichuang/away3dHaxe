package a3d.core.base;

import flash.geom.Matrix3D;
import flash.Vector.Vector;


import a3d.events.GeometryEvent;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;



/**
 * Geometry is a collection of SubGeometries, each of which contain the actual geometrical data such as vertices,
 * normals, uvs, etc. It also contains a reference to an animation class, which defines how the geometry moves.
 * A Geometry object is assigned to a Mesh, a scene graph occurence of the geometry, which in turn assigns
 * the SubGeometries to its respective SubMesh objects.
 *
 *
 *
 * @see a3d.core.base.SubGeometry
 * @see a3d.scenegraph.Mesh
 */
class Geometry extends NamedAssetBase implements IAsset
{
	private var _subGeometries:Vector<ISubGeometry>;

	/**
	 * Creates a new Geometry object.
	 */
	public function new()
	{
		_subGeometries = new Vector<ISubGeometry>();
	}
	
	public var assetType(get, null):String;
	private inline function get_assetType():String
	{
		return AssetType.GEOMETRY;
	}

	/**
	 * A collection of SubGeometry objects, each of which contain geometrical data such as vertices, normals, etc.
	 */
	public var subGeometries(get, null):Vector<ISubGeometry>;
	private inline function get_subGeometries():Vector<ISubGeometry>
	{
		return _subGeometries;
	}

	public function applyTransformation(transform:Matrix3D):Void
	{
		var len:Int = _subGeometries.length;
		for (i in 0...len)
		{
			_subGeometries[i].applyTransformation(transform);
		}
	}

	/**
	 * Adds a new SubGeometry object to the list.
	 * @param subGeometry The SubGeometry object to be added.
	 */
	public function addSubGeometry(subGeometry:ISubGeometry):Void
	{
		_subGeometries.push(subGeometry);

		subGeometry.parentGeometry = this;
		
		if (hasEventListener(GeometryEvent.SUB_GEOMETRY_ADDED))
			dispatchEvent(new GeometryEvent(GeometryEvent.SUB_GEOMETRY_ADDED, subGeometry));

		invalidateBounds(subGeometry);
	}

	/**
	 * Removes a new SubGeometry object from the list.
	 * @param subGeometry The SubGeometry object to be removed.
	 */
	public function removeSubGeometry(subGeometry:ISubGeometry):Void
	{
		_subGeometries.splice(_subGeometries.indexOf(subGeometry), 1);
		subGeometry.parentGeometry = null;
		
		if (hasEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED))
			dispatchEvent(new GeometryEvent(GeometryEvent.SUB_GEOMETRY_REMOVED, subGeometry));

		invalidateBounds(subGeometry);
	}

	/**
	 * Clones the geometry.
	 * @return An exact duplicate of the current Geometry object.
	 */
	public function clone():Geometry
	{
		var clone:Geometry = new Geometry();
		var len:Int = _subGeometries.length;
		for (i in 0...len)
		{
			clone.addSubGeometry(_subGeometries[i].clone());
		}
		return clone;
	}

	/**
	 * Scales the geometry.
	 * @param scale The amount by which to scale.
	 */
	public function scale(scale:Float):Void
	{
		var len:Int = _subGeometries.length;
		for (i in 0...len)
			_subGeometries[i].scale(scale);
	}

	/**
	 * Clears all resources used by the Geometry object, including SubGeometries.
	 */
	public function dispose():Void
	{
		var len:Int = _subGeometries.length;
		for (i in 0...len)
		{
			var subGeom:ISubGeometry = _subGeometries[0];
			removeSubGeometry(subGeom);
			subGeom.dispose();
		}
	}

	/**
	 * Scales the uv coordinates (tiling)
	 * @param scaleU The amount by which to scale on the u axis. Default is 1;
	 * @param scaleV The amount by which to scale on the v axis. Default is 1;
	 */
	public function scaleUV(scaleU:Float = 1, scaleV:Float = 1):Void
	{
		var len:Int = _subGeometries.length;
		for (i in 0...len)
			_subGeometries[i].scaleUV(scaleU, scaleV);
	}

	/**
	 * Updates the SubGeometries so all vertex data is represented in different buffers.
	 * Use this for compatibility with Pixel Bender and PBPickingCollider
	 */
	public function convertToSeparateBuffers():Void
	{
		var subGeom:ISubGeometry;

		var _removableCompactSubGeometries:Vector<CompactSubGeometry> = new Vector<CompactSubGeometry>();

		var len:Int = _subGeometries.length;
		for (i in 0...len)
		{
			subGeom = _subGeometries[i];
			if (Std.is(subGeom,SubGeometry))
				continue;

			_removableCompactSubGeometries.push(subGeom);
			addSubGeometry(subGeom.cloneWithSeperateBuffers());
		}

		for(s in _removableCompactSubGeometries)
		{
			removeSubGeometry(s);
			s.dispose();
		}
	}

	public function validate():Void
	{
		// To be overridden when necessary
	}

	public function invalidateBounds(subGeom:ISubGeometry):Void
	{
		if (hasEventListener(GeometryEvent.BOUNDS_INVALID))
			dispatchEvent(new GeometryEvent(GeometryEvent.BOUNDS_INVALID, subGeom));
	}
}
