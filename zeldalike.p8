pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
--game name goes here
--by gouspourd,yolwoocle,notgoyome

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
	 if (stat(34) & 2==2) spawn_bullet(i.x,i.y,2,4)
	end
end

function _draw()
 cls()
 map()
	draw_bullet()
	draw_mouse()
	draw_player()
	check_flag(1,mouse_x,mouse_y)
	
	print(players[1].dx, 0,0)
	print(players[1].dy, 0,10)
	print (timeur_bullet,15,15)
	print((stat(34) & 2==2),20,20)
end
-->8
--player
function init_player()
	players={}
	add(players, 
	{
		n=0,
		
		x=64,y=64,
		dx=0,dy=0,
		
		spd=.30,
		fric=0.8,
		
		bx=0,by=0,
		bw=8,bh=8,
	})
end

function player_update()
	for p in all(players) do
	 local dx,dy = p.dx,p.dy
	 local spd = p.spd
	 
	 if stat(34) & 1==1 then
	  spawn_bullet(p.x,p.y,1,2)
	 end
	 
	 if (btn(⬅️,p.n)) p.dx-=spd
	 if (btn(➡️,p.n)) p.dx+=spd
	 if (btn(⬆️,p.n)) p.dy-=spd
	 if (btn(⬇️,p.n)) p.dy+=spd
	 p.dx *= p.fric
	 p.dy *= p.fric
	 
	 collide(p)
	 
	 p.x += p.dx
	 p.y += p.dy
	end
end

function draw_player()
	for p in all(players) do
		spr(3,p.x,p.y)
	end
end

-->8
--bullet
function init_bullet()
	bullet = {}
	timeur_bullet = 0
end

function spawn_bullet(x,y,type_bullet,speed)
if timeur_bullet == 0 then
 xy = get_traj(x,y,mouse_x,mouse_y)
 traj_x = xy.x*speed
 traj_y = xy.y*speed
 
 if (type_bullet==1) timeur_bullet = 10 sprite = 1
	if (type_bullet==2) timeur_bullet = 5  sprite = 6
	
	add(bullet,{x=x,y=y,type_bullet=type_bullet,speed=speed,traj_x=traj_x,traj_y=traj_y,sprite=sprite})
	
end
end

function update_bullet()
 if (timeur_bullet>0) timeur_bullet -= 1

	for i in all(bullet) do
		if is_solid(i.x+(i.traj_x*1.5)+4,i.y+4+(i.traj_y*1.5)) then
		 del(bullet,i)
		 
	 end
		i.x += i.traj_x
		i.y += i.traj_y
	end
end

function draw_bullet()
	for i in all(bullet) do
		spr(i.sprite,i.x,i.y)
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
	angle=atan2(x_end-x_satr-4, y_end-y_start-4)
	return {x = cos(angle),y = sin(angle)}
end

function draw_mouse()
	spr(2,mouse_x,mouse_y)
end

function check_flag(flag,x,y)
	return fget(mget((x\8),(y\8)),flag)
end

-->8
--collision
function is_solid(x,y)
	return check_flag(0,x,y)
end

function collision(x,y,h,w,flag)
	return 
	   is_solid(x,  y)
	or is_solid(x+7,y)
	or is_solid(x,  y+7)
	or is_solid(x+7,y+7) 
end

function collide(o)
	local x,y = o.x,o.y
	local dx,dy = o.dx,o.dy
	local w,h = o.bw,o.bh
	local ox,oy = x+o.bx,y+o.by
	local bounce = 0.1
	
	--collisions
	local coll_x = collision( 
	ox+dx, oy,    w, h)
	local coll_y = collision(
	ox,    oy+dy, w, h)
	local coll_xy = collision(
	ox+dx, oy+dy, w, h)
	
	if coll_x then
		o.dx *= -bounce
	end
	
	if coll_y then
		o.dy *= -bounce
	end
	
	if coll_xy and 
	not coll_x and not coll_y then
		--prevent stuck in corners 
		o.dx *= -bounce
		o.dy *= -bounce
	end
end
__gfx__
000000000000000077700000cc0000cc616611655500005500000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000071100000c000000c165116555000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000990007000000000000000151111550000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
00077000009aa9001000000000000000111661110000000000877800000000000000000000000000000000000000000000000000000000000000000000000000
00077000009aa9000000000000000000611655110000000000877800000000000000000000000000000000000000000000000000000000000000000000000000
00700700000990000000000000000000561151160000000000088000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000c000000c556111655000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000cc0000cc555166555500005500000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000806600688066006880660068806600688066006880660068806600680000000000000000
00000000000000000000000000000000000000000000000000000000065006550650065506500655065006550650065506500655065006550000000000000000
00000000000000000000000000000000000000000000000000000000050000550500005505000055050000550500005505000055050000550000000000000000
00000000000000000000000000000000000000000000000000000000000660000006600000066000000660000006600000066000000660000000000000000000
00000000000000000000000000000000000000000000000000000000600655006006550060065500600655006006550060065500600655000000000000000000
00000000000000000000000000000000000000000000000000000000560050065600500656005006560050065600500656005006560050060000000000000000
00000000000000000000000000000000000000000000000000000000556000655560006555600065556000655560006555600065556000650000000000000000
00000000000000000000000000000000000000000000000000000000855066588550665885506658855066588550665885506658855066580000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000806600680000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065006550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600655000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560050060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556000650000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000855066580000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000806600680000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065006550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600655000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560050060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556000650000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000855066580000000000000000
00000000806600688066006800000000000000000000000000000000000000000000000000000000000000000000000000000000806600680000000000000000
00000000065006550650065500000000000000000000000000000000000000000000000000000000000000000000000000000000065006550000000000000000
00000000050000550500005500000000000000000000000000000000000000000000000000000000000000000000000000000000050000550000000000000000
00000000000660000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000
00000000600655006006550000000000000000000000000000000000000000000000000000000000000000000000000000000000600655000000000000000000
00000000560050065600500600000000000000000000000000000000000000000000000000000000000000000000000000000000560050060000000000000000
00000000556000655560006500000000000000000000000000000000000000000000000000000000000000000000000000000000556000650000000000000000
00000000855066588550665800000000000000000000000000000000000000000000000000000000000000000000000000000000855066580000000000000000
00000000806600680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000806600680000000000000000
00000000065006550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065006550000000000000000
00000000050000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000550000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000660000000000000000000
00000000600655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600655000000000000000000
00000000560050060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000560050060000000000000000
00000000556000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556000650000000000000000
00000000855066580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000855066580000000000000000
00000000806600680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000806600680000000000000000
00000000065006550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065006550000000000000000
00000000050000550000000000000000000000000000000000000000000000000077700000000000000000000000000000000000050000550000000000000000
00000000000660000000000000000000000000000000000000000000000000000071100000000000000000000000000000000000000660000000000000000000
00000000600655000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000600655000000000000000000
00000000560050060000000000000000000000000000000000000000000000000010000000000000000000000000000000000000560050060000000000000000
00000000556000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556000650000000000000000
00000000855066580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000855066580000000000000000
0000000080660068000000000000000000000000000000000000000000000000cc0000cc00000000000000000000000080660068806600680000000000000000
0000000006500655000000000000000000000000000000000000000000000000c000000c00000000000000000000000006500655065006550000000000000000
00000000050000550000000000000000000000000000000000000000000000000000000000000000000000000000000005000055050000550000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000066000000660000000000000000000
00000000600655000000000000000000000000000000000000000000000000000000000000000000000000000000000060065500600655000000000000000000
00000000560050060000000000000000000000000000000000000000000000000000000000000000000000000000000056005006560050060000000000000000
0000000055600065000000000000000000000000000000000000000000000000c000000c00000000000000000000000055600065556000650000000000000000
0000000085506658000000000000000000000000000000000000000000000000cc0000cc00000000000000000000000085506658855066580000000000000000
00000000806600680000000000000000000000000000000000000000000000000000000000000000806600688066006880660068000000000000000000000000
00000000065006550000000000000000000000000000000000000000000000000000000000000000065006550650065506500655000000000000000000000000
00000000050000550000000000000000000000000000000000000000000000000000000000000000050000550500005505000055000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000660000006600000066000000000000000000000000000
00000000600655000000000000000000000000000000000000000000000000000000000000000000600655006006550060065500000000000000000000000000
00000000560050060000000000000000000000000000000000000000000000000000000000000000560050065600500656005006000000000000000000000000
00000000556000650000000000000000000000000000000000000000000000000000000000000000556000655560006555600065000000000000000000000000
00000000855066580000000000000000000000000000000000000000000000000000000000000000855066588550665885506658000000000000000000000000
00000000806600680000000000000000000000000000000000000000806600688066006880660068806600680000000000000000000000000000000000000000
00000000065006550000000000000000000000000000000000000000065006550650065506500655065006550000000000000000000000000000000000000000
00000000050000550000000000000000000000000000000000000000050000550500005505000055050000550000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000660000006600000066000000660000000000000000000000000000000000000000000
00000000600655000000000000000000000000000000000000000000600655006006550060065500600655000000000000000000000000000000000000000000
00000000560050060000000000000000000000000000000000000000560050065600500656005006560050060000000000000000000000000000000000000000
00000000556000650000000000000000000000000000000000000000556000655560006555600065556000650000000000000000000000000000000000000000
00000000855066580000000000000000000000000000000000000000855066588550665885506658855066580000000000000000000000000000000000000000
00000000806600680000000000000000000000000000000000000000806600680000000000000000000000000000000000000000000000000000000000000000
00000000065006550000000000000000000000000000000000000000065006550000000000000000000000000000000000000000000000000000000000000000
00000000050000550000000000000000000000000000000000000000050000550000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000
00000000600655000000000000000000000000000000000000000000600655000000000000000000000000000000000000000000000000000000000000000000
00000000560050060000000000000000000000000000000000000000560050060000000000000000000000000000000000000000000000000000000000000000
00000000556000650000000000000000000000000000000000000000556000650000000000000000000000000000000000000000000000000000000000000000
00000000855066580000000000000000000000000000000000000000855066580000000000000000000000000000000000000000000000000000000000000000
00000000806600680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065006550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000560050060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000556000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000855066580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000806600680000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065006550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000600655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000560050060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000556000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000855066580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000004040404040404000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000004000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000004000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004040000000000000000000004000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000000000004000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000000000004000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000000000404000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000004040400000000000000040000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000004040404000000000000000000040000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000004000000000000000000000000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000000000000000000000000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000000000000000000000000000000000000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000040404040404040404040000040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000040404040000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000004040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040404040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
