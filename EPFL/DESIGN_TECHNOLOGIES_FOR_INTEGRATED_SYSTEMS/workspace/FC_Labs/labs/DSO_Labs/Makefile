
DSO_EXE = eda snps dso_shell

run:
	@mkdir -p sbs_sessions/logs
	cd sbs_sessions && \
	$(DSO_EXE)  -f lab01_dso_compile.tcl | tee ./logs/dso.log && \
	cd -
clean:
	rm -rf sbs_sessions/logs sbs_sessions/work_compile dso_db sbs_sessions/dso_* Synopsys_stack_trace_*
 
