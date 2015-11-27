package away3d.materials.lightpickers;

import away3d.core.base.IRenderable;
import away3d.core.traverse.EntityCollector;
import away3d.entities.lights.DirectionalLight;
import away3d.entities.lights.LightBase;
import away3d.entities.lights.LightProbe;
import away3d.entities.lights.PointLight;
import away3d.io.library.assets.AssetType;
import away3d.io.library.assets.IAsset;
import away3d.io.library.assets.NamedAssetBase;
import away3d.math.FMath;
import flash.geom.Vector3D;
import flash.Vector;

/**
 * LightPickerBase provides an abstract base clase for light picker classes. These classes are responsible for
 * feeding materials with relevant lights. Usually, StaticLightPicker can be used, but LightPickerBase can be
 * extended to provide more application-specific dynamic selection of lights.
 *
 * @see StaticLightPicker
 */
class LightPickerBase extends NamedAssetBase implements IAsset
{
	public var assetType(get,null):String;
	/**
	 * The maximum amount of directional lights that will be provided
	 */
	public var numDirectionalLights(default,null):Int;
	/**
	 * The maximum amount of point lights that will be provided
	 */
	public var numPointLights(default,null):Int;
	/**
	 * The maximum amount of directional lights that cast shadows
	 */
	public var numCastingDirectionalLights(default,null):Int;
	/**
	 * The amount of point lights that cast shadows
	 */
	public var numCastingPointLights(default,null):Int;
	/**
	 * The maximum amount of light probes that will be provided
	 */
	public var numLightProbes(default,null):Int;
	/**
	 * The collected point lights to be used for shading.
	 */
	public var pointLights(get,null):Vector<PointLight>;
	/**
	 * The collected directional lights to be used for shading.
	 */
	public var directionalLights(get,null):Vector<DirectionalLight>;
	/**
	 * The collected point lights that cast shadows to be used for shading.
	 */
	public var castingPointLights(get,null):Vector<PointLight>;
	/**
	 * The collected directional lights that cast shadows to be used for shading.
	 */
	public var castingDirectionalLights(get,null):Vector<DirectionalLight>;
	/**
	 * The collected light probes to be used for shading.
	 */
	public var lightProbes(get,null):Vector<LightProbe>;
	/**
	 * The weights for each light probe, defining their influence on the object.
	 */
	public var lightProbeWeights(get,null):Vector<Float>;
	/**
	 * A collection of all the collected lights.
	 */
	public var allPickedLights(get, null):Vector<LightBase>;
	
	private var _allPickedLights:Vector<LightBase>;
	private var _pointLights:Vector<PointLight>;
	private var _castingPointLights:Vector<PointLight>;
	private var _directionalLights:Vector<DirectionalLight>;
	private var _castingDirectionalLights:Vector<DirectionalLight>;
	private var _lightProbes:Vector<LightProbe>;
	private var _lightProbeWeights:Vector<Float>;

	/**
	 * Creates a new LightPickerBase object.
	 */
	public function new()
	{
		super();
	}

	/**
	 * Disposes resources used by the light picker.
	 */
	public function dispose():Void
	{
	}

	
	private function get_assetType():String
	{
		return AssetType.LIGHT_PICKER;
	}

	private function get_pointLights():Vector<PointLight>
	{
		return _pointLights;
	}

	
	private function get_directionalLights():Vector<DirectionalLight>
	{
		return _directionalLights;
	}

	
	private function get_castingPointLights():Vector<PointLight>
	{
		return _castingPointLights;
	}

	
	private function get_castingDirectionalLights():Vector<DirectionalLight>
	{
		return _castingDirectionalLights;
	}

	
	private function get_lightProbes():Vector<LightProbe>
	{
		return _lightProbes;
	}

	
	private function get_lightProbeWeights():Vector<Float>
	{
		return _lightProbeWeights;
	}

	
	private function get_allPickedLights():Vector<LightBase>
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


	/**
	 * Updates the weights for the light probes, based on the renderable's position relative to them.
	 * @param renderable The renderble for which to calculate the light probes' influence.
	 */
	private function updateProbeWeights(renderable:IRenderable):Void
	{
		// todo: this will cause the same calculations to occur per SubMesh. See if this can be improved.
		var objectPos:Vector3D = renderable.sourceEntity.scenePosition;
		var lightPos:Vector3D;
		var rx:Float = objectPos.x, ry:Float = objectPos.y, rz:Float = objectPos.z;
		var dx:Float, dy:Float, dz:Float;
		var w:Float, total:Float = 0;

		// calculates weights for probes
		for (i in 0...numLightProbes)
		{
			lightPos = _lightProbes[i].scenePosition;
			dx = rx - lightPos.x;
			dy = ry - lightPos.y;
			dz = rz - lightPos.z;
			// weight is inversely proportional to square of distance
			w = FMath.lengthSquared(dx, dy, dz);
			
			// just... huge if at the same spot
			w = w > .00001 ? 1 / w : 50000000;
			_lightProbeWeights[i] = w;
			total += w;
		}

		// normalize
		total = 1 / total;
		for (i in 0...numLightProbes)
			_lightProbeWeights[i] *= total;
	}

}
