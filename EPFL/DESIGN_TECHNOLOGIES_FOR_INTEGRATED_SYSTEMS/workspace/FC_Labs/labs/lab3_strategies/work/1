#########################
### Makefile for Lab3 ###
#########################

FC_EXE = eda snps fc_shell

help:
	@echo ""
	@echo " To print usage: 			make help "
	@echo " To run Lab3 with Fusion Compiler:	make all "
	@echo " To clean working area:			make clean "
	@echo ""

run_1:
	test -d ./logs	|| mkdir ./logs
	$(FC_EXE)  -no_log -f ../scripts/logic_opto_mcmm_basic.tcl | tee ./logs/logic_opto_mcmm_basic.log 

run_2: run_1
	$(FC_EXE)  -no_log -f ../scripts/logic_opto_mcmm_effort_for_area.tcl | tee ./logs/logic_opto_mcmm_effort_for_area.log 

run_3: run_2
	$(FC_EXE)  -no_log -f ../scripts/logic_opto_mcmm_effort_for_power.tcl | tee ./logs/logic_opto_mcmm_effort_for_power.log 
	
run_4: run_3
	$(FC_EXE)  -no_log -f ../scripts/logic_opto_mcmm_effort_for_timing.tcl | tee ./logs/logic_opto_mcmm_effort_for_timing.log 
	
all: run_4

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/*
