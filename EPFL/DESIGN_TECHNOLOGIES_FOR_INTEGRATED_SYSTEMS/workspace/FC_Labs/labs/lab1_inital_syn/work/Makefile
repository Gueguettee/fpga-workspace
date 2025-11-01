#########################
### Makefile for Lab1 ###
#########################

FC_EXE = eda snps fc_shell

help:
	@echo ""
	@echo " To print usage: 			make help "
	@echo " To run Lab1 with Fusion Compiler:	make run "
	@echo " To clean working area:			make clean "
	@echo ""

run:
	test -d ./logs	|| mkdir ./logs
	$(FC_EXE)  -no_log -f ../scripts/inital_syn.tcl | tee ./logs/inital_syn.log 

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/*
