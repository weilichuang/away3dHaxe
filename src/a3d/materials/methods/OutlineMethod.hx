package a3d.materials.methods;


import a3d.core.managers.Stage3DProxy;
import a3d.materials.passes.MaterialPassBase;
import a3d.materials.passes.OutlinePass;
import a3d.materials.compilation.ShaderRegisterCache;
import a3d.materials.compilation.ShaderRegisterElement;
import flash.Vector;



class OutlineMethod extends EffectMethodBase
{
	private var _outlinePass:OutlinePass;

	/**
	 * Creates a new OutlineMethod object.
	 * @param outlineColor The colour of the outline stroke
	 * @param outlineSize The size of the outline stroke
	 * @param showInnerLines Indicates whether or not strokes should be potentially drawn over the existing model.
	 * @param dedicatedWaterProofMesh Used to stitch holes appearing due to mismatching normals for overlapping vertices. Warning: this will create a new mesh that is incompatible with animations!
	 */
	public function new(outlineColor:UInt = 0x000000, outlineSize:Float = 1, showInnerLines:Bool = true, dedicatedWaterProofMesh:Bool = false)
	{
		super();
		_passes = new Vector<MaterialPassBase>();
		_outlinePass = new OutlinePass(outlineColor, outlineSize, showInnerLines, dedicatedWaterProofMesh);
		_passes.push(_outlinePass);
	}

	override public function initVO(vo:MethodVO):Void
	{
		vo.needsNormals = true;
	}

	/**
	 * Indicates whether or not strokes should be potentially drawn over the existing model.
	 * Set this to true to draw outlines for geometry overlapping in the view, useful to achieve a cel-shaded drawing outline.
	 * Setting this to false will only cause the outline to appear around the 2D projection of the geometry.
	 */
	private inline function get_showInnerLines():Bool
	{
		return _outlinePass.showInnerLines;
	}

	private inline function set_showInnerLines(value:Bool):Void
	{
		_outlinePass.showInnerLines = value;
	}

	/**
	 * The colour of the outline.
	 */
	private inline function get_outlineColor():UInt
	{
		return _outlinePass.outlineColor;
	}

	private inline function set_outlineColor(value:UInt):Void
	{
		_outlinePass.outlineColor = value;
	}

	/**
	 * The size of the outline.
	 */
	private inline function get_outlineSize():Float
	{
		return _outlinePass.outlineSize;
	}

	private inline function set_outlineSize(value:Float):Void
	{
		_outlinePass.outlineSize = value;
	}

	override public function reset():Void
	{
		super.reset();
	}

	override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
	{
	}

	override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
	{
		return "";
	}
}
