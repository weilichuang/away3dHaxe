package away3d.animators.data;

/**
 * ...
 * @author weilichuang
 */
class CombineAnimationFrame extends UVAnimationFrame
{
	public var alpha : Float = 1;
	public var mulR : Float = 1;
	public var mulG : Float = 1;
	public var mulB : Float = 1;

	public function newoffsetU : Float = 0, offsetV : Float = 0, scaleU : Float = 1, scaleV : Float = 1, rotation : Float = 0, alpha : Float = 1 )
	{
		this.offsetU = offsetU;
		this.offsetV = offsetV;
		this.scaleU = scaleU;
		this.scaleV = scaleV;
		this.rotation = rotation;
		this.alpha = alpha;
	}
	
}