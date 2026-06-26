library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity goomba_ctrl is
    Port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        frame_tick   : in  std_logic;
        game_active  : in  std_logic;

        scroll_x     : in  unsigned(12 downto 0);

        pixel_x      : in  std_logic_vector(9 downto 0);
        pixel_y      : in  std_logic_vector(9 downto 0);

        mario_x      : in  std_logic_vector(9 downto 0);
        mario_y      : in  std_logic_vector(9 downto 0);
        mario_estado : in  std_logic_vector(1 downto 0);

        goomba_on    : out std_logic;
        rgb_goomba   : out std_logic_vector(7 downto 0);

        mario_muere  : out std_logic;
        goomba_score : out std_logic
    );
end goomba_ctrl;

architecture Behavioral of goomba_ctrl is

    constant NUM_GOOMBAS : integer := 4;

    constant GOOMBA_W : integer := 16;
    constant GOOMBA_H : integer := 16;
    constant MARIO_W  : integer := 16;
    constant MARIO_H  : integer := 16;

    constant TILE : integer := 16;
    constant COLS : integer := 200;

    constant GOOMBA_SPEED : integer := 1;

    type int_array is array (0 to NUM_GOOMBAS - 1) of integer range 0 to 4095;
    type y_array   is array (0 to NUM_GOOMBAS - 1) of integer range 0 to 479;

    -- Coordenadas X del mundo. Cambia estos valores si quieres mover los Goombas.
    constant START_X : int_array := (520, 980, 1560, 2240);
    constant START_Y : y_array   := (352, 352, 352, 352);

    signal gx : int_array := START_X;
    signal gy : y_array   := START_Y;

    -- '1' derecha, '0' izquierda
    signal gdir  : std_logic_vector(NUM_GOOMBAS - 1 downto 0) := "1010";
    signal alive : std_logic_vector(NUM_GOOMBAS - 1 downto 0) := (others => '1');

    signal rom_addr_s  : std_logic_vector(12 downto 0) := (others => '0');
    signal rom_data_s  : std_logic_vector(10 downto 0);
    signal dummy_addr  : std_logic_vector(12 downto 0) := (others => '0');
    signal dummy_data  : std_logic_vector(10 downto 0);

    type fsm_t is (
        IDLE,
        REQ_W1, WAIT_W1, RD_W1,
        REQ_W2, WAIT_W2, RD_W2,
        REQ_F1, WAIT_F1, RD_F1,
        REQ_F2, WAIT_F2, RD_F2,
        UPDATE_G,
        NEXT_G
    );

    signal estado : fsm_t := IDLE;
    signal idx    : integer range 0 to NUM_GOOMBAS - 1 := 0;

    signal t_wall  : std_logic := '0';
    signal s_wall  : std_logic := '0';
    signal s_floor_ahead   : std_logic := '0';
    signal s_floor_current : std_logic := '0';

    signal mario_muere_s  : std_logic := '0';
    signal goomba_score_s : std_logic := '0';

    function es_solido(id : integer) return std_logic is
    begin
        case id is
            when 0 | 34 | 35 | 6 | 7 | 8 | 103 => return '1';
            when 2 | 3 | 4 | 5                 => return '1';
            when 24 to 32                      => return '1';
            when others                        => return '0';
        end case;
    end function;

    function calc_addr(wx, py : integer) return std_logic_vector is
        variable col : integer;
        variable row : integer;
        variable x   : integer;
        variable y   : integer;
    begin
        x := wx;
        y := py;

        if x < 0 then
            x := 0;
        end if;

        if x > 3199 then
            x := 3199;
        end if;

        if y < 0 then
            y := 0;
        end if;

        if y > 479 then
            y := 479;
        end if;

        col := x / TILE;
        row := y / TILE;

        if col > 199 then col := 199; end if;
        if row > 29  then row := 29;  end if;

        return std_logic_vector(to_unsigned(row * COLS + col, 13));
    end function;

begin

    U_Mapa_Goombas : entity work.rom_nivel1
        port map (
            clk        => clk,
            addr       => rom_addr_s,
            addr_mario => dummy_addr,
            outt       => rom_data_s,
            out_mario  => dummy_data
        );

    process(clk, rst)
        variable check_x : integer;
        variable mxw     : integer;
        variable my      : integer;
        variable new_x   : integer;
        variable overlap : boolean;
        variable stomp   : boolean;
    begin
        if rst = '1' then

            for i in 0 to NUM_GOOMBAS - 1 loop
                gx(i) <= START_X(i);
                gy(i) <= START_Y(i);
            end loop;

            gdir  <= "1010";
            alive <= (others => '1');

            idx <= 0;
            estado <= IDLE;

            mario_muere_s  <= '0';
            goomba_score_s <= '0';

        elsif rising_edge(clk) then

            mario_muere_s  <= '0';
            goomba_score_s <= '0';

            if game_active = '1' then

                case estado is

                    when IDLE =>
                        if frame_tick = '1' then
                            idx <= 0;
                            estado <= REQ_W1;
                        end if;

                    -- Pared al frente, parte superior
                    when REQ_W1 =>
                        if gdir(idx) = '1' then
                            check_x := gx(idx) + GOOMBA_W;
                        else
                            check_x := gx(idx) - 1;
                        end if;

                        rom_addr_s <= calc_addr(check_x, gy(idx) + 3);
                        estado <= WAIT_W1;

                    when WAIT_W1 =>
                        estado <= RD_W1;

                    when RD_W1 =>
                        t_wall <= es_solido(to_integer(unsigned(rom_data_s)));
                        estado <= REQ_W2;

                    -- Pared al frente, parte inferior
                    when REQ_W2 =>
                        if gdir(idx) = '1' then
                            check_x := gx(idx) + GOOMBA_W;
                        else
                            check_x := gx(idx) - 1;
                        end if;

                        rom_addr_s <= calc_addr(check_x, gy(idx) + 13);
                        estado <= WAIT_W2;

                    when WAIT_W2 =>
                        estado <= RD_W2;

                    when RD_W2 =>
                        s_wall <= t_wall or es_solido(to_integer(unsigned(rom_data_s)));
                        estado <= REQ_F1;

                    -- Piso adelante para no caerse por orillas
                    when REQ_F1 =>
                        if gdir(idx) = '1' then
                            check_x := gx(idx) + GOOMBA_W + 1;
                        else
                            check_x := gx(idx) - 2;
                        end if;

                        rom_addr_s <= calc_addr(check_x, gy(idx) + GOOMBA_H + 1);
                        estado <= WAIT_F1;

                    when WAIT_F1 =>
                        estado <= RD_F1;

                    when RD_F1 =>
                        s_floor_ahead <= es_solido(to_integer(unsigned(rom_data_s)));
                        estado <= REQ_F2;

                    -- Piso actual debajo del centro del Goomba
                    when REQ_F2 =>
                        rom_addr_s <= calc_addr(gx(idx) + 8, gy(idx) + GOOMBA_H + 1);
                        estado <= WAIT_F2;

                    when WAIT_F2 =>
                        estado <= RD_F2;

                    when RD_F2 =>
                        s_floor_current <= es_solido(to_integer(unsigned(rom_data_s)));
                        estado <= UPDATE_G;

                    when UPDATE_G =>

                        if alive(idx) = '1' then

                            if s_floor_current = '0' then
                                if gy(idx) < 463 then
                                    gy(idx) <= gy(idx) + 2;
                                else
                                    alive(idx) <= '0';
                                end if;
                            else
                                if s_wall = '1' or s_floor_ahead = '0' then
                                    gdir(idx) <= not gdir(idx);
                                else
                                    new_x := gx(idx);

                                    if gdir(idx) = '1' then
                                        new_x := gx(idx) + GOOMBA_SPEED;
                                    else
                                        new_x := gx(idx) - GOOMBA_SPEED;
                                    end if;

                                    if new_x < 0 then
                                        new_x := 0;
                                        gdir(idx) <= '1';
                                    elsif new_x > 3180 then
                                        new_x := 3180;
                                        gdir(idx) <= '0';
                                    end if;

                                    gx(idx) <= new_x;
                                end if;
                            end if;

                            mxw := to_integer(unsigned(mario_x)) + to_integer(scroll_x);
                            my  := to_integer(unsigned(mario_y));

                            overlap :=
                                (mxw < gx(idx) + GOOMBA_W) and
                                (mxw + MARIO_W > gx(idx)) and
                                (my < gy(idx) + GOOMBA_H) and
                                (my + MARIO_H > gy(idx));

                            stomp :=
                                (mario_estado = "11") and
                                (my + MARIO_H <= gy(idx) + 8);

                            if overlap then
                                if stomp then
                                    alive(idx) <= '0';
                                    goomba_score_s <= '1';
                                else
                                    mario_muere_s <= '1';
                                end if;
                            end if;

                        end if;

                        estado <= NEXT_G;

                    when NEXT_G =>
                        if idx = NUM_GOOMBAS - 1 then
                            estado <= IDLE;
                        else
                            idx <= idx + 1;
                            estado <= REQ_W1;
                        end if;

                end case;

            end if;
        end if;
    end process;

    -- Dibujo del Goomba por lógica.
    process(clk)
        variable wx : integer;
        variable y  : integer;
        variable lx : integer;
        variable ly : integer;
        variable found : boolean;
    begin
        if rising_edge(clk) then

            wx := to_integer(unsigned(pixel_x)) + to_integer(scroll_x);
            y  := to_integer(unsigned(pixel_y));
            found := false;

            goomba_on  <= '0';
            rgb_goomba <= "11100011";

            for i in 0 to NUM_GOOMBAS - 1 loop
                if found = false then
                    if alive(i) = '1' and
                       wx >= gx(i) and wx < gx(i) + GOOMBA_W and
                       y  >= gy(i) and y  < gy(i) + GOOMBA_H then

                        lx := wx - gx(i);
                        ly := y  - gy(i);

                        -- Transparencia en esquinas superiores para que parezca redondo
                        if (ly < 3 and (lx < 4 or lx > 11)) then
                            goomba_on  <= '0';
                            rgb_goomba <= "11100011";
                        else
                            goomba_on <= '1';

                            -- Ojos
                            if (ly = 6 and (lx = 5 or lx = 10)) then
                                rgb_goomba <= "11111111";
                            elsif (ly = 7 and (lx = 5 or lx = 10)) then
                                rgb_goomba <= "00000000";

                            -- Patas
                            elsif (ly >= 14 and ((lx >= 2 and lx <= 5) or (lx >= 10 and lx <= 13))) then
                                rgb_goomba <= "00000000";

                            -- Cuerpo cafe con sombra
									elsif (lx = 0 or lx = 15 or ly = 3 or ly = 13) then
										 rgb_goomba <= "00000000"; -- contorno negro

									elsif ly >= 10 then
										 rgb_goomba <= "10001000"; -- cafe oscuro

									else
										 rgb_goomba <= "11001000"; -- cafe principal
									end if;
                        end if;

                        found := true;
                    end if;
                end if;
            end loop;

        end if;
    end process;

    mario_muere  <= mario_muere_s;
    goomba_score <= goomba_score_s;

end Behavioral;