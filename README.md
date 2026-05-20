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

## ⚙️ Core RTL Module Architecture

The synthesizable Verilog modules provided in this repository are compiled via the Bluespec Compiler (version 2026.01). They represent a modular, highly decoupled stream processing pipeline:

* **`BRAM1.v`**: A parameterized single-ported Block RAM wrapper featuring configurable memory limits, array sizing, and optional dual-stage output pipelining registers.
* **`mkCaptureStarter.v`**: A high-speed synchronization block that safely handles frame boundaries by latching onto the rising edges of camera synchronization pulses.
* **`mkCapture.v`**: The front-end sensor interface that extracts 8-bit active Luminance ($Y$) channels from incoming camera data lines while managing coordinate counting for active frame streaming dimensions up to standard QVGA/VGA window ranges.
* **`mkFrameBuffer.v`**: Implements a dedicated memory controller adapter wrapping the underlying BRAM1 storage grid, ensuring consistent read/write page boundaries.
* **`mkAddressMux.v` & `mkDataMux.v`**: High-speed, combinational routing blocks that multiplex 17-bit memory addressing channels and 8-bit wide streams between capture operations and live filter processing windows.
* **`mkReadWriteController.v`**: A centralized arbitration finite state machine (FSM) that coordinates read/write window assignments, checking state signals between capture completion and screen sync periods.
* **`mkSobelStoch.v`**: The stochastic accelerator core. This block shifts image bytes into a localized spatial tracking matrix (`o_0_0` through `o_2_2`), translates standard pixel words to stochastic bitstreams, executes the logic-gate filtering, and handles the output accumulation scaling.
* **`mkVgaDisplay.v`**: Standard horizontal and vertical sync timing controller generating standard 640×480 @ 60 Hz scanning signals and calculating accurate active matrix address offsets.

---

## 🔌 Hardware Setup & Pin Mapping

### Required Components
* **FPGA Board:** Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).
* **Camera Sensor:** OV7670 (Configured for 8-bit YUV422 output, raw variant without onboard FIFO).
* **Display:** Any standard VGA monitor capable of accepting 640×480 @ 60 Hz timing dynamics.
* **Interconnects:** ~20 Pmod jumper cables.

### Board-Side Wiring Configuration (`const.xdc`)

| Peripheral Device | Signal Port Name | Basys 3 Package Pin Location | Notes / Extension Port |
| :--- | :--- | :--- | :--- |
| **OV7670 Data** | `D0` .. `D7` | A14, A16, B15, B16, A15, A17, C15, C16 | Connected to Pmod JB |
| **OV7670 Clocks** | `PCLK` | P18 | Connected to Pmod JC |
| | `XCLK` | M19 | 24 MHz driven from System Clock |
| **OV7670 Sync** | `VSYNC` | L17 | Hardware Frame Sync |
| | `HREF` | M18 | Line Data Window Validation |
| | `RSTn` | N17 | Camera Hardware Reset Control |
| **VGA Output** | `R[3:0]` | G19, H19, J19, N19 | Wired to On-board Resistor DAC |
| | `G[3:0]` | J17, H17, G17, D17 | Greyscale output replicates... |
| | `B[3:0]` | N18, L18, K18, J18 | ...lower 4 bits of filtered data |
| | `HSYNC` / `VSYNC` | P19 / R19 | Monitor sync drives |
| **On-board SW** | `SW0` / `SW1` / `SW2` | V17 / V16 / W16 | System Reset / Write En / Camera Reset |

> **💡 Sensor Initialization Note:** Register initialization for the OV7670 sensor (enabling auto-white-balance, forcing YUV422 format scaling, and configuring window ranges) is decoupled from this RTL design. Pre-program the camera's registers over an I²C link using an external MCU prior to enabling the FPGA pipeline, or deploy an independent I²C master on unassigned Pmod pins.

---

## 🛠️ Toolchain & Implementation Flow

### Environment Requirements
* **Xilinx Vivado 2024.2** (WebPACK/Standard free edition is fully sufficient; no licensed IP cores required). *Backward compatible down to Vivado 2019.2.*
* **Digilent Board Files:** Must be linked to Vivado's board repository directory (`<Vivado>/data/boards/board_files/`) to resolve target presets correctly.

### Building from Source (Vivado Block Design Path)

1. Initialize a new Vivado project targeting the **Basys 3** profile.
2. Select your pipeline type and add the corresponding sources into your workspace:
   * Add all source Verilog text documents inside `Sobel/verilog_out/` along with `Sobel/constraints/const.xdc`.
3. Select **Create Block Design** and designate the structure name exactly as `design_1` *(this is vital for binding constraints accurately)*.
4. Right-click the block canvas, choose **Add Module**, and add all the structural project blocks: `camera_reset_clk`, `capture_starter`, `capture`, `frame_buffer`, `address_mux`, `data_MUX`, `vga_display`, `sobel_stoch`, and `read_write_controller`.
5. Insert a **Clocking Wizard IP** core. Set inputs to match the 100 MHz onboard oscillator (`W5`), and configure two discrete clock outputs:
   * `clk_out1`: **100 MHz** (Feeds the system processing loop).
   * `clk_out2`: **25 MHz** (Feeds the VGA pixel clock engine).
6. Connect the signals cleanly across ports, map external connections out to their designated board boundaries, run **Validate Design**, and generate the top-level HDL wrapper (`design_1_wrapper.v`).
7. Execute **Synthesis**, run **Implementation**, and generate your target bitstream file!

---

## 📂 Repository Layout

The repository contains two parallel, structural directories designed with identical top-level interfaces, VGA timing matrix blocks, and BRAM structures. The core algorithmic variance is self-contained within the XOR / concatenation layer inside the stochastic core.

```text
StEdge/
├── Sobel/
│   ├── StEdge_Sobel_Basys3/  # Vivado hardware project folder (contains IP blocks & block designs)
│   ├── bsv_files/            # High-level Bluespec SystemVerilog (BSV) source code files
│   ├── build/                # Compilation artifacts, simulation outputs, and intermediate build directories
│   ├── constraints/          # const.xdc (Targeted pin-out and timing assignments for Basys 3)
│   └── verilog_out/          # Synthesizable Verilog files generated by the Bluespec Compiler (BSC)
└── README.md
