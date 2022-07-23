## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
##   (if you are using the editor in Vivado, you can select lines and hit "Ctrl + /" to comment/uncomment.)
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
    set_property IOSTANDARD LVCMOS33 [get_ports clk]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# LEDs
 set_property PACKAGE_PIN U16 [get_ports {led[0]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
 set_property PACKAGE_PIN E19 [get_ports {led[1]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
 set_property PACKAGE_PIN U19 [get_ports {led[2]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
 set_property PACKAGE_PIN V19 [get_ports {led[3]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
 set_property PACKAGE_PIN W18 [get_ports {led[4]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
 set_property PACKAGE_PIN U15 [get_ports {led[5]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
 set_property PACKAGE_PIN U14 [get_ports {led[6]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
 set_property PACKAGE_PIN V14 [get_ports {led[7]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
 set_property PACKAGE_PIN V13 [get_ports {led[8]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
 set_property PACKAGE_PIN V3 [get_ports {led[9]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
 set_property PACKAGE_PIN W3 [get_ports {led[10]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
 set_property PACKAGE_PIN U3 [get_ports {led[11]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
 set_property PACKAGE_PIN P3 [get_ports {led[12]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
 set_property PACKAGE_PIN N3 [get_ports {led[13]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
 set_property PACKAGE_PIN P1 [get_ports {led[14]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
 set_property PACKAGE_PIN L1 [get_ports {led[15]}]
     set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]


# 7 segment display
 set_property PACKAGE_PIN W7 [get_ports {DISPLAY[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[0]}]
 set_property PACKAGE_PIN W6 [get_ports {DISPLAY[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[1]}]
 set_property PACKAGE_PIN U8 [get_ports {DISPLAY[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[2]}]
 set_property PACKAGE_PIN V8 [get_ports {DISPLAY[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[3]}]
 set_property PACKAGE_PIN U5 [get_ports {DISPLAY[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[4]}]
 set_property PACKAGE_PIN V5 [get_ports {DISPLAY[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[5]}]
 set_property PACKAGE_PIN U7 [get_ports {DISPLAY[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DISPLAY[6]}]

# set_property PACKAGE_PIN V7 [get_ports dp]
#    set_property IOSTANDARD LVCMOS33 [get_ports dp]
#
 set_property PACKAGE_PIN U2 [get_ports {DIGIT[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[0]}]
 set_property PACKAGE_PIN U4 [get_ports {DIGIT[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[1]}]
 set_property PACKAGE_PIN V4 [get_ports {DIGIT[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[2]}]
 set_property PACKAGE_PIN W4 [get_ports {DIGIT[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {DIGIT[3]}]


# Buttons
 set_property PACKAGE_PIN U18 [get_ports rst]
    set_property IOSTANDARD LVCMOS33 [get_ports rst]
 set_property PACKAGE_PIN T18 [get_ports up]
    set_property IOSTANDARD LVCMOS33 [get_ports up]
# set_property PACKAGE_PIN W19 [get_ports btnL]
#    set_property IOSTANDARD LVCMOS33 [get_ports btnL]
set_property PACKAGE_PIN T17 [get_ports en]
    set_property IOSTANDARD LVCMOS33 [get_ports en]
set_property PACKAGE_PIN U17 [get_ports down]
    set_property IOSTANDARD LVCMOS33 [get_ports down]

## USB HID (PS/2)
 set_property PACKAGE_PIN C17 [get_ports PS2_CLK]
    set_property IOSTANDARD LVCMOS33 [get_ports PS2_CLK]
    set_property PULLUP true [get_ports PS2_CLK]
 set_property PACKAGE_PIN B17 [get_ports PS2_DATA]
    set_property IOSTANDARD LVCMOS33 [get_ports PS2_DATA]
    set_property PULLUP true [get_ports PS2_DATA]


## where 3.3 is the voltage provided to configuration bank 0
    set_property CONFIG_VOLTAGE 3.3 [current_design]
## where value1 is either VCCO(for Vdd=3.3) or GND(for Vdd=1.8)
    set_property CFGBVS VCCO [current_design]