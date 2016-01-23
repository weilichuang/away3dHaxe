package away3d.materials.lightpickers;

import away3d.lights.DirectionalLight;
import away3d.lights.LightBase;
import away3d.lights.LightProbe;
import away3d.lights.PointLight;
import away3d.events.LightEvent;
import flash.events.Event;
import flash.Vector;

using away3d.utils.VectorUtil;

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
		var numPL:Int = 0;
		var numDL:Int = 0;
		var numCPL:Int = 0;
		var numCDL:Int = 0;
		var numLP:Int = 0;
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
					_castingPointLights[numCPL++] = Std.instance(light,PointLight);
				else
					_pointLights[numPL++] = Std.instance(light,PointLight);

			}
			else if (Std.is(light,DirectionalLight))
			{
				if (light.castsShadows)
					_castingDirectionalLights[numCDL++] = Std.instance(light,DirectionalLight);
				else
					_directionalLights[numDL++] = Std.instance(light,DirectionalLight);
			}
			else if (Std.is(light, LightProbe))
			{
				_lightProbes[numLP++] = Std.instance(light,LightProbe);
			}
		}

		if (this.numDirectionalLights == numDL && 
			this.numPointLights == numPL && 
			this.numLightProbes == numLP &&
			this.numCastingPointLights == numCPL && 
			this.numCastingDirectionalLights == numCDL)
			return _lights;

		this.numDirectionalLights = numDL;
		this.numCastingDirectionalLights = numCDL;
		this.numPointLights = numPL;
		this.numCastingPointLights = numCPL;
		this.numLightProbes = numLP;

		// MUST HAVE MULTIPLE OF 4 ELEMENTS!
		_lightProbeWeights = new Vector<Float>(Math.ceil(numLP / 4) * 4, true);

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

		if (Std.is(light, PointLight))
		{
			updatePointCasting(Std.instance(light,PointLight));
		}
		else if (Std.is(light, DirectionalLight))
		{
			updateDirectionalCasting(Std.instance(light,DirectionalLight));
		}

		dispatchEvent(new Event(Event.CHANGE));
	}

	/**
	 * Called when a directional light's shadow casting configuration changes.
	 */
	private function updateDirectionalCasting(light:DirectionalLight):Void
	{
		if (light.castsShadows)
		{
			--numDirectionalLights;
			++numCastingDirectionalLights;
			_directionalLights.remove(light);
			_castingDirectionalLights.push(light);
		}
		else
		{
			++numDirectionalLights;
			--numCastingDirectionalLights;
			_castingDirectionalLights.remove(light);
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
			--numPointLights;
			++numCastingPointLights;
			_pointLights.remove(light);
			_castingPointLights.push(light);
		}
		else
		{
			++numPointLights;
			--numCastingPointLights;
			_castingPointLights.remove(light);
			_pointLights.push(light);
		}
	}
}
