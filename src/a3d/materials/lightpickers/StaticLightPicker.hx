package a3d.materials.lightpickers;

import flash.events.Event;
import flash.Vector;

import a3d.events.LightEvent;
import a3d.entities.lights.DirectionalLight;
import a3d.entities.lights.LightBase;
import a3d.entities.lights.LightProbe;
import a3d.entities.lights.PointLight;

class StaticLightPicker extends LightPickerBase
{
	private var _lights:Array;

	public function new(lights:Array)
	{
		this.lights = lights;
	}

	private inline function get_lights():Array
	{
		return _lights;
	}

	private inline function set_lights(value:Array):Void
	{
		var numPointLights:UInt = 0;
		var numDirectionalLights:UInt = 0;
		var numCastingPointLights:UInt = 0;
		var numCastingDirectionalLights:UInt = 0;
		var numLightProbes:UInt = 0;
		var light:LightBase;

		if (_lights)
			clearListeners();

		_lights = value;
		_allPickedLights = Vector<LightBase>(value);
		_pointLights = new Vector<PointLight>();
		_castingPointLights = new Vector<PointLight>();
		_directionalLights = new Vector<DirectionalLight>();
		_castingDirectionalLights = new Vector<DirectionalLight>();
		_lightProbes = new Vector<LightProbe>();

		var len:UInt = value.length;
		for (var i:UInt = 0; i < len; ++i)
		{
			light = value[i];
			light.addEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
			if (Std.is(light,PointLight))
			{
				if (light.castsShadows)
					_castingPointLights[numCastingPointLights++] = PointLight(light);
				else
					_pointLights[numPointLights++] = PointLight(light);

			}
			else if (Std.is(light,DirectionalLight))
			{
				if (light.castsShadows)
					_castingDirectionalLights[numCastingDirectionalLights++] = DirectionalLight(light);
				else
					_directionalLights[numDirectionalLights++] = DirectionalLight(light);
			}
			else if (Std.is(light,LightProbe))
				_lightProbes[numLightProbes++] = LightProbe(light);
		}

		if (_numDirectionalLights == numDirectionalLights && _numPointLights == numPointLights && _numLightProbes == numLightProbes &&
			_numCastingPointLights == numCastingPointLights && _numCastingDirectionalLights == numCastingDirectionalLights)
			return;

		_numDirectionalLights = numDirectionalLights;
		_numCastingDirectionalLights = numCastingDirectionalLights;
		_numPointLights = numPointLights;
		_numCastingPointLights = numCastingPointLights;
		_numLightProbes = numLightProbes;

		// MUST HAVE MULTIPLE OF 4 ELEMENTS!
		_lightProbeWeights = new Vector<Float>(Math.ceil(numLightProbes / 4) * 4, true);

		// notify material lights have changed
		dispatchEvent(new Event(Event.CHANGE));
	}

	private function clearListeners():Void
	{
		var len:UInt = _lights.length;
		for (var i:Int = 0; i < len; ++i)
			_lights[i].removeEventListener(LightEvent.CASTS_SHADOW_CHANGE, onCastShadowChange);
	}

	private function onCastShadowChange(event:LightEvent):Void
	{
		// TODO: Assign to special caster collections, just append it to the lights in SinglePass
		// But keep seperated in multipass

		var light:LightBase = LightBase(event.target);

		if (Std.is(light,PointLight))
			updatePointCasting(Std.instance(light,PointLight));
		else if (Std.is(light,DirectionalLight))
			updateDirectionalCasting(Std.instance(light,DirectionalLight));

		dispatchEvent(new Event(Event.CHANGE));
	}

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
