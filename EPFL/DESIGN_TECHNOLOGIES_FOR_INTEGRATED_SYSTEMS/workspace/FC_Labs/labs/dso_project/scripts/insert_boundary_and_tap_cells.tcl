#####################################################################
#####			Boundary/TAP cell insertion		#####
#####################################################################

#### Inserting boundary cells
set_boundary_cell_rules  \
        -top_boundary_cells                */${CELL_PREFIX}_CAPT2 \
        -bottom_boundary_cells             */${CELL_PREFIX}_CAPB2 \
	-left_boundary_cell                */${CELL_PREFIX}_CAPT2 \
	-right_boundary_cell               */${CELL_PREFIX}_CAPB2 \
        -top_left_outside_corner_cell      */${CELL_PREFIX}_CAPTIN13 \
        -top_right_outside_corner_cell     */${CELL_PREFIX}_CAPTIN13 \
        -bottom_left_outside_corner_cell   */${CELL_PREFIX}_CAPBIN13 \
        -bottom_right_outside_corner_cell  */${CELL_PREFIX}_CAPBIN13 
	
#	-mirror_left_outside_corner_cell \
#	-mirror_right_outside_corner_cell 
	
compile_boundary_cells

#### Inserting TAP cells
create_tap_cells   \
         -lib_cell  */${CELL_PREFIX}_TAPDS \
         -distance 60  \
         -pattern stagger \
         -skip_fixed_cells
