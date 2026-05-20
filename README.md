# StEdge: Real-Time Stochastic Computing Edge-Detection Accelerator

[![Board](https://img.shields.io/badge/FPGA-Xilinx%20Artix--7-orange)](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)
[![Target](https://img.shields.io/badge/Hardware-Digilent%20Basys%203-blue)](https://digilent.com/reference/programmable-logic/basys-3/start)
[![Toolchain](https://img.shields.io/badge/Vivado-2024.2-red)](https://www.xilinx.com/products/design-tools/vivado.html)

StEdge is a high-performance, real-time edge-detection hardware accelerator operating natively within the **Stochastic Computing (SC)** domain. Built and optimized for the Digilent Basys 3 development board, this architecture replaces resource-heavy conventional gradient arithmetic with hardware-efficient XOR-based subtraction and a deterministic bitstream-concatenation adder tree. 

Both Sobel and Prewitt operators are capable of running within a tight **100 MHz clock domain**, streaming **30 FPS video** from an OV7670 camera module directly to a standard VGA monitor without the need for external frame-buffer hardware or processor intervention.

---

## 📈 Performance Benchmarks

When synthesized and implemented against a standard deterministic baseline on the exact same Artix-7 fabric, the StEdge accelerator achieves massive architectural efficiency gains while maintaining visual edge-fidelity:

* **~84% Reduction** in Logic Utilization (LUTs)
* **~68% Reduction** in Block RAM (BRAM) footprint
* **~17% Lower** On-Chip Power Consumption (~0.209 W vs. 0.251 W baseline)

*For detailed algebraic reformulations, mathematical derivations of the bit-interleaved accumulator trick, and absolute hardware baseline figures, please refer to the companion paper: `Hardware_StoBel.pdf`.*

---

## 📽️ Hardware Demo
The real-time operational video captures showing live sensor processing can be accessed here:
👉 [Watch the StEdge Demo Videos on Google Drive](https://drive.google.com/drive/folders/1ev4mEHUn8ps4adxoBAxjehTk1-IdUQ-h)

---

## 📂 Repository Layout

The repository contains two parallel, structural directories designed with identical top-level interfaces, VGA timing matrix blocks, and BRAM structures. The core algorithmic variance is self-contained within the XOR / concatenation layer inside the stochastic core.

```text
StEdge/
├── sobel_stochastic/
│   ├── RTL/              # Core modules (Uses 4-stage bitstream interleaving for ×2 kernel weighting)
│   ├── constraint/       # const.xdc (Targeted pin-out assignments for Basys 3)
│   └── Bitfile/          # Pre-built design_1_wrapper.bit & debug probe (.ltx)
├── prewitt_stochastic/
│   ├── RTL/              # Core modules (Uses 3-stage uniform weights; zero-padded matrix slots)
│   ├── constraints/      # const.xdc
│   └── bitfile/          # Pre-built bitstream execution payload
└── README.md
