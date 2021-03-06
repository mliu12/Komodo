include "ARMdef.s.dfy"

type exvector = Maybe<string>
datatype vectbl = VecTable(
    reset: exvector,
    undef: exvector,
    svc_smc: exvector,
    prefetch_abort: exvector,
    data_abort: exvector,
    irq: exvector,
    fiq: exvector)

function method emptyVecTbl(): vectbl
{
    VecTable(Nothing, Nothing, Nothing, Nothing, Nothing, Nothing, Nothing)
}

function method user_continue_label(): string
{
    "usermode_return_continue"
}

method nl()
{
    print("\n");
}

function method cmpNot(c:ocmp):ocmp
{
    match c
        case OEq => ONe
        case ONe => OEq
        case OLe => OGt
        case OGe => OLt
        case OLt => OGe
        case OGt => OLe
        case OTstEq => OTstNe
        case OTstNe => OTstEq
}

method printBcc(c:ocmp)
{
    match c
        case OEq => print("  BEQ ");
        case ONe => print("  BNE ");
        case OLe => print("  BLE ");
        case OGe => print("  BGE ");
        case OLt => print("  BLT ");
        case OGt => print("  BGT ");
        case OTstEq => print("  BEQ ");
        case OTstNe => print("  BNE ");
}

method printCmp(c:ocmp, o1:operand, o2:operand)
{
    if c == OTstEq || c == OTstNe {
        printIns2Op("TST", o1, o2);
    } else {
        printIns2Op("CMP", o1, o2);
    }
}

method printMode(m:mode)
{
    match m
        case User => print("usr");
        case FIQ => print("fiq");
        case IRQ => print("irq");
        case Supervisor => print("svc");
        case Abort => print("abt");
        case Undefined => print("und");
        case Monitor => print("mon");
}

method printReg(r:ARMReg)
{
    match r
        case R0 => print("r0");
        case R1 => print("r1");
        case R2 => print("r2");
        case R3 => print("r3");
        case R4 => print("r4");
        case R5 => print("r5");
        case R6 => print("r6");
        case R7 => print("r7");
        case R8 => print("r8");
        case R9 => print("r9");
        case R10 => print("r10");
        case R11 => print("r11");
        case R12 => print("r12");
        case SP(m) => print("sp_"); printMode(m);
        case LR(m) => print("lr_"); printMode(m);
}

method printShift(s:Shift)
{
    match s
        case LSLShift(amount) => if amount == 0 { 
                                     print("Shifts cannot be 0!"); 
                                 } else { 
                                     print("lsl#"); 
                                     print(amount); 
                                 }
        case LSRShift(amount) => if amount == 0 { 
                                     print("Shifts cannot be 0!"); 
                                 } else { 
                                     print("lsr#"); 
                                     print(amount); 
                                 }
        case RORShift(amount) => if amount == 0 { 
                                     print("Shifts cannot be 0!"); 
                                 } else { 
                                     print("ror#"); 
                                     print(amount); 
                                 }
}

method printOperand(o:operand)
{
    match o
        case OConst(n) => print("#"); print(n);
        case OReg(r) => { printReg(r); }
        case OShift(r, s) => { printReg(r); print(","); printShift(s); }
        case OSReg(r) =>
            if (r == cpsr) {
                print("cpsr");
            } else if (r.spsr?) {
                print("spsr_"); printMode(r.m);
            } else {
                print("XXX-invalid-OSReg");
            }
        case OSP => print("sp");
        case OLR => print("lr");
}

method printIns3Op(instr:string, dest:operand, src1:operand, src2:operand)
{
    print("  ");
    print(instr);
    print(" ");
    printOperand(dest);
    print(", ");
    printOperand(src1);
    print(", ");
    printOperand(src2);
    nl();
}

method printIns2Op(instr:string, dest:operand, src:operand)
{
    print("  ");
    print(instr);
    print(" ");
    printOperand(dest);
    print(", ");
    printOperand(src);
    nl();
}

method printIns1Op(instr:string, op:operand)
{
    print("  ");
    print(instr);
    print(" ");
    printOperand(op);
    nl();
}

method printInsFixed(instr:string, ops:string)
{
    print("  ");
    print(instr);
    print(" ");
    print(ops);
    nl();
}

method printInsReloc(instr:string, op:operand, sym:symbol)
{
    print("  ");
    print(instr);
    print(" ");
    printOperand(op);
    print(", =");
    print(sym);
    nl();
}

method printMcr(instr:string, sro:operand, op:operand)
{

    print("  ");
    print(instr);

    if (sro.OSReg?) {
        var sr := sro.sr;
        print(" p15, 0, ");
        printOperand(op);
        match sr
        {
            case cpsr => print("XXX-invalid: CPSR in MCR");
            case spsr(m) => print("XXX invalid: SPSR in MCR");
            case SCTLR => print(", c1, c0, 0");
            case SCR => print(", c1, c1, 0");
            case VBAR => print(", c12, c0, 0");
            case ttbr0 => print(", c2, c0, 0");
            case TLBIALL => print(", c8, c7, 0");
            //case TLBIASID => print(", c8, c7, 2");
        }
    } else {
        print("XXX-invalid-sreg");
    }
    nl();
}

method printInsLdStr(instr:string, dest:operand, base:operand, offset:operand)
{
    print("  ");
    print(instr);
    print(" ");
    printOperand(dest);
    print(", [");
    printOperand(base);
    if (offset != OConst(0)) {
        print(", ");
        printOperand(offset);
    }
    print("]");
    nl();
}

method printIns(ins:ins)
{
    match ins
    {
        case ADD(dest, src1, src2) => printIns3Op("ADD", dest, src1, src2);
        case SUB(dest, src1, src2) => printIns3Op("SUB", dest, src1, src2);
        case MUL(dest, src1, src2) => printIns3Op("MUL", dest, src1, src2);
        case UDIV(dest, src1, src2) => printIns3Op("UDIV", dest, src1, src2);
        case AND(dest, src1, src2) => printIns3Op("AND", dest, src1, src2);
        case ORR(dest, src1, src2) => printIns3Op("ORR", dest, src1, src2);
        case EOR(dest, src1, src2) => printIns3Op("EOR", dest, src1, src2);
        case LSL(dest, src1, src2) => printIns3Op("LSL", dest, src1, src2);
        case LSR(dest, src1, src2) => printIns3Op("LSR", dest, src1, src2);
        case REV(dest, src) => printIns2Op("REV", dest, src);
        case MVN(dest, src) => printIns2Op("MVN", dest, src);
        case LDR(rd, base, ofs) => printInsLdStr("LDR", rd, base, ofs);
        case LDR_global(rd, global, base, ofs) => printInsLdStr("LDR", rd, base, ofs);
        case LDR_rng(rd, base, ofs) => printInsLdStr("LDR", rd, base, ofs);
        case LDR_reloc(rd, sym) => printInsReloc("LDR", rd, sym);
        case STR(rd, base, ofs) => printInsLdStr("STR", rd, base, ofs);
        case STR_global(rd, global, base, ofs) => printInsLdStr("STR", rd, base, ofs);
        case MOV(dst, src) => printIns2Op("MOV", dst, src);
        case MOVW(dst, src) => printIns2Op("MOVW", dst, src);
        case MOVT(dst, src) => printIns2Op("MOVT", dst, src);
        case MRS(dst, src) => printIns2Op("MRS", dst, src);
        case MSR(dst, src) => printIns2Op("MSR", dst, src);
        case MRC(dst, src) => printMcr("MRC", src, dst);
        case MCR(dst,src) => {
            printMcr("MCR", dst, src);
            printInsFixed("ISB", "");
        }
        case CPSID_IAF(mod) => printIns1Op("CPSID iaf,", mod);
        case MOVS_PCLR_TO_USERMODE_AND_CONTINUE =>
            printInsFixed("MOVS", "pc, lr");
            print(user_continue_label()); print(":"); nl();
    }
}

method printBlock(b:codes, n:int) returns(n':int)
{
    n' := n;
    var i := b;
    while (i.va_CCons?)
        decreases i
    {
        n' := printCode(i.hd, n');
        i := i.tl;
    }
}

method printLabel(n:int)
{
    print("L");
    print(n);
}

method printCode(c:code, n:int) returns(n':int)
{
    match c
    {
        case Ins(ins) => printIns(ins); n':= n;
        case Block(block) => n' := printBlock(block, n);
        case IfElse(ifb, ift, iff) => {
            var false_branch := n;
            var end_of_block := n + 1;
            // Do comparison
            printCmp(ifb.cmp, ifb.o1, ifb.o2);
            // Branch to false branch if cond is false
            printBcc(cmpNot(ifb.cmp)); printLabel(false_branch); nl();
            // True branch
            n' := printCode(ift, n + 2);
            print("  B "); printLabel(end_of_block); nl();
            printLabel(false_branch); print(":"); nl();
            // False branch
            n' := printCode(iff, n');
            // Label end of block
            printLabel(end_of_block); print(":"); nl();
        }   
        case While(b, loop) =>
        {
          var n1 := n;
          var n2 := n + 1;
          print("  B "); printLabel(n2); nl();
          print(".LTORG"); nl();
          printLabel(n1); print(":"); nl();
          n' := printCode(loop, n + 2);
          printLabel(n2); print(":"); nl();
          printCmp(b.cmp, b.o1, b.o2);
          printBcc(b.cmp); printLabel(n1); nl();
        }
    }
}

method printFunction(symname:string, c:code, n:int) returns(n':int)
{
    print(".global "); print(symname); nl();
    print(symname); print(":"); nl();
    n' := printCode(c, n);
}

method printHeader()
{
    print(".arm"); nl();
    print(".section .text"); nl();
}

method printVecTblEntry(vector: exvector)
{
    match vector 
        case Nothing =>
            print("1: B 1b"); nl();
        case Just(symname) =>
            print("  B "); print(symname); nl();
}

method printVecTbl(symname: string, vectbl: vectbl)
{
    print(".align 5"); nl();
    print(".global "); print(symname); nl();
    print(symname); print(":"); nl();
    printVecTblEntry(vectbl.reset);
    printVecTblEntry(vectbl.undef);
    printVecTblEntry(vectbl.svc_smc);
    printVecTblEntry(vectbl.prefetch_abort);
    printVecTblEntry(vectbl.data_abort);
    printVecTblEntry(Nothing); // reserved
    printVecTblEntry(vectbl.irq);
    printVecTblEntry(vectbl.fiq);
}


method printGlobal(symname: string, bytes: int)
{
    print(".lcomm ");
    print(symname);
    print(", ");
    print(bytes);
    nl();
}

method printBss(gdecls: globaldecls)
    requires ValidGlobalDecls(gdecls)
{
    print(".section .bss"); nl();
    print(".align 2"); nl(); // 4-byte alignment
    var syms := (set k | k in gdecls :: k);
    while (|syms| > 0)
        invariant forall s :: s in syms ==> s in gdecls;
    {
        var s :| s in syms;
        printGlobal(s, gdecls[s]);
        syms := syms - {s};
    }
}
