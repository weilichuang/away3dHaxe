package a3d.materials.passes;

import a3d.animators.data.AnimationRegisterCache;
import a3d.animators.IAnimationSet;
import a3d.core.base.IRenderable;
import a3d.core.managers.AGALProgram3DCache;
import a3d.core.managers.Stage3DProxy;
import a3d.entities.Camera3D;
import a3d.errors.AbstractMethodError;
import a3d.materials.lightpickers.LightPickerBase;
import a3d.materials.MaterialBase;
import a3d.utils.Debug;
import flash.display.BlendMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.errors.ArgumentError;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.Vector;


/**
 * MaterialPassBase provides an abstract base class for material shader passes.
 *
 * Vertex stream index 0 is reserved for vertex positions.
 * Vertex shader constants index 0-3 are reserved for projections, constant 4 for viewport positioning
 * Vertex shader constant index 4 is reserved for render-to-texture scaling
 */
class MaterialPassBase extends EventDispatcher
{
	// keep track of previously rendered usage for faster cleanup of old vertex buffer streams and textures
	private static var _previousUsedStreams:Vector<Int> = Vector.ofArray([0, 0, 0, 0, 0, 0, 0, 0]);
	private static var _previousUsedTexs:Vector<Int> = Vector.ofArray([0, 0, 0, 0, 0, 0, 0, 0]);
	
	
	private var _material:MaterialBase;
	private var _animationSet:IAnimationSet;

	private var _program3Ds:Vector<Program3D>;
	private var _program3Dids:Vector<Int>;
	private var _context3Ds:Vector<Context3D>;

	// agal props. these NEED to be set by subclasses!
	// todo: can we perhaps figure these out manually by checking read operations in the bytecode, so other sources can be safely updated?
	private var _numUsedStreams:UInt;
	private var _numUsedTextures:UInt;
	private var _numUsedVertexConstants:UInt;
	private var _numUsedFragmentConstants:UInt;
	private var _numUsedVaryings:UInt;

	private var _smooth:Bool = true;
	private var _repeat:Bool = false;
	private var _mipmap:Bool = true;
	private var _depthCompareMode:Context3DCompareMode;

	private var _blendFactorSource:Context3DBlendFactor;
	private var _blendFactorDest:Context3DBlendFactor;

	private var _enableBlending:Bool;

	private var _bothSides:Bool;

	private var _lightPicker:LightPickerBase;
	private var _animatableAttributes:Vector<String>;
	private var _animationTargetRegisters:Vector<String>;
	private var _shadedTarget:String;

	private var _defaultCulling:Context3DTriangleFace;

	private var _renderToTexture:Bool;

	// render state mementos for render-to-texture passes
	private var _oldTarget:TextureBase;
	private var _oldSurface:Int;
	private var _oldDepthStencil:Bool;
	private var _oldRect:Rectangle;

	private var _alphaPremultiplied:Bool;
	private var _needFragmentAnimation:Bool;
	private var _needUVAnimation:Bool;
	private var _UVTarget:String;
	private var _UVSource:String;

	private var _writeDepth:Bool;

	public var animationRegisterCache:AnimationRegisterCache;

	/**
	 * Creates a new MaterialPassBase object.
	 *
	 * @param renderToTexture
	 */
	public function new(renderToTexture:Bool = false)
	{
		super();
		
		_renderToTexture = renderToTexture;
		_numUsedStreams = 1;
		_numUsedVertexConstants = 5;
		
		_program3Ds = new Vector<Program3D>(8);
		_program3Dids = Vector.ofArray([ -1, -1, -1, -1, -1, -1, -1, -1]);
		_context3Ds = new Vector<Context3D>(8);
		
		_depthCompareMode = Context3DCompareMode.LESS_EQUAL;

		_blendFactorSource = Context3DBlendFactor.ONE;
		_blendFactorDest = Context3DBlendFactor.ZERO;

		_animatableAttributes = Vector.ofArray(["va0"]);
		_animationTargetRegisters = Vector.ofArray(["vt0"]);
		_shadedTarget = "ft0";

		_defaultCulling = Context3DTriangleFace.BACK;
		
		_writeDepth = true;
	}

	public function getProgram3Dids():Vector<Int>
	{
		return _program3Dids;
	}

	public function getProgram3Did(stageIndex:Int):Int
	{
		return _program3Dids[stageIndex];
	}

	public function setProgram3Dids(stageIndex:Int, value:Int):Void
	{
		_program3Dids[stageIndex] = value;
	}

	public function getProgram3D(stageIndex:Int):Program3D
	{
		return _program3Ds[stageIndex];
	}

	public function setProgram3D(stageIndex:Int, p:Program3D):Void
	{
		_program3Ds[stageIndex] = p;
	}

	/**
	 * The material to which this pass belongs.
	 */
	private inline function get_material():MaterialBase
	{
		return _material;
	}

	private inline function set_material(value:MaterialBase):Void
	{
		_material = value;
	}

	/**
	 * Indicate whether this pass should write to the depth buffer or not. Ignored when blending is enabled.
	 */
	private inline function get_writeDepth():Bool
	{
		return _writeDepth;
	}

	private inline function set_writeDepth(value:Bool):Void
	{
		_writeDepth = value;
	}

	/**
	 * Defines whether any used textures should use mipmapping.
	 */
	private inline function get_mipmap():Bool
	{
		return _mipmap;
	}

	private inline function set_mipmap(value:Bool):Void
	{
		if (_mipmap == value)
			return;
		_mipmap = value;
		invalidateShaderProgram();
	}


	/**
	 * Defines whether smoothing should be applied to any used textures.
	 */
	private inline function get_smooth():Bool
	{
		return _smooth;
	}

	private inline function set_smooth(value:Bool):Void
	{
		if (_smooth == value)
			return;
		_smooth = value;
		invalidateShaderProgram();
	}

	/**
	 * Defines whether textures should be tiled.
	 */
	private inline function get_repeat():Bool
	{
		return _repeat;
	}

	private inline function set_repeat(value:Bool):Void
	{
		if (_repeat == value)
			return;
		_repeat = value;
		invalidateShaderProgram();
	}

	/**
	 * Defines whether or not the material should perform backface culling.
	 */
	private inline function get_bothSides():Bool
	{
		return _bothSides;
	}

	private inline function set_bothSides(value:Bool):Void
	{
		_bothSides = value;
	}

	public var depthCompareMode(get, set):Context3DCompareMode;
	private inline function get_depthCompareMode():Context3DCompareMode
	{
		return _depthCompareMode;
	}

	private inline function set_depthCompareMode(value:Context3DCompareMode):Context3DCompareMode
	{
		return _depthCompareMode = value;
	}

	/**
	 * The animation used to add vertex code to the shader code.
	 */
	private inline function get_animationSet():IAnimationSet
	{
		return _animationSet;
	}

	private inline function set_animationSet(value:IAnimationSet):Void
	{
		if (_animationSet == value)
			return;

		_animationSet = value;

		invalidateShaderProgram();
	}

	/**
	 * Specifies whether this pass renders to texture
	 */
	private inline function get_renderToTexture():Bool
	{
		return _renderToTexture;
	}

	/**
	 * Cleans up any resources used by the current object.
	 * @param deep Indicates whether other resources should be cleaned up, that could potentially be shared across different instances.
	 */
	public function dispose():Void
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);

		for (i in 0...8)
		{
			if (_program3Ds[i] != null)
			{
				AGALProgram3DCache.getInstanceFromIndex(i).freeProgram3D(_program3Dids[i]);
				_program3Ds[i] = null;
			}
		}
	}

	/**
	 * The amount of used vertex streams in the vertex code. Used by the animation code generation to know from which index on streams are available.
	 */
	private inline function get_numUsedStreams():UInt
	{
		return _numUsedStreams;
	}

	/**
	 * The amount of used vertex constants in the vertex code. Used by the animation code generation to know from which index on registers are available.
	 */
	private inline function get_numUsedVertexConstants():UInt
	{
		return _numUsedVertexConstants;
	}

	private inline function get_numUsedVaryings():UInt
	{
		return _numUsedVaryings;
	}

	private inline function get_numUsedFragmentConstants():UInt
	{
		return _numUsedFragmentConstants;
	}

	private inline function get_needFragmentAnimation():Bool
	{
		return _needFragmentAnimation;
	}

	private inline function get_needUVAnimation():Bool
	{
		return _needUVAnimation;
	}

	/**
	 * Sets up the animation state. This needs to be called before render()
	 *
	 * @private
	 */
	public function updateAnimationState(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		renderable.animator.setRenderState(stage3DProxy, renderable, _numUsedVertexConstants, _numUsedStreams, camera);
	}

	/**
	 * Renders an object to the current render target.
	 *
	 * @private
	 */
	public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void
	{
		throw new AbstractMethodError();
	}

	public function getVertexCode():String
	{
		throw new AbstractMethodError();
	}

	public function getFragmentCode(fragmentAnimatorCode:String):String
	{
		throw new AbstractMethodError();
	}

	public function setBlendMode(value:BlendMode):Void
	{
		switch (value)
		{
			case BlendMode.NORMAL:
				_blendFactorSource = Context3DBlendFactor.ONE;
				_blendFactorDest = Context3DBlendFactor.ZERO;
				_enableBlending = false;
				
			case BlendMode.LAYER:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				_enableBlending = true;
				
			case BlendMode.MULTIPLY:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_COLOR;
				_enableBlending = true;
				
			case BlendMode.ADD:
				_blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
				_blendFactorDest = Context3DBlendFactor.ONE;
				_enableBlending = true;
				
			case BlendMode.ALPHA:
				_blendFactorSource = Context3DBlendFactor.ZERO;
				_blendFactorDest = Context3DBlendFactor.SOURCE_ALPHA;
				_enableBlending = true;
				
			default:
				throw new ArgumentError("Unsupported blend mode!");
		}
	}

	public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void
	{
		// TODO: not used
		//camera = camera;

		var contextIndex:Int = stage3DProxy.stage3DIndex;
		var context:Context3D = stage3DProxy.context3D;

		context.setDepthTest(_writeDepth && !_enableBlending, _depthCompareMode);
		if (_enableBlending)
			context.setBlendFactors(_blendFactorSource, _blendFactorDest);

		if (_context3Ds[contextIndex] != context || 
			_program3Ds[contextIndex] == null)
		{
			_context3Ds[contextIndex] = context;
			updateProgram(stage3DProxy);
			dispatchEvent(new Event(Event.CHANGE));
		}

		var prevUsed:Int = _previousUsedStreams[contextIndex];
		var i:UInt;
		for (i in _numUsedStreams...prevUsed)
		{
			context.setVertexBufferAt(i, null);
		}

		prevUsed = _previousUsedTexs[contextIndex];

		for (i in _numUsedTextures...prevUsed)
			context.setTextureAt(i, null);

		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.activate(stage3DProxy, this);

		context.setProgram(_program3Ds[contextIndex]);

		context.setCulling(_bothSides ? Context3DTriangleFace.NONE : _defaultCulling);

		if (_renderToTexture)
		{
			_oldTarget = stage3DProxy.renderTarget;
			_oldSurface = stage3DProxy.renderSurfaceSelector;
			_oldDepthStencil = stage3DProxy.enableDepthAndStencil;
			_oldRect = stage3DProxy.scissorRect;
		}
	}

	/**
	 * Turns off streams starting from a certain offset
	 *
	 * @private
	 */
	public function deactivate(stage3DProxy:Stage3DProxy):Void
	{
		var index:UInt = stage3DProxy.stage3DIndex;
		_previousUsedStreams[index] = _numUsedStreams;
		_previousUsedTexs[index] = _numUsedTextures;

		if (_animationSet != null && !_animationSet.usesCPU)
			_animationSet.deactivate(stage3DProxy, this);

		if (_renderToTexture)
		{
			// kindly restore state
			stage3DProxy.setRenderTarget(_oldTarget, _oldDepthStencil, _oldSurface);
			stage3DProxy.scissorRect = _oldRect;
		}

		stage3DProxy.context3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
	}

	/**
	 * Marks the shader program as invalid, so it will be recompiled before the next render.
	 *
	 * @param updateMaterial Indicates whether the invalidation should be performed on the entire material. Should always pass "true" unless it's called from the material itself.
	 */
	public function invalidateShaderProgram(updateMaterial:Bool = true):Void
	{
		for (i in 0...8)
			_program3Ds[i] = null;

		if (_material != null && updateMaterial)
			_material.invalidatePasses(this);
	}

	/**
	 * Compiles the shader program.
	 * @param polyOffsetReg An optional register that contains an amount by which to inflate the model (used in single object depth map rendering).
	 */
	public function updateProgram(stage3DProxy:Stage3DProxy):Void
	{
		var animatorCode:String = "";
		var UVAnimatorCode:String = "";
		var fragmentAnimatorCode:String = "";
		var vertexCode:String = getVertexCode();

		if (_animationSet != null && !_animationSet.usesCPU)
		{
			animatorCode = _animationSet.getAGALVertexCode(this, _animatableAttributes, _animationTargetRegisters, stage3DProxy.profile);
			if (_needFragmentAnimation)
				fragmentAnimatorCode = _animationSet.getAGALFragmentCode(this, _shadedTarget, stage3DProxy.profile);
			if (_needUVAnimation)
				UVAnimatorCode = _animationSet.getAGALUVCode(this, _UVSource, _UVTarget);
			_animationSet.doneAGALCode(this);
		}
		else
		{
			var len:UInt = _animatableAttributes.length;

			// simply write attributes to targets, do not animate them
			// projection will pick up on targets[0] to do the projection
			for (i in 0...len)
				animatorCode += "mov " + _animationTargetRegisters[i] + ", " + _animatableAttributes[i] + "\n";
			if (_needUVAnimation)
				UVAnimatorCode = "mov " + _UVTarget + "," + _UVSource + "\n";
		}

		vertexCode = animatorCode + UVAnimatorCode + vertexCode;

		var fragmentCode:String = getFragmentCode(fragmentAnimatorCode);
		if (Debug.active)
		{
			trace("Compiling AGAL Code:");
			trace("--------------------");
			trace(vertexCode);
			trace("--------------------");
			trace(fragmentCode);
		}
		AGALProgram3DCache.getInstance(stage3DProxy).setProgram3D(this, vertexCode, fragmentCode);
	}

	private inline function get_lightPicker():LightPickerBase
	{
		return _lightPicker;
	}

	private inline function set_lightPicker(value:LightPickerBase):LightPickerBase
	{
		if (_lightPicker != null)
			_lightPicker.removeEventListener(Event.CHANGE, onLightsChange);
			
		_lightPicker = value;
		
		if (_lightPicker != null)
			_lightPicker.addEventListener(Event.CHANGE, onLightsChange);
			
		updateLights();
		
		return _lightPicker;
	}

	private function onLightsChange(event:Event):Void
	{
		updateLights();
	}

	// need to implement if pass is light-dependent
	private function updateLights():Void
	{

	}

	private inline function get_alphaPremultiplied():Bool
	{
		return _alphaPremultiplied;
	}

	private inline function set_alphaPremultiplied(value:Bool):Void
	{
		_alphaPremultiplied = value;
		invalidateShaderProgram(false);
	}
}
