vlog +incdir+$UVM_HOME/src -L mtiAvm -L mtiOvm -L mtiUvm -L mtiUPF top_tb.sv
vsim -sv_seed 19940902 -ldflags "-lregex" -t 1ns -c -sv_lib  C:/questasim64_10.6c/uvm-1.1d/win64/uvm_dpi work.top_tb -novopt