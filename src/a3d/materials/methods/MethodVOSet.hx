package a3d.materials.methods
{
	class MethodVOSet
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
