// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__pch.h"
#include "Vtop.h"
#include "Vtop___024root.h"

// FUNCTIONS
Vtop__Syms::~Vtop__Syms()
{

    // Tear down scope hierarchy
    __Vhier.remove(0, &__Vscope_control);

}

Vtop__Syms::Vtop__Syms(VerilatedContext* contextp, const char* namep, Vtop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
        // Check resources
        Verilated::stackCheck(37);
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", "<null>", 0, VerilatedScope::SCOPE_OTHER);
    __Vscope_control.configure(this, name(), "control", "control", "control", -9, VerilatedScope::SCOPE_MODULE);

    // Set up scope hierarchy
    __Vhier.add(0, &__Vscope_control);

    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
        __Vscope_TOP.varInsert(__Vfinal,"butterfly", &(TOP.butterfly), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,1 ,1,0);
        __Vscope_TOP.varInsert(__Vfinal,"clk", &(TOP.clk), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"flag", &(TOP.flag), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"mag_done", &(TOP.mag_done), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"mag_index", &(TOP.mag_index), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_TOP.varInsert(__Vfinal,"result_init", &(TOP.result_init), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"result_wr_en", &(TOP.result_wr_en), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"rst_n", &(TOP.rst_n), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"stage", &(TOP.stage), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,1 ,1,0);
        __Vscope_TOP.varInsert(__Vfinal,"start", &(TOP.start), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"start_fft", &(TOP.start_fft), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"start_mag", &(TOP.start_mag), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,0);
        __Vscope_TOP.varInsert(__Vfinal,"twiddle_index", &(TOP.twiddle_index), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0,1 ,1,0);
        __Vscope_control.varInsert(__Vfinal,"DONE", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__DONE))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"FFT_RUN", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__FFT_RUN))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"FFT_START", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__FFT_START))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"IDLE", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__IDLE))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"MAG_START", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__MAG_START))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"MAG_WAIT", const_cast<void*>(static_cast<const void*>(&(TOP.control__DOT__MAG_WAIT))), true, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"butterfly", &(TOP.control__DOT__butterfly), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,1,0);
        __Vscope_control.varInsert(__Vfinal,"clk", &(TOP.control__DOT__clk), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"flag", &(TOP.control__DOT__flag), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"mag_done", &(TOP.control__DOT__mag_done), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"mag_index", &(TOP.control__DOT__mag_index), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"result_init", &(TOP.control__DOT__result_init), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"result_wr_en", &(TOP.control__DOT__result_wr_en), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"rst_n", &(TOP.control__DOT__rst_n), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"stage", &(TOP.control__DOT__stage), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,1,0);
        __Vscope_control.varInsert(__Vfinal,"start", &(TOP.control__DOT__start), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"start_fft", &(TOP.control__DOT__start_fft), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"start_mag", &(TOP.control__DOT__start_mag), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,0);
        __Vscope_control.varInsert(__Vfinal,"state", &(TOP.control__DOT__state), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,2,0);
        __Vscope_control.varInsert(__Vfinal,"twiddle_index", &(TOP.control__DOT__twiddle_index), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0,1 ,1,0);
    }
}
