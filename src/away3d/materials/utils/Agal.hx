package away3d.materials.utils;

/**
 * ...
 * @author 
 */
class Agal
{

	public function new() 
	{
		
	}
	
	public static inline function mov(des:String, src1:String):String
	{
		return 'mov ${des},${src1}\n';
		//"mov $}" + des + "," + src1 + "\n";
	}
	
	public static inline function add(des:String, src1:String,src2:String):String
	{
		return 'add $des,$src1,$src2\n';
		//"add " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function sub(des:String, src1:String,src2:String):String
	{
		return 'sub $des,$src1,$src2\n';
		//"sub " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function mul(des:String, src1:String,src2:String):String
	{
		return 'mul ${des},${src1},${src2}\n';
		//return "mul " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function div(des:String, src1:String,src2:String):String
	{
		return 'div $des,$src1,$src2\n';
		//"div " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function rcp(des:String, src1:String):String
	{
		return 'rcp $des,$src1\n';
		//"rcp " + des + "," + src1 + "\n";
	}
	
	public static inline function min(des:String, src1:String,src2:String):String
	{
		return 'min $des,$src1,$src2\n';
		//return "min " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function max(des:String, src1:String,src2:String):String
	{
		return 'max $des,$src1,$src2\n';
		//return "max " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function frc(des:String, src1:String):String
	{
		return 'frc $des,$src1\n';
		//return "frc " + des + "," + src1 + "\n";
	}
	
	public static inline function sqt(des:String, src1:String):String
	{
		return 'sqt $des,$src1\n';
		//return "sqt " + des + "," + src1 + "\n";
	}
	
	public static inline function rsq(des:String, src1:String):String
	{
		return 'rsq $des,$src1\n';
		//return "rsq " + des + "," + src1 + "\n";
	}
	
	public static inline function pow(des:String, src1:String,src2:String):String
	{
		return 'pow $des,$src1,$src2\n';
		//return "pow " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function log(des:String, src1:String):String
	{
		return 'log $des,$src1\n';
		//return "log " + des + "," + src1 + "\n";
	}
	
	public static inline function exp(des:String, src1:String):String
	{
		return 'exp $des,$src1\n';
		//return "exp " + des + "," + src1 + "\n";
	}
	
	public static inline function nrm(des:String, src1:String):String
	{
		return 'nrm $des,$src1\n';
		//return "nrm " + des + "," + src1 + "\n";
	}
	
	public static inline function sin(des:String, src1:String):String
	{
		return 'sin $des,$src1\n';
		//return "sin " + des + "," + src1 + "\n";
	}
	
	public static inline function cos(des:String, src1:String):String
	{
		return 'cos $des,$src1\n';
		//return "cos " + des + "," + src1 + "\n";
	}
	
	public static inline function crs(des:String, src1:String,src2:String):String
	{
		return 'crs $des,$src1,$src2\n';
		//return "crs " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function dp3(des:String, src1:String,src2:String):String
	{
		return 'dp3 $des,$src1,$src2\n';
		//return "dp3 " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function dp4(des:String, src1:String,src2:String):String
	{
		return 'dp4 $des,$src1,$src2\n';
		//return "dp4 " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function abs(des:String, src1:String):String
	{
		return 'abs $des,$src1\n';
		//return "abs " + des + "," + src1 + "\n";
	}
	
	public static inline function neg(des:String, src1:String):String
	{
		return 'neg $des,$src1\n';
		//return "neg " + des + "," + src1 + "\n";
	}
	
	public static inline function sat(des:String, src1:String):String
	{
		return 'sat $des,$src1\n';
		//return "sat " + des + "," + src1 + "\n";
	}
	
	public static inline function m33(des:String, src1:String,src2:String):String
	{
		return 'm33 $des,$src1,$src2\n';
		//return "m33 " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function m44(des:String, src1:String,src2:String):String
	{
		return 'm44 $des,$src1,$src2\n';
		//return "m44 " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function m34(des:String, src1:String,src2:String):String
	{
		return 'm34 $des,$src1,$src2\n';
		//return "m34 " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function kil(des:String):String
	{
		return 'kil $des\n';
		//return "kil " + des + "\n";
	}
	
	public static inline function tex(des:String, src1:String,src2:String):String
	{
		return 'tex $des,$src1,<$src2>\n';
		//return "tex " + des + "," + src1 + ",<" + src2 + ">\n";
	}
	
	public static inline function sge(des:String, src1:String,src2:String):String
	{
		return 'sge $des,$src1,$src2\n';
		//return "sge " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function slt(des:String, src1:String,src2:String):String
	{
		return 'slt $des,$src1,$src2\n';
		//return "slt " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function seq(des:String, src1:String,src2:String):String
	{
		return 'seq $des,$src1,$src2\n';
		//return "seq " + des + "," + src1 + "," + src2 + "\n";
	}
	
	public static inline function sne(des:String, src1:String,src2:String):String
	{
		return 'sne $des,$src1,$src2\n';
		//return "sne " + des + "," + src1 + "," + src2 + "\n";
	}
}