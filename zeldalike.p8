pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
	init_player()
	init_bullet()
end

function _update60()
 mouse_x_y()
	update_bullet()
	player_update()	
	for i in all(player) do
	 if (stat(34) & 1==1) spawn_bullet(i.x,i.y,1,2)
 end
end

function _draw()
 cls()
	draw_bullet()
	draw_mouse()
	draw_player()
	print(xy)
end
-->8
--player
function init_player()
	player={}
	add(player,{nb_player=1,x=64,y=64})
end

function player_update()
	for i in all(player) do
	 if (btn(⬅️)) i.x-=1
	 if (btn(➡️)) i.x+=1
	 if (btn(⬆️)) i.y-=1
	 if (btn(⬇️)) i.y+=1
	end  
end

function draw_player()
 for i in all(player) do
  spr(3,i.x,i.y)
 end
end

-->8
--bullet
function init_bullet()
	bullet = {}
end

function spawn_bullet(x,y,type_bullet,speed)
 xy = get_traj(x,y,mouse_x,mouse_y)
 traj_x = xy.x*speed
 traj_y = xy.y*speed
	add(bullet,{x=x,y=y,type_bullet=type_bullet,speed=speed,traj_x=traj_x,traj_y=traj_y})
	
end

function update_bullet()
	for i in all(bullet) do
		i.x += i.traj_x
		i.y += i.traj_y
	end
end

function draw_bullet()
	for i in all(bullet) do
		spr(i.type_bullet,i.x,i.y)
	end
end

-->8
--mouse
function mouse_x_y()
	poke(0x5f2d, 1)
	mouse_x=stat(32)
	mouse_y=stat(33)
end

function get_traj(x_satr,y_start,x_end,y_end)
	angle=atan2(x_end-x_satr, y_end-y_start)
	return {x = cos(angle),y = sin(angle)}
end

function draw_mouse()
	spr(2,mouse_x,mouse_y)
end

__gfx__
000000000000000000000000cc0000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000c000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000990000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000990000007110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000010000c000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000cc0000cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
