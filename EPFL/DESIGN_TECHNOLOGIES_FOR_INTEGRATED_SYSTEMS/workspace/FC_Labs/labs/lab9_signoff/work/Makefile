#########################
### Makefile for Lab9 ###
#########################

help:
	@echo ""
	@echo " To print usage: 			make help "
	@echo " To run Lab7 with Fusion Compiler:	make run "
	@echo " To clean working area:			make clean "
	@echo ""

run:
	test -d ./logs	|| mkdir ./logs
	eda snps fc_shell  -no_log -f ../scripts/signoff.tcl | tee ./logs/signoff.log 

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/* legalizer* fmax_LP* signoff* report* post*
