package a3d.entities.lights.shadowmaps;


import a3d.entities.Camera3D;
import flash.Vector;



class NearDirectionalShadowMapper extends DirectionalShadowMapper
{
	private var _coverageRatio:Float;

	public function new(coverageRatio:Float = .5)
	{
		super();
		this.coverageRatio = coverageRatio;
	}

	/**
	 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
	 */
	private inline function get_coverageRatio():Float
	{
		return _coverageRatio;
	}

	private inline function set_coverageRatio(value:Float):Void
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;

		_coverageRatio = value;
	}

	override private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		var corners:Vector<Float> = viewCamera.lens.frustumCorners;

		for (var i:Int = 0; i < 12; ++i)
		{
			var v:Float = corners[i];
			_localFrustum[i] = v;
			_localFrustum[i + 12] = v + (corners[i + 12] - v) * _coverageRatio;
		}

		updateProjectionFromFrustumCorners(viewCamera, _localFrustum, _matrix);
		_overallDepthLens.matrix = _matrix;
	}
}
