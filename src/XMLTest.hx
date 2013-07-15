package ;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import haxe.xml.Fast;

/**
 * ...
 * @author ...
 */
class XMLTest
{
	static function main()
	{
		new XMLTest();
	}

	public function new() 
	{
		var data:ByteArray = new HeadModel();
		data.position = 0;
		var xml:Xml = Xml.parse(data.readUTFBytes(data.length));
		var fast:Fast = new Fast(xml.firstElement());
		var xmlns:String = fast.att.xmlns;
		var effects = fast.node.library_effects;
		var materials = fast.node.library_materials;
		var geometries = fast.node.library_geometries;
		var lights = fast.node.library_lights;
		var images = fast.node.library_images;
	}
	
}

//Infinite, 3D head model
@:file("embeds/dae/Medieval_building.DAE") class HeadModel extends ByteArray {}
