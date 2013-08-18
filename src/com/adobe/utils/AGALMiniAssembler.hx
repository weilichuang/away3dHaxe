package com.adobe.utils;

import flash.display3D.Context3DProgramType;
import flash.Lib;
import flash.utils.ByteArray;
import flash.utils.Endian;
import haxe.ds.StringMap.StringMap;

class AGALMiniAssembler 
{
	private static var initialized : Bool = false;
	
	public var error(get, null):String;
	public var agalcode(get, null):ByteArray;

	// AGAL bytes and error buffer
	private var _agalcode : ByteArray;
	private var _error : String;

	private var debugEnabled : Bool;
	
	

	public function new(debugging : Bool = false) : Void 
	{
		_agalcode = null;
		_error = "";
		debugEnabled = debugging;
		if (!initialized) 
			init();
	}

	public function assemble(mode : Context3DProgramType, source : String, verbose : Bool = false) : ByteArray 
	{
		//var start:UInt = getTimer();

		_agalcode = new ByteArray();
		_error = "";

		var isFrag:Bool = false;

		if (mode == Context3DProgramType.FRAGMENT) 
			isFrag = true;

		_agalcode.endian = Endian.LITTLE_ENDIAN;
		_agalcode.writeByte(0xa0);            // tag version
		_agalcode.writeUnsignedInt(0x1);      // AGAL version, big endian, bit pattern will be 0x01000000
		_agalcode.writeByte(0xa1);            // tag program id
		_agalcode.writeByte(isFrag ? 1 : 0);  // vertex or fragment

		var reg : EReg = ~/[\n\r]+/g;
		var lines : Array<String> = reg.replace(source, "\n").split("\n");
		var nest : Int = 0;
		var nops : Int = 0;
		
		var lng : Int = lines.length;
		var i : Int = 0;
		while (i < lng && _error == "") 
		{
			var line : String = lines[i];
			if (line == "")
			{
				i++;
				continue;
			}

			// remove comments
			var startcomment : Int = line.indexOf("//");
			if (startcomment != -1) 
				line = line.substr(0, startcomment);

			// grab options
			reg = ~/<.*>/g;
			var optsi:Int = -1;
			var options:String = line;
			if (reg.match(options))
				optsi = reg.matchedPos().pos;

			var opts:Array<String> = [];
			if (optsi != -1)
			{
				line = line.substr(0, optsi);
				while (optsi != -1)
				{
					options = options.substr(optsi);

					reg = ~/([\w\.\-\+]+)/gi;
					if (reg.match(options))
					{
						opts.push(reg.matched(0));
						var pos = reg.matchedPos();
						optsi = pos.pos + pos.len;
					}
					else
					{
						optsi = -1;
					}
				}
			}

			// find opcode
			reg = ~/^\w{3}/ig;
			var matched:Bool = reg.match(line);
			if (!matched)
			{
				i++;
				continue;
			}
			
			var opCode : String = reg.matched(0);
			var opFound : OpCode = OPMAP.get(opCode);

			// if debug is enabled, output the opcodes
			if (debugEnabled) 
				Lib.trace(opFound);

			if (opFound == null) 
			{
				if (line.length >= 3) 
					Lib.trace("warning: bad line " + i + ": " + lines[i]);
				++i;
				continue;
			}

			line = line.substr(line.indexOf(opFound.name) + opFound.name.length);

			// nesting check
			if ((opFound.flags & OP_DEC_NEST) != 0) 
			{
				nest--;
				if (nest < 0)
				{
					_error = "error: conditional closes without open.";
					break;
				}
			}
			
			if ((opFound.flags & OP_INC_NEST) != 0)
			{
				nest++;
				if (nest > MAX_NESTING) 
				{
					_error = "error: nesting to deep, maximum allowed is " + MAX_NESTING + ".";
					break;
				}
			}
			
			if (((opFound.flags & OP_VERT_ONLY) != 0) && isFrag)
			{
				_error = "error: opcode is only allowed in vertex programs.";
				break;
			}
			
			if (((opFound.flags & OP_FRAG_ONLY) != 0) && !isFrag) 
			{
				_error = "error: opcode is only allowed in fragment programs.";
				break;
			}
			
			if (verbose) 
				Lib.trace("emit opcode=" + opFound);

			_agalcode.writeUnsignedInt( opFound.emitCode );
			nops++;

			if (nops > MAX_OPCODES) 
			{
				_error = "error: too many opcodes. maximum is " + MAX_OPCODES + ".";
				break;
			}

			// get operands, use regexp
			reg = ~/vc\[([vof][acostdip]?)(\d*)?(\.[xyzw](\+\d{1,3})?)?\](\.[xyzw]{1,4})?|([vof][acostdip]?)(\d*)?(\.[xyzw]{1,4})?/gi;
			var subline : String = line;
			var regs : Array<String> = [];
			while (reg.match(subline)) 
			{
				regs.push(reg.matched(0));
				subline = subline.substr(reg.matchedPos().pos + reg.matchedPos().len);
				if (subline.charAt(0) == ",") 
					subline = subline.substr(1);
					
				reg = ~/vc\[([vof][actps]?)(\d*)?(\.[xyzw](\+\d{1,3})?)?\](\.[xyzw]{1,4})?|([vof][actps]?)(\d*)?(\.[xyzw]{1,4})?/gi;
			}
			
			if (regs.length != Std.int(opFound.numRegister)) 
			{
				_error = "error: wrong number of operands. found " + regs.length + " but expected " + opFound.numRegister + ".";
				break;
			}

			var badreg : Bool    = false;
			var pad : Int       = 64 + 64 + 32;
			var regLength : Int = regs.length;
			for (j in 0...regLength)
			{
				var isRelative : Bool = false;
				reg = ~/\[.*\]/ig;
				var relreg : String = "";
				if (reg.match(regs[j])) 
				{
					relreg = reg.matched(0);
					var relpos : Int = source.indexOf(relreg);
					regs[j] = regs[j].substr(0, relpos) + "0" + regs[j].substr(relpos + relreg.length);

					if (verbose) 
						Lib.trace("IS REL");
					isRelative = true;
				}

				reg = ~/^\b[A-Za-z]{1,2}/ig;
				reg.match(regs[j]);
				var res : String = reg.matched(0);
				var regFound : Register = REGMAP.get(res);

				// if debug is enabled, output the registers
				if (debugEnabled) 
					Lib.trace(regFound);

				if (regFound == null) 
				{
					_error = "error: could not parse operand " + j + " (" + regs[j] + ").";
					badreg = true;
					break;
				}

				if (isFrag) 
				{
					if ((regFound.flags & REG_FRAG) == 0) 
					{
						_error = "error: register operand "+j+" ("+regs[j]+") only allowed in vertex programs.";
						badreg = true;
						break;
					}
					if (isRelative) 
					{
						_error = "error: register operand " + j + " (" + regs[j] + ") relative adressing not allowed in fragment programs.";
						badreg = true;
						break;
					}
				}
				else 
				{
					if ((regFound.flags & REG_VERT) == 0)
					{
						_error = "error: register operand " + j + " (" + regs[j] + ") only allowed in fragment programs.";
						badreg = true;
						break;
					}
				}

				regs[j] = regs[j].substr(regs[j].indexOf( regFound.name ) + regFound.name.length);
				//trace( "REGNUM: " +regs[j] );
				reg = ~/\d+/;
				var idxmatched : Bool;
				if (isRelative) 
					idxmatched = reg.match(relreg);
				else 
					idxmatched = reg.match(regs[j]);

				var regidx : UInt = 0;

				if (idxmatched) 
					regidx = Std.parseInt(reg.matched(0));

				if (regFound.range < regidx) 
				{
					_error = "error: register operand " + j + " (" + regs[j] + ") index exceeds limit of " + (regFound.range + 1) + ".";
					badreg = true;
					break;
				}

				var regmask : UInt   = 0;
				var isDest : Bool    = (j == 0 && (opFound.flags & OP_NO_DEST) == 0);
				var isSampler : Bool = (j == 2 && (opFound.flags & OP_SPECIAL_TEX) != 0);
				var reltype : UInt   = 0;
				var relsel : UInt    = 0;
				var reloffset : Int  = 0;

				if (isDest && isRelative) 
				{
					_error = "error: relative can not be destination";
					badreg = true;
					break;
				}

				reg = ~/(\.[xyzw]{1,4})/;
				if (reg.match(regs[j])) 
				{
					var maskmatch : String = reg.matched(0);
					regmask = 0;
					var cv : UInt = 0;
					var maskLength : UInt = maskmatch.length;
					var k : Int = 1;
					while (k < Std.int(maskLength)) 
					{
						cv = maskmatch.charCodeAt(k) - "x".charCodeAt(0);
						if (cv > 2) 
							cv = 3;
						if (isDest) 
							regmask |= 1 << cv;
						else 
							regmask |= cv << ( ( k - 1 ) << 1 );
						++k;
					}
					if (!isDest) 
					{
						while (k <= 4) 
						{
							regmask |= cv << ( ( k - 1 ) << 1 ); // repeat last
							++k;
						}
					}
				}
				else 
					regmask = isDest ? 0xf : 0xe4; // id swizzle or mask

				if (isRelative) 
				{
					reg = ~/[A-Za-z]{1,2}/ig;
					reg.match(relreg);
					var relname : String = reg.matched(0);
					var regFoundRel : Register = REGMAP.get(relname);
					if (regFoundRel == null) 
					{
						_error = "error: bad index register";
						badreg = true;
						break;
					}
					reltype = regFoundRel.emitCode;
					reg = ~/(\.[xyzw]{1,1})/;
					if (!reg.match(relreg)) 
					{
						_error = "error: bad index register select";
						badreg = true;
						break;
					}
					var selmatch : String = reg.matched(0);
					relsel = selmatch.charCodeAt(1) - "x".charCodeAt(0);
					if (relsel > 2) 
						relsel = 3;
					reg = ~/\+\d{1,3}/ig;
					if (reg.match(relreg)) 
					{
						reloffset = Std.parseInt(reg.matched(0));
					}
					if (reloffset < 0 || reloffset > 255) 
					{
						_error = "error: index offset "+reloffset+" out of bounds. [0..255]";
						badreg = true;
						break;
					}
					if (verbose) 
						Lib.trace( "RELATIVE: type="+reltype+"=="+relname+" sel="+relsel+"=="+selmatch+" idx="+regidx+" offset="+reloffset );
				}

				if (verbose) 
					Lib.trace("  emit argcode=" + regFound + "[" + regidx + "][" + regmask + "]");
				
				if (isDest) 
				{
					_agalcode.writeShort(regidx);
					_agalcode.writeByte(regmask);
					_agalcode.writeByte(regFound.emitCode);
					pad -= 32;
				}
				else 
				{
					if (isSampler) 
					{
						if (verbose) 
							Lib.trace("  emit sampler");
						var samplerbits : UInt = 5; // type 5
						var optsLength:UInt = opts.length;
						var bias:Float = 0;
						var k : Int = 0;
						while (k < Std.int(optsLength))
						{
							if (verbose)
							{
								Lib.trace("    opt: " + opts[k]);
							}

							var optfound:Sampler = SAMPLEMAP.get(opts[k]);
							if (optfound == null)
							{
								// todo check that it's a number...
								//trace( "Warning, unknown sampler option: "+opts[k] );
								bias = Std.parseFloat(opts[k]);
								if (verbose)
								{
									Lib.trace("    bias: " + bias);
								}
							}
							else
							{
								if (optfound.flag != SAMPLER_SPECIAL_SHIFT)
								{
									samplerbits &= ~(0xf << optfound.flag);
								}

								samplerbits |= optfound.mask << optfound.flag;
							}
							++k;
						}
						_agalcode.writeShort(regidx);
						_agalcode.writeByte(Std.int(bias * 8.0));
						_agalcode.writeByte(0);
						_agalcode.writeUnsignedInt(samplerbits);

						if (verbose) trace("    bits: " + ( samplerbits - 5 ));
						pad -= 64;
					}
					else 
					{
						if (j == 0) 
						{
							_agalcode.writeUnsignedInt(0);
							pad -= 32;
						}
						_agalcode.writeShort(regidx);
						_agalcode.writeByte(reloffset);
						_agalcode.writeByte(regmask);
						_agalcode.writeByte(regFound.emitCode);
						_agalcode.writeByte(reltype);
						_agalcode.writeShort(isRelative ? ( relsel | ( 1 << 15 ) ) : 0);

						pad -= 64;
					}
				}
			}

			// pad unused regs
			var u:Int = 0;
			while (u < pad) 
			{
				_agalcode.writeByte(0);
				u += 8;
			}

			if (badreg) 
				break;
			++i;
		}

		if (_error != "") 
		{
			_error += "\n  at line " + i + " " + lines[i];
			_agalcode.length = 0;
			Lib.trace(_error);
		}

		// trace the bytecode bytes if debugging is enabled
		if (debugEnabled)
		{
			var dbgLine : String = "generated bytecode:";
			var agalLength : UInt = _agalcode.length;
			var index : UInt = 0;
			while (index < agalLength) 
			{
				if (( index % 16) == 0) 
					dbgLine += "\n";
				if ((index % 4) == 0) 
					dbgLine += " ";

				var byteStr : String = Std.string(_agalcode[index]);// .toString( 16 );
				if (byteStr.length < 2) 
					byteStr = "0" + byteStr;

				dbgLine += byteStr;
				++index;
			}
			Lib.trace( dbgLine );
		}

		//if (verbose) 
			//Lib.trace( "AGALMiniAssembler.assemble time: " + ( ( getTimer() - start ) / 1000 ) + "s" );

		return _agalcode;
	}
	
	private inline function get_error() : String      
	{
		return _error;
	}
	
	private inline function get_agalcode() : ByteArray
	{ 
		return _agalcode; 
	}

	static private function init() : Void 
	{
		initialized = true;

		// Fill the dictionaries with opcodes and registers
		OPMAP.set(MOV, new OpCode(MOV, 2, 0x00, 0));
		OPMAP.set(ADD, new OpCode(ADD, 3, 0x01, 0));
		OPMAP.set(SUB, new OpCode(SUB, 3, 0x02, 0));
		OPMAP.set(MUL, new OpCode(MUL, 3, 0x03, 0));
		OPMAP.set(DIV, new OpCode(DIV, 3, 0x04, 0));
		OPMAP.set(RCP, new OpCode(RCP, 2, 0x05, 0));
		OPMAP.set(MIN, new OpCode(MIN, 3, 0x06, 0));
		OPMAP.set(MAX, new OpCode(MAX, 3, 0x07, 0));
		OPMAP.set(FRC, new OpCode(FRC, 2, 0x08, 0));
		OPMAP.set(SQT, new OpCode(SQT, 2, 0x09, 0));
		OPMAP.set(RSQ, new OpCode(RSQ, 2, 0x0a, 0));
		OPMAP.set(POW, new OpCode(POW, 3, 0x0b, 0));
		OPMAP.set(LOG, new OpCode(LOG, 2, 0x0c, 0));
		OPMAP.set(EXP, new OpCode(EXP, 2, 0x0d, 0));
		OPMAP.set(NRM, new OpCode(NRM, 2, 0x0e, 0));
		OPMAP.set(SIN, new OpCode(SIN, 2, 0x0f, 0));
		OPMAP.set(COS, new OpCode(COS, 2, 0x10, 0));
		OPMAP.set(CRS, new OpCode(CRS, 3, 0x11, 0));
		OPMAP.set(DP3, new OpCode(DP3, 3, 0x12, 0));
		OPMAP.set(DP4, new OpCode(DP4, 3, 0x13, 0));
		OPMAP.set(ABS, new OpCode(ABS, 2, 0x14, 0));
		OPMAP.set(NEG, new OpCode(NEG, 2, 0x15, 0));
		OPMAP.set(SAT, new OpCode(SAT, 2, 0x16, 0));
		OPMAP.set(M33, new OpCode(M33, 3, 0x17, OP_SPECIAL_MATRIX));
		OPMAP.set(M44, new OpCode(M44, 3, 0x18, OP_SPECIAL_MATRIX));
		OPMAP.set(M34, new OpCode(M34, 3, 0x19, OP_SPECIAL_MATRIX));
		OPMAP.set(IFZ, new OpCode(IFZ, 1, 0x1a, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(INZ, new OpCode(INZ, 1, 0x1b, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(IFE, new OpCode(IFE, 2, 0x1c, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(INE, new OpCode(INE, 2, 0x1d, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(IFG, new OpCode(IFG, 2, 0x1e, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(IFL, new OpCode(IFL, 2, 0x1f, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(IEG, new OpCode(IEG, 2, 0x20, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(IEL, new OpCode(IEL, 2, 0x21, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(ELS, new OpCode(ELS, 0, 0x22, OP_NO_DEST | OP_INC_NEST | OP_DEC_NEST));
		OPMAP.set(EIF, new OpCode(EIF, 0, 0x23, OP_NO_DEST | OP_DEC_NEST));
		OPMAP.set(REP, new OpCode(REP, 1, 0x24, OP_NO_DEST | OP_INC_NEST | OP_SCALAR));
		OPMAP.set(ERP, new OpCode(ERP, 0, 0x25, OP_NO_DEST | OP_DEC_NEST));
		OPMAP.set(BRK, new OpCode(BRK, 0, 0x26, OP_NO_DEST));
		OPMAP.set(KIL, new OpCode(KIL, 1, 0x27, OP_NO_DEST | OP_FRAG_ONLY));
		OPMAP.set(TEX, new OpCode(TEX, 3, 0x28, OP_FRAG_ONLY | OP_SPECIAL_TEX));
		OPMAP.set(SGE, new OpCode(SGE, 3, 0x29, 0));
		OPMAP.set(SLT, new OpCode(SLT, 3, 0x2a, 0));
		OPMAP.set(SGN, new OpCode(SGN, 2, 0x2b, 0));
		OPMAP.set(SEQ, new OpCode(SEQ, 3, 0x2c, 0));
		OPMAP.set(SNE, new OpCode(SNE, 3, 0x2d, 0));

		REGMAP.set(VA, new Register(VA,  "vertex attribute",   0x0,   7, REG_VERT | REG_READ));
		REGMAP.set(VC, new Register(VC,  "vertex constant",    0x1, 127, REG_VERT | REG_READ));
		REGMAP.set(VT, new Register(VT,  "vertex temporary",   0x2,   7, REG_VERT | REG_WRITE | REG_READ));
		REGMAP.set(OP, new Register(OP,  "vertex output",      0x3,   0, REG_VERT | REG_WRITE));
		REGMAP.set( V, new Register( V,  "varying",            0x4,   7, REG_VERT | REG_FRAG | REG_READ | REG_WRITE));
		REGMAP.set(FC, new Register(FC,  "fragment constant",  0x1,  27, REG_FRAG | REG_READ));
		REGMAP.set(FT, new Register(FT,  "fragment temporary", 0x2,   7, REG_FRAG | REG_WRITE | REG_READ));
		REGMAP.set(FS, new Register(FS,  "texture sampler",    0x5,   7, REG_FRAG | REG_READ));
		REGMAP.set(OC, new Register(OC,  "fragment output",    0x3,   0, REG_FRAG | REG_WRITE));

		SAMPLEMAP.set(RGBA,       new Sampler(RGBA,       SAMPLER_TYPE_SHIFT,    0));
		SAMPLEMAP.set(DXT1,       new Sampler(DXT1,       SAMPLER_TYPE_SHIFT,    1));
		SAMPLEMAP.set(DXT5,       new Sampler(DXT5,       SAMPLER_TYPE_SHIFT,    2));
		SAMPLEMAP.set(VIDEO,      new Sampler(VIDEO,      SAMPLER_TYPE_SHIFT,    3));
		SAMPLEMAP.set(D2,         new Sampler(D2,         SAMPLER_DIM_SHIFT,     0));
		SAMPLEMAP.set(D3,         new Sampler(D3,         SAMPLER_DIM_SHIFT,     2));
		SAMPLEMAP.set(CUBE,       new Sampler(CUBE,       SAMPLER_DIM_SHIFT,     1));
		SAMPLEMAP.set(MIPNEAREST, new Sampler(MIPNEAREST, SAMPLER_MIPMAP_SHIFT,  1));
		SAMPLEMAP.set(MIPLINEAR,  new Sampler(MIPLINEAR,  SAMPLER_MIPMAP_SHIFT,  2));
		SAMPLEMAP.set(MIPNONE,    new Sampler(MIPNONE,    SAMPLER_MIPMAP_SHIFT,  0));
		SAMPLEMAP.set(NOMIP,      new Sampler(NOMIP,      SAMPLER_MIPMAP_SHIFT,  0));
		SAMPLEMAP.set(NEAREST,    new Sampler(NEAREST,    SAMPLER_FILTER_SHIFT,  0));
		SAMPLEMAP.set(LINEAR,     new Sampler(LINEAR,     SAMPLER_FILTER_SHIFT,  1));
		SAMPLEMAP.set(CENTROID,   new Sampler(CENTROID,   SAMPLER_SPECIAL_SHIFT, 1 << 0));
		SAMPLEMAP.set(SINGLE,     new Sampler(SINGLE,     SAMPLER_SPECIAL_SHIFT, 1 << 1));
		SAMPLEMAP.set(DEPTH,      new Sampler(DEPTH,      SAMPLER_SPECIAL_SHIFT, 1 << 2));
		SAMPLEMAP.set(REPEAT,     new Sampler(REPEAT,     SAMPLER_REPEAT_SHIFT,  1));
		SAMPLEMAP.set(WRAP,       new Sampler(WRAP,       SAMPLER_REPEAT_SHIFT,  1));
		SAMPLEMAP.set(CLAMP,      new Sampler(CLAMP,      SAMPLER_REPEAT_SHIFT,  0));
	}

	private static var OPMAP : StringMap<OpCode>      = new StringMap<OpCode>();
	private static var REGMAP : StringMap<Register>   = new StringMap<Register>();
	private static var SAMPLEMAP : StringMap<Sampler> = new StringMap<Sampler>();

	private static var MAX_NESTING : Int         = 4;
	private static var MAX_OPCODES : Int         = 200;

	private static var FRAGMENT : String         = "fragment";
	private static var VERTEX : String           = "vertex";

	// masks and shifts
	private static var SAMPLER_TYPE_SHIFT:UInt = 8;
	private static var SAMPLER_DIM_SHIFT : UInt     = 12;
	private static var SAMPLER_SPECIAL_SHIFT : UInt = 16;
	private static var SAMPLER_REPEAT_SHIFT : UInt  = 20;
	private static var SAMPLER_MIPMAP_SHIFT : UInt  = 24;
	private static var SAMPLER_FILTER_SHIFT : UInt  = 28;

	// regmap flags
	private static var REG_WRITE : UInt           = 0x1;
	private static var REG_READ : UInt            = 0x2;
	private static var REG_FRAG : UInt            = 0x20;
	private static var REG_VERT : UInt            = 0x40;

	// opmap flags
	private static var OP_SCALAR : UInt            = 0x1;
	private static var OP_INC_NEST : UInt          = 0x2;
	private static var OP_DEC_NEST : UInt          = 0x4;
	private static var OP_SPECIAL_TEX : UInt       = 0x8;
	private static var OP_SPECIAL_MATRIX : UInt    = 0x10;
	private static var OP_FRAG_ONLY : UInt         = 0x20;
	private static var OP_VERT_ONLY : UInt         = 0x40;
	private static var OP_NO_DEST : UInt           = 0x80;
	private static var OP_VERSION2:UInt            = 0x100;
	private static var OP_INCNEST:UInt             = 0x200;
	private static var OP_DECNEST:UInt             = 0x400;

	// opcodes
	private static inline var MOV : String              = "mov";
	private static inline var ADD : String              = "add";
	private static inline var SUB : String              = "sub";
	private static inline var MUL : String              = "mul";
	private static inline var DIV : String              = "div";
	private static inline var RCP : String              = "rcp";
	private static inline var MIN : String              = "min";
	private static inline var MAX : String              = "max";
	private static inline var FRC : String              = "frc";
	private static inline var SQT : String              = "sqt";
	private static inline var RSQ : String              = "rsq";
	private static inline var POW : String              = "pow";
	private static inline var LOG : String              = "log";
	private static inline var EXP : String              = "exp";
	private static inline var NRM : String              = "nrm";
	private static inline var SIN : String              = "sin";
	private static inline var COS : String              = "cos";
	private static inline var CRS : String              = "crs";
	private static inline var DP3 : String              = "dp3";
	private static inline var DP4 : String              = "dp4";
	private static inline var ABS : String              = "abs";
	private static inline var NEG : String              = "neg";
	private static inline var SAT : String              = "sat";
	private static inline var M33 : String              = "m33";
	private static inline var M44 : String              = "m44";
	private static inline var M34 : String              = "m34";
	private static inline var IFZ : String              = "ifz";
	private static inline var INZ : String              = "inz";
	private static inline var IFE : String              = "ife";
	private static inline var INE : String              = "ine";
	private static inline var IFG : String              = "ifg";
	private static inline var IFL : String              = "ifl";
	private static inline var IEG : String              = "ieg";
	private static inline var IEL : String              = "iel";
	private static inline var ELS : String              = "els";
	private static inline var EIF : String              = "eif";
	private static inline var REP : String              = "rep";
	private static inline var ERP : String              = "erp";
	private static inline var BRK : String              = "brk";
	private static inline var KIL : String              = "kil";
	private static inline var TEX : String              = "tex";
	private static inline var SGE : String              = "sge";
	private static inline var SLT : String              = "slt";
	private static inline var SGN : String              = "sgn";
	private static inline var SEQ :String               = "seq";
	private static inline var SNE :String               = "sne";

	// registers
	private static var VA : String              = "va";
	private static var VC : String              = "vc";
	private static var VT : String              = "vt";
	private static var OP : String              = "op";
	private static var V  : String              = "v";
	private static var FC : String              = "fc";
	private static var FT : String              = "ft";
	private static var FS : String              = "fs";
	private static var OC : String              = "oc";

	// samplers
	private static var D2 : String              = "2d";
	private static var D3 : String              = "3d";
	private static var CUBE : String            = "cube";
	private static var MIPNEAREST : String      = "mipnearest";
	private static var MIPLINEAR : String       = "miplinear";
	private static var MIPNONE : String         = "mipnone";
	private static var NOMIP : String           = "nomip";
	private static var NEAREST : String         = "nearest";
	private static var LINEAR : String          = "linear";
	private static var CENTROID : String        = "centroid";
	private static var SINGLE : String          = "single";
	private static var DEPTH : String           = "depth";
	private static var REPEAT : String          = "repeat";
	private static var WRAP : String            = "wrap";
	private static var CLAMP : String           = "clamp";
	private static var RGBA:String 				= "rgba";
	private static var DXT1:String 				= "dxt1";
	private static var DXT5:String				= "dxt5";
	private static var VIDEO:String 			= "video";
}

// ================================================================================
//  Helper Classes
// --------------------------------------------------------------------------------
class OpCode
{
	public var emitCode : UInt;
	public var flags : UInt;
	public var name : String;
	public var numRegister : UInt;
	
	public function new(name : String, numRegister : UInt, emitCode : UInt, flags : UInt) 
	{
		this.name = name;
		this.numRegister = numRegister;
		this.emitCode = emitCode;
		this.flags = flags;
	}

	public function toString() : String 
	{
		return "[OpCode name=\"" + name + "\", numRegister=" + numRegister + ", emitCode=" + emitCode + ", flags=" + flags + "]";
	}
}


class Register 
{

	public var emitCode : UInt;
	public var name:String;
	public var longName:String;
	public var flags:UInt;
	public var range:UInt;

	public function new(name : String, longName : String, emitCode : UInt, range : UInt, flags : UInt) 
	{
		this.name = name;
		this.longName = longName;
		this.emitCode = emitCode;
		this.range = range;
		this.flags = flags;
	}

	public function toString() : String 
	{
		return "[Register name=\"" + this.name + "\", longName=\"" + this.longName + "\", emitCode=" + this.emitCode + ", range=" + this.range + ", flags=" + this.flags + "]";
	}
}


class Sampler 
{
	public var flag : UInt;
	public var mask : UInt;
	public var name : String;
	
	public function new(name : String, flag : UInt, mask : UInt) 
	{
		this.name = name;
		this.flag = flag;
		this.mask = mask;
	}

	public function toString() : String 
	{
		return "[Sampler name=\"" + name.toString() + "\", flag=\"" + flag.toString() + "\", mask=" + mask.toString() + "]";
	}
}