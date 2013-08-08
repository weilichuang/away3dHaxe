package ;
import de.polygonal.gl.codec.JPEGEncode;
import flash.display.BitmapData;
import flash.Lib;
import flash.text.TextField;
/**
 * ...
 * @author ...
 */
class JPGEncodeTest
{
	static function main()
	{
		var tf:TextField = new TextField();
		tf.width = 200;
		Lib.current.addChild(tf);
		var code:JPEGEncode = new JPEGEncode(80);
		
		var time:Int = Lib.getTimer();
		code.encode(new BitmapData(2048, 2048, true, 0));
		tf.text = (Lib.getTimer() - time) + "";
	}

	public function new() 
	{
		
	}
	
}