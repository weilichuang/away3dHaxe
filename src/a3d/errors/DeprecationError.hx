package a3d.errors
{

	class DeprecationError extends Error
	{
		private var _since:String;
		private var _source:String;
		private var _info:String;


		public function DeprecationError(source:String, since:String, info:String)
		{
			super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. " + info);
			_since = since;
			_source = source;
			_info = info;
		}

		private inline function get_since():String
		{
			return _since;
		}

		private inline function get_source():String
		{
			return _source;
		}

		private inline function get_info():String
		{
			return _info;
		}
	}
}
