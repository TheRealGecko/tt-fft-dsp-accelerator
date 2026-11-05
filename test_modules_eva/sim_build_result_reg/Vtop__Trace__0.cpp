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
    bufp->chgBit(oldp+0,(vlSelfRef.clk));
    bufp->chgBit(oldp+1,(vlSelfRef.rst_n));
    bufp->chgCData(oldp+2,(vlSelfRef.magnitude),8);
    bufp->chgCData(oldp+3,(vlSelfRef.mag_rd_addr),3);
    bufp->chgCData(oldp+4,(vlSelfRef.peak_bin_index),3);
    bufp->chgCData(oldp+5,(vlSelfRef.magnitudes),8);
    bufp->chgBit(oldp+6,(vlSelfRef.init));
    bufp->chgBit(oldp+7,(vlSelfRef.wr_en));
    bufp->chgCData(oldp+8,(vlSelfRef.bin_index),3);
    bufp->chgBit(oldp+9,(vlSelfRef.result_reg__DOT__clk));
    bufp->chgBit(oldp+10,(vlSelfRef.result_reg__DOT__rst_n));
    bufp->chgCData(oldp+11,(vlSelfRef.result_reg__DOT__magnitude),8);
    bufp->chgCData(oldp+12,(vlSelfRef.result_reg__DOT__mag_rd_addr),3);
    bufp->chgCData(oldp+13,(vlSelfRef.result_reg__DOT__peak_bin_index),3);
    bufp->chgCData(oldp+14,(vlSelfRef.result_reg__DOT__magnitudes),8);
    bufp->chgBit(oldp+15,(vlSelfRef.result_reg__DOT__init));
    bufp->chgBit(oldp+16,(vlSelfRef.result_reg__DOT__wr_en));
    bufp->chgCData(oldp+17,(vlSelfRef.result_reg__DOT__bin_index),3);
    bufp->chgCData(oldp+18,(vlSelfRef.result_reg__DOT__mem[0]),8);
    bufp->chgCData(oldp+19,(vlSelfRef.result_reg__DOT__mem[1]),8);
    bufp->chgCData(oldp+20,(vlSelfRef.result_reg__DOT__mem[2]),8);
    bufp->chgCData(oldp+21,(vlSelfRef.result_reg__DOT__mem[3]),8);
    bufp->chgCData(oldp+22,(vlSelfRef.result_reg__DOT__mem[4]),8);
    bufp->chgCData(oldp+23,(vlSelfRef.result_reg__DOT__mem[5]),8);
    bufp->chgCData(oldp+24,(vlSelfRef.result_reg__DOT__mem[6]),8);
    bufp->chgCData(oldp+25,(vlSelfRef.result_reg__DOT__mem[7]),8);
    bufp->chgCData(oldp+26,(vlSelfRef.result_reg__DOT__peak_mag),8);
    bufp->chgCData(oldp+27,(vlSelfRef.result_reg__DOT__peak_idx),3);
    bufp->chgIData(oldp+28,(vlSelfRef.result_reg__DOT__i),32);
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
