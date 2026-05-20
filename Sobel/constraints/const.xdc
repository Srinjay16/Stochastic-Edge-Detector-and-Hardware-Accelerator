set_property IOSTANDARD LVCMOS33 [get_ports {vga_rgb[*]}]
## Clock signal (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100mhz]

## Buttons & Switches
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports sw0]

## VGA Connector
set_property PACKAGE_PIN H19 [get_ports {vga_rgb[1]}]
set_property PACKAGE_PIN J19 [get_ports {vga_rgb[2]}]
set_property PACKAGE_PIN H17 [get_ports {vga_rgb[5]}]
set_property PACKAGE_PIN G17 [get_ports {vga_rgb[6]}]
set_property PACKAGE_PIN L18 [get_ports {vga_rgb[9]}]
set_property PACKAGE_PIN K18 [get_ports {vga_rgb[10]}]

set_property PACKAGE_PIN P19 [get_ports vga_hsync]
set_property PACKAGE_PIN R19 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]


## Pmod Header JA - Camera Control & Data LSBs
set_property PACKAGE_PIN J1 [get_ports ov7670_pwdn]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_pwdn]
set_property PACKAGE_PIN L2 [get_ports {ov7670_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[0]}]
set_property PACKAGE_PIN J2 [get_ports {ov7670_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[2]}]
set_property PACKAGE_PIN G2 [get_ports {ov7670_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[4]}]
set_property PACKAGE_PIN H1 [get_ports ov7670_reset]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_reset]
set_property PACKAGE_PIN K2 [get_ports {ov7670_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[1]}]
set_property PACKAGE_PIN H2 [get_ports {ov7670_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[3]}]
set_property PACKAGE_PIN G3 [get_ports {ov7670_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[5]}]

## Pmod Header JB - Camera Data MSBs & Sync
set_property PACKAGE_PIN A14 [get_ports {ov7670_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[6]}]
set_property PACKAGE_PIN A16 [get_ports ov7670_xclk]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_xclk]
set_property PACKAGE_PIN B15 [get_ports ov7670_pclk]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_pclk]
set_property PACKAGE_PIN A15 [get_ports {ov7670_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {ov7670_data[7]}]
set_property PACKAGE_PIN A17 [get_ports ov7670_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_hsync]
set_property PACKAGE_PIN C15 [get_ports ov7670_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports ov7670_vsync]

set_property PACKAGE_PIN V14 [get_ports sw0]
set_property PACKAGE_PIN U14 [get_ports btnC]
set_property PACKAGE_PIN W15 [get_ports {vga_rgb[11]}]
set_property PACKAGE_PIN W13 [get_ports {vga_rgb[8]}]
set_property PACKAGE_PIN W14 [get_ports {vga_rgb[7]}]
set_property PACKAGE_PIN U15 [get_ports {vga_rgb[4]}]
set_property PACKAGE_PIN U16 [get_ports {vga_rgb[3]}]
set_property PACKAGE_PIN V13 [get_ports {vga_rgb[0]}]
