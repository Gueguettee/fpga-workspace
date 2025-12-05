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
	$(FC_EXE)  -no_log -f ../scripts/project_1.tcl | tee ./logs/project_1.log 

run_2:
	$(FC_EXE)  -no_log -f ../scripts/project_2.tcl | tee ./logs/project_2.log 

run_22:
	$(FC_EXE)  -no_log -f ../scripts/project_22.tcl | tee ./logs/project_22.log

run_23:
	$(FC_EXE)  -no_log -f ../scripts/project_23.tcl | tee ./logs/project_23.log

run_3:
	$(FC_EXE)  -no_log -f ../scripts/project_3.tcl | tee ./logs/project_3.log 

run_4:
	$(FC_EXE)  -no_log -f ../scripts/project_4.tcl | tee ./logs/project_4.log 

run_5:
	$(FC_EXE)  -no_log -f ../scripts/project_5_test.tcl | tee ./logs/project_5.log 

run_6:
	$(FC_EXE)  -no_log -f ../scripts/project_6.tcl | tee ./logs/project_6.log

run_6_test:
	$(FC_EXE)  -no_log -f ../scripts/project_6_test.tcl | tee ./logs/project_6_test.log


clean:
	rm -rf over_util* default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/* reports/* results/*
