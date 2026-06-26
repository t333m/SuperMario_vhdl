library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity colision_mux is
    Port (
        clk             : in  std_logic;
        frame_tick      : in  std_logic;
        mario_x         : in  integer range 0 to 639;
        mario_y         : in  integer range 0 to 479;
        scroll_x        : in  unsigned(12 downto 0);
        rom_addr        : out std_logic_vector(12 downto 0);
        rom_data        : in  std_logic_vector(10 downto 0);
        suelo_solido    : out std_logic;
        muro_der        : out std_logic;
        muro_izq        : out std_logic;
        cab_solido      : out std_logic;
        izq_solido      : out std_logic;
        der_solido      : out std_logic;
        resultado_listo : out std_logic
    );
end colision_mux;

architecture Behavioral of colision_mux is

    constant MARIO_W : integer := 16;
    constant MARIO_H : integer := 16;
    constant TILE    : integer := 16;
    constant COLS    : integer := 200;

    -- Como Mario ahora avanza 2 px, revisamos 1 px extra hacia los lados.
    constant ADELANTO_LATERAL : integer := 1;

    function es_solido(id : integer) return std_logic is
    begin
        case id is
            when 0 | 34 | 35 | 6 | 7 | 8 | 103 => return '1';
            when 2 | 3 | 4 | 5                 => return '1';
            when 24 to 32                      => return '1';
            when others                        => return '0';
        end case;
    end function;

    function calc_addr(px, py : integer; scroll : integer)
            return std_logic_vector is
        variable col, row, mundo_x : integer;
    begin
        mundo_x := px + scroll;
        col := mundo_x / TILE;
        row := py / TILE;

        if col > 199 then col := 199; end if;
        if col < 0   then col := 0;   end if;
        if row > 29  then row := 29;  end if;
        if row < 0   then row := 0;   end if;

        return std_logic_vector(to_unsigned(row * COLS + col, 13));
    end function;

    type fsm_t is (IDLE,
                   REQ_A1, WAIT_A1, RD_A1,
                   REQ_A2, WAIT_A2, RD_A2,
                   REQ_B1, WAIT_B1, RD_B1,
                   REQ_B2, WAIT_B2, RD_B2,
                   REQ_C1, WAIT_C1, RD_C1,
                   REQ_C2, WAIT_C2, RD_C2,
                   REQ_D1, WAIT_D1, RD_D1,
                   REQ_D2, WAIT_D2, RD_D2,
                   DONE);

    signal estado : fsm_t := IDLE;

    signal s_suelo, s_cab, s_izq, s_der : std_logic := '0';
    signal t_suelo, t_cab, t_izq, t_der : std_logic := '0';

begin

    process(clk)
        variable sc : integer;
    begin
        if rising_edge(clk) then
            resultado_listo <= '0';
            sc := to_integer(scroll_x);

            case estado is

                when IDLE =>
                    t_suelo <= '0';
                    t_cab   <= '0';
                    t_izq   <= '0';
                    t_der   <= '0';

                    if frame_tick = '1' then
                        estado <= REQ_A1;
                    end if;

                -- SUELO
                when REQ_A1 =>
                    rom_addr <= calc_addr(mario_x + 2, mario_y + MARIO_H, sc);
                    estado   <= WAIT_A1;

                when WAIT_A1 =>
                    estado <= RD_A1;

                when RD_A1 =>
                    t_suelo <= es_solido(to_integer(unsigned(rom_data)));
                    estado  <= REQ_A2;

                when REQ_A2 =>
                    rom_addr <= calc_addr(mario_x + 13, mario_y + MARIO_H, sc);
                    estado   <= WAIT_A2;

                when WAIT_A2 =>
                    estado <= RD_A2;

                when RD_A2 =>
                    s_suelo <= t_suelo or es_solido(to_integer(unsigned(rom_data)));
                    estado  <= REQ_B1;

                -- TECHO
                when REQ_B1 =>
                    rom_addr <= calc_addr(mario_x + 2, mario_y - 1, sc);
                    estado   <= WAIT_B1;

                when WAIT_B1 =>
                    estado <= RD_B1;

                when RD_B1 =>
                    t_cab <= es_solido(to_integer(unsigned(rom_data)));
                    estado <= REQ_B2;

                when REQ_B2 =>
                    rom_addr <= calc_addr(mario_x + 13, mario_y - 1, sc);
                    estado   <= WAIT_B2;

                when WAIT_B2 =>
                    estado <= RD_B2;

                when RD_B2 =>
                    s_cab <= t_cab or es_solido(to_integer(unsigned(rom_data)));
                    estado <= REQ_C1;

                -- IZQUIERDA
                when REQ_C1 =>
                    rom_addr <= calc_addr(mario_x - 1 - ADELANTO_LATERAL, mario_y + 2, sc);
                    estado   <= WAIT_C1;

                when WAIT_C1 =>
                    estado <= RD_C1;

                when RD_C1 =>
                    t_izq <= es_solido(to_integer(unsigned(rom_data)));
                    estado <= REQ_C2;

                when REQ_C2 =>
                    rom_addr <= calc_addr(mario_x - 1 - ADELANTO_LATERAL, mario_y + 13, sc);
                    estado   <= WAIT_C2;

                when WAIT_C2 =>
                    estado <= RD_C2;

                when RD_C2 =>
                    s_izq <= t_izq or es_solido(to_integer(unsigned(rom_data)));
                    estado <= REQ_D1;

                -- DERECHA
                when REQ_D1 =>
                    rom_addr <= calc_addr(mario_x + MARIO_W + ADELANTO_LATERAL, mario_y + 2, sc);
                    estado   <= WAIT_D1;

                when WAIT_D1 =>
                    estado <= RD_D1;

                when RD_D1 =>
                    t_der <= es_solido(to_integer(unsigned(rom_data)));
                    estado <= REQ_D2;

                when REQ_D2 =>
                    rom_addr <= calc_addr(mario_x + MARIO_W + ADELANTO_LATERAL, mario_y + 13, sc);
                    estado   <= WAIT_D2;

                when WAIT_D2 =>
                    estado <= RD_D2;

                when RD_D2 =>
                    s_der <= t_der or es_solido(to_integer(unsigned(rom_data)));
                    estado <= DONE;

                when DONE =>
                    suelo_solido    <= s_suelo;
                    cab_solido      <= s_cab;
                    izq_solido      <= s_izq;
                    der_solido      <= s_der;

                    muro_izq        <= s_izq;
                    muro_der        <= s_der;

                    resultado_listo <= '1';
                    estado          <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;