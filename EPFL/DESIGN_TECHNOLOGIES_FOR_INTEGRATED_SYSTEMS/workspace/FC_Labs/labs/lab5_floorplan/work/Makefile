#########################
### Makefile for Lab5 ###
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
	$(FC_EXE)  -no_log -f ../scripts/1.auto_floorplan.tcl | tee ./logs/auto_floorplan.log 

run_2: run_1
	$(FC_EXE)  -no_log -f ../scripts/2.manual_floorplan_creation.tcl | tee ./logs/manual_floorplan_creation.log 

run_3: run_2
	$(FC_EXE)  -no_log -f ../scripts/3.read_floorplan_and_create_PG_network.tcl | tee ./logs/read_floorplan_and_create_PG_network.log 
	
all: run_3

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/*
