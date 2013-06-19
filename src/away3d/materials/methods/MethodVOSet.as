package away3d.materials.methods
{
	public class MethodVOSet
	{
		

		public var method:EffectMethodBase;
		public var data:MethodVO;

		public function MethodVOSet(method:EffectMethodBase)
		{
			this.method = method;
			data = method.createMethodVO();
		}
	}
}
