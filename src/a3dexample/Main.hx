package a3dexample;
import flash.display.Sprite;
import flash.Lib;

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