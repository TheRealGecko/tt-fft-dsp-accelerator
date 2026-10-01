# FFT DSP Accelerator

**Statement of purpose**: We’re making a FFT DSP accelerator, which offloads heavy fourier transform math from the main processor, and does the math more efficiently than software. This specific implementation can be used for an accelerometer, turning g-forces over time to vibration frequency data. 

---

## System Diagram
[img]

## Specifications
- **Clock Freq.**: 20 MHz 
- **Latency**: ~3.55 μs
- **Clock cycles**: ~71 
- **FFT size**: 8-point
- **No. of butterfly units**: 1
- **Input data width**: 8 bits
- **Axes Processed**: 3 (x, y, z)

## Tables

| Pin No. | ui_in | ui_out | uio |
|----------|--------|--------|--------|
| 0 | wr_strobe | busy | data[0] |
| 1 | cmd_sel | done | data[1] |
| 2 | rd_strobe | overflow | data[2] |
| 3 | - | - | data[3] |
| 4 | - | peak_bin[0] | data[4] |
| 5 | - | peak_bin[1] | data[5] |
| 6 | - | peak_bin[2] | data[6] |
| 7 | - | peak_bin[3] | data[7] |

## Task Assignment
- Eva:
  - Parallel bus interface
  - Command decoder
  - Result registers
  - Control FSM 
- Fatma:
  - Magnitude block
  - Sample buffer
  - Butterfly unit
  - Twiddle ROM

## Schedule
| Date | Task |
|----------|--------|
| Oct 1-4 | <ul><li>Start sample buffer & parallel bus interface</li></ul> |
| Oct 5-11 | <ul><li>Finish sample buffer & parallel bus</li><li>Start twiddle ROM & command decoder</li></ul> |
| Oct 12-18 | <ul><li>Finish twiddle ROM & command decoder</li><li>Start butterfly unit, result registers & control FSM</li></ul> |
| Oct 31-Nov 5 | <ul><li>Finish butterfly unit & result registers</li><li>Start magnitude block</li><li>Continue control FSM</li></ul> |
| Nov 6-12 | <ul><li>Finish magnitude & control FSM</li><li>Integrate all modules</li></ul> |
| Nov 13-23 | <ul><li>Debug integration, arithmetic & sequencing</li></ul> |
| Nov 24-27 | <ul><li>Verify output values & commands</li><li>Debug for edge cases (overflow, negative inputs, etc)</li></ul> |
| Nov 28-30 | <ul><li>Fix remaining datapath/control issues</li><li>Write documentation</li></ul> |
| Dec 1-3 | <ul><li>Review documentation</li><li>Submit</li></ul> |
