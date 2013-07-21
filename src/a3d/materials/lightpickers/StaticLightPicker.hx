package a3d.materials.lightpickers;

import flash.events.Event;
import flash.Vector;

import a3d.events.LightEvent;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;

/**
 * StaticLightPicker is a light picker that provides a static set of lights. The lights can be reassigned, but
 * if the configuration changes (number of directional lights, point lights, etc), a material recompilation may
 * occur.
 */
class StaticLightPicker extends LightPickerBase
{
	/**
	 * The lights used for shading.
	 */
	public var lights(get, set):Array<LightBase>;
	
	private var _lights:Array<LightBase>;

	/**
	 * Creates a new StaticLightPicker object.
	 * @param lights The lights to be used for shading.
	 */
	public function new(lights:Array<LightBase>)
	{
		super();
		this.lights = lights;
	}

	
	private function get_lights():Array<LightBase>
	{
		return _lights;
	}

	private function set_lights(value:Array<LightBase>):Array<LightBase>
	{
		var numPointLights:Int = 0;
		var numDirectionalLights:Int = 0;
		var numCastingPointLights:Int = 0;
		var numCastingDirectionalLights:Int = 0;
		var numLightProbes:Int = 0;
		var light:LightBase;

		if (_lights != null)
			clearListeners();

		_lights = value;
		_allPickedLights = Vector.ofArray(value);
		_pointLights = new Vector<PointLight>();
		_castingPointLights = new Vector<PointLight>();
		_directionalLights = new Vector<DirectionalLight>();
		_castingDirectionalLights = new Vector<DirectionalLight>();
		_lightProbes = new Vector<LightProbe>();

		var len:Int = value.length;
		for (i in 0...len)
		{
			light = value[i];
			light.addEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
			if (Std.is(light,PointLight))
			{
				if (light.castsShadows)
					_castingPointLights[numCastingPointLights++] = Std.instance(light,PointLight);
				else
					_pointLights[numPointLights++] = Std.instance(light,PointLight);

			}
			else if (Std.is(light,DirectionalLight))
			{
				if (light.castsShadows)
					_castingDirectionalLights[numCastingDirectionalLights++] = Std.instance(light,DirectionalLight);
				else
					_directionalLights[numDirectionalLights++] = Std.instance(light,DirectionalLight);
			}
			else if (Std.is(light,LightProbe))
				_lightProbes[numLightProbes++] = Std.instance(light,LightProbe);
		}

		if (_numDirectionalLights == numDirectionalLights && 
			_numPointLights == numPointLights && _numLightProbes == numLightProbes &&
			_numCastingPointLights == numCastingPointLights && 
			_numCastingDirectionalLights == numCastingDirectionalLights)
			return _lights;

		_numDirectionalLights = numDirectionalLights;
		_numCastingDirectionalLights = numCastingDirectionalLights;
		_numPointLights = numPointLights;
		_numCastingPointLights = numCastingPointLights;
		_numLightProbes = numLightProbes;

		// MUST HAVE MULTIPLE OF 4 ELEMENTS!
		_lightProbeWeights = new Vector<Float>(Math.ceil(numLightProbes / 4) * 4, true);

		// notify material lights have changed
		dispatchEvent(new Event(Event.CHANGE));
		
		return _lights;
	}

	/**
	 * Remove configuration change listeners on the lights.
	 */
	private function clearListeners():Void
	{
		var len:Int = _lights.length;
		for (i in 0...len)
			_lights[i].removeEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
	}

	/**
	 * Notifies the material of a configuration change.
	 */
	private function onCastShadowChange(event:LightEvent):Void
	{
		// TODO: Assign to special caster collections, just append it to the lights in SinglePass
		// But keep seperated in multipass

		var light:LightBase = Std.instance(event.target,LightBase);

		if (Std.is(light,PointLight))
			updatePointCasting(Std.instance(light,PointLight));
		else if (Std.is(light,DirectionalLight))
			updateDirectionalCasting(Std.instance(light,DirectionalLight));

		dispatchEvent(new Event(Event.CHANGE));
	}

	/**
	 * Called when a directional light's shadow casting configuration changes.
	 */
	private function updateDirectionalCasting(light:DirectionalLight):Void
	{
		if (light.castsShadows)
		{
			--_numDirectionalLights;
			++_numCastingDirectionalLights;
			_directionalLights.splice(_directionalLights.indexOf(light), 1);
			_castingDirectionalLights.push(light);
		}
		else
		{
			++_numDirectionalLights;
			--_numCastingDirectionalLights;
			_castingDirectionalLights.splice(_castingDirectionalLights.indexOf(light), 1);
			_directionalLights.push(light);
		}
	}

	/**
	 * Called when a point light's shadow casting configuration changes.
	 */
	private function updatePointCasting(light:PointLight):Void
	{
		if (light.castsShadows)
		{
			--_numPointLights;
			++_numCastingPointLights;
			_pointLights.splice(_pointLights.indexOf(light), 1);
			_castingPointLights.push(light);
		}
		else
		{
			++_numPointLights;
			--_numCastingPointLights;
			_castingPointLights.splice(_castingPointLights.indexOf(light), 1);
			_pointLights.push(light);
		}
	}
}
