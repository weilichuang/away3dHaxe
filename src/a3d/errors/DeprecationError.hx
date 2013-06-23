package a3d.errors
import flash.errors.Error;

class DeprecationError extends Error
{
	public var since:String;
	public var source:String;
	public var info:String;


	public function new(source:String, since:String, info:String)
	{
		super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. " + info);
		this.since = since;
		this.source = source;
		this.info = info;
	}
}
