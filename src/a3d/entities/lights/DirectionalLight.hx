package a3d.entities.lights;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;


import a3d.bounds.BoundingVolumeBase;
import a3d.bounds.NullBounds;
import a3d.core.base.IRenderable;
import a3d.core.partition.DirectionalLightNode;
import a3d.core.partition.EntityNode;
import a3d.entities.lights.shadowmaps.DirectionalShadowMapper;
import a3d.entities.lights.shadowmaps.ShadowMapperBase;
import a3d.math.Matrix3DUtils;



/**
 * DirectionalLight represents an idealized light "at infinity", to be used for distant light sources such as the sun.
 * In any position in the scene, the light raytracing will always be parallel.
 * Although the position of the light does not impact its effect, it can be used along with lookAt to intuitively
 * create day cycles by orbiting the position around a center point and using lookAt at that position.
 */
class DirectionalLight extends LightBase
{
	private var _direction:Vector3D;
	private var _tmpLookAt:Vector3D;
	private var _sceneDirection:Vector3D;
	private var _projAABBPoints:Vector<Float>;

	/**
	 * Creates a new DirectionalLight object.
	 * @param xDir The x-component of the light's directional vector.
	 * @param yDir The y-component of the light's directional vector.
	 * @param zDir The z-component of the light's directional vector.
	 */
	public function DirectionalLight(xDir:Float = 0, yDir:Float = -1, zDir:Float = 1)
	{
		super();
		direction = new Vector3D(xDir, yDir, zDir);
		_sceneDirection = new Vector3D();
	}

	override private function createEntityPartitionNode():EntityNode
	{
		return new DirectionalLightNode(this);
	}

	/**
	 * The direction of the light in scene coordinates.
	 */
	private inline function get_sceneDirection():Vector3D
	{
		if (_sceneTransformDirty)
			updateSceneTransform();
		return _sceneDirection;
	}

	/**
	 * The direction of the light.
	 */
	private inline function get_direction():Vector3D
	{
		return _direction;
	}

	private inline function set_direction(value:Vector3D):Void
	{
		_direction = value;
		//lookAt(new Vector3D(x + _direction.x, y + _direction.y, z + _direction.z));
		if (!_tmpLookAt)
			_tmpLookAt = new Vector3D();
		_tmpLookAt.x = x + _direction.x;
		_tmpLookAt.y = y + _direction.y;
		_tmpLookAt.z = z + _direction.z;

		lookAt(_tmpLookAt);
	}

	/**
	 * @inheritDoc
	 */
	override private function getDefaultBoundingVolume():BoundingVolumeBase
	{
		// directional lights are to be considered global, hence always in view
		return new NullBounds();
	}

	/**
	 * @inheritDoc
	 */
	override private function updateBounds():Void
	{
	}


	/**
	 * @inheritDoc
	 */
	override private function updateSceneTransform():Void
	{
		super.updateSceneTransform();
		sceneTransform.copyColumnTo(2, _sceneDirection);
		_sceneDirection.normalize();
	}

	override private function createShadowMapper():ShadowMapperBase
	{
		return new DirectionalShadowMapper();
	}

	/**
	 * @inheritDoc
	 */
	override public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D
	{
		var raw:Vector<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
		var bounds:BoundingVolumeBase = renderable.sourceEntity.bounds;
		var m:Matrix3D = new Matrix3D();

		m.copyFrom(renderable.sceneTransform);
		m.append(inverseSceneTransform);

		if (!_projAABBPoints)
			_projAABBPoints = new Vector<Float>();
		m.transformVectors(bounds.aabbPoints, _projAABBPoints);

		var xMin:Float = Number.POSITIVE_INFINITY, xMax:Float = Number.NEGATIVE_INFINITY;
		var yMin:Float = Number.POSITIVE_INFINITY, yMax:Float = Number.NEGATIVE_INFINITY;
		var zMin:Float = Number.POSITIVE_INFINITY, zMax:Float = Number.NEGATIVE_INFINITY;
		var d:Float;
		for (var i:Int = 0; i < 24; )
		{
			d = _projAABBPoints[i++];
			if (d < xMin)
				xMin = d;
			if (d > xMax)
				xMax = d;
			d = _projAABBPoints[i++];
			if (d < yMin)
				yMin = d;
			if (d > yMax)
				yMax = d;
			d = _projAABBPoints[i++];
			if (d < zMin)
				zMin = d;
			if (d > zMax)
				zMax = d;
		}

		var invXRange:Float = 1 / (xMax - xMin);
		var invYRange:Float = 1 / (yMax - yMin);
		var invZRange:Float = 1 / (zMax - zMin);
		raw[0] = 2 * invXRange;
		raw[5] = 2 * invYRange;
		raw[10] = invZRange;
		raw[12] = -(xMax + xMin) * invXRange;
		raw[13] = -(yMax + yMin) * invYRange;
		raw[14] = -zMin * invZRange;
		raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
		raw[15] = 1;

		if (target == null)
			target = new Matrix3D();
		target.copyRawDataFrom(raw);
		target.prepend(m);

		return target;
	}
}
