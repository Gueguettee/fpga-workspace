## This is an example Fusion Compiler script for use in DSO.ai labs

# This loads the block from the copied design_dir data directory
open_block data/nlib/RGRJ.nlib:pre_floorplan

set core_utilization [expr {[info exists ::DSO_core_utilization] ? $::DSO_core_utilization : 0.6}]
set side_ratio       [expr {[info exists ::DSO_side_ratio]       ? $::DSO_side_ratio       : 1.0}]
initialize_floorplan -core_utilization $core_utilization -side_ratio "1 $side_ratio";

# Insert rudimentary PG network
create_net -power VDD
create_net -ground VSS
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]

create_pg_mesh_pattern pg_mesh1 -layers {{{vertical_layer: M2} \
          {width: 2} {spacing: interleaving} {pitch: 20} } \
          {{horizontal_layer: M3} {width: 2} {spacing: interleaving} \
          {pitch: 20} }} \
          -via_rule { {intersection : all} {via_master : {default}} }
set_pg_strategy s_mesh -core -pattern {{pattern: pg_mesh1} \
          {nets: {VDD VSS}}} -extension {{stop: design_boundary}}
compile_pg -strategies s_mesh

create_pg_std_cell_conn_pattern std_pattern -layers {M1}
set_pg_strategy s_rail -core \
          -pattern {{pattern: std_pattern}{nets: {VDD VSS}}} \
          -extension {{stop: outermost_ring}}
compile_pg -strategies s_rail


# And place pins on boundary
place_pins -self

set_threshold_voltage_group_type -type low_vt low_vt

# After floorplan is created, sized, and shaped, run thru entire compile fusion flow to assess QoR metrics
set_app_options -name route.global.deterministic -value on
compile_fusion

# The end of this script is the last launcher of the slice and required to save the block
save_block -as compile
