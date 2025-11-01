#########################
### Makefile for Lab8 ###
#########################

help:
	@echo ""
	@echo " To print usage: 			make help "
	@echo " To run Lab6 with Fusion Compiler:	make run "
	@echo " To clean working area:			make clean "
	@echo ""

run:
	test -d ./logs	|| mkdir ./logs
	/softs/synopsys/fusioncompiler/W-2024.09-SP2/bin/fc_shell  -no_log -f ../scripts/route_opt.tcl | tee ./logs/route_opt.log 

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/* legalizer* fmax_LP*
