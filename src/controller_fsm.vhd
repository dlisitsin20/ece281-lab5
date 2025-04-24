----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    --Signals
    signal f_Q:         std_logic_vector(3 downto 0) := "0001";
    signal f_Q_next:    std_logic_vector(3 downto 0) := "0010";
    
    
begin
    -- Concurrent Statements
    --Next State Logic:
    f_Q_next(3) <= f_Q(2);
    f_Q_next(2) <= f_Q(1);
    f_Q_next(1) <= f_Q(0);
    f_Q_next(0) <= f_Q(3);
    
    --Output Logic:
    o_cycle(3) <= (f_Q(3) and not f_Q(2) and not f_Q(1) and not f_Q(0));
    o_cycle(2) <= (not f_Q(3) and f_Q(2) and not f_Q(1) and not f_Q(0));
    o_cycle(1) <= (not f_Q(3) and not f_Q(2) and f_Q(1) and not f_Q(0));
    o_cycle(0) <= (not f_Q(3) and not f_Q(2) and not f_Q(1) and f_Q(0));
    
	-- State register ------------
	-- State memory with "synchronous" reset
	state_register : process(i_adv)
	begin
        if rising_edge(i_adv) then
           if i_reset = '1' then
               f_Q <= "0001"; -- reset state "CLEAR"
           else
                f_Q <= f_Q_next;
            end if;
        end if;
	end process state_register;
end FSM;
