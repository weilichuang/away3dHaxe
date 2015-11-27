package away3d.entities.lights.shadowmaps;


import away3d.entities.Camera3D;
import flash.Vector;



class NearDirectionalShadowMapper extends DirectionalShadowMapper
{
	/**
	 * A value between 0 and 1 to indicate the ratio of the view frustum that needs to be covered by the shadow map.
	 */
	public var coverageRatio(get, set):Float;
	
	private var _coverageRatio:Float;

	public function new(coverageRatio:Float = .5)
	{
		super();
		this.coverageRatio = coverageRatio;
	}

	
	private function get_coverageRatio():Float
	{
		return _coverageRatio;
	}

	private function set_coverageRatio(value:Float):Float
	{
		if (value > 1)
			value = 1;
		else if (value < 0)
			value = 0;

		_coverageRatio = value;
		
		return _coverageRatio;
	}

	override private function updateDepthProjection(viewCamera:Camera3D):Void
	{
		var corners:Vector<Float> = viewCamera.lens.frustumCorners;

		for (i in 0...12)
		{
			var v:Float = corners[i];
			_localFrustum[i] = v;
			_localFrustum[i + 12] = v + (corners[i + 12] - v) * _coverageRatio;
		}

		updateProjectionFromFrustumCorners(viewCamera, _localFrustum, _matrix);
		_overallDepthLens.matrix = _matrix;
	}
}
