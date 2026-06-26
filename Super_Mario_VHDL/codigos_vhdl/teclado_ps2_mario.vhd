library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity teclado_ps2_mario is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        ps2_clk   : in  std_logic;
        ps2_data  : in  std_logic;

        key_left  : out std_logic;
        key_right : out std_logic;
        key_jump  : out std_logic
    );
end teclado_ps2_mario;

architecture Behavioral of teclado_ps2_mario is

    signal ps2_clk_sync  : std_logic_vector(3 downto 0) := "1111";
    signal ps2_data_sync : std_logic_vector(1 downto 0) := "11";

    signal bit_count : integer range 0 to 10 := 0;
    signal data_reg  : std_logic_vector(7 downto 0) := (others => '0');

    signal rx_byte  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_ready : std_logic := '0';

    signal break_code : std_logic := '0';

    signal left_s  : std_logic := '0';
    signal right_s : std_logic := '0';
    signal jump_s  : std_logic := '0';

begin

    -- =========================
    -- RECEPTOR PS/2
    -- =========================
    process(clk, rst)
    begin
        if rst = '1' then
            ps2_clk_sync  <= "1111";
            ps2_data_sync <= "11";
            bit_count     <= 0;
            data_reg      <= (others => '0');
            rx_byte       <= (others => '0');
            rx_ready      <= '0';

        elsif rising_edge(clk) then

            rx_ready <= '0';

            ps2_clk_sync  <= ps2_clk_sync(2 downto 0) & ps2_clk;
            ps2_data_sync <= ps2_data_sync(0) & ps2_data;

            -- Detectar flanco de bajada del reloj PS/2
            if ps2_clk_sync(3 downto 2) = "10" then

                case bit_count is

                    when 0 =>
                        -- Start bit
                        if ps2_data_sync(1) = '0' then
                            bit_count <= 1;
                        else
                            bit_count <= 0;
                        end if;

                    when 1 =>
                        data_reg(0) <= ps2_data_sync(1);
                        bit_count <= 2;

                    when 2 =>
                        data_reg(1) <= ps2_data_sync(1);
                        bit_count <= 3;

                    when 3 =>
                        data_reg(2) <= ps2_data_sync(1);
                        bit_count <= 4;

                    when 4 =>
                        data_reg(3) <= ps2_data_sync(1);
                        bit_count <= 5;

                    when 5 =>
                        data_reg(4) <= ps2_data_sync(1);
                        bit_count <= 6;

                    when 6 =>
                        data_reg(5) <= ps2_data_sync(1);
                        bit_count <= 7;

                    when 7 =>
                        data_reg(6) <= ps2_data_sync(1);
                        bit_count <= 8;

                    when 8 =>
                        data_reg(7) <= ps2_data_sync(1);
                        bit_count <= 9;

                    when 9 =>
                        -- Paridad, se ignora
                        bit_count <= 10;

                    when 10 =>
                        -- Stop bit
                        if ps2_data_sync(1) = '1' then
                            rx_byte  <= data_reg;
                            rx_ready <= '1';
                        end if;

                        bit_count <= 0;

                    when others =>
                        bit_count <= 0;

                end case;

            end if;

        end if;
    end process;

    -- =========================
    -- DECODIFICADOR WASD
    -- =========================
    process(clk, rst)
    begin
        if rst = '1' then
            break_code <= '0';

            left_s  <= '0';
            right_s <= '0';
            jump_s  <= '0';

        elsif rising_edge(clk) then

            if rx_ready = '1' then

                -- F0 indica que la tecla se solto
                if rx_byte = x"F0" then
                    break_code <= '1';

                else

                    case rx_byte is

                        -- A = izquierda
                        -- Scan code set 2: 1C
                        when x"1C" =>
                            if break_code = '1' then
                                left_s <= '0';
                            else
                                left_s <= '1';
                            end if;
                            break_code <= '0';

                        -- D = derecha
                        -- Scan code set 2: 23
                        when x"23" =>
                            if break_code = '1' then
                                right_s <= '0';
                            else
                                right_s <= '1';
                            end if;
                            break_code <= '0';

                        -- W = salto
                        -- Scan code set 2: 1D
                        when x"1D" =>
                            if break_code = '1' then
                                jump_s <= '0';
                            else
                                jump_s <= '1';
                            end if;
                            break_code <= '0';

                        when others =>
                            break_code <= '0';

                    end case;

                end if;

            end if;

        end if;
    end process;

    key_left  <= left_s;
    key_right <= right_s;
    key_jump  <= jump_s;

end Behavioral;