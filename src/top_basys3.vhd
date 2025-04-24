--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- clock reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- Declare components
    component clock_divider is
        generic ( constant k_DIV : natural := 2 );
        port (  i_clk    : in std_logic;    -- basys3 clk
                i_reset  : in std_logic;    -- asynchronous
                o_clk    : out std_logic    -- divided (slow) clock
        );
    end component clock_divider;
    
    component controller_fsm is
        port(  i_reset : in STD_LOGIC; --"synchronous" reset
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component controller_fsm;
    
    component ALU is
        port (  i_A : in STD_LOGIC_VECTOR (7 downto 0);
                i_B : in STD_LOGIC_VECTOR (7 downto 0);
                i_op : in STD_LOGIC_VECTOR (2 downto 0);
                o_result : out STD_LOGIC_VECTOR (7 downto 0);
                o_flags : out STD_LOGIC_VECTOR (3 downto 0)
                );
    end component ALU;
    
    component TDM4 is
        generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        port (  i_clk		: in  STD_LOGIC;
                i_reset		: in  STD_LOGIC; -- asynchronous
                i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	           );
        end component TDM4;
        
    component twos_comp is
        port (  i_bin: in std_logic_vector(7 downto 0);
                o_sign: out std_logic;
                o_hund: out std_logic_vector(3 downto 0);
                o_tens: out std_logic_vector(3 downto 0);
                o_ones: out std_logic_vector(3 downto 0)
               );
        end component twos_comp;
     
    component sevenseg_decoder is
        Port (  i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
                o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
               );
    end component sevenseg_decoder;
    
    -- Declare signals
    signal w_cycle : std_logic_vector(3 downto 0) := "0001"; --reset state
    signal w_clk_tdm   : std_logic;
    signal w_clk_fsm   : std_logic;
    signal w_data  : std_logic_vector(3 downto 0);
    signal w_sign  : std_logic:= '0';
    signal w_hund  : std_logic_vector(3 downto 0);
    signal w_tens  : std_logic_vector(3 downto 0);
    signal w_ones  : std_logic_vector(3 downto 0);
    signal w_zero  : std_logic_vector(7 downto 0) := "00000000";
    signal w_A     : std_logic_vector(7 downto 0) := "00000000";
    signal w_B     : std_logic_vector(7 downto 0) := "00000000";
    signal w_result: std_logic_vector(7 downto 0);
    signal w_bin   : std_logic_vector(7 downto 0);
    signal w_reg_reset: std_logic;
    signal w_F:      std_logic_vector(3 downto 0):= x"F";
    signal w_pos:    std_logic_vector(6 downto 0):= "1111111";
    signal w_neg:    std_logic_vector(6 downto 0):= "0111111";
    signal w_seg:    std_logic_vector(6 downto 0);
    signal w_mux_seg:std_logic_vector(1 downto 0);
    signal w_sel    :std_logic_vector(3 downto 0);
    signal w_fsm_ctrl:std_logic;
    signal w_op    : std_logic_vector(2 downto 0);
    signal f_regA  : std_logic_vector(7 downto 0);
    signal f_regB  : std_logic_vector(7 downto 0);
    signal f_regA_next  : std_logic_vector(7 downto 0);
    signal f_regB_next  : std_logic_vector(7 downto 0);
    signal w_reg_A_clk  : std_logic;
    signal w_reg_B_clk  : std_logic;
    
begin
	-- PORT MAPS ----------------------------------------
    controller_fsm_inst: controller_fsm
    port map(
        i_adv => w_clk_fsm,
        i_reset => btnU,
        o_cycle => w_cycle
        );
    
    clk_div_inst: clock_divider
    generic map( k_DIV => 50000)
    port map(
        i_clk => clk,
        i_reset => btnL,
        o_clk => w_clk_tdm
        );
   
    clk_div_fsm_inst: clock_divider
    generic map( k_DIV => 50000000)
    port map(
        i_clk => clk,
        i_reset => w_fsm_ctrl,
        o_clk => w_clk_fsm
        );
   
    twos_comp_inst: twos_comp
    port map(
        i_bin => w_bin,
        o_sign => w_sign,
        o_hund => w_hund,
        o_tens => w_tens,
        o_ones => w_ones
        );
    TDM4_inst: TDM4
    generic map( k_WIDTH => 4)
    port map(
        i_D3 => w_F,
        i_D2 => w_hund,
        i_D1 => w_tens,
        i_D0 => w_ones,
        i_clk => w_clk_tdm,
        i_reset => btnU,
        o_data => w_data,
        o_sel => w_sel
        );
     
     sevenseg_inst: sevenseg_decoder
     port map(
        i_Hex => w_data,
        o_seg_n => w_seg
        );
     
     ALU_inst: ALU
     port map(
        i_A => w_A,
        i_B => w_B,
        i_op => w_op,
        o_result => w_result,
        o_flags => led(15 downto 12)
        );              
   
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	led(3 downto 0) <= w_cycle;
	led(11 downto 4) <= (others => '0');
	an <= w_sel;
	w_mux_seg(1) <= w_sel(3);
	w_mux_seg(0) <= w_sign;
	w_fsm_ctrl <= not btnC;
	w_op(2) <= sw(2);
	w_op(1) <= sw(1);
	w_op(0) <= sw(0);
	--resets
	w_reg_reset <= (w_cycle(0) and not btnC) or btnU;
	--MUX
	w_bin <= w_A when (w_cycle = "0010") else
	         w_B when (w_cycle = "0100") else
	         w_result when (w_cycle = "1000") else
	         w_zero;
	seg <=   w_pos when (w_mux_seg = "00") else
	         w_neg when (w_mux_seg = "01") else
	         w_seg;
	             
	-- Registers signals
	w_reg_A_clk <= w_cycle(1);
	w_reg_B_clk <= w_cycle(2);
	f_regA_next <= sw(7 downto 0);
	f_regB_next <= sw(7 downto 0);
	w_A         <= f_regA;
	w_B         <= f_regB;
	--Processes (Registers)
	-- Registers w/ asynchronous reset------------
	register_A : process (w_reg_A_clk, w_reg_reset)
    begin
        if w_reg_reset = '1' then
            f_regA <= w_zero;        -- reset state is zero
        elsif (rising_edge(w_reg_A_clk)) then
            f_regA <= f_regA_next;    -- next state becomes current state
        end if;
    end process register_A;
	
	register_B : process (w_reg_B_clk, w_reg_reset)
    begin
        if w_reg_reset = '1' then
            f_regB <= w_zero;        -- reset state is zero
        elsif (rising_edge(w_reg_B_clk)) then
            f_regB <= f_regB_next;    -- next state becomes current state
        end if;
    end process register_B;
	
	
end top_basys3_arch;
