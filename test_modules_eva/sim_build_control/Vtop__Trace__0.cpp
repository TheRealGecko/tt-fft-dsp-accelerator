// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "Vtop__Syms.h"


void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp);

void Vtop___024root__trace_chg_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop___024root__trace_chg_0_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_0_sub_0\n"); );
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelfRef.start));
    bufp->chgBit(oldp+1,(vlSelfRef.flag));
    bufp->chgCData(oldp+2,(vlSelfRef.stage),2);
    bufp->chgCData(oldp+3,(vlSelfRef.butterfly),2);
    bufp->chgBit(oldp+4,(vlSelfRef.start_fft));
    bufp->chgCData(oldp+5,(vlSelfRef.mag_index),3);
    bufp->chgCData(oldp+6,(vlSelfRef.twiddle_index),2);
    bufp->chgBit(oldp+7,(vlSelfRef.start_mag));
    bufp->chgBit(oldp+8,(vlSelfRef.mag_done));
    bufp->chgBit(oldp+9,(vlSelfRef.result_init));
    bufp->chgBit(oldp+10,(vlSelfRef.result_wr_en));
    bufp->chgBit(oldp+11,(vlSelfRef.clk));
    bufp->chgBit(oldp+12,(vlSelfRef.rst_n));
    bufp->chgBit(oldp+13,(vlSelfRef.control__DOT__start));
    bufp->chgBit(oldp+14,(vlSelfRef.control__DOT__flag));
    bufp->chgCData(oldp+15,(vlSelfRef.control__DOT__stage),2);
    bufp->chgCData(oldp+16,(vlSelfRef.control__DOT__butterfly),2);
    bufp->chgBit(oldp+17,(vlSelfRef.control__DOT__start_fft));
    bufp->chgCData(oldp+18,(vlSelfRef.control__DOT__mag_index),3);
    bufp->chgCData(oldp+19,(vlSelfRef.control__DOT__twiddle_index),2);
    bufp->chgBit(oldp+20,(vlSelfRef.control__DOT__start_mag));
    bufp->chgBit(oldp+21,(vlSelfRef.control__DOT__mag_done));
    bufp->chgBit(oldp+22,(vlSelfRef.control__DOT__result_init));
    bufp->chgBit(oldp+23,(vlSelfRef.control__DOT__result_wr_en));
    bufp->chgBit(oldp+24,(vlSelfRef.control__DOT__clk));
    bufp->chgBit(oldp+25,(vlSelfRef.control__DOT__rst_n));
    bufp->chgCData(oldp+26,(vlSelfRef.control__DOT__state),3);
}

void Vtop___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_cleanup\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
