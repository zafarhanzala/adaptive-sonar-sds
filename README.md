# Low-Power Adaptive Software-Defined Sonar Transmitter for AUVs

[![FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Zynq--7000-red.svg)](https://www.xilinx.com)
[![Toolchain](https://img.shields.io/badge/Vivado-2024.1-blue.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Timing](https://img.shields.io/badge/Timing-MET%20(+2.703ns)-brightgreen.svg)]()
[![Power](https://img.shields.io/badge/Dynamic%20Power-2mW-success.svg)]()

> **Smart India Hackathon (SIH) 2026 Idea Submission | Team JAM-UN**  
> An open-architecture, real-time frequency-agile sonar transmitter core engineered in synthesizable Verilog for micro-AUVs.

---

## 🌊 System Architecture
The payload generates dynamic Linear Frequency Modulated (LFM) chirps and phase-coded acoustic sweeps, automatically adapting pulse parameters to surrounding water turbidity.

[ Environmental Sensors ] ──> [ Sonar FSM ] ──> [ Dual-Accumulator DDS ] ──> [ DSP Hann Window ] ──> [ 8-bit DAC Frontend ]
### Adaptive Modes
- **Clear Water (<85 NTU):** 400–500 kHz chirp | 1.0 ms duration | 60% power
- **Mixed Water (85–169 NTU):** 200–300 kHz chirp | 1.5 ms duration | 80% power
- **Muddy/Turbid (>169 NTU):** 80–120 kHz chirp | 2.0 ms duration | 100% power

---

## ⚡ Silicon Benchmarks (Xilinx Zynq-7000 `xc7z020`)
- **System Clock:** 125 MHz (8.0 ns period)
- **Worst Negative Slack (WNS):** `+2.703 ns` (Zero timing violations)
- **Dynamic Logic Power:** `0.002 W` (2 mW)
- **Total On-Chip Power:** `0.108 W` (108 mW)
- **Fabric Footprint:** < 1% LUT / 1 DSP48E1 / 1 BRAM

---

## 🛠️ Physical Testbed (TRL-4 Prototype)
The synthesizable RTL was verified on physical hardware:
1. **Target Board:** TUL PYNQ-Z2 (Zynq-7000 SoC).
2. **Analog Frontend:** Discrete 8-bit R-2R resistor ladder (1 kΩ / 2 kΩ metal film array).
3. **Trigger Synchronization:** Hardware trigger pin (`AR8` / `W18`) for oscilloscope synchronization.

*(See `/docs/lab_testbed_photo.jpg` for physical testbed layout).*

---

## 🚀 How to Reproduce in Vivado 2024.1
1. Clone the repository:
   ```bash
   git clone [https://github.com/](https://github.com/)<zafarhanzala>/adaptive-sonar-sds.git
   cd adaptive-sonar-sds
