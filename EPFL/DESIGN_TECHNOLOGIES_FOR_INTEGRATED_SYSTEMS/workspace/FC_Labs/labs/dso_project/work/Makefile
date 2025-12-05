################################
### Makefile for DSO Project ###
################################
DSO_EXE = eda snps dso_shell
FC_EXE  = eda snps fc_shell

run_dso:
	$(DSO_EXE)  -no_log -f ../scripts/dso.tcl | tee ./logs/dso.log

run_fc:
	$(FC_EXE)  -no_log -f ../scripts/fc_compile.tcl | tee ./logs/fc.log


clean:
	rm -rf over_util* default* *.dlib fc.log HDL* CLIBs fc* check* dso_* lm_command.log work* logs/* reports/* results/* dso_db/* dso_work_compile/*
