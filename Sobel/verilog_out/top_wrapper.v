`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.05.2026 11:43:21
// Design Name: 
// Module Name: top_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_wrapper(
    input  clk_100mhz,        // Physical Pin W5
    input  btnC,              // Master Reset
    input  sw0,               // Enable System / Start Pipeline
    
    // Camera OV7670 Interface
    input  ov7670_pclk,
    input  ov7670_vsync,
    input  ov7670_hsync,
    input  [7:0] ov7670_data,
    output ov7670_xclk,
    output ov7670_reset,
    output ov7670_pwdn,
    
    // VGA Interface
    output vga_hsync,
    output vga_vsync,
    output [11:0] vga_rgb
);

    // ---- 1. Clock Generation (Clocking Wizard IP) ----
    wire clk_sys; // 100 MHz logic clock
    wire clk_vga; // 25 MHz pixel clock
    wire locked;

    // Instantiate Clocking Wizard to create clk_vga from clk_100mhz
    clk_wiz_0 clock_gen (
        .clk_in1(clk_100mhz),
        .clk_out1(clk_sys),
        .clk_out2(clk_vga),
        .locked(locked)
    );

    // ---- 2. Synchronization & Camera Glue ----
    wire reset_n = locked && !btnC;
    wire capture_reset, vsync_detected;
    assign ov7670_pwdn = 1'b0;

    // Feed system clock to camera XCLK[cite: 21]
    assign ov7670_xclk = clk_sys;

    mkCameraResetClk cam_rst (
        .CLK(clk_sys), .RST_N(reset_n),
        .camera_reset_crst(btnC), .camera_reset(ov7670_reset)
    );

    mkCaptureStarter starter (
        .CLK(clk_sys), .RST_N(reset_n),
        .vsync(ov7670_vsync), .reset(btnC),
        .vsync_detected(vsync_detected), .capture_reset_out(capture_reset)
    );

    // ---- 3. Image Capture (Camera Domain) ----
    wire [7:0] cam_luma;
    wire [16:0] wr_addr;
    wire data_valid, writing_done;

    mkCapture capture_inst (
        .CLK(clk_sys), .RST_N(reset_n),
        .CLK_pclk(ov7670_pclk), .RST_N_rst(!capture_reset),
        .d_in(ov7670_data), .vsync(ov7670_vsync), .hsync(ov7670_hsync),
        .data_Y(cam_luma), .address(wr_addr), 
        .data_valid(data_valid), .frame_done(writing_done)
    );

    // ---- 4. Memory Arbitration (Logic Domain)[cite: 20, 26] ----
    wire [16:0] rd_addr, final_addr;
    wire [7:0] bram_out;
    wire write_en, read_en, video_on_signal, select, wea;
    wire display_done;

    // FSM to manage BRAM access[cite: 26]
    mkReadWriteController controller (
        .CLK(clk_sys), .RST_N(reset_n),
        .en(sw0), .writing_done(writing_done), .display_done(display_done),
        .video_on(video_on_signal), .data_valid(data_valid),
        .write_en(write_en), .read_en(read_en), .select(select)
    );
    
    // Steering logic for BRAM address port[cite: 20]
    assign wea = write_en; 
    mkAddressMux addr_mux (
        .CLK(clk_sys), .RST_N(reset_n),
        .out_rd_add(rd_addr), .out_wr_add(wr_addr), .out_wea(wea),
        .out(final_addr)
    );

    // ---- 5. Frame Storage (BRAM1 Primitive)[cite: 19, 25] ----
    // Mapping BSV's Action/ActionValue methods to physical BRAM ports
    mkFrameBuffer storage (
        .CLK(clk_sys), .RST_N(reset_n),
        .put_addr(final_addr), .put_data(cam_luma), .put_wea(wea),
        .EN_put(write_en), .EN_read(read_en), .read(bram_out)
    );

    // ---- 6. Processing & Display (VGA Domain)[cite: 27, 28] ----
    wire [7:0] sobel_pix, muxed_pix;
    
    // Stochastic Sobel Engine[cite: 27]
    mkSobelStoch sobel_engine (
        .CLK(clk_sys), .RST_N(reset_n),
        .data_in(bram_out), .video_on(video_on_signal),
        .address(rd_addr), .pix_out(sobel_pix)
    );

    // Prevent screen tearing by blanking during writes[cite: 24]
    mkDataMux video_gate (
        .CLK(clk_sys), .RST_N(reset_n),
        .out_select(select), .out_din(sobel_pix), .out(muxed_pix)
    );

    // VGA Timing and Output[cite: 28]
    // Note: ensure video_on is exposed in your VGA module's Verilog
    mkVgaDisplay vga_driver (
        .CLK(clk_vga), .RST_N(reset_n),
        .rgb_data_in(muxed_pix), .hsync(vga_hsync), .vsync(vga_vsync),
        .rgb(vga_rgb), .address(), .frame_done(display_done)
    );

    // Internal glue for missing port[cite: 26, 28]
    assign video_on_signal = (vga_hsync && vga_vsync); // Placeholder if video_on port is unexposed

endmodule