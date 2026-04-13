# =============================================================================
# mips_easy.sdc
# Timing Constraints - MIPS Easy Processor
# Technology : 90nm
# Clock      : 100 MHz (10 ns)
# =============================================================================

# -----------------------------------------------------------------------------
# Clock
# -----------------------------------------------------------------------------
create_clock -name clk -period 10.0 -waveform {0 5.0} [get_ports clk]

set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold  0.1 [get_clocks clk]
set_clock_transition   0.15      [get_clocks clk]

# -----------------------------------------------------------------------------
# I/O Delays
# -----------------------------------------------------------------------------
set_input_delay  -clock clk -max 2.0 [get_ports rst_n]
set_input_delay  -clock clk -max 2.0 [get_ports scan_en]
set_input_delay  -clock clk -max 2.0 [get_ports scan_in]
set_input_delay  -clock clk -max 2.0 [get_ports test_mode]
set_input_delay  -clock clk -max 2.0 [get_ports instr]
set_output_delay -clock clk -max 2.0 [get_ports pc_out]
set_output_delay -clock clk -max 2.0 [get_ports scan_out]

# -----------------------------------------------------------------------------
# False paths on DFT / async control signals
# -----------------------------------------------------------------------------
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports scan_en]
set_false_path -from [get_ports test_mode]

# -----------------------------------------------------------------------------
# Drive / Load
# -----------------------------------------------------------------------------
set_driving_cell -lib_cell BUFX4 -pin Z [all_inputs]
set_load 0.05 [all_outputs]

# -----------------------------------------------------------------------------
# Design rule constraints (90nm typical)
# -----------------------------------------------------------------------------
set_max_transition  0.5  [current_design]
set_max_fanout      20   [current_design]
set_max_capacitance 0.5  [current_design]
