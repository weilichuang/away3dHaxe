package a3dexample;
import flash.display.Sprite;
import flash.Lib;
import flash.Vector.Vector;
using a3d.utils.VectorUtil;
/**
 * ...
 * @author 
 */
class Main extends Sprite
{
	static function main()
	{
		var t:Main = new Main();
		t.x = 200;
		
		t.graphics.beginFill(0x0);
		t.graphics.drawRect(0, 0, 400, 400);
		t.graphics.endFill();
		
		Lib.current.addChild(t);
		
		trace(t.x);
		
		var list:Vector<Int> = Vector.ofArray([1, 2, 3, 4, 5]);
		Lib.trace(list);
		list.insert(3, 6);
		Lib.trace(list);
	}

	public function new() 
	{
		super();
	}
	//
	@:getter(x) function getX():Float
	{
		return super.x;
	}
	//
	@:setter(x) function setX(x:Float):Void
	{
		super.x = x;
	}
	
}