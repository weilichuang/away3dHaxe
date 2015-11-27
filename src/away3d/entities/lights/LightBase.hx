package away3d.entities.lights;

import away3d.core.base.IRenderable;
import away3d.core.partition.EntityNode;
import away3d.core.partition.LightNode;
import away3d.entities.Entity;
import away3d.errors.AbstractMethodError;
import away3d.events.LightEvent;
import away3d.io.library.assets.AssetType;
import away3d.entities.lights.shadowmaps.ShadowMapperBase;
import away3d.math.FMath;

import flash.geom.Matrix3D;



/**
 * LightBase provides an abstract base class for subtypes representing lights.
 */
class LightBase extends Entity
{
	public var castsShadows(get,set):Bool;
	/**
	 * The specular emission strength of the light. Default value is <code>1</code>.
	 */
	public var specular(get,set):Float;
	/**
	 * The diffuse emission strength of the light. Default value is <code>1</code>.
	 */
	public var diffuse(get,set):Float;
	/**
	 * The color of the light. Default value is <code>0xffffff</code>.
	 */
	public var color(get,set):UInt;
	/**
	 * The ambient emission strength of the light. Default value is <code>0</code>.
	 */
	public var ambient(get, set):Float;
	
	public var ambientColor(get, set):UInt;
	
	public var shadowMapper(get, set):ShadowMapperBase;
	
	private var _color:UInt = 0xffffff;
	private var _colorR:Float = 1;
	private var _colorG:Float = 1;
	private var _colorB:Float = 1;

	private var _ambientColor:UInt = 0xffffff;
	private var _ambient:Float = 0;
	public var ambientR:Float = 0;
	public var ambientG:Float = 0;
	public var ambientB:Float = 0;

	private var _specular:Float = 1;
	public var specularR:Float = 1;
	public var specularG:Float = 1;
	public var specularB:Float = 1;

	private var _diffuse:Float = 1;
	public var diffuseR:Float = 1;
	public var diffuseG:Float = 1;
	public var diffuseB:Float = 1;

	private var _castsShadows:Bool;

	private var _shadowMapper:ShadowMapperBase;


	/**
	 * Create a new LightBase object.
	 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
	 */
	public function new()
	{
		super();
	}

	
	private function get_castsShadows():Bool
	{
		return _castsShadows;
	}

	private function set_castsShadows(value:Bool):Bool
	{
		if (_castsShadows == value)
			return _castsShadows;

		_castsShadows = value;

		if (value)
		{
			if (_shadowMapper == null)
				_shadowMapper = createShadowMapper();
			_shadowMapper.light = this;
		}
		else
		{
			_shadowMapper.dispose();
			_shadowMapper = null;
		}

		dispatchEvent(new LightEvent(LightEvent.CASTS_SHADOW_CHANGE));
		
		return _castsShadows;
	}

	private function createShadowMapper():ShadowMapperBase
	{
		throw new AbstractMethodError();
	}

	
	private function get_specular():Float
	{
		return _specular;
	}


	private function set_specular(value:Float):Float
	{
		if (value < 0)
			value = 0;
		_specular = value;
		updateSpecular();
		
		return _specular;
	}

	
	private function get_diffuse():Float
	{
		return _diffuse;
	}

	private function set_diffuse(value:Float):Float
	{
		if (value < 0)
			value = 0;
		//else if (value > 1) value = 1;
		_diffuse = value;
		updateDiffuse();
		
		return _diffuse;
	}

	
	private function get_color():UInt
	{
		return _color;
	}

	private function set_color(value:UInt):UInt
	{
		_color = value;
		_colorR = ((_color >> 16) & 0xff) / 0xff;
		_colorG = ((_color >> 8) & 0xff) / 0xff;
		_colorB = (_color & 0xff) / 0xff;
		updateDiffuse();
		updateSpecular();
		
		return _color;
	}

	
	private function get_ambient():Float
	{
		return _ambient;
	}

	private function set_ambient(value:Float):Float
	{
		_ambient = FMath.fclamp(value, 0, 1);
		updateAmbient();
		
		return _ambient;
	}

	
	private function get_ambientColor():UInt
	{
		return _ambientColor;
	}

	/**
	 * The ambient emission colour of the light. Default value is <code>0xffffff</code>.
	 */
	private function set_ambientColor(value:UInt):UInt
	{
		_ambientColor = value;
		updateAmbient();
		return _ambientColor;
	}

	private function updateAmbient():Void
	{
		ambientR = ((_ambientColor >> 16) & 0xff) / 0xff * _ambient;
		ambientG = ((_ambientColor >> 8) & 0xff) / 0xff * _ambient;
		ambientB = (_ambientColor & 0xff) / 0xff * _ambient;
	}

	/**
	 * Gets the optimal projection matrix to render a light-based depth map for a single object.
	 * @param renderable The IRenderable object to render to a depth map.
	 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
	 * @return A Matrix3D object containing the projection transformation.
	 */
	public function getObjectProjectionMatrix(renderable:IRenderable, target:Matrix3D = null):Matrix3D
	{
		throw new AbstractMethodError();
	}

	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new LightNode(this);
	}

	/**
	 * @inheritDoc
	 */
	override private function get_assetType():String
	{
		return AssetType.LIGHT;
	}


	/**
	 * Updates the total specular components of the light.
	 */
	private function updateSpecular():Void
	{
		specularR = _colorR * _specular;
		specularG = _colorG * _specular;
		specularB = _colorB * _specular;
	}

	/**
	 * Updates the total diffuse components of the light.
	 */
	private function updateDiffuse():Void
	{
		diffuseR = _colorR * _diffuse;
		diffuseG = _colorG * _diffuse;
		diffuseB = _colorB * _diffuse;
	}

	
	private function get_shadowMapper():ShadowMapperBase
	{
		return _shadowMapper;
	}

	private function set_shadowMapper(value:ShadowMapperBase):ShadowMapperBase
	{
		_shadowMapper = value;
		_shadowMapper.light = this;
		return _shadowMapper;
	}
}
