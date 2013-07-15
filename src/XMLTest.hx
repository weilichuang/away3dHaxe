package ;
import flash.Lib;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.Namespace;
import flash.xml.XML;
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
		var effects = fast.node.resolve(":library_effects");
		var materials = fast.node.resolve(":library_materials");
		var geometries = fast.node.resolve(":library_geometries");
		var lights = fast.node.resolve(":library_lights");
		var images = fast.node.resolve(":library_images");

		
		//var xml2 = Xml.parse("<myNode1 id='sdfsdf'></myNode1><myNode2/>");
//
		//var fast2 = new haxe.xml.Fast(xml2.firstElement());
//
		//var myNode1Value = fast2.node.myNode1.att.id;
		// parse some xml data
		
		var xml2 = Xml.parse("
			<user name='john'>
				<phone>
					<number>0000</number>
					<number>111</number>
				</phone>
			</user>
		");

		// wrap the xml for fast access
		var fast2 = new Fast(xml2.firstElement());

		// access attributes
		trace(fast2.att.name); // attribute "name"
		if ( fast2.has.age ) 
			trace( fast2.att.age ); // optional attribute

		// access the "phone" child, which is wrapped with haxe.xml.Fast too
		var phone = fast2.node.phone;

		// iterate over numbers
		for( p in phone.nodes.number ) {
			 trace(p.innerData);
		}
	}
	
}

//Infinite, 3D head model
@:file("embeds/dae/Medieval_building.DAE") class HeadModel extends ByteArray {}
