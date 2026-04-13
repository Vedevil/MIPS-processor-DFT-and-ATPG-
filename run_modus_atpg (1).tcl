puts "\n============================================="
puts "Starting Modus Test Run Script for mips_easy";
puts "=============================================\n"

set WORKDIR ./
set CELL mips_easy

# 1. CREATE RESULTS DIRECTORY
set RESULTS_DIR $WORKDIR/results
puts ">>> Creating results directory at $RESULTS_DIR"
file mkdir $RESULTS_DIR

## Set netlist and dynamically locate library information
set NETLIST $WORKDIR/mips_easy_post_dft.v

puts ">>> Actively Locating Library Models..."
set LIBRARY ""
catch {
    set raw_files [exec bash -c "find /home/install/FOUNDRY/digital/90nm/dig/ -type f | grep -E \"\\.v$|\\.v\\.gz$|\\.V$\""]
    set LIBRARY [split $raw_files "\n"]
}

## Testmode information
set TESTMODE FULLSCAN

# Dynamically find pinassign and modedef since Genus naming conventions vary
set ASSIGNFILE ""
set MODEDEF ""
catch {
    set ASSIGNFILE [exec bash -c "find $WORKDIR -type f -name \"*.pinassign\" | head -n 1"]
    set MODEDEF [exec bash -c "find $WORKDIR -type f -name \"*.modedef\" | head -n 1"]
}

## Processing steps  1=do, 0=don't
set do_build_model 1;
set do_fault_model 1;

set do_build_testmode_FULLSCAN 1;
set do_report_test_structures_FULLSCAN 1;
set do_verify_test_structures_FULLSCAN 1;

set do_create_atpg_vectors 1;

#*************************************************
#BUILD MODEL
#*************************************************
if {$do_build_model} {
    puts  "Building Test Model"
    build_model  \
       -cell $CELL \
       -workdir $WORKDIR \
       -designsource $NETLIST \
       -TECHLIB $LIBRARY \
       -allowmissingmodules yes 
}

#*************************************************
#BUILD TEST MODE FULLSCAN
#*************************************************
if {$do_build_testmode_FULLSCAN} {
    puts "Building Test Mode $TESTMODE"
    if {$MODEDEF ne ""} {
        build_testmode \
           -workdir $WORKDIR \
           -testmode $TESTMODE \
           -modedef $MODEDEF \
           -assignfile $ASSIGNFILE 
    } else {
        build_testmode \
           -workdir $WORKDIR \
           -testmode $TESTMODE \
           -assignfile $ASSIGNFILE 
    }
}

#*************************************************
#Report Test Structures for FULLSCAN MODE
#*************************************************
if {$do_report_test_structures_FULLSCAN} {
    puts "Report Test Structures $TESTMODE"
    # REDIRECT OUTPUT TO RESULTS FOLDER
    report_test_structures \
       -workdir $WORKDIR \
       -testmode $TESTMODE > $RESULTS_DIR/test_structures.rpt
}

#*************************************************
#Verify Test Structures for FULLSCAN MODE
#*************************************************
if {$do_verify_test_structures_FULLSCAN} {
    puts "Verify Test Structures $TESTMODE"
    # REDIRECT OUTPUT TO RESULTS FOLDER
    verify_test_structures \
       -workdir $WORKDIR \
       -testmode $TESTMODE > $RESULTS_DIR/verify_structures.rpt
}

#*************************************************
#BUILD FAULT MODEL
#*************************************************
if { $do_fault_model} {
    puts "Building Test Fault Model"
    build_faultmodel
}

#*************************************************
#Create ATPG Vectors & Generate Reports
#*************************************************
#*************************************************
#Create ATPG Vectors & Generate Reports
#*************************************************
#*************************************************
#Create ATPG Vectors & Generate Reports
#*************************************************
if {$do_create_atpg_vectors} {
    puts "Generating Test Vectors..."

    # Capture ATPG output (coverage, faults, etc.)
    redirect $RESULTS_DIR/test_coverage.rpt {
        create_logic_tests -experiment ex1 -testmode $TESTMODE
    }

    puts ">>> Writing Verilog Vectors..."

    write_vectors -inexperiment ex1 -testmode $TESTMODE -language verilog -outputfilename $RESULTS_DIR/test_vectors.v
}
puts "\n============================================="
puts "Modus Run Complete."
puts "All reports and vectors are saved in: $RESULTS_DIR"
puts "=============================================\n"
