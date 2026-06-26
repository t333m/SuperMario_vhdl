library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_mario is
    Port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        btn_izq       : in  std_logic;
        btn_der       : in  std_logic;
        btn_salto     : in  std_logic;
        frame_tick    : in  std_logic;
        muro_der    : out  std_logic;
        muro_izq    : out  std_logic;

        scroll_x      : in  unsigned(12 downto 0);
        map_rom_addr  : out std_logic_vector(12 downto 0);
        map_rom_data  : in  std_logic_vector(10 downto 0);

        pixel_x       : in  std_logic_vector(9 downto 0);
        pixel_y       : in  std_logic_vector(9 downto 0);

        mario_on      : out std_logic;
        mario_x       : out std_logic_vector(9 downto 0);
        mario_y       : out std_logic_vector(9 downto 0);
        mario_dir     : out std_logic;
        mario_estado  : out std_logic_vector(1 downto 0);
        mario_vivo    : out std_logic
    );
end top_mario;

architecture Behavioral of top_mario is

    signal s_col_A   : std_logic;
    signal s_col_B   : std_logic;
    signal s_col_C   : std_logic;
    signal s_col_D   : std_logic;
	 signal s_resultado_listo: std_logic;

    signal mario_x_s : std_logic_vector(9 downto 0);
    signal mario_y_s : std_logic_vector(9 downto 0);
    signal mx_int    : integer range 0 to 639;
    signal my_int    : integer range 0 to 479;

begin

    mx_int <= to_integer(unsigned(mario_x_s));
    my_int <= to_integer(unsigned(mario_y_s));

    u_col_mux : entity work.colision_mux
        port map (
            clk             => clk,
            frame_tick      => frame_tick,
            mario_x         => mx_int,
            mario_y         => my_int,
            scroll_x        => scroll_x,
            rom_addr        => map_rom_addr,
            rom_data        => map_rom_data,
            suelo_solido    => s_col_A,
            cab_solido      => s_col_B,
            izq_solido      => s_col_C,
            der_solido      => s_col_D,
				muro_der => muro_der,
				muro_izq => muro_izq,
            resultado_listo => s_resultado_listo
        );

    u_mario_core : entity work.mario_ctrl
        port map (
            clk          => clk,
            rst          => rst,
            resultado_listo => s_resultado_listo,
            btn_izq      => btn_izq,
            btn_der      => btn_der,
            btn_salto    => btn_salto,
            col_A        => s_col_A,
            col_B        => s_col_B,
            col_C        => s_col_C,
            col_D        => s_col_D,
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            mario_on     => mario_on,
            mario_x      => mario_x_s,
            mario_y      => mario_y_s,
            mario_dir    => mario_dir,
            mario_estado => mario_estado,
            mario_vivo   => mario_vivo
        );

    mario_x <= mario_x_s;
    mario_y <= mario_y_s;

end Behavioral;
