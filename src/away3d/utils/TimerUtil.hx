package away3d.utils;

/**
 * ...
 * @author ...
 */
class TimerUtil
{

	public inline static function setTimeout(closure:Void->Void, delay:Float) : Int 
	{
		return untyped __global__["flash.utils.setTimeout"](closure,delay);
	}
	
	public inline static function clearTimeout(id:Int) : Void 
	{
		return untyped __global__["flash.utils.clearTimeout"](id);
	}
}