----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    component ripple_adder is
        Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
               B : in STD_LOGIC_VECTOR (7 downto 0);
               Cin : in STD_LOGIC;
               S : out STD_LOGIC_VECTOR (7 downto 0);
               Cout : out STD_LOGIC
               );
    end component ripple_adder;

       --Signal declarations
       signal w_Ba:          std_logic_vector(7 downto 0);
       signal w_B_as:       std_logic_vector(7 downto 0);
       signal w_sum:        std_logic_vector(7 downto 0);
       signal w_result:     std_logic_vector(7 downto 0);
       signal w_and:        std_logic_vector(7 downto 0);
       signal w_or:         std_logic_vector(7 downto 0);
       signal w_as:         std_logic;
       signal w_CF:         std_logic;
       signal w_ZF:         std_logic;
       signal w_VF:         std_logic;
       signal w_Co:         std_logic;
       signal w_asum_xor:   std_logic;
       signal w_Vf_xnor:    std_logic;
       signal w_NF:         std_logic;

begin
    --Port Map
    ripple_adder_inst: ripple_adder
    port map(
            A => i_A,
            B => w_B_as,
            Cin => i_op(0),
            S => w_sum,
            Cout => w_Co
            );
     --Concurrent Statements
     
     --MUX for sub and add B
     w_Ba <= i_B;
     w_B_as <= not w_Ba when (i_op(0) = '1') else
                w_Ba;
     
     --MUX for the result selection
     w_result <= w_and when (i_op = "010") else
                 w_or  when (i_op = "011") else
                 w_sum;
     
     --Zero Flag logic (o_flags(2))
     w_ZF <= ((not w_result(7) and not(w_result(6)) and (not w_result(5) and not(w_result(4)))))
              and ((not w_result(3) and not(w_result(2)) and (not w_result(1) and not(w_result(0)))));
     
     --AND Operation
     w_and <= i_A and w_Ba;
     
     --OR Operation
     w_or <= i_A or w_Ba;
     
     --Addition and Subtraction (as) signal inversion
     w_as <= not i_op(1);
     
     --Carry Flag logic (o_flags(1))
     w_CF <= w_Co and w_as;
     
     --XOR for the Overflow
     w_asum_xor <= w_sum(7) xor i_A(7);
     
     --XNOR for the Overflow
     w_Vf_xnor <= not (i_A(7) xor w_Ba(7) xor i_op(0));
     
     --Overflow Flag logic (o_flags(0))
     w_VF <= w_Vf_xnor and w_as and w_asum_xor;
     
     --Negative Flag logic (o_flags(3))
     w_NF <= w_result(7);
     
     --Output connections
     o_result    <= w_result;
     o_flags(3)  <= w_NF;
     o_flags(2)  <= w_ZF;
     o_flags(1)  <= w_CF;
     o_flags(0)  <= w_VF;   

end Behavioral;
