pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- -- birds with guns --
--by gouspourd,yolwoocle,notgoyome

function _init()
	--mouse
	mx=0
	my=0
	
	--flags
	solid=0
	breakable=1
	spawnable=2
	lootable=3
	notbulletsolid=4
	
	--camera
	camx=0
	camy=0
	targetcamx=0
	cam_follow_player=true
	shake = 0
	
	trainpal = {{8,2},{11,3},
	{7,13},{12,13},{10,9},{0,2}}
	pal_n = 1
	
	menu = "main"
	
	debug=""
	cde = 5
	
	actors = {}
	init_enemies()
	
	init_ptc()
	
	wagonlen = 4
	gen_train()
	update_room()
	random = {}
	
	enemies = {}
	parcourmap()
	
	drops={}
	
	init_menus()
	
	bird_choice=0
	
	bullets_shooted=0
	bullets_hit=0
	stats={
	 kills=0,
	 accuracy=0,
	 time=0,
	 wagon=0,
	}
	
	--darker blue
	--pal(1,130,1)
	--pal(1,129,1)
	reset_pal()
	poke(0x5f2e,1)
end

function _update60()
	mouse_x_y()
	
	if menu == "game" then
		grasstile()
		delchecker()
		
		update_drops()
		
		player_update()
		for i in all(players) do
		end
		
		for a in all(actors) do
			a:update()
			if(a.destroy_flag)del(actors,a)
		end
		--for e in all(enemies) do
			update_enemy(e)
			--if(e.destroy_flag)del(enemy,e)
		--end
		
		for p in all(particles) do
			update_ptc(p)
			if(p.destroy)del(particles,p)
		end
		
		update_door()
		
		cde = max(cde-1,0)
		
		stats.accuracy = bullets_hit/bullets_shooted
		
		--shake = 0
		
		update_camera()
	elseif menus[menu] != nil then
		local m = menus[menu]
		m.update(m)
	else
		
	end
	
	shake -= 0.3
	shake = max(0,shake)
end


function _draw()
	local ox = rnd(2*shake)-shake
	local oy = rnd(2*shake)-shake
	camera(camx+ox, camy+oy)
	
	cls(15)
	
	--draw map
	drawgrass()
	draw_map()
	draw_weel()
	
	draw_drops()
	
	
	for e in all(enemies) do
		draw_enemy(e)
	end
	draw_player()
	
	for a in all(actors) do
		a:draw()
	end
	
	for p in all(particles) do
		draw_ptc(p)
	end
	
	drawcheck()
	for i in all(players) do
		draw_player_ui(players[1])
	end
	
	if menus[menu] != nil then
		local m = menus[menu]
		m.draw(m)
	end
	
	-->>no code below this<<--
	draw_mouse()
	pal(1,129,1)
end

----------
function begin_game()
	if birdchoice == 0 then
		birdchoice=flr(rnd(12))+1
	end
	init_player(111+birdchoice)
	
	stats.time = time()
	
	for p in all(players) do
		p.x = 6*8
		p.y = 7*8
	end
	
	shake += 7
	for i=1,10 do
		make_ptc(
		 6*8 + rnd(16)-8,
		 7*8 + rnd(16)-8,
		 8+rnd(8),rnd({2,4,6}),0.97,
		 rnd(4)-2,rnd(4)-2
		)
	end
end

function isleft(a)
	return a<.75 and .25<a
end

function reset_pal()
	pal()
end

function ospr(s,x,y,col)
	for i=0,15do
		pal(i,col)
	end
	
	for i=-1,1do
		for j=-1,1do
			spr(s,x+i,y+j)
		end
	end
	
	reset_pal()
	spr(s,x,y)
end

function oprint(t,x,y,col,ocol)
	local ocol = ocol or 1
	for i=-1,1do
		for j=-1,1do
			print(t,x+i,y+j,ocol)
		end
	end
	
	local col = col or 7
	print(t,x,y,col)
end

function copy(t)
	local n={}
	for k,v in pairs(t) do
		n[k] = v
	end
	return n
end

function update_camera()
	local px = players[1].x
	local wl = wagonlen
	local maxlen = 240
	
	if px > 128*(wl-1) then
		--pan cam to connector room
		cam_follow_player=false
		targetcamx=128*(wl-1)
	end
	
	if cam_follow_player then 
		--camera follows player
		camx = px-60
		--offset camera to cursor
		camx += (stat(32)-64)/3
		camx = min(max(0,camx),128*(wl-2)+8)
		camx = flr(camx)
		camy = 0
	else
		--do a cool animation
		camx+=(targetcamx-camx)/10
		camx=ceil(camx)
		
		if targetcamx <= 0
		and ceil(camx)==targetcamx then
			cam_follow_player=true
		end
	end
end

function draw_ghost_connector()
	if camx<0 then
		map(3*16,0, -128,0, 16,16)
	end
end

-->8
--player
function init_player(bird)
	b=0
	players={} 
	local p = {
		n=1,
		
		x=-64,y=-64,
		dx=0,dy=0,
		a=0,
		
		spd=.4,
		fric=0.75,
		
		bx=2,by=2,
		bw=4,bh=4,
		
		hx=2,hy=2,
		hw=4,
		
		life=10,
		maxlife=10,
		ammo=250,
		maxammo=250,
		
		spr=bird,
		
		gun=nil,
		gunn=1,
		gunls={copy(guns.debuggun),copy(guns.shotgun)},
	
		lmbp = true,
		tbnd=30,
		
		damage=damage_player,
	}
	p.gun = p.gunls[p.gunn]
	add(players,p)
end

function player_update()
	for p in all(players) do
	 --damage
	 p.tbnd = max(0,p.tbnd-1)
		--movement
		local dx,dy = p.dx,p.dy
		local spd = p.spd
		
		if (btn(⬅️,p.n)) p.dx-=spd
		if (btn(➡️,p.n)) p.dx+=spd
		if (btn(⬆️,p.n)) p.dy-=spd
		if (btn(⬇️,p.n)) p.dy+=spd
		
		p.dx *= p.fric
		p.dy *= p.fric
		
		collide(p,0.1)
		
		p.x += p.dx
		p.y += p.dy
		
		--angle
		p.a = atan2(mouse_x-p.x,
		mouse_y-p.y)
		
		p.flip = false
		if(isleft(p.a))p.flip=true
		
		--ammo & life
		p.life=min(max(0,p.life),p.maxlife)
		p.gun.ammo=min(max(0,p.gun.ammo),p.gun.maxammo)
		
		--death
		if p.life <= 0 
		and menu!="death"then
			menu = "death"
			shake += 9
			burst_ptc(p.x+4,p.y+4,7)
			
			stats.time=time()-stats.time 
			stats.wagon=wagon_n
		end
		
		--shooting
		if stat(36) ==1 or stat(36) ==-1 then
		sfx(0)
			nextgun(p)
			print(p.gun.cooldown,0,0)
			p.gun.timer = p.gun.cooldown/2
		end
		
		local fire=stat(34)&1 > 0
		local active=stat(34)&2 > 0
		
		
		
		p.gun:update()
		test = p.gun.name
		-- not auto
		if fire and
		p.gun.timer<=0 and
		p.gun.ammo > 0 and p.gun.auto == false
		then
			if p.lmbp == true then
				make_ptc(p.x+cos(p.a)*6+4, 
				p.y+sin(p.a)*3+4, rnd(3)+6,7,.7)
				p.gun.ammo -= 1
				p.gun:fire(p.x+4,p.y+4,p.a)
				p.lmbp = false
			end
			
		-- auto
		elseif fire and p.gun.timer<=0 
		and p.ammo > 0 then
			make_ptc(p.x+cos(p.a)*6+4, 
			p.y+sin(p.a)*3+4, rnd(3)+6,7,.7)
			p.ammo -= 1
			p.gun:fire(p.x+4,p.y+4,p.a)
		end
		
		-- if mleft not pressed 
		if stat(34)&1 == 0 then
			p.lmbp = true
		end
		
		--next wagon
		if p.x>128*wagonlen then
			random = {}
			
			wagon_n += 1
			update_room()
			enemiescleared=false
			pal_n += 1
			
			--pan cam to next wagon
			camx = -128
			targetcamx=0
			drops = {}
			enemies = {}
			parcourmap()
			--teleport players
			for p in all(players)do
				p.x -= 128*wagonlen
				p.x = max(p.x, 0)
			end
		end
		for e in all(enemies)do
			
			if touches_rect(
			p.x+4,p.y+4,
			e.x+1,e.y+1,e.x+7,e.y+7) then
				
				if(shake<=2)shake += 2
				if (p.tbnd == 0) then
					p.life-=e.gun.dmg 
					p.tbnd = 30 
				end
				knockback_player(p,e)
			
			end
		end
	end
end

function draw_player()
	for p in all(players) do
	if (p.tbnd%5) == 0  then
		local x=flr(p.x) + cos(p.a)*6 +0
		local y=flr(p.y) + sin(p.a)*3 +0
		
		if p.gun.name=="sniper" then
			local c,s=cos(p.a),sin(p.a)
			line(
			x+4+c*6,
			y+4+s*6,
			p.x+c*128,
			p.y+s*128,8)
		end
		spr(p.gun.spr,x,y,1,1, p.flip)
		
		palt(0,false)
		palt(1,true)
		spr(p.spr,p.x,p.y,1,1, p.flip)
		
		palt()
	end
	end
end

function draw_player_ui(p)
	--life counter
	rectfill(camx+1,1,camx+43,7,2)
	local l=40*(p.life/p.maxlife)
	rectfill(camx+2,2,camx+2+l,6,8)
	
	local s="♥"..p.life.."/"..p.maxlife.." "
	print(s, camx+2,2,7)
	
	--ammo bar
	rectfill(camx+84,1,camx+84+42,7,4)
	local l=40*(p.gun.ammo/p.gun.maxammo)
	if(p.ammo>0)rectfill(camx+85,2,camx+85+l,6,9)
	
	s = tostr(p.gun.ammo)
	spr(110,camx+89,2)
	print(s, camx+95,2,7)
	
	--weapon list
	for i=1,#p.gunls do
		local col = 1
		if(i==p.gunn)col=7
		
		ospr(p.gunls[i].spr, 
		camx+90+(i-1)*10, 10,col)
	end
	
	--wagon
	oprint("wagon "..wagon_n+1,
	camx+50,2,7,1)
	--print(test,0,80)
end

function nextgun(p)
	p.gunn += 1
	if(p.gunn > #p.gunls) p.gunn = 1
	update_gun(p)
	--[[local f = 0
	for i=1,#p.gunls do
	if p.gunls[i] == p.gunn then
		if (((i+stat(36))%#p.gunls)<1) f = #p.gunls
		 return p.gunls[(i+stat(36))%(#p.gunls)+f]
		end
	end]]
end

function update_gun(p)
	p.gun = p.gunls[p.gunn]
end

function knockback_player(p,e)
	if abs(p.dx)+abs(p.dy) < 3 then
			  p.dx+=e.dx*e.spd*2
				 p.dy+=e.dy*e.spd*2
			end	
end

function knockback_enemy(e,b)
	
		if (abs(e.dx)+abs(e.dy<30)) then
			e.dx+=b.dx*b.spd*.1
			e.dy+=b.dy*b.spd*.1
		end

end

-->8
--gun & bullet

function make_gun(name,spr,cd,
spd,oa,dmg,is_enemy,auto,fire)
	--todo:not have 3000 args
	local gun = {
		name=name,
		spr=spr,
		spd=spd,
		oa=oa,--offset angle in [0,1[
		dmg=dmg,
		shake=shake,
		auto=auto,
		
		ammo=250,
		maxammo=250,
		
		timer=0,
		cooldown=cd,
		is_enemy=is_enemy,
		
		x=0,y=0,
		dir=0,
		burst=0,
	}
	
	gun.fire = fire
	
	gun.shoot=function(gun,x,y,dir,spd)
		--remove? it complicates code
		local s=93
		if(gun.is_enemy)s=95
		if not gun.is_enemy and gun.name!="debuggun" then
			if(shake<3)shake+=1 
		end
		
		spd = spd or gun.spd
		spawn_bullet(x,y,dir,
		spd,3,s,dmg,is_enemy)
		gun.timer = gun.cooldown
	end
	
	gun.update=function(gun)
		gun.timer = max(gun.timer-1,0)
		gun.ammo = min(max(0,gun.ammo),
		           gun.maxammo)
		
		if gun.burst > 0 then
			gun:shoot(gun.x,gun.y,gun.dir)
			gun.burst -= 1
		end
	end
	
	return gun
end

guns = {
	debuggun = make_gun("debuggun",
--spr cd spd oa dmg is_enemy auto
		64, 1, 3, .02,10, true,  true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),

	revolver = make_gun("revolver",
--spr cd spd oa dmg is_enemy auto
		64, 15,3, .02,3   ,false,  false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	shotgun = make_gun("shotgun",
--spr cd spd oa dmg is_enemy auto
	 65, 60,4, .05,1,  false,   false,
	 function(gun,x,y,dir)
	 	for i=1,8 do
	 		local o=rnd(.1)-.05
	 		local ospd=gun.spd*(rnd(.2)+.9)
	 		gun:shoot(x,y,dir+o, ospd)
	 	end
	 end),
	 
	machinegun = make_gun("machinegun",
--spr cd spd oa dmg is_enemy auto
		66, 7, 3, .05,2   ,false,  true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	assaultrifle = make_gun("assault rifle",
--spr cd spd oa dmg is_enemy auto
		67, 30,4, .02,1   ,false,  true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun.burst = 4
			gun.x, gun.y = x, y
			gun.dir = dir
			gun:shoot(x,y,dir)
		end
	),
	
	sniper = make_gun("sniper",
--spr cd spd oa dmg is_enemy auto
		68, 40,7, .0, 5  ,false,   false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	gunslime = make_gun("gunslime",
--spr cd spd oa  dmg is_enemy auto
		64, 100,1.5,.02,3,  true,  true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	,true),
	
	snipeurpisto = make_gun("gunslime",
--spr cd spd oa  dmg is_enemy auto
		64, 100,2.5, 0, 5, true,    true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	,true),
	
	shotgunmechant = make_gun("shotgunmechant",
--spr cd spd oa dmg is_enemy  auto
	 65, 60,1.35, .04,1,  true,  true,
	 function(gun,x,y,dir)
	 	for i=1,4 do
	 		local o=rnd(.1)-.05
	 		local ospd=gun.spd*(rnd(.2)+.9)
	 		gun:shoot(x,y,dir+o, ospd)
	 	end
	 end),
	 
	 null = make_gun("null",
--spr cd spd oa dmg is_enemy  auto
	 1, 0,57, 0,1,  true,  true,
	 function(gun,x,y,dir) 	
	 		local o=rnd(.1)-.05
	 		local ospd=gun.spd*(rnd(.2)+.9)
	 		gun:shoot(x,y,dir+o, ospd)
	 end),
}

--table of number-indexed guns
local iguns={}
for k,v in pairs(guns)do
	if(not v.is_enemy)add(iguns,v)
end

function rnd_gun()
	--todo: "power" param
	--later weapons should be  
	--more powerful
	return iguns[flr(rnd(#iguns))+1]
end

function spawn_bullet(x,y,dir,spd,r,spr,dmg,is_enemy)
	local dx=cos(dir)*spd
	local dy=sin(dir)*spd
	add(actors,{
		x=x,  y=y,
		dx=dx,dy=dy,
		r=4,
		dmg=dmg,
		spd=spd,
		spr=spr,
		is_enemy=is_enemy,
		destroy_flag=false,
		
		update=update_bullet,
		draw=draw_bullet,
	})
end

function update_bullet(b)
	b.x += b.dx
	b.y += b.dy
	
	debug=""
	if b.is_enemy then
		
		for p in all(players)do
			local x,y= b.x,b.y
			local x2 = p.x+p.hx+p.hw
			local y2 = p.y+p.hx+p.hw 
			if touches_rect(x,y,
			p.x+p.hx, p.y+p.hy,
			x2,y2) then
				
				if (p.tbnd == 0)p.life-=b.dmg p.tbnd = 30
				if(shake<=4)shake += 4
				knockback_player(p,b)
				make_ptc(b.x,b.y,rnd(4)+6,7,.8)
				b.destroy_flag = true
				
			end
		end
		
	else
		
		for e in all(enemies)do
			local x,y= b.x,b.y
			local x2 = e.x+e.hx+e.hw
			local y2 = e.y+e.hx+e.hw 
			if touches_rect(x,y,
			e.x+e.hx,e.y+e.hy,
			x2,y2) then
				
				e.life -= b.dmg
				if(e.life<=0) stats.kills+=1
				bullets_hit+=1
				
				knockback_enemy(e,b)
				
				spawn_loot(e.x,e.y)
				e.timer = 5
				make_ptc(b.x,b.y,rnd(4)+6,7,.8)
				b.destroy_flag = true
				return
			end
		end
	end
	
	--destroy on collision
	if (is_solid(b.x,b.y)
	and not check_flag(
	    notbulletsolid,b.x,b.y)) 
	or b.x+11<camx 
	or b.x>camx+128+11 
	or b.y<-8 or b.y>132
	then
		if check_flag(breakable,b.x,b.y) then
			if check_flag(lootable,b.x,b.y)then
				break_crate(b.x,b.y)
			end
			mset(b.x\8,b.y\8,39)
			add(random,{
			 x=(b.x\8)*8+4,
			 y=(b.y\8)*8+4,
			 spr=rnd({55,22,39}),
			 f=rnd({true,false}),
			 r=rnd({true,false})
			})
		end
		make_ptc(b.x,b.y,rnd(4)+6,7,.8)
			
		b.destroy_flag = true
	end
end

function draw_bullet(b)
	spr(b.spr, b.x-4, b.y-4)
end

function draw_random()
for i in all(random)do
	 spr(i.spr, i.x-4, i.y-4,1,1,i.f,i.r)
	end
end

--------

--[[
function spawn_bullet(x,y,type_bullet,speed,timer_bullet1,sprite,nb_bullet,ecartement)
	if timer_bullet == 0 then
		local xy = get_traj(x,y,mouse_x,mouse_y)
		local traj_x = xy.x*speed
		local traj_y = xy.y*speed
		local angle = xy.angle
		timer_bullet = timer_bullet1
		
		if type_bullet == 1 then
			nvelement = {
			  x=x,y=y,
			  type_bullet=type_bullet,
			  traj_x=traj_x,
			  traj_y=traj_y,
			  sprite=sprite
			}
			rafale(10,nvelement)
		end
	 
	 if type_bullet == 2 then
	  for i=0,nb_bullet do
	   if nb_bullet == 0 then
	    add(bullet,{
	      x=x,y=y,
	      type_bullet=type_bullet,
	      traj_x=traj_x,
	      traj_y=traj_y,
	      sprite=sprite
	    })
				else 
					add(bullet,{
					  x=x,y=y,
					  type_bullet=type_bullet,
					  traj_x=cos((angle-((1/ecartement)/2)+(i/nb_bullet)/ecartement))*speed,
					  traj_y=sin((angle-((1/ecartement)/2)+(i/nb_bullet)/ecartement))*speed,
					  sprite=sprite
					})
	   end
	  end
	 end
 end
end

-- -(i/2)+i/nb_bullet
function update_bullet()
 if (timer_bullet>0)timer_bullet-=1
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

function rafale(nb,bullet)
 add(rafalels,{nb=nb,bullet=bullet})
end

function updaterafale()	
	for i in all(rafalels) do
  if (i.nb<1) del(rafalels,i)
  add(bullet,i.bullet)
  i.nb -=1
	end
end
--]]
-->8
--mouse
function mouse_x_y()
	poke(0x5f2d, 1)
	mx=stat(32)+flr(camx)
	my=stat(33)
	mouse_x=mx
	mouse_y=my
	lmb=stat(34)&1 > 0
	rmb=stat(34)&2 > 0
	mmb=stat(34)&4 > 0
end

function get_traj(x_satr,y_start,x_end,y_end)
	angle=atan2(x_end-x_satr-4, y_end-y_start-4)
	return {x=cos(angle),y=sin(angle),angle=angle}
end

function draw_mouse()
	spr(127,mouse_x-1,mouse_y-1)
end

function check_flag(flag,x,y)
	return fget(mget((x\8),(y\8)),flag)
end

-->8
--collision
function is_solid(x,y)
	if(x<0)return true 
	return check_flag(0,x,y)
end

function touches_rect(x,y,x1,y1,x2,y2)
	return x1 <= x
	   and x2 >= x
	   and y1 <= y
	   and y2 >= y
end

function circ_coll(a,b)
	--https://www.lexaloffle.com/bbs/?tid=28999
	--b: bullet
	local dx=a.x+4 - b.x
	local dy=a.y+4 - b.y
	local d = max(dx,dy)
	dx /= d
	dy /= d
	local sr = (a.r+b.r)/d
	
	return dx*dx+dy*dy < sr*sr 
end

function rect_overlap(a1,a2,b1,b2)
	return not (a1.x>b2.x
	         or a1.y>b2.y 
	         or a2.x<b1.x
	         or a2.y<b1.y)
end

function collision(x,y,w,h,flag)
	return 
	   is_solid(x,  y)
	or is_solid(x+w,y)
	or is_solid(x,  y+h)
	or is_solid(x+w,y+h) 
end

function collide(o,bounce1)
	local x,y = o.x,o.y
	local dx,dy = o.dx,o.dy
	local w,h = o.bw,o.bh
	local ox,oy = x+o.bx,y+o.by
	local bounce = bounce1
	
	--collisions
	local e = 1
	local coll_x = collision( 
	ox+dx, oy,    w-e, h-e)
	local coll_y = collision(
	ox,    oy+dy, w-e, h-e)
	local coll_xy = collision(
	ox+dx, oy+dy, w-e, h-e)
	
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
-->8
--map 
test = 0
wagon_n = 0

function gen_train()
	--gen talbe of all wagon nums
	nums = {[0]=10}
	for i=11,30 do
		add(nums,i)
	end
	
	--gen train
	train = {}
	
	for i=0,5 do
		local w = i*wagonlen
		for j=0,wagonlen-2 do
			
			local n = 10+flr(rnd(21))
			if(#nums>0)n=nums[flr(rnd(#nums+1))]--#nums
			train[w+j]=n
			del(nums,n)
			
		end
		train[w+wagonlen-1] = 8
	end
	
	--train[2]=31
	train[0]=9
end

function clone_room(a,b)
	local ax = (a%8)*16
	local ay = (a\8)*16
	room_all= {}
	for j = 0,15 do
		for i = 0,15 do
			local t=mget(ax+i,ay+j)
			mset(b*16+i,j,t)
		end
	end
end

function update_door()
	local wl = wagonlen
	--unlock next wagon
	if #enemies <= 0 and 
	not enemiescleared then
		local x=(wl-1)*16
		local g=rnd_gun()
		make_drop(x*8+60,56,g.spr,"gun",
		copy(g))
		enemiescleared=true
		for i=1,5 do
			make_ptc(
			  x*8 + rnd(16)-8,
			  7*8 + rnd(16)-8,
			8+rnd(8),rnd({9,10}))
		end
		
		mset(x,6,40)
		mset(x,7,39)
		
		shake += 5
		
	end 
end

function update_room()
	for i=0,3 do
		local w=wagon_n*wagonlen + i
		clone_room(train[w],i)
	end
end

function draw_map()
	-- wall palette
	if(pal_n>#trainpal) pal_n=1
	pal(8,trainpal[pal_n][1])
	pal(14,trainpal[pal_n][2])
	
	draw_ghost_connector()
	map()
	draw_random()
	
	palt()
	reset_pal()
end

function break_crate(x,y)
	spawn_loot(x\8*8,y\8*8)
end



function swichtile(x,y)
 local t = mget((x\8),(y\8))
 mset((x\8),(y\8),t+1)
end

function parcourmap()
 local x1=0
 if(wagon_n==0)x1=16
 for x=x1,16*(wagonlen-1) do
  for y=2,12 do
  if x>3 or players[1].y-20>y*8 or players[1].y+20<y*8 then
   if fget(mget(x,y),2) and ceil(rnd(max(3,30-(wagon_n*2))))==1 then
    if ceil(rnd(max(3,25-(wagon_n*2))))==1 then
     spenemie(x * 8,y * 8,enemy.juggernaut)
    elseif ceil(rnd(max(3,13-(wagon_n*2))))==1 then
     for i=0,ceil(rnd(wagon_n*1.2))+10 do
     spenemie(x * 8,y * 8,enemy.warm)
     end
    else spenemie(x * 8,y * 8,enemy.hedgehog)
    end
   end
   
  end
  end
 end
end


-->8
--enemies
function make_enemy(x,y,spr,spd,life,agro,chase,seerange,gunt)
	return {
		x=x, y=y,
		angle=0,
		dx=0,dy=0,
		spd=spd,
		agro=agro,
		
		bx=1,by=1,
		bw=6,bh=6,
		
		hx=0,hy=0,
		hw=8,
		
		chase=chase,
		seerange=seerange,
		spr=spr,
		life=life,
		
		gun=gunt,
		cd=30,
		timer = 0,
		a=0,
	}
end

function init_enemies()
	enemies = {}
	checker = {}
	enemy= {
	
	hedgehog=make_enemy(
--x,y,sprite,speed,life,shootrange,  
	 x,y,108   ,1    ,5   ,7   ,
--chase,seerange
	 false,1,
	 guns.gunslime),
	 
	snipeur=make_enemy(
--x,y,sprite,speed,life,shootrange,  
	 x,y,96   ,0.5  ,15  ,8    ,  
--chase,seerange
	 false,1, 
	 guns.snipeurpisto),
	 
	 
  juggernaut=make_enemy(
--x,y,sprite,speed,life,shootrange,  
	 x,y,98    ,1.5  ,30  ,3   ,  
--chase,seerange
  true,8, 
	 guns.shotgunmechant),
	 
	 warm=make_enemy(
--x,y,sprite,speed,life,shootrange,  
	 x,y,126    ,1  ,1  ,0   ,  
--chase,seerange
  true,7, 
	 guns.null),
}

end

function spenemie(x,y,name)
 local a=copy(name)
 a.x = x
 a.y = y
 a.gun = copy(a.gun)
 a.gun.cooldown += rnd(60)
 if (a.spr == 126) a.spd = 0.9+rnd(0.3)
 if a.x<175 then
  a.gun.timer += 60
  a.timer = 60
 end
 
	add(enemies,a)
end

function update_enemy(e)
	for i in all(enemies) do
		if i.life <= 0 then  
			burst_ptc(i.x+4,i.y+4,8) 
			del(enemies,i)
		end
		if loaded(i) then
			mouvrnd = true
			
			i.gun.timer = max(i.gun.timer-1--/#enemies
			,0)
			
			if i.gun.timer<=0 and 
			canshoot(i) then
				i.gun:fire(i.x+4,i.y+4,i.a)
			end
			if mouvrnd then
				changedirection(i)
			end
			collide(i,0.1)
			
			i.flip=isleft(i.angle)
			
			i.x += i.dx
			i.y += i.dy
		end
	end
end

function draw_enemy(e)
	spr(e.spr, e.x,e.y,1,1,e.flip)
	local x=flr(e.x)+cos(e.angle)*6
	local y=flr(e.y)+sin(e.angle)*3
		
	spr(e.gun.spr,x,y,1,1, e.flip)
		
	--print(e.life, e.x,e.y-8,7)
	--circ(e.x+4,e.y+4,e.r,12)
	--print(e.gun.timer,e.x,e.y)
	--print(abs(e.dy)+abs(e.dx),e.x,e.y+6)
end

function changedirection(i)
	i.timer-=1
	if i.timer < 1 then
	 i.angle += rnd(0.5)-0.25
	 i.timer=i.cd
	 i.dx=cos(i.angle)/8*i.spd 
	 i.dy=sin(i.angle)/8*i.spd
	end
end

function canshoot(e)
	local angle = atan2(players[1].x-e.x,
	players[1].y-e.y)
	e.a=angle
	local x = cos(angle)
	local y = sin(angle) 
	local dist =sqrt(abs(players[1].y-e.y)^2+abs(players[1].x-e.x)^2)/8
	
	if abs(dist)<e.agro and abs(players[1].x-e.x)<128 then
 return cansee(e,angle,x,y,dist)
 elseif abs(dist)<e.seerange and abs(dist)>e.agro and e.chase and cansee(e,angle,x,y,dist) then
  o= e.dx+e.dy
   e.dx=x*(e.spd*2)/max(dist,4)
   e.dy=y*(e.spd*2)/max(dist,4)
   
    mouvrnd = false
   
  
 end	
end
 
function cansee(e,angle,x,y,dist)	 
 for i =1,dist do
	add(checker,{x=e.x+x*i*8,y=e.y+y*i*8})  
	 if is_solid(checker[#checker].x+4,checker[#checker].y+4) then
	 	delchecker()
	 	e.gun.timer = e.gun.cooldown/2
	 return false 
	 end
	end
	delchecker() 
	return true 
end


function drawcheck()
	for i in all(checker) do
	 spr(19,i.x,i.y)
	end
end

function delchecker()
	checker = {}
end

function loaded(i)
	return abs(camx+64-i.x)<71--71
end
-->8
--particles & bg
function init_ptc()
	particles={}
	grass = {}
	for i=0,20 do 
	add(grass,{x=(flr(rnd(16))*8),y=flr(rnd(16))*8,spr=56})
 end
 for i=0,5 do 
 add(grass,{x=(flr(rnd(16))*8),y=rnd({0,14*8}),spr=56})
 end
 for i=0,3 do
 for v=4,14 do
 add(grass,{x=4*8*i,y=v*8,spr=24})
 end
 end
 weelflip = true
 weelframe = 5
 weelcount = weelframe
end

function make_ptc(x,y,r,col,fric,dx,dy,txt)
	fric=fric or rnd(.1)+.85
	dx=dx or 0
	dy=dy or 0
	add(particles, {
		x=x,  y=y,
		dx=dx,dy=dy,
		fric=fric,
		
		txt=txt,
		
		r=r, col=col,
		destroy=false,
	})
end

function update_ptc(p)
	p.x += p.dx
	p.y += p.dy
	
	p.dx *= p.fric
	p.dy *= p.fric
	
	p.r *= p.fric
	
	if(p.r<=1)p.destroy=true
end

function draw_ptc(p)
	--kinda bodgey but whatever
	if p.txt==nil then
		circfill(p.x,p.y,p.r,p.col)
	else
		print(p.txt,p.x,p.y,p.col)
	end
end

function burst_ptc(x,y,col)
	for i=1,5 do
		make_ptc(
		   x+rnd(16)-8,
		   y+rnd(16)-8,
		   rnd(5)+5,col,
		   0.9+rnd(0.07))
	end 
end

function grasstile()
	for i in all(grass)do
	 i.x = i.x
		i.x-=2.5
		if (i.x<-8)i.x = 128
	end
end

function drawgrass()
	for elt in all(grass)do
		spr(elt.spr,camx+elt.x,elt.y)
	end
end

function draw_weel()
 weelcount -=1
 if (weelcount<1) weelflip = not weelflip weelcount=weelframe
 for n=0,5do
	for i=0,2do
		spr(42,8+n*64+i*16,14*8, 2,2,weelflip)--, flip_x ,flip_y)
	end
	end
end






----


-->8
--menus
function init_menus()
	menus = {}
	menus.main = make_main_menu()
	menus.death = make_death_menu()
end

function make_death_menu()
	local m = {
	  update=update_death_menu,
	  draw=draw_death_menu,
	  
	  circt=1,
	  timer=0,
	  showtext=false,
	}
	
	m.buttons = {}
	m.buttons[1]={
		t="retry",
		x=0,y=0,
		active=false
	}
	
	return m
end

function update_death_menu(m)
	m.circt=min(m.circt*1.05,600)
	if m.circt>=600 then
		m.showtext=true
		m.timer += 1
	end
	
	local b = m.buttons[1]
	local t=m.timer / 100
	b.x = camx+50+cos(t+.2)*3
	b.y = 1/t+ 80+sin(t+.2)*3
	
	b.active = false
	if touches_rect(mx,my,
	b.x-4,b.y-4,
	b.x+#b.t*4+3, b.y+9) then
		b.active = true
	end
end

function draw_death_menu(m)
	--circles animation
	palt(1,true)
	for p in all(players)do
		local x,y = p.x+4,p.y+4
		circfill(x,y,m.circt    ,9)
		circfill(x,y,m.circt*.75,2)
		circfill(x,y,m.circt*.5 ,1)
		circfill(x,y,m.circt*.25,0)
		spr(p.spr,p.x,p.y)
	end
	palt()
	
	--text & buttons
	local t=m.timer/100
	oxxl("game over",
	     camx+30+cos(t)*3,
	     1/t +30+sin(t)*3)
	for b in all(m.buttons) do
		if b.active then
			oprint(b.t,b.x,b.y,1,7)
		else
			oprint(b.t,b.x,b.y)
		end
	end
	
	--stats
	for k,v in pairs(stats)do
		oprint()
	end
end

------

function make_main_menu()
	--this code could be better
	local m = {
	  update=update_main_menu,
	  draw=draw_main_menu,
	  
	  sel=0,
	  done=false,
	  ui_oy=0,
	  ui_dy=0,
	}
	m.buttons={}
	
	local names=split("pigeon,duck,sparrow,parrot,toucan,flamingo,eagle,seagull,ostrich,penguin,jay,chicken")
	local x=4
	local y=105
	for i=0,11 do
		add(m.buttons,{
		  n=i+1,
		  spr=i+80,
		  bird=i+112,
		  
		  x=i*10+4,
		  y=105,
		  w=9,
		  h=17,
		  col=1,
		  sh=2,
		  
		  name=names[i+1],
		  active=false,
		})
	end
	m.buttons[0]={
		  n=0,
		  spr=124,
		  bird=39,
		  
		  x=114,
		  y=91,
		  w=9,
		  h=9,
		  
		  oy=0,
		  col=1,
		  sh=1,
		  
		  name="random",
		  active=false,
		}
		
	m.buttons[13]={
	  n=13,
	  spr=111,
	  bird=39,
	  
	  x=2,
	  y=2,
	  w=9,
	  h=9,
	  
	  oy=0,
	  col=1,
	  sh=1,
	  
	  name="random",
	  active=false,
	}
	
	return m
end

function update_main_menu(m)
	if not m.done then
		for k=0,#m.buttons do
			i=m.buttons[k]
			
			i.active = false
			i.col = 1
			i.oy = 0
			if touches_rect(mx,my,i.x,i.y,
			i.x+i.w-1, i.y+i.h-1) then
				i.active=true
				i.col = 7
				i.oy = 2
				m.sel = i.n
				
				if lmb and i.n<=12 then
					m.done = true
				end
			end
		end
	else
		m.ui_dy += .1
		m.ui_oy += m.ui_dy
		
		if m.ui_dy > 5 then
			birdchoice = m.sel
			menu = "game"
			begin_game()
			return
		end 
	end
end

function draw_main_menu(m)
	local oy = m.ui_oy
	
	palt(0,false)
	
	draw_logo(44,5-oy)
	
	--player selection
	rectfill(112,89+oy,125,110+oy,12)
	rectfill(2,103+oy,125,124+oy,1)
	for k=0,#m.buttons do
		i = m.buttons[k]
		
		oy = abs(oy)
		if(k == 13)oy = -oy
		
		rectfill(i.x, 
		i.y-i.oy + oy, 
		i.x+i.w, 
		i.y+i.h-i.oy + oy, 
		i.col)
		spr(i.spr, 
		i.x+1, 
		i.y+1-i.oy + oy,
		1,i.sh)
		
		if i.n==13and i.active then
			oprint("a game by:",2,13, 14)
			oprint("\nyOLWOOCLE"..
			"\ngOUSPOURD\nnOTGOYOME"..
			"\nsIMON.t",2,13)
			oprint("\ncode,art"..
			"\ncode,level design"..
			"\ncode"..
			"\nmusic",45,13, 13)
		end
	end
	oy=abs(oy)
	
	local sel=m.buttons[m.sel]
	rectfill(
	2,93+oy,
	2+#sel.name*8, 102+oy,1)
	wide(sel.name,4,95+oy,7)
	palt()
	
	palt(1,true)
	spr(sel.bird,6*8,7*8)
	spr(32,6*8,7*8)
	
	palt()
end

function draw_logo(x,y)
	--"birds"
	oxxl("birds",x,y,10)
	
	oxxl("guns",x,y+15, 6)
	
	--"with"
	oprint("with",x+11,y+10)
	
	oprint("with",x+11,y+9)
end

function oxxl(t,x,y,col)
	--credit to freds72
	for ix=-2,2 do
		for iy=-2,4 do
			if abs(ix)==2 
			or abs(iy)>=2 then
				print("\^p"..t,x+ix,y+iy,1)
			end
		end
	end
	
	col=col or 7 
	for ix=-1,1 do
		for iy=-1,1 do
			print("\^p"..t,
			x+ix,y+iy,col)
		end
	end
end

function wide(t,x,y,col,pre)
	--credit to yolwoocle
	t1= "                ! #$%&'()  ,-./[12345[7[9:;<=>?([[c[efc[ij[l[[([([st[[[&yz[\\]'_`[[c[efc[ij[l[[([([st[[[&yz{|}~"
	t2="                !\"=$  '()*+,-./0123]5678]:;<=>?@abcdefghijklmnopqrstuvwx]z[\\]^_`abcdefghijklmnopqrstuvwx]z{|} "
	n1,n2="",""
	pre=pre or ""
	
	for i=1,#t do
		local char = sub(t,i,i)
		local c=ord(char)-16
		n1..=sub(t1,c,c).." "
		n2..=sub(t2,c,c).." "
	end
	
	if(col!=nil)color(col)
	print(pre..n1,x,y)
	print(pre..n2,x+1,y)
end


-->8
--drops
function make_drop(x,y,spr,type,q)
	add(drops,{
	 x=x, y=y,
	 bx=8,dy=8,
	 
	 spr=spr,
	 type=type,
	 
	 q=q,
	 touched=false,
	 cooldown=0,
	 
	 destroy=false,
	})
end

function update_drops()
	for d in all(drops) do
		d.cooldown=max(0,d.cooldown-1)
		
		for p in all(players) do
			
			local touches = touches_rect(
			p.x+4,p.y+4,
			d.x,d.y,d.x+8,d.y+8)
			
			if(not touches)d.touched=false
			if touches then
				
				local col=7
				local txt=""
				local do_ptc = false
				
				if d.type=="ammo" then
					d.destroy = true
					p.ammo += d.q
					
					do_ptc=true
					col=9
					txt="+"..d.q.." ammo"
					
				elseif d.type=="health"then
					d.destroy = true
					p.life += d.q
					
					do_ptc=true
					col=8
					txt="+"..d.q.." health"
					
				elseif d.type=="gun" 
				and not d.touched
				and d.cooldown<=0 then
					d.touched = true
					d.cooldown = 60
					
					do_ptc=true
					col=6
					txt=d.q.name
					
					p.gunls[p.gunn],d.q=d.q,p.gunls[p.gunn]
					update_gun(p)
					d.spr = d.q.spr
					
				end
				
				if do_ptc then
					for i=1,5 do
						make_ptc(
						   d.x+rnd(16)-8,
						   d.y+rnd(16)-8,
						   rnd(5)+5,col,
						   0.9+rnd(0.07))
					end 
				end
				
				make_ptc(
				   d.x+4-(#txt*2),
				   d.y+4,
				   rnd(5)+5,7,
				   .98,0,-0.3,txt
				)
			end
		end
		
		if(d.destroy)del(drops,d)
	end
end

function draw_drops()
	for d in all(drops)do
		spr(d.spr,d.x,d.y)
	end
end

function spawn_loot(x,y)
	local r = rnd(2)
	
	if r < .01 then
		local g = rnd_gun()
		make_drop(x,y,g.spr,"gun",
		copy(g))
	elseif r < .03 then
		make_drop(x,y,79,"ammo",50)
	elseif r < .05 then
		make_drop(x,y,78,"health",2)
	end
end
__gfx__
0000000000000000000000000000000000000000000000006666666d7777777644444444444444444444444444444444eeeeeeeeee1111ee11eeee11ee1111ee
000000000000000000000000000000006d0000660000000065d11d557d6666dd24444422444444444444444424411422eeeeeeeeee1111ee1eeeeee1ee1111ee
00700700000000000000000000000000ddd006dd000000006d1111d57666666d22244444222222224444444422211444ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000007776760000000006d1111d57666666d444442242222222244444444444d1224ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000006666660000000006dd11dd57666666d444444444444444444444444444d4444ee1111eeee1111eeee1111eeee1111ee
007007000000000000000000000000006dd00dd6000000006dd11dd57666666d422244444444444444444444422d4444ee1111eeee1111eeee1111eeee1111ee
00000000000000000000000000000000dd0000dd0000000065dddd557d6666dd44444444222222222222222244464444ee1111eeee1111eeee1111ee8eeeeee8
000000000000000000000000000000000000000000000000d55555556ddddddd22222222222222222222222222262222ee1111eeee1111eeee1111ee88eeee88
00000000000000000000000077777776222222224444444112211111555555554424424414444444111bb111444644446666666614444441eeeeeeee888e8ee8
0000000000000000000000007000770d222222224444444121124111555555554424424414444444111331b1244644226666666614444441eeeeeeee888e8ee8
0000000000000000000000007007700d4244444444444441114444210000000042244444144444441b13313122264444666666661444444111111111888e8ee8
0000000000000000000000007077000d2444444444444441122444210000000042444442144444441313333144464114666666661446444111111111888e8ee8
0000000000000000000000007770700d42444467444444412422422100000000424244421444444413333411444d1441666666661443444111111111888e8ee8
0000000000000000000000007707000d2444444444444421244222110000000044424442124444441143341142ddd4417777777714b3344111111111188e8ee1
0000000000000000000000007070000d2244444422222221124244210000000044444444122222221144441111444414dddddddd14bb3441eeeeeeee118e8e11
0000000000000000000000006dddddd62444444222222211122122210000000044444244112222221122221122111122dddddddd14b33441eeeeeeee11111111
44444441ffffffff111111111111111111111111111111114444444111111111eeeeeeeeeeeeeeee1111122222211111661111111444444111111166111dd111
44444441f444444ffffff1111111111111111111111111114444444111111111eeeeeeeeeeeeeeee11112222222221116661111114444441111116661111d111
44444441f4f4f4fff44ff111111111111444444444444411444444411111111188888888eeeeeeee112221d1d1d222116661111114444441111116661111d111
22222221f4f4f4fff4ffffffffffffff1444444444444411222222211111111188888888ecc777ce1122d1d1d11d22116661111114444441111116661111d111
d16161d1fffffffff4f4ff444444444f1444444444444411d16861d11111111188888888ec777cce022d1d1dd1d11220556111111444444111111655111dd111
6161d1d144444444fff4ff4f4f4f4f4f14444444444444116868d9d11111111188888888e777ddde022011d22d1dd220665666111444444111666566111d1111
61d1d1d142424244ff44ff4f4f4f4f4f122222222222221161d9d1d11111111188888888eeeeeeee022ddd2222d00220666666611444444116666666111d1111
2222222144444444ffffff4f4f4f4f4f1d1d1d1d1d1616112222222111111111888888888888888802200d2222ddd220666666611444444116666666111d1111
666666611111111144444fffffffffff1d1d1d16161717114444444111111111ffffffff00000000622dd6d22d66622666666661144444411666666611111111
66666661ffffffff42224444444444441d161617b71717114444444111411441ffffffff0000000062266d6dd6d6d226556555611444444116555655111dd111
6666666177777777422fffff222222241617c79717b616114444444114444144ff3fffff000000006622d66d6d6d226655566651144444411566655511dddd11
ddddddd177777777444f4f4f2424242417c717a6b6b6bd112222222112424214ff3f3fff0000000066222d6d6d62226655566661144444411666655511dddd11
51d1d151ffffffff111fffff4444444417c6c626b6bd2d11d16a61d122222411ff3f3fff000000006662222222226666555666611222222116666555115dd511
d1d1515144444444111444441111111116c6262d2d2d2d11d9da6a6124424441ffffffff00000000777772222227777755566661122222211666655511155111
d1515151411141441114222411111111162d2d2d2d2d2d11d1d9d16112422421ffffffff00000000dddddddddddddddd55555551111661111555555511111111
ddddddd144444444111444441111111112222222222222112222222111211211ffffffff00000000dddddddddddddddd55555551111661111555555511111111
000000000000000000000000000000000066d6000000000000000000000000000000000000000000000000000000000000000000000000000111110002222200
000000000000000000000000000000000066d6000000000000000000000000000000000000000000000000000000000000000000000000001678761029a9a920
06000000060000000000000000ddd000000dd0000000000000000000000000000000000000000000000000000000000000000000000000001688861029242920
0066660000d666660446d6d6446664000d6666660000000000000000000000000000000000000000000000000000000000000000000000001678761029a9a920
046ddd00444504404440500044ddd4dd4d4440000000000000000000000000000000000000000000000000000000000000000000000000001766671024949420
444500004400000044005000404050004405000000000000000000000000000000000000000000000000000000000000000000000000000015ddd51024949420
44000000000000000000000000405000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110002222200
00000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111222222221111111111111111222222221111111155555555444444445555555522222222444444445555552800000000000000000000000000000000
1111111122222222111111111111111122222222112ee21155555555444444445555555522222222cd4444445555288800000000009aa90000000000008ee800
115dd511222222221111111111288821222222221eeeee215567765544446776555eee5522222210cccd4444555288880000000009a77a900000000008e77e80
17dddd51225335221111111112888882222222102eeeffe157777775444677775efffff2222220007cccd44455d888e7000000000a7777a0000000000e7777e0
557d22d12333339a111111111822888892222100ee1ef0e1d677766d447777dd2fffff2222210000c77ccd4455667777000000000a7777a0000000000e7777e0
157d882553333aaa1111111112678866aa92009aee1ee7e1ddd77ddd44777d0622ff22052100000070dc1114566777770000000009a77a900000000008e77e80
11d8188d33339aa21111111116772666aaaaa0cce2127f7190077009446776065028e00549994000700c0111510aa77700000000009aa90000000000008ee800
11d8188d3003a44211242111177066119aaa0c1cee11fff17909a097444977665f8888fe21109990777cc044d0a22a7000000000000000000000000000000000
15dd88dd30139444994442111760566699aa0c1cee2100f1777997774499aa77f828828f2222a0001777764467a211a0004222000000000077700000cccccccc
53ddddd553333994a941422116000666e9909acc2ee000116799a977499a7777f2e22e2f2222a9101177764467911997042777200022220000000000ccc77ccc
33d3ddd1253333391a742222161006688e00aaa71ee001110719a16749a47777fffeeffe22227aa9c1777444678999774271f1700288882077700000cccccccc
3233d3512233333216777222111288882807777712ee21110600a017444477775feeeff52222777acc1764447788887724f1f1f028e8888277700000cc777ccc
2223333122533372116777611128888225777777e11ee21101009006444d77775feeee2522267777cd71444477e88877427fff442881818277700000ccc77ccc
2222232226557744411e1e111928882827777777ee12ee1100000010d6666777552eee2522267777d776444477788e77247777702821218200000000ccc77ccc
62626226d66d554424e11e11aa8889a805777777ee21ee211000001066666677555eeee2222777777774444477777777024777002822228200000000cc7777cc
6666626666666dd51224e421cca88caa00057777eee12ee110010000666666665552eeee222777777764444477777777002202200222222000000000cccccccc
11115d1111113b111111111111288e1110001111111eeee111167711111167111111eef111000011dccccd111111888111d66dd5007777000000000011100000
1115ddd1111333b111111111127078710779aa01111e7075116079a1111677711111f0ee1000000111c777c1117888811d6777dd070000700000000017110000
11152dd111130aa111111111127770770c799990e111ee151167799a1116079951111ff100a70999111d707d167779aa6777776d707744070000000017711000
5113dd7711133a991111441118870066077888892eeeee11100005191166777115544ff10000aa111111d771677077887772777d7077ff07000ff00017771000
56623331dddd334111414691aa88881100770118122ee1111000005166666671545544e100077611cd7ccc71677777787728e7767041f2070fd00df017111000
d566222116664441111461111baa821100000111117171110007000156666771feff4411000776111cd7c76166777761677877767044ff070000000011100000
1d666611116444111111111111cc2111100011111171711117700011157776111e11e11100776611117776111667761117777611070404700000000000000000
118181111191911111111111115151111c1c11111121211111911911111e1e111e11e11100755001111515111191911111761111007777000000000000000000
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
8282928282829282828292828282928282829282828292828282928282829282c0829282c0829282c0829282c082c08282c082929292929292929282c0829282
82c08282c08282c08282c08282c09282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
02132232721302021212a172727272a172122290909090909090905272121212d0c1a0a0d0a0a0c1d0a0a0c1d0c3d02232d060c1c1c1c1c1c1c1c160d01272f2
13d0c3c1d0c3c1d0c3c1d0c3c1d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
1272233372727272727272727272727272132390909090909090905372020202d0727213d0727272d0727213d061d02333d0f28183838383838381f2d01272f2
13d07272d07272d07272d07372d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
7272727272727272727272d2d272727272727290909090909090907272720202d072f3d3d072f3d3d0d3f372d072d07272d0f28183838383838381f2d01272f2
72d04182824182824182824182d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272d2d27272727272d3d1d2d3727272727272727272727272727272727202d0727272d0824182d0727272d073d07272d0f28183838383838381f2d01272f2
72d07272727272727272727272d072f2727272720000007200007272727272f2727272720000007200000072727272f2727272720000007200000072727272f2
7272d3d1d2d37272727272d2d2727272727272727272727272727272727272728282418282a172a1828241828241827272d090909090909090909090d07272f2
72d07272727272727272727272d072f2727272727272007272007272727272f2727272727272007272720072727272f2727272727272007272720072727272f2
727272d2d17272727272d3d2d1d37272727272c1a0a0a0a0a0a0c172727272727272727272727272727272727272727272d0a1a1727272727272f3d1d07272f2
72d0a1727272727272727272a1d072f2727272720000007272007272727272f2727272720000007200000072727272f2727272720000007272000072727272f2
7272d3d2d2d3727272727291517272727272d3d17272727272a1d272727272727272727272727272727272727272727272d0a1a1a1727272727272d3d07272f2
728282828282824141828282828272f2727272720072727272007272727272f2727272720072727200727272727272f2727272720072727272720072727272f2
72727291517272727272727272727272727272d2727272727272d1d37272727272727272c0824182c0824182c041c072728282828282828241418282827272f2
72a112121272727272727272127272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2
7272727272727272727272727272727272727291a0a0a0a0c1a051727272727272727202d0727291d0727272d012d002727272a11212223272722232727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
72137272727272c272d172e27272727272727272d37272d372d372727272727272720312d04272f3d0f3a0f3d012d012727272727272233372722333727272f2
727272727272721272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
12121302127272c372d372e3727272a11272727272727272727272727272727272721362d0437212d072f312d013d012727272727272727272727272727272f2
727272727272121213a17272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
8282928282c092828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282c0829292929292c09393939393939393
a1727272a1d0a1727272d2727272137272e2c272d1c272c1c172e2d172e2c272d0c2727272727272727272e2d04203f2c1c1a2b2c1c1c1a2b2c1c1c1a2b2c172
13d0808080b080808080b0808080d0f2727272727272727272727272727272f2727272727272727272727272727272f2d0727272727272829292c09393939393
c2d272d1e2d07272727291a0a0a0c1f272e3c372d3c372727272e3d372e3c3f2d0c3727272425272727272e3d04372f27270a3b370a170a3b370a170a3b37072
02f0808080b180808080b1808080f0f2727272727272727272727272727272f2727272727272727272727272727272f2d07272727272727272728292c0939393
c3d372d3e3d0727272727272727272f2727272727272727272727272727272f2d0a1727272435363127272a1d00272f272707070707270707070727070707072
72f18080808080b0b08080808080f1f2727272727272727272727272727272f2727272727272727272727272727272f2d0727272727272727272727282319393
7272727272d0137213e0c2d172d2e2f27272727272a172727272a172727272f2828241828282c08282824182827272f272f27272f272f27203f272f21202f272
72a19080808080b1b18080808090a1f2727272720000007200000072727272f2727272720000007200000072727272f260727272727272727272727272319393
72c2d1e272d02232a1d0c3d372d3e3f272637272d3d2f37272f3d1d3727262f2727272722232d00202037272727272f272f27272f272f27272f272f27213f272
727272909090909090909090907272f2727272727272007200720072727272f2727272727272007200720072727272f272727272727272727272727272319393
72c3d3e372d0233313d0a172727272f27262727272d1f37272f3d272727262f2727272722333d01203727272727272f272f22232f272f27272f272f27272f272
727272727272727272727272727272f2727272720000007200000072727272f2727272720000007200720072727272f260727272727272727272727272319393
7272727272f0721272d0c272d17272f272637272d3d272f3f372d2d3727263f2828241828282d08282824182827272f272f22333f272f27272f272f27272f272
7272c272d172e27272c272d172e272f2727272720072727272720072727272f2727272727272007200720072727272f260727272727272727272727272319393
7272727272f1727272d0c372d37272f2727272727291a0a0a0a05172727272f2d07272720262f0a172727272d07272f272f27272f272f21272f272f27272f272
7272c372d372e37272c372d372e372f2727272720000007272720072727272f2727272720000007200000072727272f2c0727272727272727272727272319393
727272727272727272d0a172727272f2727272727272727272727272727272f2d00372727272f17272727212d0a172f272c17272c1c1c11372c1c1c17203c172
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2d07272727272727272727272c0319393
223272727272727272d0c2d272d1e2f272e2c272d1c272727272e2d172e2c2f2d04202727272727272720363d02232f2e270f3f3e270c2f3f3e270c2f3f370c2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2d0727272727272727272c09282939393
23331312a1727272a1d0c3d372d3e3f272e3c372d3c372c1c172e3d372e3c3f2d04362037272727272031362d02333f2e37013f3e370c3f3f3e370c3f31270c3
727272c272d172e2c272d172e27272f2727272727272727272727272727272f2727272727272727272727272727272f2d0727272727272c09292829393939393
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829292929292829393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffff3ffffffffffffffffffffffff3ffffffffffffffffffffffffffffffffffffffffffffffffffffff3ffffffffffffff3fffffffff3ff
ffffffffffffffffffff3f3fffffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhfffhhhhhhhfffffffffffffffff3f3ffffffffffff3f3fffffff3f3
ffffffffffffffffffff3f3fffffffffffffffffffhaaaaaaahaaaaaaahaaaaaaahaaaaahfffhaaaaahfffffffffffffffff3f3ffffffffffff3f3fffffff3f3
ffffffffffffffffffffffffffffffffffffffffffhaaaaaaahaaaaaaahaaaaaaahaaaaahhhhhaaaaahfffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffhaaaaaaahaaaaaaahaaaaaaahaaaaaaahaaaaaaahfffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffhaaahaaahhhaaahhhaaahaaahaaahaaahaaahhhhhfffffffffffffffffffffffffffffffffffffffffffff
222222222222222222222222222222222222222222haaaaaaahhhaaahhhaaaaaaahaaahaaahaaaaaaah222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222haaaaahhhhhaaahhhaaaaahhhaaahaaahaaaaaaah222222222222222222222222222222222222222222222
888888888888888822222222888888888888888888haaaaaaah2haaah8haaaaaaahaaahaaahaaaaaaah222228888888888888888888888882222222288888888
88888888888888882cc777c2888888888888888888haaahaaahhhaaahhhaaahaaahaaahaaahhhhhaaah777c28888888888888888888888882cc777c288888888
88888888888888882c777cc2888888888888888888haaaaaaahaaaaaaahaaahaaahaaaaaaahaaaaaaah77cc28888888888888888888888882c777cc288888888
88888888888888882777ddd2888888888888888888haaaaaaahaaahhhhhhhhhhhhhhhhhaaahaaaaahhh7ddd28888888888888888888888882777ddd288888888
888888888888888822222222888888888888888888haaaaaaahaaah7h7h777h777h7h7haaahaaaaahhh222228888888888888888888888882222222288888888
888888888888888888888888888888888888888888hhhhhhhhhhhhh7h7hh7hhh7hh7h7hhhhhhhhhhhhh888888888888888888888888888888888888888888888
ffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhffhhhhhhhhhhhhh7h7hh7hhh7hh777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhh
f444444ff444444ffffffhhhhhhhhhhhhhhhhhhhf4hhhhhhhhhhhhh777hh7hhh7hh7h7hhhhhhhhhhhffffffffffffffffffffffff444444fhhhhhhhhhhhhhhhh
f4f4f4fff4f4f4fff44ffhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhh777h777hh7hh7h7h7hhhhhhh7777777777777777777777777f4f4f4ffhhhhhhhhhhhhhhhh
f4f4f4fff4f4f4fff4ffffffffffffffhhhhhhhhf4f4f4ffh66666hhhhhhhhhhhhhhhhh7h66666h7777777777777777777777777f4f4f4ffhhhhhhhhhhhhhhhh
fffffffffffffffff4f4ff444444444fhhhhhhhhffffffhhh66666hhhhhhhhhhhhhhhhhhh66666hfffffffffffffffffffffffffffffffffhhhhhhhhhhhhhhhh
4444444444444444fff4ff4f4f4f4f4fhhhhhhhh444444h6666666h666h666h6666666h6666666h444444444444444444444444444444444hhhhhhhhhhhhhhhh
4242424442424244ff44ff4f4f4f4f4fhhhhhhhh424242h666hhhhh666h666h666h666h666hhhhh44hhh4h444hhh4h444hhh4h4442424244hhhhhhhhhhhhhhhh
4444444444444444ffffff4f4f4f4f4fhhhhhhhh444444h666hhhhh666h666h666h666h6666666h444444444444444444444444444444444hhhhhhhhhhhhhhhh
ffffffffffffffff44444fffffffffffffffffffffffffh666hhhhh666h666h666h666h6666666hfffffffffhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhhhh
f444444ff444444f4222444444444444f444444ff44444h666h666h666h666h666h666h6666666hff444444fhhhhhhhhf444444fffffffffffffffffhhhhhhhh
f4f4f4fff4f4f4ff422fffff22222224f4f4f4fff4f4f4h666h666h666h666h666h666hhhhh666hff4f4f4ffhhhhhhhhf4f4f4ff7777777777777777hhhhhhhh
f4f4f4fff4f4f4ff444f4f4f24242424f4f4f4fff4f4f4h6666666h6666666h666h666h6666666hff4f4f4ffhhhhhhhhf4f4f4ff7777777777777777hhhhhhhh
ffffffffffffffffhhhfffff44444444ffffffffffffffh6666666hhh66666h666h666h66666hhhfffffffffhhhhhhhhffffffffffffffffffffffffhhhhhhhh
4444444444444444hhh44444hhhhhhhh44444444444444h6666666hhh66666h666h666h66666hhh444444444hhhhhhhh444444444444444444444444hhhhhhhh
4242424442424244hhh42224hhhhhhhh42424244424242hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh442424244hhhhhhhh424242444hhh4h444hhh4h44hhhhhhhh
4444444444444444hhh44444hhhhhhhh44444444444444hhhhhhhhh4hhhhhhhhhhhhhhhhhhhhh44444444444hhhhhhhh444444444444444444444444hhhhhhhh
ffffffffffffffffhhhhhhhh6666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffhhhhhhhh
f444444ff444444fffffffff6666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhf444444ff444444fffffffff
f4f4f4fff4f4f4ff777777776666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhf4f4f4fff4f4f4ff77777777
f4f4f4fff4f4f4ff77777777dddddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhf4f4f4fff4f4f4ff77777777
ffffffffffffffffffffffff5hdhdh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffffffffffffffffffff
444444444444444444444444dhdh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh444444444444444444444444
42424244424242444hhh4h44dh5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhh42424244424242444hhh4h44
444444444444444444444444dddddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh444444444444444444444444
ffffffff4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
f444444f4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhh
f4f4f4ff4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhh
f4f4f4ff2222222h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhh
ffffffffdh686hdhdh6a6hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhh
444444446868d9dhd9da6a6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhh
424242446hd9dhdhdhd9dh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhh
444444442222222h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhh
4444444h4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffff
4444444h4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444fhhhhhhhhhhhhhhhhf444444f
4444444h4444444h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhf4f4f4ff
2222222h2222222h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhf4f4f4ff
dh686hdhdh686hdhdh6h6hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffff
6868d9dh6868d9dh6h6hdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444
6hd9dhdh6hd9dhdh6hdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh42424244hhhhhhhhhhhhhhhh42424244
2222222h2222222h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444
4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhh
4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444fhhhhhhhh
4444444hh4444444444444hhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhh
2222222hh4444444444444hhhhhhhhhhhhhhhhhhhhhhhhhh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhhf4f4f4ffhhhhhhhh
dh6h6hdhh4444444444444hhhhhhhhhhhhhhhhhhhhhhhhhhd46262dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhhhhhhhhhffffffffhhhhhhhh
6h6hdhdhh4444444444444hhhhhhhhhhhhhhhhhhhhhhhhhh6462d2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777hhhhhhhhh44444444hhhhhhhh
6hdhdhdhh2222222222222hhhhhhhhhhhhhhhhhhhhhhhhhh62d2d4dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhhhhhhhh42424244hhhhhhhh
2222222hhdhdhdhdhdh6h6hhhhhhhhhhhhhhhhhhhhhhhhhh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhh
6666666hhdhdhdh6h6h7h7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
6666666hhdh6h6h7b7h7h7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhh
6666666hh6h7c797h7b6h6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhh
dddddddhh7c7h7a6b6b6bdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhh
5hdhdh5hh7c6c626b6bd2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhh
dhdh5h5hh6c6262d2d2d2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhh
dh5h5h5hh62d2d2d2d2d2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhh
dddddddhh2222222222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhh
6666666h6666666h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
6666666h6666666h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffff
6666666h6666666h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhh77777777
dddddddhdddddddh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhh77777777
5hdhdh5h5hdhdh5hdh686hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffff
dhdh5h5hdhdh5h5h6868d9dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444
dh5h5h5hdh5h5h5h6hd9dhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhh4hhh4h44
dddddddhdddddddh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444
4444444h4444444h6666666hffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffffffffff
4444444h4444444h6666666hf444444fhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444ff444444ff444444f
4444444h4444444h6666666hf4f4f4ffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4fff4f4f4fff4f4f4ff
2222222h2222222hdddddddhf4f4f4ffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4fff4f4f4fff4f4f4ff
dh6a6hdhdh6h6hdh5hdhdh5hffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffffffffff
d9da6a6h6h6hdhdhdhdh5h5h44444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh444444444444444444444444
dhd9dh6h6hdhdhdhdh5h5h5h42424244hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh424242444242424442424244
2222222h2222222hdddddddh44444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh444444444444444444444444
4444444h4444444h4444444h4444444h4444444hhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhh
4444444h4444444h4444444h4444444h4444444hhhhhhhhhhhhhhhhh4444444hhhhhhhhhfffffhhhhhhhhhhhf444444ff444444fffffffffcccccccccccccchh
4444444h4444444h4444444h4444444h4444444hh4444444444444hh4444444hhhhhhhhhf44ffhhhhhhhhhhhf4f4f4fff4f4f4ff77777777cccccccccccccchh
2222222h2222222h2222222h2222222h2222222hh4444444444444hh2222222hhhhhhhhhf4fffffffffffffff4f4f4fff4f4f4ff77777777cchhhhhhhhhhcchh
dh686hdhdh6a6hdhdh6h6hdhdh6h6hdhdh6h6hdhh4444444444444hhdh686hdhhhhhhhhhf4f4ff444444444fffffffffffffffffffffffffcchhhd66dd5hcchh
68hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh444hh6868d9dhhhhhhhhhfff4ff4f4f4f4f4f444444444444444444444444cchhd6777ddhcchh
6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222hh6hd9dhdhhhhhhhhhff44ff4f4f4f4f4f42424244424242444hhh4h44cch6777776dhcchh
22hh7777hhhh7777hhhh777hhhhh777hhhhhh777hhhh7777hhh6h6hh2222222hhhhhhhhhffffff4f4f4f4f4f444444444444444444444444cch7772777dhcchh
44hh77h7hhhh77h7hhhh77h7hhhh77h7hhhh77h7hhhh7777hhh7h7hh4444444h4444444h44444fffffffffffffffffffffffffff4444444hcch7728e776hcchh
44hh777hhhhh7777hhhh77h7hhhh77h7hhhh77h7hhhh77h7hhh7h7hh4444444h4444444h4222444444444444f444444ff444444f4444444hcch67787776hcchh
44hh77h7hhhh77h7hhhh77h7hhhh77h7hhhh77h7hhhh77h7hhh6h6hh4444444h4444444h422fffff22222224f4f4f4fff4f4f4ff4444444hcchh77776hhhcchh
22hh77h7hhhh77h7hhhh77h7hhhh7777hhhhh77hhhhh77h7hhh6bdhh2222222h2222222h444f4f4f24242424f4f4f4fff4f4f4ff2222222hcchhh76hhhhhcchh
dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd2dhhdh6a6hdhdh6a6hdhhhhfffff44444444ffffffffffffffffdh686hdhcchhhhhhhhhhcchh
68hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd2dhhd9da6a6hd9da6a6hhhh44444hhhhhhhh44444444444444446868d9dhcccccccccccccchh
6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd2dhhdhd9dh6hdhd9dh6hhhh42224hhhhhhhh42424244424242446hd9dhdhcccccccccccccchh
22hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
22hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22
22hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22
88hhhhhhhhhhhhh22222222hhhhhhhhhhhhhhhhhhhhhh22222222hhhhhhhhhhhh55555555hh44444444hh55555555hh22222222hh44444444hh55555528hhh88
88hhhhhhhhhhhhh22222222hhhhhhhhhhhhhhhhhhhhhh22222222hhhh2ee2hhhh55555555hh44444444hh55555555hh22222222hhcd444444hh55552888hhh88
88hhhhh5dd5hhhh22222222hhhhhhhhhhhhhh28882hhh22222222hhheeeee2hhh55677655hh44446776hh555eee55hh222222h0hhcccd4444hh55528888hhh88
88hhhh7dddd5hhh22533522hhhhhhhhhhhhh2888882hh222222h0hh2eeeffehhh57777775hh44467777hh5efffff2hh22222000hh7cccd444hh55d888e7hhh88
88hhh557d22dhhh2333339ahhhhhhhhhhhhh8228888hh92222h00hheehef0ehhhd677766dhh447777ddhh2fffff22hh222h0000hhc77ccd44hh55667777hhh88
88hhhh57d8825hh53333aaahhhhhhhhhhhhh2678866hhaa92009ahheehee7ehhhddd77dddhh44777d06hh22ff2205hh2h000000hh70dchhh4hh56677777hhh88
ffhhhhhd8h88dhh33339aa2hhhhhhhhhhhhh6772666hhaaaaa0cchhe2h27f7hhh90077009hh44677606hh5028e005hh49994000hh700c0hhhhh5h0aa777hhhff
ffhhhhhd8h88dhh3003a442hhhh242hhhhhh77066hhhh9aaa0chchheehhfffhhh7909a097hh44497766hh5f8888fehh2hh09990hh777cc044hhd0a22a70hhhff
ffhhhh5dd88ddhh30h39444hh994442hhhhh7605666hh99aa0chchhee2h00fhhh77799777hh4499aa77hhf828828fhh2222a000hhh7777644hh67a2hha0hhhff
ffhhh53ddddd5hh53333994hha94h422hhhh6000666hhe9909acchh2ee000hhhh6799a977hh499a7777hhf2e22e2fhh2222a9h0hhhh777644hh679hh997hhhff
ffhhh33d3dddhhh25333339hhha742222hhh6h00668hh8e00aaa7hhhee00hhhhh07h9ah67hh49a47777hhfffeeffehh22227aa9hhch777444hh67899977hhhff
ffhhh3233d35hhh22333332hhh6777222hhhhh28888hh28077777hhh2ee2hhhhh0600a0h7hh44447777hh5feeeff5hh2222777ahhcch76444hh77888877hhhff
ffhhh2223333hhh22533372hhhh67776hhhhh288882hh25777777hhehhee2hhhh0h009006hh444d7777hh5feeee25hh22267777hhcd7h4444hh77e88877hhhff
ffhhh22222322hh26557744hh4hhehehhhhh9288828hh27777777hheeh2eehhhh000000h0hhd6666777hh552eee25hh22267777hhd7764444hh77788e77hhhff
66hhh62626226hhd66d5544hh24ehhehhhhaa8889a8hh05777777hhee2hee2hhhh00000h0hh66666677hh555eeee2hh22277777hh77744444hh77777777hhh66
66hhh66666266hh66666dd5hhh224e42hhhcca88caahh00057777hheeeh2eehhhh00h0000hh66666666hh5552eeeehh22277777hh77644444hh77777777hhh66
66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66
66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66
66hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66
77777777777772222227777777777222222777777777722222277777777777777777777777777222222777777777722222277777777772222227777777777777
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000040100040403040101010100000001030300110403030411030101030b0b0b010101040101010101030104030b0b0b01010100001101010103010400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404041339393939393939393939393939391539393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040c39393939393939393939393939390c28282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070739393939393939390707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000021212100000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000000021210000000000000404000000210000002100000000000004280707070739393939393907070707282727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000002100210000000000000404000000000000210000000000000004270707070808080808080808070707272727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000000210000000000000000040c07070707393939393939070707070c2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000021212121210000000004040000002121212121000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070717393939393939170707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000042817171739393939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
040000000000000000000000000000040400000000000000000000000000000404000000000000000000000000000004393939393939393939393939393939391c2a2a2b1c1c2a2a2b1c1c2a2a2b1c1c1c2a2a2b1c1c2a2a2b1c1c2a2a2b1c1c1c2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b3b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b
040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404393939393939393939393939393939391c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c
1339393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
0c39393939393939393939393939390c0c282928282829282828292828282928282829280c282928280c2928282829282828292828282928282829282828292828282928282829280d282928282829282828292828282928282829282828292828280c2828282928282829282828292828282928282829282828292828282928
0d07070739393939393939390707070d0d212223272121213131313131212727272731210d080b08080d2121272727271a271a27271a2d271c21211a27271a270d212121212131210d2c2d2e272c2d2e2627242521212425212127272425272727270d2121312727272727313127272727272721212727212127272121272727
0d07070707393939393939070707070d0d213233212131273121212721312721272727270f081b08080f272727272727272727273d271d2727272727272727270d213131272121210d3c3d3e273c3d3e2027343536363435212727273435272727270d2127271a1a272727272727272727272e0c28282928282928280c2c2727
0d07070707040407070404070707070d0d2131303127272727273127272721272727271a1f090909091f1a2727272727272727272727190a0a0a0a0a1c27272728282828272828280d272727272727272027262727272425362026272720272727270d2727271a1a271a27272727272727273e0d3127272727273131283c2727
0d070707071c1c1c1c1c1c070707070d0d263621272727272727272727213127272727272727272727272727272727272727272727272727272727272727272727272727272727270d272727272727272620263626273435272727272720263627270d271a271a1a271a27270e2727272727270d272727272727272727272727
0d0707070739393939393907070707280d262027272727272727272727312721272c2d2e2727272727272c1d2e27272727272c2d2e27273d2727273d2727272727272727272727270d27272727272d272727272726272425272727272726272727270d271a271a1a1a1a27270d27272727273d0d27272727272727270c272727
060707070704042727040407070707270d242527272716272727272727272127273c3d3e2727272727273c3d3e27272727273c3d3e2727272727272727272727272c2d2e272c2d2e0f2c2d2e27272d272727272736273435272736272726272727270d271a1a1a1a1d2727270d27272727272728272c272a2b272e270d3d2727
0c07070707393917173939070707070c0d3435272727272727272727272731272727272727272727272727272727272727272727272727272727272c2d2e2727273c3d3e273c3d3e1f3c3d3e27272d273636272727272627272720272720272727270d27271d1a1a2d2727270d27272727272727273c273a3b273e270d272727
0d07070707393939393939070707070d0d3026312727272727272727312727312727272727272727272727272727272727272727272727272727273c3d3e272727272727272727272727272727273d272720272727272727272736272720272727270f2727190a0a152727270d27272727272e0c27272727272727270d2c2727
0d07070707040407070404070707070d0d2030212727272727272727272121272727272c2d2e27272c2d2e2727272727273d27273d27273d2727272727272727272727272727272727272727272727272736272727272027272726272727272727271f27273d3d3d3d2727210d21272727273e0d27272727272727270d3c2727
0d07070707393939393939070707070d0d3620202024252627222321213127272727273c3d3e27273c3d3e2727272727210a0a0a0a0a0a0a0a0a272727272727272c2d2e272c2d2e270a0a0a0a0a0a0a272627272727202727273627272727272727272727272727272727210d21272727272728282829282829282828272727
0d07070717393939393939170707070d0d3636202634353636323321212626272727272727272727272727272727272721272727272727272721272727272727273c3d3e273c3d3e2721272721272721272031212131262727272627272727272727272727272727272727210d21272727272721212727212127272121272727
2817171739393939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
3939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c
__sfx__
000100001a0601f000230002100000000000003400039000000003c000000000000029000290002d00036000000003b0003e0003c00000000300002200014000090001900022000260002400000000000001d000
010c00000c9500b9310a911189500000000000169500000000050000000005000000000500000000050000000c9500b9310a91118950000001895016950000000c0500000000050000000c050000000005000000
030c000024635180003c6303c62024635180003c6303c62024635180003c6303c62024635180003c6303c62024635180003c6303c62024635180003c6303c620246353c6553c6353c6253c6353c6553c6353c625
010c00000c9500b9310a911189500000000000169500000002050009000e0500c90002050000000e050000000f9500e9310d9111b95000000000001a950000000505000000110500000005050000001105000000
010c00002455024530245100c5000c5000c50023550245502655026530265100c5000c5000c50024550265502755027530275100c5000c5000c500265502455022550225302251029554295550c5003055430555
010c00002b5542b5522b5422b5322b5222b5150c5020c5020c5020c5020c5020c5020c5020c5002b52429555275550c5020c5020c5020c5000c5000c5000c50026554265550c50027554275550c5002655426555
010c00002455024530245100c5000c5000c50023550245502655026530265100c5000c5000c50024550265502755027530275100c5000c5000c500265502755029550295302951027554275550c5002955429555
010c00002b5542b5522b5422b5322b5222b5152b5540c5022b5540c5042b5540c5042b5540c5042b554000042b554000042b554000042b554000042b554000042b5540000400004000042f554000043055430552
010c0000245542455224542245322452224515245540c502245540c504245540c504245540c50424554005042355400504235540050423554005042355400504235540050400504005042b554005042b5542b552
010c00000c950000000c95018950000001895016950000000c950000000c95018950000001895016950000000a950000000a95016950000001695014950000000a950000000a9501695000000169501495000000
010c000030552305422f5312e5212d5112c51100000000002455224555000003055230555000002e5542e5522e5522e5422d5312c5212b5112a51100000000002255222555000002e5522e555000002c5542c552
010c00002b5522b5422a53129521285112751100000000001f5521f555000002b5522b55500000295542955229552295422853127521265112551100000000001d5521d555000002955229555000002755427552
010c000008950000000895014950000001495013950000000895000000089501495000000149501395000000079500000007950000000795000000079500000007950000000b950000000e950000001195000000
010c00002c5522c5422b5312a521295112851100000000002055220555000002c5522c555000002b5542b5522b5522b5252c5542c5502b5502b5252c5502c5252b5502b525000002b0002f5512f5553055430552
010c000027552275422653125521245112351100000000001b5521b55500000275522755500000265542655226552265252755427550265502652527550275252655026525000002b0002b5512b5552b5542b552
010c0000089500000008950149500000014950139500000008950000000895014950000001495016950000000a950000000a95016950000001695014950000000a950000000a9501695000000169501795000000
010c00002c5522c5422b5312a521295112851100000000002055220555000002c5522c555000002e5542e5522e5522e5250000000000000000000000000000002b5522b555000002f5522f555000003555235555
010c000027552275422653125521245112351100000000001b5521b55500000275522755500000295542955229552295250000000000000000000000000000002655226555000002b5522b555000002f5522f555
010c00000c950000000c950189500c900189500c950000000b950000000b950179500b900179500b950000000a950000000a950169500a900169500a950000000995001000099501595009900159500995001000
050c000033752337423273131721307112f711327523275533752337553275232755337523375532752327513375133755327523275530752307552b7542b7522b7322b7222b7150070000700007000070000700
090c000030752307422f7312e7212d7112c7112b7522b7552b7522b7552b7522b7552b7522b7552b7522b7512b7512b7552b7522b7552b7522b75527754277522773227722277150070000700007000070000700
010c0000089500000008950149500890014950089500000007950000000795013950079001395007950000000e950020000e9501a9500e9001a9500e950020000c950000000c950179500b900179500b95000000
030c000024635180003c6303c62024635180003c6303c62024635180003c6303c62024635180003c6303c6253c600000003c6303c62500000000003c6303c6253c6353c65524635246253c6553c6552465524655
050c000033752337423273131721307112f7113275232755337523375532752327553375233751357513573235722357153375433732337223371532754327323272232715337543373233722337150070000700
090c000030752307422f7312e7212d7112c7112b7522b7552c7522c7552b7522b7552c7522c75132751327323272232715307543073230722307152f7542f7322f7222f715307543073230722307150070000700
010c0000089500000008950149500890014950089500000008950010000895014950059001495008950010000a950000000a950169500c900169500a950000000a9500a9500c9001395013950179001795017950
050c00002c7522c7422b7312a721297112871100700007002075220755007002c7522c755007002e7542e7522e7522e7250070000700007000070000700007002b7522b755007002f7522f755007003575235755
090c0000277522774224750247501f7501f7502475024750277522775500700277522775500700267542675226752267250070000700007000070000700007002375223755007001f7521f755007001a7521a755
__music__
00 01024344
00 01024344
01 03020444
00 01020544
00 03020644
00 03020708
00 09020a0b
00 0c020d0e
00 09020a0b
00 0f021011
00 09020a0b
00 0c020d0e
00 09020a0b
00 0f021011
00 12021314
00 15161718
00 12021314
02 19021a1b

