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
    VL_IN8(start,0,0);
    VL_OUT8(flag,0,0);
    VL_OUT8(stage,1,0);
    VL_OUT8(butterfly,1,0);
    VL_OUT8(start_fft,0,0);
    VL_OUT8(mag_index,2,0);
    VL_OUT8(twiddle_index,1,0);
    VL_OUT8(start_mag,0,0);
    VL_IN8(mag_done,0,0);
    VL_OUT8(result_init,0,0);
    VL_OUT8(result_wr_en,0,0);
    CData/*0:0*/ control__DOT__start;
    CData/*0:0*/ control__DOT__flag;
    CData/*1:0*/ control__DOT__stage;
    CData/*1:0*/ control__DOT__butterfly;
    CData/*0:0*/ control__DOT__start_fft;
    CData/*2:0*/ control__DOT__mag_index;
    CData/*1:0*/ control__DOT__twiddle_index;
    CData/*0:0*/ control__DOT__start_mag;
    CData/*0:0*/ control__DOT__mag_done;
    CData/*0:0*/ control__DOT__result_init;
    CData/*0:0*/ control__DOT__result_wr_en;
    CData/*0:0*/ control__DOT__clk;
    CData/*0:0*/ control__DOT__rst_n;
    CData/*2:0*/ control__DOT__state;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst_n__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // PARAMETERS
    static constexpr CData/*2:0*/ control__DOT__IDLE = 0U;
    static constexpr CData/*2:0*/ control__DOT__FFT_START = 1U;
    static constexpr CData/*2:0*/ control__DOT__FFT_RUN = 2U;
    static constexpr CData/*2:0*/ control__DOT__MAG_START = 3U;
    static constexpr CData/*2:0*/ control__DOT__MAG_WAIT = 4U;
    static constexpr CData/*2:0*/ control__DOT__DONE = 5U;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
