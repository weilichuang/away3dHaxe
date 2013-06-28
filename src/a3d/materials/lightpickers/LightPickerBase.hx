package a3d.materials.lightpickers;

import flash.geom.Vector3D;
import flash.Vector;


import a3d.core.base.IRenderable;
import a3d.core.traverse.EntityCollector;
import a3d.io.library.assets.AssetType;
import a3d.io.library.assets.IAsset;
import a3d.io.library.assets.NamedAssetBase;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;



class LightPickerBase extends NamedAssetBase implements IAsset
{
	private var _numPointLights:UInt;
	private var _numDirectionalLights:UInt;
	private var _numCastingPointLights:UInt;
	private var _numCastingDirectionalLights:UInt;
	private var _numLightProbes:UInt;
	private var _allPickedLights:Vector<LightBase>;
	private var _pointLights:Vector<PointLight>;
	private var _castingPointLights:Vector<PointLight>;
	private var _directionalLights:Vector<DirectionalLight>;
	private var _castingDirectionalLights:Vector<DirectionalLight>;
	private var _lightProbes:Vector<LightProbe>;
	private var _lightProbeWeights:Vector<Float>;

	public function new()
	{
		super();
	}

	public function dispose():Void
	{
	}

	public var assetType(get,null):String;
	private inline function get_assetType():String
	{
		return AssetType.LIGHT_PICKER;
	}

	/**
	 * The maximum amount of directional lights that will be provided
	 */
	public var numDirectionalLights(get,null):UInt;
	private inline function get_numDirectionalLights():UInt
	{
		return _numDirectionalLights;
	}

	/**
	 * The maximum amount of point lights that will be provided
	 */
	public var numPointLights(get,null):UInt;
	private inline function get_numPointLights():UInt
	{
		return _numPointLights;
	}

	/**
	 * The maximum amount of directional lights that cast shadows
	 */
	public var numCastingDirectionalLights(get,null):UInt;
	private inline function get_numCastingDirectionalLights():UInt
	{
		return _numCastingDirectionalLights;
	}

	/**
	 * The amount of point lights that cast shadows
	 */
	public var numCastingPointLights(get,null):UInt;
	private inline function get_numCastingPointLights():UInt
	{
		return _numCastingPointLights;
	}

	/**
	 * The maximum amount of light probes that will be provided
	 */
	public var numLightProbes(get,null):UInt;
	private inline function get_numLightProbes():UInt
	{
		return _numLightProbes;
	}

	public var pointLights(get,null):Vector<PointLight>;
	private inline function get_pointLights():Vector<PointLight>
	{
		return _pointLights;
	}

	public var directionalLights(get,null):Vector<DirectionalLight>;
	private inline function get_directionalLights():Vector<DirectionalLight>
	{
		return _directionalLights;
	}

	public var castingPointLights(get,null):Vector<PointLight>;
	private inline function get_castingPointLights():Vector<PointLight>
	{
		return _castingPointLights;
	}

	public var castingDirectionalLights(get,null):Vector<DirectionalLight>;
	private inline function get_castingDirectionalLights():Vector<DirectionalLight>
	{
		return _castingDirectionalLights;
	}

	public var lightProbes(get,null):Vector<LightProbe>;
	private inline function get_lightProbes():Vector<LightProbe>
	{
		return _lightProbes;
	}

	public var lightProbeWeights(get,null):Vector<Float>;
	private inline function get_lightProbeWeights():Vector<Float>
	{
		return _lightProbeWeights;
	}

	public var allPickedLights(get,null):Vector<LightBase>;
	private inline function get_allPickedLights():Vector<LightBase>
	{
		return _allPickedLights;
	}

	/**
	 * Updates set of lights for a given renderable and EntityCollector. Always call super.collectLights() after custom overridden code.
	 */
	public function collectLights(renderable:IRenderable, entityCollector:EntityCollector):Void
	{
//			entityCollector = entityCollector;
		updateProbeWeights(renderable);
	}


	private function updateProbeWeights(renderable:IRenderable):Void
	{
		// todo: this will cause the same calculations to occur per SubMesh. See if this can be improved.
		var objectPos:Vector3D = renderable.sourceEntity.scenePosition;
		var lightPos:Vector3D;
		var rx:Float = objectPos.x, ry:Float = objectPos.y, rz:Float = objectPos.z;
		var dx:Float, dy:Float, dz:Float;
		var w:Float, total:Float = 0;

		// calculates weights for probes
		for (i in 0..._numLightProbes)
		{
			lightPos = _lightProbes[i].scenePosition;
			dx = rx - lightPos.x;
			dy = ry - lightPos.y;
			dz = rz - lightPos.z;
			// weight is inversely proportional to square of distance
			w = dx * dx + dy * dy + dz * dz;

			// just... huge if at the same spot
			w = w > .00001 ? 1 / w : 50000000;
			_lightProbeWeights[i] = w;
			total += w;
		}

		// normalize
		total = 1 / total;
		for (i in 0..._numLightProbes)
			_lightProbeWeights[i] *= total;
	}

}
