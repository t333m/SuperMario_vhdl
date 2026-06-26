library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mario_ctrl is
    Port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        resultado_listo : in  std_logic;
        btn_izq         : in  std_logic;
        btn_der         : in  std_logic;
        btn_salto       : in  std_logic;

        col_A        : in  std_logic;
        col_B        : in  std_logic;
        col_C        : in  std_logic;
        col_D        : in  std_logic;

        pixel_x      : in  std_logic_vector(9 downto 0);
        pixel_y      : in  std_logic_vector(9 downto 0);

        mario_on     : out std_logic;
        mario_x      : out std_logic_vector(9 downto 0);
        mario_y      : out std_logic_vector(9 downto 0);
        mario_dir    : out std_logic;
        mario_estado : out std_logic_vector(1 downto 0);
        mario_vivo   : out std_logic
    );
end mario_ctrl;

architecture Behavioral of mario_ctrl is

    constant MARIO_W       : integer := 16;
    constant MARIO_H       : integer := 16;
    constant TILE          : integer := 16;

    constant GRAVEDAD      : integer := 1;
    constant MAX_V_CAIDA   : integer := 8;
    constant FUERZA_SALTO  : integer := 12;

    -- Velocidad horizontal real
    constant VEL_CAMINAR   : integer := 2;

    constant MARIO_START_X : integer := 100;
    constant MARIO_START_Y : integer := 352;

    -- 1 = no divide el movimiento horizontal
    constant MOVE_DIV : integer := 1;

    signal mx     : integer range 0 to 639 := MARIO_START_X;
    signal my     : integer range 0 to 479 := MARIO_START_Y;
    signal mvy    : integer range -20 to 20 := 0;

    signal m_dir  : std_logic := '1';
    signal m_est  : std_logic_vector(1 downto 0) := "00";
    signal m_vivo : std_logic := '1';

    signal move_cont : integer range 0 to MOVE_DIV - 1 := 0;

    signal px_int, py_int : integer;

    function snap_suelo(y_actual : integer) return integer is
        variable suelo_y : integer;
        variable nuevo_y : integer;
    begin
        -- y_actual + MARIO_H es el punto que colision_mux revisa como suelo.
        -- Se acomoda al inicio del tile solido.
        suelo_y := ((y_actual + MARIO_H) / TILE) * TILE;
        nuevo_y := suelo_y - MARIO_H;

        if nuevo_y < 0 then
            nuevo_y := 0;
        end if;

        if nuevo_y > 463 then
            nuevo_y := 463;
        end if;

        return nuevo_y;
    end function;

begin

    process(clk, rst)
        variable nx, ny, nvy : integer;
        variable allow_hmove : boolean;
    begin
        if rst = '1' then
            mx        <= MARIO_START_X;
            my        <= MARIO_START_Y;
            mvy       <= 0;
            m_dir     <= '1';
            m_est     <= "00";
            m_vivo    <= '1';
            move_cont <= 0;

        elsif rising_edge(clk) then

            -- La fisica corre cuando el mux YA termino de calcular colisiones
            if resultado_listo = '1' and m_vivo = '1' then

                nvy := mvy;
                nx  := mx;
                ny  := my;
                allow_hmove := false;

                -- =========================
                -- GRAVEDAD / SALTO / SUELO
                -- =========================
                if col_A = '0' then

                    -- En el aire
                    if nvy < MAX_V_CAIDA then
                        nvy := nvy + GRAVEDAD;
                    end if;

                    ny := my + nvy;

                    if nvy < 0 then
                        m_est <= "10"; -- saltando
                    else
                        m_est <= "11"; -- cayendo
                    end if;

                else

                    -- Tocando suelo
                    if btn_salto = '1' then
                        nvy   := -FUERZA_SALTO;
                        ny    := my + nvy;
                        m_est <= "10"; -- saltando
                    else
                        nvy := 0;
                        ny  := snap_suelo(my); -- evita que se quede metido en el piso
                    end if;

                end if;

                -- Choque con techo
                if col_B = '1' and nvy < 0 then
                    nvy := 0;
                    ny  := my;
                end if;

                -- =========================
                -- DIVISOR DE MOVIMIENTO HORIZONTAL
                -- =========================
                if btn_der = '1' or btn_izq = '1' then

                    if move_cont = MOVE_DIV - 1 then
                        move_cont   <= 0;
                        allow_hmove := true;
                    else
                        move_cont   <= move_cont + 1;
                        allow_hmove := false;
                    end if;

                else
                    move_cont <= 0;
                end if;

                -- =========================
                -- MOVIMIENTO HORIZONTAL
                -- =========================
                if btn_der = '1' then

                    m_dir <= '1';

                    if col_A = '1' then
                        m_est <= "01"; -- caminando
                    end if;

                    if allow_hmove = true then
                        nx := mx + VEL_CAMINAR;
                    end if;

                elsif btn_izq = '1' then

                    m_dir <= '0';

                    if col_A = '1' then
                        m_est <= "01"; -- caminando
                    end if;

                    if allow_hmove = true then
                        nx := mx - VEL_CAMINAR;
                    end if;

                else

                    if col_A = '1' then
                        m_est <= "00"; -- quieto
                    end if;

                end if;

                -- Colisiones laterales
                if btn_der = '1' and col_D = '1' then
                    nx := mx;
                end if;

                if btn_izq = '1' and col_C = '1' then
                    nx := mx;
                end if;

                -- Limites de velocidad vertical
                if nvy > MAX_V_CAIDA then
                    nvy := MAX_V_CAIDA;
                end if;

                if nvy < -FUERZA_SALTO then
                    nvy := -FUERZA_SALTO;
                end if;

                -- Limites de pantalla
                if nx < 0 then
                    nx := 0;
                end if;

                if nx > 623 then
                    nx := 623;
                end if;

                if ny < 0 then
                    ny := 0;
                end if;

                -- Muerte por caida
                if ny > 463 then
                    mvy    <= 0;
                    m_est  <= "11";
                    m_vivo <= '0';
                else
                    mvy <= nvy;
                    mx  <= nx;
                    my  <= ny;
                end if;

            end if;
        end if;
    end process;

    px_int <= to_integer(unsigned(pixel_x));
    py_int <= to_integer(unsigned(pixel_y));

    mario_on <= '1' when (px_int >= mx and px_int < mx + MARIO_W and
                          py_int >= my and py_int < my + MARIO_H) else '0';

    mario_x      <= std_logic_vector(to_unsigned(mx, 10));
    mario_y      <= std_logic_vector(to_unsigned(my, 10));
    mario_dir    <= m_dir;
    mario_estado <= m_est;
    mario_vivo   <= m_vivo;

end Behavioral;