#===============================================================================
## Adjust for your enviroment
## This script is sourced by other lab scripts within dso_shell
## during the setup of sessions
#===============================================================================

## Make sure the /path/to/fc_shell works in your environment.
#set fc_shell "/softs/synopsys/fusioncompiler/2024.09/bin/fc_shell"
set fc_shell "fc_shell"

# set_lsf_options -name lsf -queue_name atto -app "batch_normal" -resource_requirement { rusage[mem=10G] } -thread_count {8}

## For customer usage, if you are using bundled licensing, uncomment the
## following command line.
#set_license_mode bundled_license

## If you are using project-based licensing, uncomment the following
## command lines and update the project license name.
#set_license_mode project_based_license
#set_session_options -project_license MYLICENSE

## Define the compute resources available for this session; in this script,
## we define an LSF compute resource.
     ## For NetBatch:
     # set_netbatch_options -target <pool_name> -qslot <slot_name> \
     #    -exec_limit 12h:24h -class {"SLES12&&10G&&4C"}

     ## For Slurm:
     # set_slurm_options -partition_name <Enter_submission_queue_name_here> \
     #    -num_cpus 4 -mem 10G

     ## For SGE:
     # set_sge_options -name sge4 -project_name bnormal \
     #   -resource_list os_minor="7.3",mem_free=10G \
     #   -parallel_environment {mt 4}
#set_lsf_options -name lsf1 -app_profile bnormal -thread_count 4 \
#   -resource_requirement {'rusage[mem=10GB] span[hosts=1] select[(os=CS7.3)]'}
# set_lsf_options -name lsf1 -app_profile batch_ais -thread_count 4 \
#    -resource_requirement {span[hosts=1] rusage[mem=10GB] select[(qsc=w&&os=AlmaLinux8.4)]} \
#    -extra_options {-We 20 -P harness=bsub:#:product=fusioncompiler}

# set_lsf_options -name lsf -queue_name atto -app "batch_normal" -resource_requirement { rusage[mem=10G] } -thread_count {8}

### added by README
set_localhost_options -num_cores 1 -name tum_localhost -max_workers 5

