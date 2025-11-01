#########################
### Makefile for Lab6 ###
#########################

FC_EXE = eda snps fc_shell

help:
	@echo ""
	@echo " To print usage: 			make help "
	@echo " To run Lab4 with Fusion Compiler:	make run "
	@echo " To clean working area:			make clean "
	@echo ""

run:
	test -d ./logs	|| mkdir ./logs
	$(FC_EXE)  -no_log -f ../scripts/place_opt.tcl | tee ./logs/place_opt.log 

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/* legalizer*
