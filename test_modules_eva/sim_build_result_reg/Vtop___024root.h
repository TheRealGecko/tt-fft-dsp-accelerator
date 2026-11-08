// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst_n,0,0);
    VL_IN8(magnitude,7,0);
    VL_IN8(mag_rd_addr,2,0);
    VL_OUT8(peak_bin_index,2,0);
    VL_OUT8(magnitudes,7,0);
    VL_IN8(init,0,0);
    VL_IN8(wr_en,0,0);
    VL_IN8(bin_index,2,0);
    CData/*0:0*/ result_reg__DOT__clk;
    CData/*0:0*/ result_reg__DOT__rst_n;
    CData/*7:0*/ result_reg__DOT__magnitude;
    CData/*2:0*/ result_reg__DOT__mag_rd_addr;
    CData/*2:0*/ result_reg__DOT__peak_bin_index;
    CData/*7:0*/ result_reg__DOT__magnitudes;
    CData/*0:0*/ result_reg__DOT__init;
    CData/*0:0*/ result_reg__DOT__wr_en;
    CData/*2:0*/ result_reg__DOT__bin_index;
    CData/*7:0*/ result_reg__DOT__peak_mag;
    CData/*2:0*/ result_reg__DOT__peak_idx;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ result_reg__DOT__i;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*7:0*/, 8> result_reg__DOT__mem;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
