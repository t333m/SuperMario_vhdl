----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    05:20:08 06/07/2026 
-- Design Name: 
-- Module Name:    mux_rifado - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux_rifado is
    Port ( clk : in STD_LOGIC;
			  mario_on : in STD_LOGIC;
			  rgb_mapa : in  STD_LOGIC_VECTOR (7 downto 0);
           rgb_mario : in  STD_LOGIC_VECTOR (7 downto 0);
           rgb_final : out  STD_LOGIC_VECTOR (7 downto 0));
end mux_rifado;

architecture Behavioral of mux_rifado is

signal rgb : std_logic_vector(7 downto 0);

begin

process(clk)
begin
	if(rising_edge(clk)) then 
		if(mario_on = '1' and rgb_mario /= "11100011") then
		rgb<= rgb_mario;
		else
		rgb<= rgb_mapa;
		end if;
	
	
	end if;
end process;

rgb_final<= rgb;


end Behavioral;

