----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:04:11 06/05/2026 
-- Design Name: 
-- Module Name:    pintar_Mario - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

entity pintar_Mario is
    Port (
        clk                : in  STD_LOGIC;
        frame_tick         : in  STD_LOGIC;

        mario_estado       : in  STD_LOGIC_VECTOR (1 downto 0);
        mario_orientacion  : in  STD_LOGIC;

        mario_x            : in  STD_LOGIC_VECTOR (9 downto 0);
        mario_y            : in  STD_LOGIC_VECTOR (9 downto 0);

        px                 : in  STD_LOGIC_VECTOR (9 downto 0);
        py                 : in  STD_LOGIC_VECTOR (9 downto 0);

        mario_pixelsprite  : out STD_LOGIC_VECTOR (7 downto 0)
    );
end pintar_Mario;

architecture Behavioral of pintar_Mario is

    signal direccion_sprite : integer range 0 to 63 := 49;
    signal direccion_rom    : STD_LOGIC_VECTOR(13 downto 0);
    signal s_rgb_out        : STD_LOGIC_VECTOR (7 downto 0);

    signal walk_frame       : integer range 0 to 2 := 0;
    signal anim_cont        : integer range 0 to 5 := 0;

    signal sprite_x_local   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal sprite_y_local   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    u_sprites : entity work.sprites_personajes
        port map (
            clk       => clk,
            addr      => direccion_rom, 
            rgb_pixel => s_rgb_out
        );

    -- =========================
    -- CONTROL DE ANIMACION
    -- =========================
    process(clk)
    begin
        if rising_edge(clk) then

            if frame_tick = '1' then

                -- Mario caminando
                if mario_estado = "01" then

                    if anim_cont = 5 then
                        anim_cont <= 0;

                        if walk_frame = 2 then
                            walk_frame <= 0;
                        else
                            walk_frame <= walk_frame + 1;
                        end if;

                    else
                        anim_cont <= anim_cont + 1;
                    end if;

                else
                    anim_cont  <= 0;
                    walk_frame <= 0;
                end if;

            end if;

        end if;
    end process;

    -- =========================
    -- SELECCION DE SPRITE
    -- =========================
    process(mario_estado, mario_orientacion, walk_frame)
    begin

        if mario_orientacion = '1' then

            -- Mario viendo derecha
            case mario_estado is

                when "00" =>
                    direccion_sprite <= 49; -- quieto derecha

                when "01" =>
                    case walk_frame is
                        when 0 =>
                            direccion_sprite <= 55;
                        when 1 =>
                            direccion_sprite <= 56;
                        when others =>
                            direccion_sprite <= 57;
                    end case;

                when "10" =>
                    direccion_sprite <= 54; -- saltando derecha

                when others =>
                    direccion_sprite <= 50; -- cayendo derecha

            end case;

        else

            -- Mario viendo izquierda
            case mario_estado is

                when "00" =>
                    direccion_sprite <= 57; -- quieto izquierda

                when "01" =>
                    case walk_frame is
                        when 0 =>
                            direccion_sprite <= 60;
                        when 1 =>
                            direccion_sprite <= 59;
                        when others =>
                            direccion_sprite <= 58;
                    end case;

                when "10" =>
                    direccion_sprite <= 58; -- saltando izquierda

                when others =>
                    direccion_sprite <= 53; -- cayendo izquierda

            end case;

        end if;

    end process;

    -- =========================
    -- PIXEL LOCAL DEL SPRITE
    -- =========================
    process(px, py, mario_x, mario_y)
        variable px_i : integer;
        variable py_i : integer;
        variable mx_i : integer;
        variable my_i : integer;
        variable lx   : integer;
        variable ly   : integer;
    begin
        px_i := to_integer(unsigned(px));
        py_i := to_integer(unsigned(py));
        mx_i := to_integer(unsigned(mario_x));
        my_i := to_integer(unsigned(mario_y));

        lx := px_i - mx_i;
        ly := py_i - my_i;

        if lx >= 0 and lx < 16 then
            sprite_x_local <= std_logic_vector(to_unsigned(lx, 4));
        else
            sprite_x_local <= (others => '0');
        end if;

        if ly >= 0 and ly < 16 then
            sprite_y_local <= std_logic_vector(to_unsigned(ly, 4));
        else
            sprite_y_local <= (others => '0');
        end if;

    end process;

    -- Direccion final de la ROM:
    -- sprite + fila local + columna local
    direccion_rom <= std_logic_vector(to_unsigned(direccion_sprite, 6)) &
                     sprite_y_local &
                     sprite_x_local;

    mario_pixelsprite <= s_rgb_out;

end Behavioral;