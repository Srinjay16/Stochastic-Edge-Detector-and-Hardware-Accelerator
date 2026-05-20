# StEdge: Real-Time Stochastic Computing Edge-Detection Accelerator

[![Board](https://img.shields.io/badge/FPGA-Xilinx%20Artix--7-orange)](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)
[![Target](https://img.shields.io/badge/Hardware-Digilent%20Basys%203-blue)](https://digilent.com/reference/programmable-logic/basys-3/start)
[![Toolchain](https://img.shields.io/badge/Vivado-2024.2-red)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Compiler](https://img.shields.io/badge/HDL-Bluespec%20SystemVerilog-green)](https://github.com/B-Lang-org/bsc)
[![Language](https://img.shields.io/badge/Language-Verilog-black)](https://en.wikipedia.org/wiki/Verilog)

StEdge is a high-performance, real-time edge-detection hardware accelerator operating natively within the **Stochastic Computing (SC)** domain. Built and optimized for the Digilent Basys 3 development board, this architecture replaces resource-heavy conventional gradient arithmetic with hardware-efficient XOR-based subtraction and a deterministic bitstream-concatenation adder tree. 

Both Sobel and Prewitt operators are capable of running within a tight **100 MHz clock domain**, streaming **30 FPS video** from an OV7670 camera module directly to a standard VGA monitor without the need for external frame-buffer hardware or processor intervention.

---

## 📈 Performance Benchmarks

## 📊 Implementation Results (Basys 3)

The following metrics were captured post-implementation in Vivado 2024.2, targeting the Artix-7 `xc7a35tcpg236-1` fabric. The design proves to be highly resource-efficient and comfortably meets all timing constraints.

### Resource Utilization
| Resource | Utilization | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **LUT** | 178 | 20,800 | 0.86% |
| **FF** | 170 | 41,600 | 0.41% |
| **BRAM** | 9 | 50 | 18.00% |
| **IO** | 25 | 106 | 23.58% |
| **BUFG** | 3 | 32 | 9.38% |
| **MMCM** | 1 | 5 | 20.00% |

### Timing Summary
| Metric | Setup | Hold | Pulse Width |
| :--- | :--- | :--- | :--- |
| **Worst Slack** | 3.015 ns (WNS) | 0.091 ns (WHS) | 3.000 ns (WPWS) |
| **Total Slack** | 0.000 ns (TNS) | 0.000 ns (THS) | 0.000 ns (TPWS) |
| **Failing Endpoints**| 0 | 0 | 0 |
| **Total Endpoints** | 507 | 507 | 187 |

### Power Consumption
* **Total On-Chip Power:** 0.196 W
* **Junction Temperature:** 26.0°C
* **Thermal Margin:** 59.0°C (11.7 W)

**On-Chip Power Breakdown:**
* **Dynamic Power:** 0.123 W (63%)
  * *MMCM:* 0.106 W (86% of dynamic)
  * *I/O:* 0.014 W (9% of dynamic)
  * *Clocks:* 0.002 W (2% of dynamic)
  * *Signals / Logic / BRAM:* < 0.001 W each
* **Device Static Power:** 0.072 W (37%)

---

## ⚙️ Core RTL Module Architecture

The synthesizable Verilog modules provided in this repository are compiled via the Bluespec Compiler (version 2026.01). They represent a modular, highly decoupled stream processing pipeline:

* **`BRAM1.v`**: A parameterized single-ported Block RAM wrapper featuring configurable memory limits (`MEMSIZE`), array sizing (`ADDR_WIDTH`, `DATA_WIDTH`), and optional dual-stage output pipelining registers (`PIPELINED`).
* **`mkCameraResetClk.v`**: A clock domain and reset synchronization block that receives an active-high reset signal (`camera_reset_crst`) and drives an inverted camera hardware reset control line.
* **`mkCaptureStarter.v`**: A high-speed synchronization block that safely handles frame boundaries by latching onto camera synchronization pulses (`vsync`). It generates a localized `vsync_detected` signal alongside a synchronized capture reset pulse.
* **`mkCapture.v`**: The front-end sensor interface that extracts incoming 8-bit camera data (`d_in`) while managing coordinate counting for active frame streaming dimensions up to a QVGA window range (320×240). It outputs the active Luminance data, a 17-bit calculated memory address, and downstream validation signals.
* **`mkFrameBuffer.v`**: Implements a dedicated memory controller adapter wrapping the underlying `BRAM1` storage grid. It manages initialized read and write operations across a memory size of 76,800 to accommodate the active pixel payload.
* **`mkAddressMux.v` & `mkDataMux.v`**: High-speed, combinational routing blocks. `mkAddressMux.v` multiplexes 17-bit memory addressing channels (`out_rd_add` and `out_wr_add`) based on write-enable signals. `mkDataMux.v` routes 8-bit wide streams or zeroes them out depending on the active select signal.
* **`mkReadWriteController.v`**: A centralized arbitration finite state machine (FSM) spanning states 0 through 4. It evaluates status flags—such as `writing_done`, `display_done`, `video_on`, and `data_valid`—to safely coordinate `write_en` and `read_en` assignments between capture completion and screen sync periods.
* **`mkSobelStoch.v`**: The stochastic accelerator core. This block shifts image bytes into a localized spatial tracking matrix utilizing individual registers `o_0_0` through `o_2_2`. It processes the 8-bit input stream, executes the internal arithmetic filtering logic, and outputs an 8-bit filtered pixel payload (`pix_out`).
* **`mkVgaDisplay.v`**: Standard timing controller generating `hsync` and `vsync` signals. It tracks horizontal counts up to 799 and vertical counts up to 524 to lock into a 640×480 @ 60 Hz scanning standard. It outputs a 12-bit RGB signal by replicating the incoming lower 4 bits of filtered data across all color channels.
  
---

## 🔌 Hardware Setup & Pin Mapping

### Required Components
* **FPGA Board:** Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).
* **Camera Sensor:** OV7670 (Configured for 8-bit YUV422 output, raw variant without onboard FIFO).
* **Display:** Any standard VGA monitor capable of accepting 640×480 @ 60 Hz timing dynamics.
* **Interconnects:** Standard Pmod jumper cables.

### Board-Side Wiring Configuration (`const.xdc`)

| Peripheral Device | Signal Port Name | Basys 3 Package Pin | Notes / Extension Port |
| :--- | :--- | :--- | :--- |
| **System Clock** | `clk_100mhz` | W5 | 100 MHz Onboard Oscillator |
| **OV7670 Camera (Pmod JA)** | `ov7670_pwdn` | J1 | Power Down Control |
| | `ov7670_reset` | H1 | Hardware Reset |
| | `ov7670_data[5:0]` | G3, G2, H2, J2, K2, L2 | Lower 6 bits of image data |
| **OV7670 Camera (Pmod JB)** | `ov7670_data[7:6]` | A15, A14 | Upper 2 bits of image data |
| | `ov7670_xclk` | A16 | System clock to camera |
| | `ov7670_pclk` | B15 | Pixel clock from camera |
| | `ov7670_hsync` | A17 | Horizontal Sync |
| | `ov7670_vsync` | C15 | Vertical Sync |
| **VGA Display** | `vga_rgb[11:0]` | W15, K18, L18, W13, W14, G17, H17, U15, U16, J19, H19, V13 | 12-bit RGB color output array |
| | `vga_hsync` | P19 | Monitor Horizontal Sync |
| | `vga_vsync` | R19 | Monitor Vertical Sync |
| **On-board Controls** | `sw0` | V14 | Slide Switch 0 |
| | `btnC` | U14 | Center Button |

> **💡 Sensor Initialization Note:** Register initialization for the OV7670 sensor (enabling auto-white-balance, forcing YUV422 format scaling, and configuring window ranges) is decoupled from this RTL design. Pre-program the camera's registers over an I²C link using an external MCU prior to enabling the FPGA pipeline, or deploy an independent I²C master on unassigned Pmod pins.

---

## 🛠️ Toolchain & Implementation Flow

### Environment Requirements
* **Xilinx Vivado 2024.2** (WebPACK/Standard free edition is fully sufficient; no licensed IP cores required). *Backward compatible down to Vivado 2019.2.*
* **Digilent Board Files:** Must be linked to Vivado's board repository directory (`<Vivado>/data/boards/board_files/`) to resolve target presets correctly.

### Building from Source (Vivado Block Design Path)

1. Initialize a new Vivado project targeting the **Basys 3** profile.
2. Select your pipeline type and add the corresponding sources into your workspace:
   * Add all synthesizable Verilog files (`BRAM1.v` and all `mk*.v` files) inside `Sobel/verilog_out/` along with `Sobel/constraints/const.xdc`.
3. Select **Create Block Design** and designate the structure name exactly as `design_1` *(this is vital for binding constraints accurately)*.
4. Right-click the block canvas, choose **Add Module**, and add the core structural project blocks: `mkCameraResetClk`, `mkCaptureStarter`, `mkCapture`, `mkFrameBuffer`, `mkAddressMux`, `mkDataMux`, `mkVgaDisplay`, `mkSobelStoch`, and `mkReadWriteController`. *(Note: `BRAM1` will be automatically inferred in the hierarchy under `mkFrameBuffer`)*.
5. Insert a **Clocking Wizard IP** core. Set the primary input clock to match the 100 MHz onboard oscillator, and configure the discrete clock outputs required by the pipeline:
   * `clk_out1`: **100 MHz** (Feeds the core system processing loop and memory).
   * `clk_out2`: **25 MHz** (Feeds the VGA pixel clock engine for `mkVgaDisplay`).
   * `clk_out3`: **24 MHz** (Feeds the `ov7670_xclk` hardware requirement for the camera sensor).
6. Wire the internal signals across the module ports. When creating external ports (Ctrl+K), you **must** name them exactly as they appear in the `const.xdc` file to ensure proper routing:
   * **System/Control:** `clk_100mhz`, `sw0`, `btnC`
   * **VGA Out:** `vga_rgb[11:0]`, `vga_hsync`, `vga_vsync`
   * **Camera In:** `ov7670_pwdn`, `ov7670_reset`, `ov7670_xclk`, `ov7670_pclk`, `ov7670_hsync`, `ov7670_vsync`, `ov7670_data[7:0]`
7. Run **Validate Design** (F6) to ensure there are no hanging nets.
8. Right-click your block design in the Sources pane, select **Create HDL Wrapper**, and let Vivado manage it. 
9. Execute **Synthesis**, run **Implementation**, and generate your target bitstream file!

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
