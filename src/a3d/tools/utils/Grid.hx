package a3d.tools.utils;


import a3d.core.base.Geometry;
import a3d.core.base.ISubGeometry;
import a3d.core.base.SubGeometry;
import a3d.entities.Mesh;
import a3d.entities.ObjectContainer3D;
import a3d.math.FMath;
import flash.Vector;



/**
 * Class Grid snaps vertexes or meshes according to a given grid unit.<code>Grid</code>
 */
class Grid
{
	/**
	* Defines if the grid unit.
	*/
	public var unit(get, set):Float;
	/**
	* Defines if the grid unit is applied in objectspace or worldspace. In worldspace, objects positions are affected.
	*/
	public var objectSpace(get, set):Bool;

	private var _unit:Float;
	private var _objectSpace:Bool;

	/**
	*  Grid snaps vertexes according to a given grid unit
	* @param	 unit						[optional] Number. The grid unit. Default is 1.
	* @param	 objectSpace			[optional] Bool. Apply only to vertexes in geometry objectspace when Object3D are considered. Default is false.
	*/

	public function new(unit:Float = 1, objectSpace:Bool = false):Void
	{
		_objectSpace = objectSpace;
		_unit = Math.abs(unit);
	}

	/**
	*  Apply the grid code to a given object3D. If type ObjectContainer3D, all children Mesh vertices will be affected.
	* @param	 object3d		Object3D. The Object3d to snap to grid.
	* @param	 dovert			[optional]. If the vertices must be handled or not. When false only object position is snapped to grid. Default is false.
	*/
	public function snapObject(object3d:ObjectContainer3D, dovert:Bool = false):Void
	{
		parse(object3d, dovert);
	}

	/**
	*  Snaps to grid a given Vector.&lt;Number&gt; of vertices
	* @param	 vertices		Vector.&lt;Number&gt;. The vertices vector
	*/
	public function snapVertices(vertices:Vector<Float>):Vector<Float>
	{
		for (i in 0...vertices.length)
			vertices[i] -= vertices[i] % _unit;

		return vertices;
	}

	/**
	*  Apply the grid code to a single mesh
	* @param	 mesh		Mesh. The mesh to snap to grid. Vertices are affected by default. Mesh position is snapped if grid.objectSpace is true;
	*/
	public function snapMesh(mesh:Mesh):Void
	{
		if (!_objectSpace)
		{
			mesh.scenePosition.x -= mesh.scenePosition.x % _unit;
			mesh.scenePosition.y -= mesh.scenePosition.y % _unit;
			mesh.scenePosition.z -= mesh.scenePosition.z % _unit;
		}
		snap(mesh);
	}

	
	private function set_unit(val:Float):Float
	{
		_unit = FMath.fabs(val);
		return _unit = (_unit == 0) ? .001 : _unit;
	}

	private function get_unit():Float
	{
		return _unit;
	}

	
	private function set_objectSpace(b:Bool):Bool
	{
		return _objectSpace = b;
	}

	private function get_objectSpace():Bool
	{
		return _objectSpace;
	}

	private function parse(object3d:ObjectContainer3D, dovert:Bool = true):Void
	{
		var child:ObjectContainer3D;

		if (!_objectSpace)
		{
			object3d.scenePosition.x -= object3d.scenePosition.x % _unit;
			object3d.scenePosition.y -= object3d.scenePosition.y % _unit;
			object3d.scenePosition.z -= object3d.scenePosition.z % _unit;
		}

		if (Std.is(object3d,Mesh) && object3d.numChildren == 0 && dovert)
			snap(Std.instance(object3d,Mesh));

		for (i in 0...object3d.numChildren)
		{
			child = object3d.getChildAt(i);
			parse(child, dovert);
		}
	}

	private function snap(mesh:Mesh):Void
	{
		var geometry:Geometry = mesh.geometry;
		var geometries:Vector<ISubGeometry> = geometry.subGeometries;
		var numSubGeoms:Int = geometries.length;

		var vertices:Vector<Float>;
		var j:Int;
		var vecLength:Int;
		var subGeom:SubGeometry;
		var stride:Int;

		for (i in 0...numSubGeoms)
		{
			subGeom = Std.instance(geometries[i],SubGeometry);
			vertices = subGeom.vertexData;
			vecLength = vertices.length;
			stride = subGeom.vertexStride;
			
			j = subGeom.vertexOffset;
			while (j < vecLength)
			{
				vertices[j] -= vertices[j] % _unit;
				vertices[j + 1] -= vertices[j + 1] % _unit;
				vertices[j + 2] -= vertices[j + 2] % _unit;
				
				j += stride;
			}

			subGeom.updateVertexData(vertices);
		}
	}

}
