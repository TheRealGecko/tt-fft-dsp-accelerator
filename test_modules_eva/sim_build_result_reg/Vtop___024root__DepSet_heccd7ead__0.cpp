// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop___024root.h"

void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        Vtop___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtop___024root___ico_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___ico_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.result_reg__DOT__clk = vlSelfRef.clk;
    vlSelfRef.result_reg__DOT__rst_n = vlSelfRef.rst_n;
    vlSelfRef.result_reg__DOT__magnitude = vlSelfRef.magnitude;
    vlSelfRef.result_reg__DOT__mag_rd_addr = vlSelfRef.mag_rd_addr;
    vlSelfRef.result_reg__DOT__init = vlSelfRef.init;
    vlSelfRef.result_reg__DOT__wr_en = vlSelfRef.wr_en;
    vlSelfRef.result_reg__DOT__bin_index = vlSelfRef.bin_index;
    vlSelfRef.peak_bin_index = vlSelfRef.result_reg__DOT__peak_idx;
    vlSelfRef.result_reg__DOT__peak_bin_index = vlSelfRef.result_reg__DOT__peak_idx;
    vlSelfRef.magnitudes = vlSelfRef.result_reg__DOT__mem
        [vlSelfRef.mag_rd_addr];
    vlSelfRef.result_reg__DOT__magnitudes = vlSelfRef.result_reg__DOT__mem
        [vlSelfRef.mag_rd_addr];
}

void Vtop___024root___eval_triggers__ico(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__ico(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__ico\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelfRef.__VicoTriggered.any();
    if (__VicoExecute) {
        Vtop___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vtop___024root___eval_act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf);

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*7:0*/ __Vdly__result_reg__DOT__peak_mag;
    __Vdly__result_reg__DOT__peak_mag = 0;
    CData/*0:0*/ __VdlySet__result_reg__DOT__mem__v0;
    __VdlySet__result_reg__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__result_reg__DOT__mem__v8;
    __VdlyVal__result_reg__DOT__mem__v8 = 0;
    CData/*2:0*/ __VdlyDim0__result_reg__DOT__mem__v8;
    __VdlyDim0__result_reg__DOT__mem__v8 = 0;
    CData/*0:0*/ __VdlySet__result_reg__DOT__mem__v8;
    __VdlySet__result_reg__DOT__mem__v8 = 0;
    // Body
    __Vdly__result_reg__DOT__peak_mag = vlSelfRef.result_reg__DOT__peak_mag;
    __VdlySet__result_reg__DOT__mem__v0 = 0U;
    __VdlySet__result_reg__DOT__mem__v8 = 0U;
    if ((1U & ((~ (IData)(vlSelfRef.rst_n)) | (IData)(vlSelfRef.init)))) {
        vlSelfRef.result_reg__DOT__i = 1U;
        vlSelfRef.result_reg__DOT__i = 2U;
        vlSelfRef.result_reg__DOT__i = 3U;
        vlSelfRef.result_reg__DOT__i = 4U;
        vlSelfRef.result_reg__DOT__i = 5U;
        vlSelfRef.result_reg__DOT__i = 6U;
        vlSelfRef.result_reg__DOT__i = 7U;
        vlSelfRef.result_reg__DOT__i = 8U;
        __VdlySet__result_reg__DOT__mem__v0 = 1U;
        __Vdly__result_reg__DOT__peak_mag = 0U;
        vlSelfRef.result_reg__DOT__peak_idx = 0U;
    } else if (vlSelfRef.wr_en) {
        __VdlyVal__result_reg__DOT__mem__v8 = vlSelfRef.magnitude;
        __VdlyDim0__result_reg__DOT__mem__v8 = vlSelfRef.bin_index;
        __VdlySet__result_reg__DOT__mem__v8 = 1U;
        if (((IData)(vlSelfRef.magnitude) > (IData)(vlSelfRef.result_reg__DOT__peak_mag))) {
            __Vdly__result_reg__DOT__peak_mag = vlSelfRef.magnitude;
            vlSelfRef.result_reg__DOT__peak_idx = vlSelfRef.bin_index;
        }
    }
    if (__VdlySet__result_reg__DOT__mem__v0) {
        vlSelfRef.result_reg__DOT__mem[0U] = 0U;
        vlSelfRef.result_reg__DOT__mem[1U] = 0U;
        vlSelfRef.result_reg__DOT__mem[2U] = 0U;
        vlSelfRef.result_reg__DOT__mem[3U] = 0U;
        vlSelfRef.result_reg__DOT__mem[4U] = 0U;
        vlSelfRef.result_reg__DOT__mem[5U] = 0U;
        vlSelfRef.result_reg__DOT__mem[6U] = 0U;
        vlSelfRef.result_reg__DOT__mem[7U] = 0U;
    }
    if (__VdlySet__result_reg__DOT__mem__v8) {
        vlSelfRef.result_reg__DOT__mem[__VdlyDim0__result_reg__DOT__mem__v8] 
            = __VdlyVal__result_reg__DOT__mem__v8;
    }
    vlSelfRef.result_reg__DOT__peak_mag = __Vdly__result_reg__DOT__peak_mag;
    vlSelfRef.magnitudes = vlSelfRef.result_reg__DOT__mem
        [vlSelfRef.mag_rd_addr];
    vlSelfRef.result_reg__DOT__magnitudes = vlSelfRef.result_reg__DOT__mem
        [vlSelfRef.mag_rd_addr];
    vlSelfRef.peak_bin_index = vlSelfRef.result_reg__DOT__peak_idx;
    vlSelfRef.result_reg__DOT__peak_bin_index = vlSelfRef.result_reg__DOT__peak_idx;
}

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf);

bool Vtop___024root___eval_phase__act(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__act\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtop___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vtop___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtop___024root___eval_phase__nba(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_phase__nba\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtop___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__ico(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__nba(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(Vtop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelfRef.__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY(((0x64U < __VicoIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("/workspaces/tt-fft-dsp-accelerator/test_modules_eva/result_reg.v", 7, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vtop___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelfRef.__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("/workspaces/tt-fft-dsp-accelerator/test_modules_eva/result_reg.v", 7, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("/workspaces/tt-fft-dsp-accelerator/test_modules_eva/result_reg.v", 7, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vtop___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vtop___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if (VL_UNLIKELY(((vlSelfRef.clk & 0xfeU)))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY(((vlSelfRef.rst_n & 0xfeU)))) {
        Verilated::overWidthError("rst_n");}
    if (VL_UNLIKELY(((vlSelfRef.mag_rd_addr & 0xf8U)))) {
        Verilated::overWidthError("mag_rd_addr");}
    if (VL_UNLIKELY(((vlSelfRef.init & 0xfeU)))) {
        Verilated::overWidthError("init");}
    if (VL_UNLIKELY(((vlSelfRef.wr_en & 0xfeU)))) {
        Verilated::overWidthError("wr_en");}
    if (VL_UNLIKELY(((vlSelfRef.bin_index & 0xf8U)))) {
        Verilated::overWidthError("bin_index");}
}
#endif  // VL_DEBUG
