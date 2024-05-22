--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package miniproc_pkg is

    ------------------- Constants declaration ------------------
    
    --Adress and data size constants
    constant cDATA_SIZE      : integer := 8;
	constant cDATA_ADR_SIZE  : integer := 11;
	constant cINSTR_SIZE     : integer := 16;
	constant cPROGR_ADR_SIZE : integer := 10;
    constant cREG_SEL_SIZE : integer := 2;
    constant cREG_NB : integer := 2**cREG_SEL_SIZE;
	constant cOP_CODE_SIZE : integer := 3;
    constant cOP_CODE_ALU_SIZE : integer := 2;
	constant cSEL_IN_ALU_SIZE : integer := 2;

	--Opcode
	constant cLOAD_INSTR  : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "000";
	constant cSTORE_INSTR : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "001";
	constant cCPY_INSTR   : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "010";
	constant cMAC_INSTR   : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "011";
	constant cDEC_INSTR   : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "100";
	constant cEQL0_INSTR  : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "101";
	constant cJMP_INSTR   : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "110";
	constant cJMPC_INSTR  : std_logic_vector(cOP_CODE_SIZE-1 downto 0) := "111";

    --Opcode ALU
    constant cDEFAULT_OP : std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0) := "00";
    constant cDEC_OP     : std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0) := "01";
    constant cEQL0_OP    : std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0) := "10";
    constant cMAC_OP     : std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0) := "11";

   --READ WRITE constant for memory
	constant cREAD  : std_logic := '1';
	constant cWRITE : std_logic := '0';

	constant cRESET_ON : std_logic := '1';
	constant cRESET_OFF : std_logic := '0';

    ------------------- Register types declaration -------------------
    type tRegister is array (0 to cREG_NB-1) of std_logic_vector(cDATA_SIZE-1 downto 0);

    ------------------- Components declaration -------------------

	component miniproc_top is
		port (
			clk_i   : in std_logic;
			reset_i : in std_logic
		);
	end component;
	
	component proc is
		port (
            clk_i   : in std_logic;
            reset_i : in std_logic;
            
            addr_bus_p_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
            data_bus_p_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
            
            addr_bus_d_o  : out std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
            data_bus_d_i  : in std_logic_vector(cDATA_SIZE-1 downto 0);
            data_bus_d_o  : out std_logic_vector(cDATA_SIZE-1 downto 0);
            
            rwmem_o  : out std_logic
		);
	end component;

	component controler
		port (
            clk_i   : in std_logic;
            reset_i : in std_logic;
            
            flag_i   : in std_logic;
            opcode_i : in std_logic_vector(cOP_CODE_SIZE-1 downto 0);
            
            rwdmem_o : out std_logic;
            
            sela_o   : out std_logic;
            rwreg_o  : out std_logic;
			opcode_alu_o : out std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
            inalu_o  : out std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
            inreg_o  : out std_logic;
            ldres_o  : out std_logic;
            ldflg_o  : out std_logic;
            ldpc_o   : out std_logic;
            selpc_o  : out std_logic;
            ldir_o   : out std_logic
		);
	end component;
	
	component traitement
		port (
            clk_i   : in std_logic;
            reset_i : in std_logic;
            
            sela_i   : in std_logic;
            rwreg_i  : in std_logic;
            opcode_alu_i : in std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
            inalu_i  : in std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
            inreg_i  : in std_logic;
            ldres_i  : in std_logic;
            ldflg_i  : in std_logic;
            ldpc_i   : in std_logic;
            selpc_i  : in std_logic;
            ldir_i   : in std_logic;
            
            flag_o   : out std_logic;
            opcode_o : out std_logic_vector(2 downto 0);
            
            addr_bus_p_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
            data_bus_p_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
            
            addr_bus_d_o  : out std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
            data_mem_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
            data_mem_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
        );
	end component;

	component registers
		port (
			clk_i   : in std_logic;
			reset_i : in std_logic;
			
			input_bus_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
			
			a_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
			b_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
			c_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
			
			w_reg_i : in std_logic_vector(1 downto 0);
			reg2_i : in std_logic_vector(1 downto 0);
			reg3_i : in std_logic_vector(1 downto 0); 
			
			rw_i  : in std_logic;
			sela_i : in std_logic         
		);
	end component;
	
	component pc
		port (
			clk_i   : in std_logic;
			reset_i : in std_logic;
			
			ldpc_i   : in std_logic;
			selpc_i  : in std_logic;
			
			jmp_i : in std_logic_vector(cPROGR_ADR_SIZE downto 0);
			pc_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0)
		);
	end component;
	
	component ir
		port (
			clk_i : in std_logic;
			reset_i : in std_logic;

			ldir_i : in std_logic;
			ir_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
			ir_o : out std_logic_vector(cINSTR_SIZE-1 downto 0)
		);
	end component;

	component alu
		port (
			clk_i   : in std_logic;
			reset_i : in std_logic;
			
			inalu_i  : in std_logic_vector(cSEL_IN_ALU_SIZE-1 downto 0);
			opcode_alu_i : in std_logic_vector(cOP_CODE_ALU_SIZE-1 downto 0);
			ldres_i  : in std_logic;
            ldflg_i  : in std_logic;
			
			a_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
			b_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
			c_i      : in std_logic_vector(cDATA_SIZE-1 downto 0);
			
			flag_o   : out std_logic;
			result_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
		);
	end component;

	component write_back 
		port (
            data_mem_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
            data_from_alu_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
                
            inreg_i : in std_logic;
            
            data2reg_o : out std_logic_vector(cDATA_SIZE-1 downto 0)
		);
	end component;

	component data_mem
        port (
            clk_i : in std_logic;
            adr_i : in std_logic_vector(cDATA_ADR_SIZE-1 downto 0);
            data_i : in std_logic_vector(cDATA_SIZE-1 downto 0);
            data_o : out std_logic_vector(cDATA_SIZE-1 downto 0);
            ce_i : in std_logic;
            rw_i : in std_logic
        );
	end component;
	
	component prog_mem
		port (
			clk_i : in std_logic;
			adr_i : in std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
            data_i : in std_logic_vector(cINSTR_SIZE-1 downto 0);
            data_o : out std_logic_vector(cINSTR_SIZE-1 downto 0);
			ce_i : in std_logic;
			rw_i : in std_logic
		);
	end component;

	component mux is
		port (
			a_i : in std_logic;
			b_i : in std_logic;
			sel_i : in std_logic;
			z_o : out std_logic
		);
	end component mux;

	component pc_alu_sum is
		port (
			a_i : in std_logic_vector(cPROGR_ADR_SIZE-1 downto 0);
			b_i : in std_logic_vector(cPROGR_ADR_SIZE downto 0);
	
			z_o : out std_logic_vector(cPROGR_ADR_SIZE-1 downto 0)
		);
	end component pc_alu_sum;

end miniproc_pkg;

package body miniproc_pkg is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end miniproc_pkg;
