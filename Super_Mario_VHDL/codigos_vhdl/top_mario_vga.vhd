library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_mario_vga is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    btn_start : in  std_logic;
    btn_left  : in  std_logic;
    btn_right : in  std_logic;
    btn_jump  : in  std_logic;

    ps2_clk   : in  std_logic;
    ps2_data  : in  std_logic;

    hsync     : out std_logic;
    vsync     : out std_logic;
    rgb       : out std_logic_vector(7 downto 0);

    music_normal   : out std_logic;
    music_victoria : out std_logic;
    music_gameover : out std_logic
  );
end entity top_mario_vga;

architecture behavioral of top_mario_vga is
signal key_left_s  : std_logic := '0';
signal key_right_s : std_logic := '0';
signal key_jump_s  : std_logic := '0';

signal ctrl_left_s  : std_logic := '0';
signal ctrl_right_s : std_logic := '0';
signal ctrl_jump_s  : std_logic := '0';

signal rgb_victory_bg   : std_logic_vector(7 downto 0);
signal victory_shadow_on : std_logic := '0';

signal game_over       : std_logic := '0';
signal victoria        : std_logic := '0';
signal frame_tick_game : std_logic;
signal game_active_s   : std_logic;
signal victory_text_on : std_logic := '0';

signal goomba_on_s       : std_logic;
signal rgb_goomba        : std_logic_vector(7 downto 0);
signal goomba_score_event : std_logic;
signal goomba_mario_dead  : std_logic;

signal rgb_mapa_con_goomba : std_logic_vector(7 downto 0);

signal tile_id_gameover : std_logic_vector(10 downto 0);
signal tile_id_victoria : std_logic_vector(10 downto 0);
signal tile_id_video    : std_logic_vector(10 downto 0);

signal gameover_addr : std_logic_vector(10 downto 0);
signal tile_col_gameover : integer range 0 to 39;
signal tile_idx_gameover : integer range 0 to 1199;

signal victoria_addr : std_logic_vector(10 downto 0);
signal tile_col_victoria : integer range 0 to 39;
signal tile_idx_victoria : integer range 0 to 1199;

signal puntaje : integer range 0 to 9999 := 0;

  -- Scroll lento
  constant MAX_COUNT : integer := 1666664;
  signal contador    : integer range 0 to MAX_COUNT := 0;
  signal estado_clk  : std_logic := '0';

  -- Tick de fisica a 30 Hz (833332 ciclos a 25 MHz)
  constant MAX_COUNT60   : integer := 833332;
  signal contador60      : integer range 0 to MAX_COUNT60 := 0;
  signal estado_clk60    : std_logic := '0';
  signal estado_clk60_prev : std_logic := '0';
  signal frame_tick_s    : std_logic;
  signal s_muro_izq    : std_logic;
  signal s_muro_der    : std_logic;

  -- VGA
  signal s_video_on  : std_logic;
  signal s_p_tick    : std_logic;
  signal s_pixel_x   : std_logic_vector(9 downto 0);
  signal s_pixel_y   : std_logic_vector(9 downto 0);

  signal s_rgb_out   : std_logic_vector(7 downto 0);
  signal px          : unsigned(9 downto 0);
  signal py          : unsigned(9 downto 0);
  signal tile_row    : integer range 0 to 29;
  signal tile_col    : integer range 0 to 199;
  signal tile_idx    : integer range 0 to 5999;
  signal tile_id     : std_logic_vector(10 downto 0);

  signal direccion_internaTile : std_logic_vector(14 downto 0);
  signal rgb_reg     : std_logic_vector(7 downto 0);
  signal rgb_pre     : std_logic_vector(7 downto 0);

	signal px_delay    : unsigned(9 downto 0);
	signal py_delay    : unsigned(9 downto 0);

	signal scroll_x            : unsigned(12 downto 0) := (others => '0');
	signal pixel_mundo_x       : unsigned(12 downto 0);
	signal pixel_mundo_x_delay : unsigned(12 downto 0);

  signal rgb_mario   : std_logic_vector(7 downto 0);
  signal rgb_coin    : std_logic_vector(7 downto 0);
  signal coin_x_pix  : unsigned(3 downto 0) := (others => '0');
  signal coin_y_pix  : unsigned(3 downto 0) := (others => '0');
  signal coin_on     : std_logic := '0';

  signal mario_on_s   : std_logic;
  signal mario_x_s    : std_logic_vector(9 downto 0);
  signal mario_y_s    : std_logic_vector(9 downto 0);
  signal mario_dir    : std_logic;
  signal mario_estado : std_logic_vector(1 downto 0);
  signal mario_estado_video : std_logic_vector(1 downto 0);
  signal mario_vivo   : std_logic;

  signal mario_x_int_s     : integer range 0 to 639 := 0;
  signal camara_der_activa : std_logic := '0';
  signal camara_izq_activa : std_logic := '0';
  signal btn_right_mario   : std_logic := '0';
  signal btn_left_mario    : std_logic := '0';

  signal dir_memoria             : std_logic_vector(12 downto 0);
  signal s_rom_map_mario_entrada : std_logic_vector(12 downto 0);
  signal s_rom_map_mario_salida  : std_logic_vector(10 downto 0);

  -- HUD de tiempo y puntuacion
  constant CLK_HZ : integer := 100000000;
  signal segundo_cont : integer range 0 to CLK_HZ - 1 := 0;

  constant MARIO_W        : integer := 16;
  constant MARIO_H        : integer := 16;
  constant COIN_W         : integer := 16;
  constant COIN_H         : integer := 16;
  constant NUM_COINS      : integer := 8;

--Castillo
constant CASTILLO_X     : integer := 2900;
constant CASTILLO_Y     : integer := 300;

-- Zona de camara
constant CAMARA_DER_X : integer := 240;
constant CAMARA_IZQ_X : integer := 160;
constant SCROLL_MAX   : integer := 2560;
constant SCROLL_STEP  : integer := 2;

  type coin_pos_array is array (0 to NUM_COINS - 1) of integer;
  constant COIN_X : coin_pos_array := (180, 360, 620, 900, 1180, 1460, 1840, 2240);
  constant COIN_Y : coin_pos_array := (320, 288, 320, 272, 320, 288, 304, 320);

  signal tiempo_cent  : integer range 0 to 9 := 0;
  signal tiempo_dec   : integer range 0 to 9 := 0;
  signal tiempo_uni   : integer range 0 to 9 := 0;
signal punt_mil     : integer range 0 to 9;
signal punt_cent    : integer range 0 to 9;
signal punt_dec     : integer range 0 to 9;
signal punt_uni     : integer range 0 to 9;
  signal hud_on       : std_logic := '0';
  signal coin_collected : std_logic_vector(NUM_COINS - 1 downto 0) := (others => '0');

  function digito_on(digito : integer; fila : integer; columna : integer) return boolean is
    variable bits : std_logic_vector(14 downto 0);
  begin
    case digito is
      when 0 => bits := "111101101101111";
      when 1 => bits := "010110010010111";
      when 2 => bits := "111001111100111";
      when 3 => bits := "111001111001111";
      when 4 => bits := "101101111001001";
      when 5 => bits := "111100111001111";
      when 6 => bits := "111100111101111";
      when 7 => bits := "111001001001001";
      when 8 => bits := "111101111101111";
      when others => bits := "111101111001111";
    end case;

    if fila < 0 or fila > 4 or columna < 0 or columna > 2 then
      return false;
    end if;

    return bits(14 - (fila * 3 + columna)) = '1';
  end function;

  function letra_on(letra : integer; fila : integer; columna : integer) return boolean is
    variable bits : std_logic_vector(14 downto 0);
  begin
    case letra is
      when 0 => bits := "111010010010010"; -- T
      when others => bits := "110101110100100"; -- P
    end case;

    if fila < 0 or fila > 4 or columna < 0 or columna > 2 then
      return false;
    end if;

    return bits(14 - (fila * 3 + columna)) = '1';
  end function;

  function letra_victoria_on(letra : integer; fila : integer; columna : integer) return boolean is
    variable bits : std_logic_vector(34 downto 0);
  begin
    case letra is
      when 0 => bits := "10001100011000110001100010101000100"; -- V
      when 1 => bits := "11111001000010000100001000010011111"; -- I
      when 2 => bits := "01111100001000010000100001000001111"; -- C
      when 3 => bits := "11111001000010000100001000010000100"; -- T
      when 4 => bits := "01110100011000110001100011000101110"; -- O
      when 5 => bits := "11110100011000111110101001001010001"; -- R
      when others => bits := "01110100011000111111100011000110001"; -- A
    end case;

    if fila < 0 or fila > 6 or columna < 0 or columna > 4 then
      return false;
    end if;

    return bits(34 - (fila * 5 + columna)) = '1';
  end function;

begin

game_active_s <= '1' when (game_over = '0' and victoria = '0') else '0';

frame_tick_game <= frame_tick_s when game_active_s = '1' else '0';

-- Camara: cuando Mario llega a la zona central, se mueve el mapa
-- y se detiene el movimiento local de Mario para que no se pegue a la derecha.
mario_x_int_s <= to_integer(unsigned(mario_x_s));

camara_der_activa <= '1' when (game_active_s = '1' and
                               ctrl_right_s = '1' and
                               mario_x_int_s >= CAMARA_DER_X and
                               to_integer(scroll_x) < SCROLL_MAX and
                               s_muro_der = '0') else '0';

camara_izq_activa <= '1' when (game_active_s = '1' and
                               ctrl_left_s = '1' and
                               mario_x_int_s <= CAMARA_IZQ_X and
                               to_integer(scroll_x) > 0 and
                               s_muro_izq = '0') else '0';

btn_right_mario <= '0' when camara_der_activa = '1' else ctrl_right_s;
btn_left_mario  <= '0' when camara_izq_activa = '1' else ctrl_left_s;

-- Si la camara se esta moviendo pero Mario localmente esta quieto,
-- mantenemos la animacion de caminar.
mario_estado_video <= "01" when ((camara_der_activa = '1' or camara_izq_activa = '1') and mario_estado = "00") else mario_estado;

punt_mil  <= puntaje / 1000;
punt_cent <= (puntaje / 100) mod 10;
punt_dec  <= (puntaje / 10) mod 10;
punt_uni  <= puntaje mod 10;

  -- Pulso de 1 ciclo en cada flanco ascendente de estado_clk60
  --frame_tick_s <= '1' when (estado_clk60 = '1' and estado_clk60_prev = '0') else '0';

  pixel_mundo_x <= unsigned("000" & px) + scroll_x;
  dir_memoria   <= std_logic_vector(to_unsigned(tile_idx, 13));

U_Teclado_PS2 : entity work.teclado_ps2_mario
    port map (
        clk       => clk,
        rst       => rst,
        ps2_clk   => ps2_clk,
        ps2_data  => ps2_data,

        key_left  => key_left_s,
        key_right => key_right_s,
        key_jump  => key_jump_s
    );

-- Controles finales del juego.
-- Dejo botones y teclado juntos para que puedas probar ambos.
ctrl_left_s  <= btn_left  or key_left_s;
ctrl_right_s <= btn_right or key_right_s;
ctrl_jump_s  <= btn_jump  or key_jump_s;

  U_Nivel_1 : entity work.rom_nivel1
    port map (
      clk        => clk,
      addr       => dir_memoria,
      outt       => tile_id,
      addr_mario => s_rom_map_mario_entrada,
      out_mario  => s_rom_map_mario_salida
    );
	 
	 tile_col_gameover <= to_integer(px(9 downto 4)) when to_integer(px) < 640 else 0;
tile_idx_gameover <= tile_row * 40 + tile_col_gameover;
gameover_addr <= std_logic_vector(to_unsigned(tile_idx_gameover, 11));

 tile_col_victoria <= to_integer(px(9 downto 4)) when to_integer(px) < 640 else 0;
tile_idx_victoria <= tile_row * 40 + tile_col_victoria;
victoria_addr <= std_logic_vector(to_unsigned(tile_idx_victoria, 11));

U_GameOver : entity work.pantalla_gameover
    port map (
        clk  => clk,
        addr => gameover_addr,
        outt => tile_id_gameover
    );

U_pantallaVictoria : entity work.pantalla_inicio
    port map (
        clk  => clk,
        addr => victoria_addr,
        outt => tile_id_victoria
    );

tile_id_video <= tile_id_gameover when game_over = '1' else 
						tile_id_victoria when victoria = '1' else tile_id;

direccion_internaTile <= tile_id_video(6 downto 0) &
                         std_logic_vector(py_delay(3 downto 0)) &
                         std_logic_vector(px_delay(3 downto 0))
                         when game_over = '1' or victoria = '1' else

                         tile_id_video(6 downto 0) &
                         std_logic_vector(py_delay(3 downto 0)) &
                         std_logic_vector(pixel_mundo_x_delay(3 downto 0));
								 
  U_Catalogo_Mapa : entity work.mapa_rom
    port map (
      clk      => clk,
      addr     => direccion_internaTile,
      data_out => s_rgb_out
    );

  U_MOTOR : entity work.motor
    port map (
      clk      => clk,
      reset    => rst,
      hsync    => hsync,
      vsync    => vsync,
      video_on => s_video_on,
      p_tick   => s_p_tick,
      pixel_x  => s_pixel_x,
      pixel_y  => s_pixel_y
    );

  U_pintarMario : entity work.pintar_mario
    port map (
      clk               => clk,
      frame_tick        => frame_tick_game,

      mario_estado      => mario_estado_video,
      mario_orientacion => mario_dir,

      mario_x           => mario_x_s,
      mario_y           => mario_y_s,

      px                => std_logic_vector(px),
      py                => std_logic_vector(py),

      mario_pixelsprite => rgb_mario
    );

	 
	 U_Goombas : entity work.goomba_ctrl
    port map (
        clk          => clk,
        rst          => rst,
        frame_tick   => frame_tick_game,
        game_active  => game_active_s,
        scroll_x     => scroll_x,

        pixel_x      => s_pixel_x,
        pixel_y      => s_pixel_y,

        mario_x      => mario_x_s,
        mario_y      => mario_y_s,
        mario_estado => mario_estado,

        goomba_on    => goomba_on_s,
        rgb_goomba   => rgb_goomba,

        mario_muere  => goomba_mario_dead,
        goomba_score => goomba_score_event
    );

  -- Delay de pixel + tick de fisica sincronizado con VGA
process(clk, rst)
begin
  if rst = '1' then
    frame_tick_s <= '0';
    px_delay     <= (others => '0');
    py_delay     <= (others => '0');
    tile_idx     <= 0;

  elsif rising_edge(clk) then

   px_delay            <= px;
	py_delay            <= py;
	pixel_mundo_x_delay <= pixel_mundo_x;
	tile_idx            <= tile_row * 200 + tile_col;

    -- Tick de fisica justo al terminar el ultimo pixel visible.
    -- Asi Mario, scroll y colisiones cambian fuera de la imagen visible.
    if s_p_tick = '1' and to_integer(px) = 639 and to_integer(py) = 479 then
      frame_tick_s <= '1';
    else
      frame_tick_s <= '0';
    end if;

  end if;
end process;

 -- Contador de tiempo, monedas, puntuacion y victoria
-- Contador de tiempo, monedas, puntuacion y victoria por llegar al castillo
process(clk, rst)
    variable mario_world_x  : integer;
    variable mario_screen_y : integer;
    variable coin_touch     : boolean;
    variable new_score      : integer;
    variable coins_next     : std_logic_vector(NUM_COINS - 1 downto 0);
begin
    if rst = '1' then
        segundo_cont    <= 0;
        tiempo_cent     <= 0;
        tiempo_dec      <= 0;
        tiempo_uni      <= 0;
        puntaje         <= 0;
        coin_collected  <= (others => '0');
        victoria        <= '0';

    elsif rising_edge(clk) then

        coin_touch := false;
        coins_next := coin_collected;

        if game_active_s = '1' then

            -- Tiempo
            if segundo_cont = CLK_HZ - 1 then
                segundo_cont <= 0;

                if tiempo_cent < 9 or tiempo_dec < 9 or tiempo_uni < 9 then
                    if tiempo_uni < 9 then
                        tiempo_uni <= tiempo_uni + 1;
                    else
                        tiempo_uni <= 0;

                        if tiempo_dec < 9 then
                            tiempo_dec <= tiempo_dec + 1;
                        else
                            tiempo_dec <= 0;

                            if tiempo_cent < 9 then
                                tiempo_cent <= tiempo_cent + 1;
                            end if;
                        end if;
                    end if;
                end if;

            else
                segundo_cont <= segundo_cont + 1;
            end if;

            -- Posicion de Mario en el mundo
            mario_world_x  := to_integer(unsigned(mario_x_s)) + to_integer(scroll_x);
            mario_screen_y := to_integer(unsigned(mario_y_s));

            -- Colision con monedas
            if frame_tick_game = '1' then
                for i in 0 to NUM_COINS - 1 loop
                    if coins_next(i) = '0' and
                       mario_world_x < COIN_X(i) + COIN_W and
                       mario_world_x + MARIO_W > COIN_X(i) and
                       mario_screen_y < COIN_Y(i) + COIN_H and
                       mario_screen_y + MARIO_H > COIN_Y(i) then

                        coins_next(i) := '1';
                        coin_touch := true;
                        exit;
                    end if;
                end loop;
            end if;

            coin_collected <= coins_next;

            -- Puntuacion
            new_score := puntaje;

            if coin_touch then
                new_score := new_score + 10;
            end if;

            if goomba_score_event = '1' then
                new_score := new_score + 50;
            end if;

            if new_score > 9999 then
                new_score := 9999;
            end if;

            puntaje <= new_score;

            -- Victoria al llegar al castillo
            if mario_world_x >= CASTILLO_X and mario_screen_y >= CASTILLO_Y then
                victoria <= '1';
            end if;

        end if;
    end if;
end process;

-- Scroll del mapa con camara real siguiendo a Mario
-- Cuando Mario pasa CAMARA_DER_X, se congela su X local y avanza el scroll.
-- Asi se ve la siguiente parte del nivel antes de que Mario se pegue al borde derecho.
process(clk, rst)
begin
    if rst = '1' then
        contador   <= 0;
        estado_clk <= '0';
        scroll_x   <= (others => '0');

    elsif rising_edge(clk) then

        if game_active_s = '1' and frame_tick_game = '1' then

            if camara_der_activa = '1' then

                if to_integer(scroll_x) <= SCROLL_MAX - SCROLL_STEP then
                    scroll_x <= scroll_x + to_unsigned(SCROLL_STEP, scroll_x'length);
                else
                    scroll_x <= to_unsigned(SCROLL_MAX, scroll_x'length);
                end if;

            elsif camara_izq_activa = '1' then

                if to_integer(scroll_x) >= SCROLL_STEP then
                    scroll_x <= scroll_x - to_unsigned(SCROLL_STEP, scroll_x'length);
                else
                    scroll_x <= (others => '0');
                end if;

            end if;

        end if;

    end if;
end process;

  px <= unsigned(s_pixel_x);
  py <= unsigned(s_pixel_y);

  tile_col <= to_integer(pixel_mundo_x(11 downto 4)) when to_integer(px) < 640 else 0;
  tile_row <= to_integer(py(9 downto 4))             when to_integer(py) < 480 else 0;

  rgb_reg <= "01010011" when s_rgb_out = "11100011" else s_rgb_out;


process(clk, rst)
begin
    if rst = '1' then
        game_over <= '0';

    elsif rising_edge(clk) then
        if victoria = '0' then
            if mario_vivo = '0' or goomba_mario_dead = '1' then
                game_over <= '1';
            end if;
        end if;
    end if;
end process;

  -- Monedas estaticas en coordenadas del mundo.
  process(pixel_mundo_x, py, coin_collected)
    variable wx : integer;
    variable y  : integer;
  begin
    wx := to_integer(pixel_mundo_x);
    y  := to_integer(py);

    coin_on    <= '0';
    coin_x_pix <= (others => '0');
    coin_y_pix <= (others => '0');

    for i in 0 to NUM_COINS - 1 loop
      if coin_collected(i) = '0' and
         wx >= COIN_X(i) and wx < COIN_X(i) + COIN_W and
         y >= COIN_Y(i) and y < COIN_Y(i) + COIN_H then
        coin_on    <= '1';
        coin_x_pix <= to_unsigned(wx - COIN_X(i), 4);
        coin_y_pix <= to_unsigned(y - COIN_Y(i), 4);
        exit;
      end if;
    end loop;
  end process;
  

  process(px, py, tiempo_cent, tiempo_dec, tiempo_uni, punt_mil, punt_cent, punt_dec, punt_uni)
    variable x     : integer;
    variable y     : integer;
    variable fila  : integer;
    variable col   : integer;
    variable enc   : boolean;
  begin
    x := to_integer(px);
    y := to_integer(py);
    enc := false;

    if y >= 8 and y < 28 then
      fila := (y - 8) / 4;

      if x >= 8 and x < 20 then
        col := (x - 8) / 4;
        enc := letra_on(0, fila, col);
      elsif x >= 24 and x < 36 then
        col := (x - 24) / 4;
        enc := digito_on(tiempo_cent, fila, col);
      elsif x >= 40 and x < 52 then
        col := (x - 40) / 4;
        enc := digito_on(tiempo_dec, fila, col);
      elsif x >= 56 and x < 68 then
        col := (x - 56) / 4;
        enc := digito_on(tiempo_uni, fila, col);
      elsif x >= 96 and x < 108 then
        col := (x - 96) / 4;
        enc := letra_on(1, fila, col);
      elsif x >= 112 and x < 124 then
        col := (x - 112) / 4;
        enc := digito_on(punt_mil, fila, col);
      elsif x >= 128 and x < 140 then
        col := (x - 128) / 4;
        enc := digito_on(punt_cent, fila, col);
      elsif x >= 144 and x < 156 then
        col := (x - 144) / 4;
        enc := digito_on(punt_dec, fila, col);
      elsif x >= 160 and x < 172 then
        col := (x - 160) / 4;
        enc := digito_on(punt_uni, fila, col);
      end if;
    end if;

    if enc then
      hud_on <= '1';
    else
      hud_on <= '0';
    end if;
  end process;

-- Dibujo de moneda sin usar sprite ROM
process(coin_on, coin_x_pix, coin_y_pix)
    variable x : integer;
    variable y : integer;
begin
    x := to_integer(coin_x_pix);
    y := to_integer(coin_y_pix);

    -- Transparente por defecto
    rgb_coin <= "11100011";

    if coin_on = '1' then

        -- Forma ovalada/circular de la moneda 16x16
        if (x >= 4 and x <= 11 and y >= 1 and y <= 14) or
           (x >= 2 and x <= 13 and y >= 4 and y <= 11) then

            -- Borde negro
            if x = 2 or x = 13 or y = 1 or y = 14 then
                rgb_coin <= "00000000";

            -- Borde naranja
            elsif x = 3 or x = 12 or y = 2 or y = 13 then
                rgb_coin <= "11110000";

            -- Brillo blanco
            elsif (x = 6 or x = 7) and y >= 4 and y <= 10 then
                rgb_coin <= "11111111";

            -- Centro amarillo
            else
                rgb_coin <= "11111100";
            end if;
        end if;
    end if;
end process;

rgb_mapa_con_goomba <= rgb_goomba when (goomba_on_s = '1') else rgb_reg;
  U_mux : entity work.mux_rifado
    port map (
      clk       => clk,
      mario_on  => mario_on_s,
      rgb_mario => rgb_mario,
      rgb_mapa  => rgb_mapa_con_goomba,
      rgb_final => rgb_pre
    );

  u_marioControl : entity work.top_mario
    port map (
      clk          => clk,
      rst          => rst,
      btn_izq      => btn_left_mario,
      btn_der      => btn_right_mario,
      btn_salto    => ctrl_jump_s,
      frame_tick   => frame_tick_game,
      muro_der     => s_muro_der,
      muro_izq     => s_muro_izq,
      scroll_x     => scroll_x,
      map_rom_addr => s_rom_map_mario_entrada,
      map_rom_data => s_rom_map_mario_salida,
      pixel_x      => s_pixel_x,
      pixel_y      => s_pixel_y,
      mario_on     => mario_on_s,
      mario_x      => mario_x_s,
      mario_y      => mario_y_s,
      mario_dir    => mario_dir,
      mario_estado => mario_estado,
      mario_vivo   => mario_vivo
    );

	process(px, py)
    variable x          : integer;
    variable y          : integer;
    variable fila       : integer;
    variable col        : integer;
    variable enc        : boolean;
    variable enc_shadow : boolean;
begin
    x := to_integer(px);
    y := to_integer(py);

    enc := false;
    enc_shadow := false;

    -- =========================
    -- TEXTO PRINCIPAL: VICTORIA
    -- =========================
    if y >= 120 and y < 176 then
        fila := (y - 120) / 8;

        if x >= 132 and x < 172 then
            col := (x - 132) / 8;
            enc := letra_victoria_on(0, fila, col); -- V

        elsif x >= 180 and x < 220 then
            col := (x - 180) / 8;
            enc := letra_victoria_on(1, fila, col); -- I

        elsif x >= 228 and x < 268 then
            col := (x - 228) / 8;
            enc := letra_victoria_on(2, fila, col); -- C

        elsif x >= 276 and x < 316 then
            col := (x - 276) / 8;
            enc := letra_victoria_on(3, fila, col); -- T

        elsif x >= 324 and x < 364 then
            col := (x - 324) / 8;
            enc := letra_victoria_on(4, fila, col); -- O

        elsif x >= 372 and x < 412 then
            col := (x - 372) / 8;
            enc := letra_victoria_on(5, fila, col); -- R

        elsif x >= 420 and x < 460 then
            col := (x - 420) / 8;
            enc := letra_victoria_on(1, fila, col); -- I

        elsif x >= 468 and x < 508 then
            col := (x - 468) / 8;
            enc := letra_victoria_on(6, fila, col); -- A
        end if;
    end if;

    -- =========================
    -- SOMBRA DEL TEXTO
    -- =========================
    if y >= 124 and y < 180 then
        fila := (y - 124) / 8;

        if x >= 136 and x < 176 then
            col := (x - 136) / 8;
            enc_shadow := letra_victoria_on(0, fila, col); -- V

        elsif x >= 184 and x < 224 then
            col := (x - 184) / 8;
            enc_shadow := letra_victoria_on(1, fila, col); -- I

        elsif x >= 232 and x < 272 then
            col := (x - 232) / 8;
            enc_shadow := letra_victoria_on(2, fila, col); -- C

        elsif x >= 280 and x < 320 then
            col := (x - 280) / 8;
            enc_shadow := letra_victoria_on(3, fila, col); -- T

        elsif x >= 328 and x < 368 then
            col := (x - 328) / 8;
            enc_shadow := letra_victoria_on(4, fila, col); -- O

        elsif x >= 376 and x < 416 then
            col := (x - 376) / 8;
            enc_shadow := letra_victoria_on(5, fila, col); -- R

        elsif x >= 424 and x < 464 then
            col := (x - 424) / 8;
            enc_shadow := letra_victoria_on(1, fila, col); -- I

        elsif x >= 472 and x < 512 then
            col := (x - 472) / 8;
            enc_shadow := letra_victoria_on(6, fila, col); -- A
        end if;
    end if;

    if enc then
        victory_text_on <= '1';
    else
        victory_text_on <= '0';
    end if;

    if enc_shadow then
        victory_shadow_on <= '1';
    else
        victory_shadow_on <= '0';
    end if;
end process;

process(px, py)
    variable x : integer;
    variable y : integer;
begin
    x := to_integer(px);
    y := to_integer(py);

    -- Fondo por defecto: cielo
    if y < 140 then
        rgb_victory_bg <= "01011111"; -- azul claro
    elsif y < 300 then
        rgb_victory_bg <= "00111111"; -- azul medio
    else
        rgb_victory_bg <= "00110111"; -- azul un poco mas oscuro
    end if;

    -- =========================
    -- NUBES
    -- =========================
    if ((x >= 70 and x <= 160 and y >= 50 and y <= 85) or
        (x >= 95 and x <= 185 and y >= 35 and y <= 95) or
        (x >= 130 and x <= 210 and y >= 50 and y <= 85)) then
        rgb_victory_bg <= "11111111";
    end if;

    if ((x >= 400 and x <= 490 and y >= 70 and y <= 105) or
        (x >= 425 and x <= 515 and y >= 55 and y <= 115) or
        (x >= 460 and x <= 540 and y >= 70 and y <= 105)) then
        rgb_victory_bg <= "11111111";
    end if;

    -- =========================
    -- CASTILLO
    -- =========================
    if (x >= 500 and x <= 610 and y >= 190 and y <= 351) then
        rgb_victory_bg <= "10110110"; -- gris
    end if;

    -- techo rojo
    if (x >= 490 and x <= 620 and y >= 170 and y < 190) then
        rgb_victory_bg <= "11100000";
    end if;

    -- torres
    if (x >= 500 and x <= 525 and y >= 150 and y < 220) or
       (x >= 545 and x <= 570 and y >= 135 and y < 220) or
       (x >= 585 and x <= 610 and y >= 150 and y < 220) then
        rgb_victory_bg <= "10110110";
    end if;

    -- almenas
    if (x >= 500 and x <= 610 and y >= 150 and y < 162 and ((x / 12) mod 2 = 0)) then
        rgb_victory_bg <= "10110110";
    end if;

    -- puerta
    if (x >= 545 and x <= 567 and y >= 295 and y <= 351) then
        rgb_victory_bg <= "01000000";
    end if;

    -- bandera
    if (x >= 556 and x <= 558 and y >= 110 and y <= 150) then
        rgb_victory_bg <= "11111111"; -- asta
    end if;

    if (x >= 559 and x <= 578 and y >= 112 and y <= 124) then
        rgb_victory_bg <= "00011100"; -- bandera verde
    end if;

    -- =========================
    -- SUELO TIPO MARIO
    -- =========================
    if y >= 336 and y < 352 then
        rgb_victory_bg <= "00011100"; -- pasto verde
    end if;

    if y >= 352 then
        if ((x / 16 + y / 16) mod 2 = 0) then
            rgb_victory_bg <= "11001000"; -- ladrillo claro
        else
            rgb_victory_bg <= "10101000"; -- ladrillo oscuro
        end if;
    end if;

    -- =========================
    -- MONEDITAS DECORATIVAS
    -- =========================
    -- moneda izquierda
    if ((x >= 95 and x <= 112 and y >= 185 and y <= 205) or
        (x >= 90 and x <= 117 and y >= 190 and y <= 200)) then
        rgb_victory_bg <= "11111100"; -- amarillo
    end if;

    -- moneda centro
    if ((x >= 305 and x <= 322 and y >= 70 and y <= 90) or
        (x >= 300 and x <= 327 and y >= 75 and y <= 85)) then
        rgb_victory_bg <= "11111100";
    end if;

    -- moneda derecha
    if ((x >= 445 and x <= 462 and y >= 200 and y <= 220) or
        (x >= 440 and x <= 467 and y >= 205 and y <= 215)) then
        rgb_victory_bg <= "11111100";
    end if;
end process;
		
		 rgb <= rgb_reg when (s_video_on = '1' and victoria = '1') else
       rgb_reg    when (s_video_on = '1' and game_over = '1') else
       "11111111" when (s_video_on = '1' and hud_on = '1') else
       rgb_coin   when (s_video_on = '1' and coin_on = '1' and rgb_coin /= "11100011") else
       rgb_pre    when s_video_on = '1' else
       (others => '0');
		 
		 -- Salidas para Arduino / DFPlayer
music_normal   <= '1' when game_active_s = '1' else '0';
music_victoria <= '1' when victoria = '1' else '0';
music_gameover <= '1' when game_over = '1' else '0';
		 
end architecture behavioral;