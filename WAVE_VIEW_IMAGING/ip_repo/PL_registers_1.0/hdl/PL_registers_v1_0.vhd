library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PL_registers_v1_0 is
	generic (
		-- Users to add parameters here
        FREQ_DATA_LENGTH 	: integer := 8;
        IFBW_DATA_LENGTH 	: integer := 5;
        PATH_DATA_LENGTH    : integer := 24;
        TILT_DATA_LENGTH    : integer := 3;
        SPM_DATA_LENGTH     : integer := 28;
		RF_POWER_DATA_LENGTH  : integer := 6;
		LO_POWER_DATA_LENGTH  : integer := 6;
		ATT_POWER_DATA_LENGTH : integer := 8;
		CABLE_CALFACT_POWER_DATA_LENGTH : integer := 6;
		CALFACT_POWER_DATA_LENGTH : integer := 6;
		MODE_DATA_LENGTH : integer := 4;
		VNA_STATUS_DATA_LENGTH : integer := 2;
		VGA_GAIN_DATA_LENGTH  : integer := 5;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 7
	);
	port (
		-- Users to add ports here
        start_PL_o      : out std_logic;
		reset_from_PS_o : out std_logic;

        init_meas_o     : out std_logic;
        freq_done_o     : out std_logic;
        path_done_o     : out std_logic;    
		freqPath_done_o	: out std_logic;
		start_cw_o		: out std_logic;
        
        freq_val_o      : out std_logic_vector(FREQ_DATA_LENGTH - 1 downto 0);
        ifbw_val_o      : out std_logic_vector(IFBW_DATA_LENGTH - 1 downto 0);
        path_tx_val_o   : out std_logic_vector(PATH_DATA_LENGTH - 1 downto 0);
        path_rx_val_o   : out std_logic_vector(PATH_DATA_LENGTH - 1 downto 0);
        
        mode_o          : out std_logic_vector(MODE_DATA_LENGTH - 1 downto 0);
 
        IQ_rdy_PL_i     : in std_logic;
        VNA_rdy_PL_i    : in std_logic;
		VNA_status_i	: in std_logic_vector(VNA_STATUS_DATA_LENGTH - 1 downto 0);

        I_TX_PL_i       : in std_logic_vector(31 downto 0);
        Q_TX_PL_i       : in std_logic_vector(31 downto 0);
        I_RX_PL_i       : in std_logic_vector(31 downto 0);
        Q_RX_PL_i       : in std_logic_vector(31 downto 0);
        
        output_tilt_i   : in std_logic_vector(TILT_DATA_LENGTH - 1 downto 0);        
        SPM_data_i      : in std_logic_vector(SPM_DATA_LENGTH - 1 downto 0);

		RF_power_o		: out std_logic_vector(RF_POWER_DATA_LENGTH - 1 downto 0);
		LO_power_o		: out std_logic_vector(LO_POWER_DATA_LENGTH - 1 downto 0);
		ATT_power_o		: out std_logic_vector(ATT_POWER_DATA_LENGTH - 1 downto 0);
		Cable_calfact_power_o : out std_logic_vector(CABLE_CALFACT_POWER_DATA_LENGTH - 1 downto 0);
		CalFact_power_o : out std_logic_vector(CALFACT_POWER_DATA_LENGTH - 1 downto 0);

		TX_VGA1_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
		RX_VGA1_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
		RX_VGA2_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);

		TX_VGA1_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
		RX_VGA1_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
		RX_VGA2_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
        
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic  
	);
end PL_registers_v1_0;

architecture arch_imp of PL_registers_v1_0 is

	-- component declaration
	component PL_registers_v1_0_S00_AXI is
		generic (
			-- Users to add parameters here
			FREQ_DATA_LENGTH 	: integer := 8;
			IFBW_DATA_LENGTH 	: integer := 5;
			PATH_DATA_LENGTH    : integer := 24;
			TILT_DATA_LENGTH    : integer := 3;
			SPM_DATA_LENGTH     : integer := 28;
			RF_POWER_DATA_LENGTH  : integer := 6;
			LO_POWER_DATA_LENGTH  : integer := 6;
			ATT_POWER_DATA_LENGTH : integer := 8;
			CABLE_CALFACT_POWER_DATA_LENGTH : integer := 6;
			CALFACT_POWER_DATA_LENGTH : integer := 6;
			MODE_DATA_LENGTH  : integer := 4;
			VNA_STATUS_DATA_LENGTH  : integer := 2;
			VGA_GAIN_DATA_LENGTH  : integer := 5;
			-- User parameters ends
			
			C_S_AXI_DATA_WIDTH	: integer	:= 32;
			C_S_AXI_ADDR_WIDTH	: integer	:= 7
		);
		port (
			-- Users to add ports here
			start_PL_o      : out std_logic;
			reset_from_PS_o : out std_logic;

			init_meas_o     : out std_logic;
			freq_done_o     : out std_logic;
			path_done_o     : out std_logic;    
			freqPath_done_o	: out std_logic;
			start_cw_o		: out std_logic;
			
			freq_val_o      : out std_logic_vector(FREQ_DATA_LENGTH - 1 downto 0);
			ifbw_val_o      : out std_logic_vector(IFBW_DATA_LENGTH - 1 downto 0);
			path_tx_val_o   : out std_logic_vector(PATH_DATA_LENGTH - 1 downto 0);
			path_rx_val_o   : out std_logic_vector(PATH_DATA_LENGTH - 1 downto 0);
			
			mode_o          : out std_logic_vector(MODE_DATA_LENGTH - 1 downto 0);
	
			IQ_rdy_PL_i     : in std_logic;
			VNA_rdy_PL_i    : in std_logic;
			VNA_status_i	: in std_logic_vector(VNA_STATUS_DATA_LENGTH - 1 downto 0);

			I_TX_PL_i       : in std_logic_vector(31 downto 0);
			Q_TX_PL_i       : in std_logic_vector(31 downto 0);
			I_RX_PL_i       : in std_logic_vector(31 downto 0);
			Q_RX_PL_i       : in std_logic_vector(31 downto 0);
			
			output_tilt_i   : in std_logic_vector(TILT_DATA_LENGTH - 1 downto 0);        
			SPM_data_i      : in std_logic_vector(SPM_DATA_LENGTH - 1 downto 0);

			RF_power_o		: out std_logic_vector(RF_POWER_DATA_LENGTH - 1 downto 0);
			LO_power_o		: out std_logic_vector(LO_POWER_DATA_LENGTH - 1 downto 0);
			ATT_power_o		: out std_logic_vector(ATT_POWER_DATA_LENGTH - 1 downto 0);
			Cable_calfact_power_o : out std_logic_vector(CABLE_CALFACT_POWER_DATA_LENGTH - 1 downto 0);
			CalFact_power_o : out std_logic_vector(CALFACT_POWER_DATA_LENGTH - 1 downto 0);

			TX_VGA1_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
			RX_VGA1_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
			RX_VGA2_gain_o   : out std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);

			TX_VGA1_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
			RX_VGA1_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
			RX_VGA2_gain_i   : in std_logic_vector(VGA_GAIN_DATA_LENGTH - 1 downto 0);
			
			-- User ports ends
			S_AXI_ACLK	: in std_logic;
			S_AXI_ARESETN	: in std_logic;
			S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
			S_AXI_AWVALID	: in std_logic;
			S_AXI_AWREADY	: out std_logic;
			S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
			S_AXI_WVALID	: in std_logic;
			S_AXI_WREADY	: out std_logic;
			S_AXI_BRESP	: out std_logic_vector(1 downto 0);
			S_AXI_BVALID	: out std_logic;
			S_AXI_BREADY	: in std_logic;
			S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
			S_AXI_ARVALID	: in std_logic;
			S_AXI_ARREADY	: out std_logic;
			S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_RRESP	: out std_logic_vector(1 downto 0);
			S_AXI_RVALID	: out std_logic;
			S_AXI_RREADY	: in std_logic
		);
	end component PL_registers_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
PL_registers_v1_0_S00_AXI_inst : PL_registers_v1_0_S00_AXI
	generic map (
        -- Users to add parameters here
        FREQ_DATA_LENGTH 	=> FREQ_DATA_LENGTH,
        IFBW_DATA_LENGTH 	=> IFBW_DATA_LENGTH,
        PATH_DATA_LENGTH    => PATH_DATA_LENGTH,
        TILT_DATA_LENGTH    => TILT_DATA_LENGTH,
        SPM_DATA_LENGTH     => SPM_DATA_LENGTH,
		RF_POWER_DATA_LENGTH 	=> RF_POWER_DATA_LENGTH,
		LO_POWER_DATA_LENGTH 	=> LO_POWER_DATA_LENGTH,
		ATT_POWER_DATA_LENGTH 	=> ATT_POWER_DATA_LENGTH,
		CALFACT_POWER_DATA_LENGTH => CALFACT_POWER_DATA_LENGTH,
		MODE_DATA_LENGTH => MODE_DATA_LENGTH,
		VNA_STATUS_DATA_LENGTH => VNA_STATUS_DATA_LENGTH,
		VGA_GAIN_DATA_LENGTH => VGA_GAIN_DATA_LENGTH,
		-- User parameters ends
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	   -- Users to add ports here
        start_PL_o      => start_PL_o,
		reset_from_PS_o => reset_from_PS_o,

        init_meas_o     => init_meas_o,
        freq_done_o     => freq_done_o,
        path_done_o     => path_done_o,
		freqPath_done_o	=> freqPath_done_o,
		start_cw_o		=> start_cw_o,
        
        freq_val_o      => freq_val_o,
        ifbw_val_o      => ifbw_val_o,
        path_tx_val_o   => path_tx_val_o,
        path_rx_val_o   => path_rx_val_o,
        mode_o          => mode_o,

        IQ_rdy_PL_i     => IQ_rdy_PL_i,
        VNA_rdy_PL_i    => VNA_rdy_PL_i,
		VNA_status_i	=> VNA_status_i,

        I_TX_PL_i       => I_TX_PL_i,
        Q_TX_PL_i       => Q_TX_PL_i,
        I_RX_PL_i       => I_RX_PL_i,
        Q_RX_PL_i       => Q_RX_PL_i,
        
        output_tilt_i   => output_tilt_i,
        SPM_data_i      => SPM_data_i,

		RF_power_o		=> RF_power_o,
		LO_power_o		=> LO_power_o,
		ATT_power_o		=> ATT_power_o,
		Cable_calfact_power_o => Cable_calfact_power_o,
		CalFact_power_o => CalFact_power_o,

		TX_VGA1_gain_o => TX_VGA1_gain_o,
		RX_VGA1_gain_o   => RX_VGA1_gain_o,
		RX_VGA2_gain_o   => RX_VGA2_gain_o,

		TX_VGA1_gain_i   => TX_VGA1_gain_i,
		RX_VGA1_gain_i   => RX_VGA1_gain_i,
		RX_VGA2_gain_i   => RX_VGA2_gain_i,
        
		-- User ports ends
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
