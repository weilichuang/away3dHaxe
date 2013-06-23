package a3d.tools.utils
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	
	import a3d.entities.Entity;
	import a3d.entities.Mesh;
	import a3d.entities.ObjectContainer3D;

	

	/**
	* Helper Class to retrieve objects bounds <code>Bounds</code>
	*/

	class Bounds
	{

		private static var _minX:Float;
		private static var _minY:Float;
		private static var _minZ:Float;
		private static var _maxX:Float;
		private static var _maxY:Float;
		private static var _maxZ:Float;
		private static var _defaultPosition:Vector3D = new Vector3D(0.0, 0.0, 0.0);
		private static var _containers:Dictionary;

		/**
		* Calculate the bounds of a Mesh object
		* @param mesh		Mesh. The Mesh to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getMeshBounds(mesh:Mesh):Void
		{
			getObjectContainerBounds(mesh);
		}

		/**
		* Calculate the bounds of an ObjectContainer3D object
		* @param container		ObjectContainer3D. The ObjectContainer3D to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getObjectContainerBounds(container:ObjectContainer3D, worldBased:Bool = true):Void
		{
			reset();

			parseObjectContainerBounds(container);

			if (isInfinite(_minX) || isInfinite(_minY) || isInfinite(_minZ) ||
				isInfinite(_maxX) || isInfinite(_maxY) || isInfinite(_maxZ))
				return;

			// Transform min/max values to the scene if required
			if (worldBased)
			{
				var b:Vector<Float> = Vector<Float>([Infinity, Infinity, Infinity, -Infinity, -Infinity, -Infinity]);
				var c:Vector<Float> = getBoundsCorners(_minX, _minY, _minZ, _maxX, _maxY, _maxZ);
				transformContainer(b, c, container.sceneTransform);
				_minX = b[0];
				_minY = b[1];
				_minZ = b[2];
				_maxX = b[3];
				_maxY = b[4];
				_maxZ = b[5];
			}
		}

		/**
		* Calculate the bounds from a vector of number representing the vertices. &lt;x,y,z,x,y,z.....&gt;
		* @param vertices		Vector.&lt;Number&gt;. The vertices to get the bounds from.
		* Use the getters of this class to retrieve the results
		*/
		public static function getVerticesVectorBounds(vertices:Vector<Float>):Void
		{
			reset();
			var l:UInt = vertices.length;
			if (l % 3 != 0)
				return;

			var x:Float;
			var y:Float;
			var z:Float;

			for (var i:UInt = 0; i < l; i += 3)
			{
				x = vertices[i];
				y = vertices[i + 1];
				z = vertices[i + 2];

				if (x < _minX)
					_minX = x;
				if (x > _maxX)
					_maxX = x;

				if (y < _minY)
					_minY = y;
				if (y > _maxY)
					_maxY = y;

				if (z < _minZ)
					_minZ = z;
				if (z > _maxZ)
					_maxZ = z;
			}
		}

		/**
		* @return the smalest x value
		*/
		public static function get_minX():Float
		{
			return _minX;
		}

		/**
		* @return the smalest y value
		*/
		public static function get_minY():Float
		{
			return _minY;
		}

		/**
		* @return the smalest z value
		*/
		public static function get_minZ():Float
		{
			return _minZ;
		}

		/**
		* @return the biggest x value
		*/
		public static function get_maxX():Float
		{
			return _maxX;
		}

		/**
		* @return the biggest y value
		*/
		public static function get_maxY():Float
		{
			return _maxY;
		}

		/**
		* @return the biggest z value
		*/
		public static function get_maxZ():Float
		{
			return _maxZ;
		}

		/**
		* @return the width value from the bounds
		*/
		public static function get_width():Float
		{
			return _maxX - _minX;
		}

		/**
		* @return the height value from the bounds
		*/
		public static function get_height():Float
		{
			return _maxY - _minY;
		}

		/**
		* @return the depth value from the bounds
		*/
		public static function get_depth():Float
		{
			return _maxZ - _minZ;
		}

		private static function reset():Void
		{
			_containers = new Dictionary();
			_minX = _minY = _minZ = Infinity;
			_maxX = _maxY = _maxZ = -Infinity;
			_defaultPosition.x = 0.0;
			_defaultPosition.y = 0.0;
			_defaultPosition.z = 0.0;
		}

		private static function parseObjectContainerBounds(obj:ObjectContainer3D, parentTransform:Matrix3D = null):Void
		{
			if (!obj.visible)
				return;

			var containerBounds:Vector<Float> = _containers[obj] ||= Vector<Float>([Infinity, Infinity, Infinity, -Infinity, -Infinity, -Infinity]);

			var child:ObjectContainer3D;
			var isEntity:Entity = obj as Entity;
			var containerTransform:Matrix3D = new Matrix3D();

			if (isEntity && parentTransform)
			{
				parseObjectBounds(obj, parentTransform);

				containerTransform = obj.transform.clone();
				if (parentTransform)
					containerTransform.append(parentTransform);
			}
			else if (isEntity && !parentTransform)
			{
				var mat:Matrix3D = obj.transform.clone();
				mat.invert();
				parseObjectBounds(obj, mat);
			}

			for (var i:UInt = 0; i < obj.numChildren; ++i)
			{
				child = obj.getChildAt(i);
				parseObjectContainerBounds(child, containerTransform);
			}

			var parentBounds:Vector<Float> = _containers[obj.parent];
			if (!isEntity && parentTransform)
			{
				parseObjectBounds(obj, parentTransform, true);
			}

			if (parentBounds)
			{
				parentBounds[0] = Math.min(parentBounds[0], containerBounds[0]);
				parentBounds[1] = Math.min(parentBounds[1], containerBounds[1]);
				parentBounds[2] = Math.min(parentBounds[2], containerBounds[2]);
				parentBounds[3] = Math.max(parentBounds[3], containerBounds[3]);
				parentBounds[4] = Math.max(parentBounds[4], containerBounds[4]);
				parentBounds[5] = Math.max(parentBounds[5], containerBounds[5]);
			}
			else
			{
				_minX = containerBounds[0];
				_minY = containerBounds[1];
				_minZ = containerBounds[2];
				_maxX = containerBounds[3];
				_maxY = containerBounds[4];
				_maxZ = containerBounds[5];
			}
		}

		private static function isInfinite(value:Float):Bool
		{
			return value == Number.POSITIVE_INFINITY || value == Number.NEGATIVE_INFINITY;
		}

		private static function parseObjectBounds(oC:ObjectContainer3D, parentTransform:Matrix3D = null, resetBounds:Bool = false):Void
		{
			var e:Entity = oC as Entity;
			var corners:Vector<Float>;
			var mat:Matrix3D = oC.transform.clone();
			var cB:Vector<Float> = _containers[oC];
			if (e)
			{
				if (isInfinite(e.minX) || isInfinite(e.minY) || isInfinite(e.minZ) ||
					isInfinite(e.maxX) || isInfinite(e.maxY) || isInfinite(e.maxZ))
					return;

				corners = getBoundsCorners(e.minX, e.minY, e.minZ, e.maxX, e.maxY, e.maxZ);
				if (parentTransform)
					mat.append(parentTransform);
			}
			else
			{
				corners = getBoundsCorners(cB[0], cB[1], cB[2], cB[3], cB[4], cB[5]);
				if (parentTransform)
					mat.prepend(parentTransform);
			}

			if (resetBounds)
			{
				cB[0] = cB[1] = cB[2] = Infinity;
				cB[3] = cB[4] = cB[5] = -Infinity;
			}

			transformContainer(cB, corners, mat);
		}

		private static function getBoundsCorners(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Vector<Float>
		{
			return Vector<Float>([
				minX, minY, minZ,
				minX, minY, maxZ,
				minX, maxY, minZ,
				minX, maxY, maxZ,
				maxX, minY, minZ,
				maxX, minY, maxZ,
				maxX, maxY, minZ,
				maxX, maxY, maxZ
				]);
		}

		private static function transformContainer(bounds:Vector<Float>, corners:Vector<Float>, matrix:Matrix3D):Void
		{

			matrix.transformVectors(corners, corners);

			var x:Float;
			var y:Float;
			var z:Float;

			var pCtr:Int = 0;
			while (pCtr < corners.length)
			{
				x = corners[pCtr++];
				y = corners[pCtr++];
				z = corners[pCtr++];

				if (x < bounds[0])
					bounds[0] = x;
				if (x > bounds[3])
					bounds[3] = x;

				if (y < bounds[1])
					bounds[1] = y;
				if (y > bounds[4])
					bounds[4] = y;

				if (z < bounds[2])
					bounds[2] = z;
				if (z > bounds[5])
					bounds[5] = z;
			}
		}
	}
}
