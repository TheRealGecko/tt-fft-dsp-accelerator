// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "Vtop__pch.h"
#include "Vtop__Syms.h"
#include "Vtop___024root.h"

// Parameter definitions for Vtop___024root
constexpr CData/*2:0*/ Vtop___024root::control__DOT__IDLE;
constexpr CData/*2:0*/ Vtop___024root::control__DOT__FFT_START;
constexpr CData/*2:0*/ Vtop___024root::control__DOT__FFT_RUN;
constexpr CData/*2:0*/ Vtop___024root::control__DOT__MAG_START;
constexpr CData/*2:0*/ Vtop___024root::control__DOT__MAG_WAIT;
constexpr CData/*2:0*/ Vtop___024root::control__DOT__DONE;


void Vtop___024root___ctor_var_reset(Vtop___024root* vlSelf);

Vtop___024root::Vtop___024root(Vtop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtop___024root___ctor_var_reset(this);
}

void Vtop___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtop___024root::~Vtop___024root() {
}
