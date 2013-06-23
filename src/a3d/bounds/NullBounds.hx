package a3d.bounds;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import a3d.core.base.Geometry;
import a3d.math.Plane3D;
import a3d.math.PlaneClassification;
import a3d.entities.primitives.WireframePrimitiveBase;
import a3d.entities.primitives.WireframeSphere;

/**
 * NullBounds represents a debug bounding "volume" that is either considered always in, or always out of the frustum.
 * NullBounds is useful for entities that are always considered in the frustum, such as directional lights or skyboxes.
 */
class NullBounds extends BoundingVolumeBase
{
	private var _alwaysIn:Bool;
	private var _renderable:WireframePrimitiveBase;

	public function new(alwaysIn:Bool = true, renderable:WireframePrimitiveBase = null)
	{
		super();
		_alwaysIn = alwaysIn;
		_renderable = renderable;
		_max.x = _max.y = _max.z = Number.POSITIVE_INFINITY;
		_min.x = _min.y = _min.z = _alwaysIn ? Number.NEGATIVE_INFINITY : Number.POSITIVE_INFINITY;
	}

	override public function clone():BoundingVolumeBase
	{
		return new NullBounds(_alwaysIn);
	}

	override private function createBoundingRenderable():WireframePrimitiveBase
	{
		return _renderable || new WireframeSphere(100, 16, 12, 0xffffff, 0.5);
	}

	/**
	 * @inheritDoc
	 */
	override public function isInFrustum(planes:Vector<Plane3D>, numPlanes:Int):Bool
	{
		planes = planes;
		numPlanes = numPlanes;
		return _alwaysIn;
	}

	/**
	 * @inheritDoc
	 */
	override public function fromGeometry(geometry:Geometry):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	override public function fromSphere(center:Vector3D, radius:Float):Void
	{
	}

	/**
	 * @inheritDoc
	 */
	override public function fromExtremes(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void
	{
	}

	override public function classifyToPlane(plane:Plane3D):Int
	{
		plane = plane;
		return PlaneClassification.INTERSECT;
	}

	override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):Void
	{
		matrix = matrix;
		_alwaysIn = NullBounds(bounds)._alwaysIn;
	}
}
