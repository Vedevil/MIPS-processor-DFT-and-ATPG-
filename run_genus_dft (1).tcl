#=============================================================================
# Genus Synthesis + DFT Insertion Script
# Design: mips_easy (Single-Cycle MIPS Processor)
# Tool: Cadence Genus Synthesis Solution
# Library: 90nm (slow.lib)
#
# This script performs:
#   1. Library setup (90nm foundry)
#   2. RTL read & elaborate
#   3. Constraints application (SDC)
#   4. Synthesis (generic + mapped)
#   5. DFT scan chain insertion
#   6. Incremental optimization post-DFT
#   7. Netlist export (pre-DFT and post-DFT)
#=============================================================================

puts "============================================================"
puts "  Genus Synthesis + DFT Script for mips_easy"
puts "  Technology: 90nm"
puts "============================================================"

#---------------------------------------------------------------------
# Step 1: Setup 90nm Library Paths
#---------------------------------------------------------------------
set_db init_lib_search_path /home/install/FOUNDRY/digital/90nm/dig/lib/
set_db library slow.lib

#---------------------------------------------------------------------
# Step 2: Read HDL source
#---------------------------------------------------------------------
puts "\n>>> Reading RTL Design..."
read_hdl ./mips_easy.v

#---------------------------------------------------------------------
# Step 3: Elaborate the design
#---------------------------------------------------------------------
puts "\n>>> Elaborating Design..."

# Drive unconnected inputs to 0 instead of X so Genus does not
# constant-propagate (and optimize away) the entire datapath.
set_db hdl_unconnected_value 0

elaborate mips_easy

# Check for elaboration issues
check_design -unresolved

# Exclude data_memory array from scan (MBIST covers it)


#---------------------------------------------------------------------
# Step 4: Read timing constraints (SDC)
#---------------------------------------------------------------------
puts "\n>>> Reading SDC Constraints..."
read_sdc ./mips_easy.sdc

#---------------------------------------------------------------------
# Step 5: Power optimization goals
#---------------------------------------------------------------------
set_max_leakage_power 0.0
set_max_dynamic_power 0.0

#---------------------------------------------------------------------
# Step 5b: Pre-Synthesis DFT Definitions (Required for mapping to Scan FFs)
#---------------------------------------------------------------------
set_db dft_scan_style muxed_scan
set_db dft_prefix DFT_

# Define DFT signals before synthesis so Genus is aware of them
define_dft shift_enable -name scan_en_sig -active high scan_en
define_dft test_clock   -name clk_test    -period 10000 clk

#---------------------------------------------------------------------
# Step 6: Synthesize to generic gates
#---------------------------------------------------------------------
puts "\n>>> Synthesizing to Generic Gates..."
set_db syn_generic_effort high
syn_generic

#---------------------------------------------------------------------
# Step 7: Synthesize to mapped (technology) gates
#---------------------------------------------------------------------
puts "\n>>> Mapping to 90nm Technology Library..."
set_db syn_map_effort high
syn_map

#---------------------------------------------------------------------
# Step 8: Incremental Optimization
#---------------------------------------------------------------------
puts "\n>>> Running Incremental Optimization..."
set_db syn_opt_effort high
syn_opt

#---------------------------------------------------------------------
# Step 9: Pre-DFT Reports
#---------------------------------------------------------------------
puts "\n>>> Generating Pre-DFT Reports..."
report timing > ./pre_dft_timing.rpt
report area   > ./pre_dft_area.rpt
report power  > ./pre_dft_power.rpt
report gates  > ./pre_dft_gates.rpt

#---------------------------------------------------------------------
# Step 10: Write Pre-DFT Netlist
#---------------------------------------------------------------------
puts "\n>>> Writing Pre-DFT Netlist..."
write_hdl > ./mips_easy_pre_dft.v
write_sdc > ./mips_easy_pre_dft.sdc

#---------------------------------------------------------------------
# Step 11: DFT Setup and Scan Chain Insertion
#---------------------------------------------------------------------
puts "\n>>> Setting up DFT..."

# (DFT signals defined prior to synthesis in Step 5b)

#---------------------------------------------------------------------
# Step 12: Check DFT Rules & Insert Scan Chains
#---------------------------------------------------------------------
puts "\n>>> Checking DFT Rules..."
check_dft_rules > ./dft_rules_check.rpt

puts "\n>>> Replacing Flip-Flops with Scan FFs..."
replace_scan

puts "\n>>> Connecting Scan Chains..."
# Connect chains and hook them to scan_in/scan_out ports
define_scan_chain -name chain1 -sdi scan_in -sdo scan_out -non_shared_output
connect_scan_chains

#---------------------------------------------------------------------
# Step 13: Post-DFT Optimization
#---------------------------------------------------------------------
puts "\n>>> Post-DFT Incremental Optimization..."
syn_opt -incr

#---------------------------------------------------------------------
# Step 14: Post-DFT Reports
#---------------------------------------------------------------------
puts "\n>>> Generating Post-DFT Reports..."
report timing    > ./post_dft_timing.rpt
report area      > ./post_dft_area.rpt
report power     > ./post_dft_power.rpt
report gates     > ./post_dft_gates.rpt
report dft_setup > ./dft_setup.rpt
report dft_chains > ./scan_chains.rpt
check_dft_rules  > ./post_dft_rules.rpt

#---------------------------------------------------------------------
# Step 15: Write Post-DFT Netlist, SDC, and SDF
#---------------------------------------------------------------------
puts "\n>>> Writing Post-DFT Netlist..."
write_hdl > ./mips_easy_post_dft.v
write_sdf > ./mips_easy_post_dft.sdf
write_sdc > ./mips_easy_post_dft.sdc

# Write the scandef file for Modus
write_scandef > ./mips_easy.scandef

#---------------------------------------------------------------------
# Step 16: Write DFT/ATPG files for Modus
# This generates: test_netlist.v, .pinassign, test.modedef, test.exclude
# These files go into the working directory that Modus uses
#---------------------------------------------------------------------
puts "\n>>> Writing DFT Protocol for Modus..."
write_dft_atpg -library ./mips_easy_post_dft.v \
               -directory ./

puts "\n============================================================"
puts "  Genus Synthesis + DFT Complete! (90nm)"
puts "  Check current directory for all reports and netlists"
puts "  Check current directory for Modus ATPG input files"
puts "============================================================"

# Open the GUI to inspect the schematic
gui_show
