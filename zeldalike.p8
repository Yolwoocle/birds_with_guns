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
	
	bird_choice=0,
	
	--darker blue
	--pal(1,130,1)
	--pal(1,129,1)
	reset_pal()
	poke(0x5f2e,1)
end

function _update60()
	mouse_x_y()
	grasstile()
	
	if menu == "game" then
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
		
		shake -= 0.3
		shake = max(0,shake)
		shake = 0

		update_camera()
	elseif menus[menu] != nil then
		local m = menus[menu]
		m.update(m)
	else
		
	end
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
	
	for p in all(players) do
		p.x = 6*8
		p.y = 7*8
	end
	
	shake += 10
	for i=1,10 do
		make_ptc(
		 6*8 + rnd(16)-8,
		 7*8 + rnd(16)-8,
		 8+rnd(8),rnd({2,4,6}),0.95,
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
		gunls={copy(guns.debuggun),copy(guns.revolver),copy(guns.shotgun)},
	
		lmbp = true,
	}
	p.gun = p.gunls[p.gunn]
	add(players,p)
end

function player_update()
	for p in all(players) do
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
	end
end

function draw_player()
	for p in all(players) do
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
		64, 1, 3, .02,10, false,  true,
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
		64, 100,0.9, .02,1,  true,  true,
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
				p.life -= b.dmg
				p.dx+=b.dx*b.spd*2
				p.dy+=b.dy*b.spd*2
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
				if (e.dx+e.dy<30) then
					e.dx+=b.dx*b.spd*.1
					e.dy+=b.dy*b.spd*.1
				end
				
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
		
		enemiescleared=true
		for i=1,5 do
			make_ptc(
			  x*8 + rnd(16)-8,
			  7*8 + rnd(16)-8,
			8+rnd(8),rnd({9,10}))
		end
		
		mset(x,6,40)
		mset(x,7,7)
		
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
    elseif ceil(rnd(max(3,0-(wagon_n*2))))==1 then
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
	 x,y,108    ,1    ,5   ,7   ,
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
	 x,y,88    ,2  ,1  ,0   ,  
--chase,seerange
  true,7, 
	 guns.snipeurpisto),
}

end

function spenemie(x,y,name)
 local a=copy(name)
 a.x = x
 a.y = y
 a.gun = copy(a.gun)
 a.gun.cooldown += rnd(60)
 if a.x<175 then
  a.gun.timer += 60
  a.timer = 60
 end
 
	add(enemies,a)
end

function update_enemy(e)
	for i in all(enemies) do
		if i.life <= 0 then  
			make_ptc(i.x+4,i.y+4,rnd(4)+10,8,.8) 
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
--particles & screenshake
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

function grasstile()
	for i in all(grass)do
	 i.x = i.x
		i.x-=2.5
		if (i.x<1)i.x = 128
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
end

function make_main_menu()
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
				
				if lmb then
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
	
	rectfill(112,89+oy,125,110+oy,12)
	rectfill(2,103+oy,125,124+oy,1)
	for k=0,#m.buttons do
		i = m.buttons[k]
		
		rectfill(i.x, 
		i.y-i.oy + oy, 
		i.x+i.w, 
		i.y+i.h-i.oy + oy, 
		i.col)
		spr(i.spr, 
		i.x+1, 
		i.y+1-i.oy + m.ui_oy,
		1,i.sh)
	end
	
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

function wide(t,x,y,col)
	--credit to yolwoocle
	t1= "                ! #$%&'()  ,-./[12345[7[9:;<=>?([[c[efc[ij[l[[([([st[[[&yz[\\]'_`[[c[efc[ij[l[[([([st[[[&yz{|}~"
	t2="                !\"=$  '()*+,-./0123]5678]:;<=>?@abcdefghijklmnopqrstuvwx]z[\\]^_`abcdefghijklmnopqrstuvwx]z{|} "
	n1,n2="",""
	for i=1,#t do
	    local c=ord(sub(t,i,i))-16
	    n1..=sub(t1,c,c).." "
	    n2..=sub(t2,c,c).." "
	end
	if(col!=nil)color(col)
	print(n1,x,y)
print(n2,x+1,y)
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
	local r = rnd(1)
	
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
0000000000000000000000000000000000000000181811816666666d7777777644444444444444444444444444444444eeeeeeeeee1111ee11eeee11ee1111ee
000000000000000000000000000000006d0000668118111165d11d557d6666dd24444422444444444444444424411422eeeeeeeeee1111ee1eeeeee1ee1111ee
00700700000000000000000000000000ddd006dd181811816d1111d57666666d22244444222222224444444422211444ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000007776760811881816d1111d57666666d444442242222222244444444444d1224ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000006666660111111116dd11dd57666666d444444444444444444444444444d4444ee1111eeee1111eeee1111eeee1111ee
007007000000000000000000000000006dd00dd6818188816dd11dd57666666d422244444444444444444444422d4444ee1111eeee1111eeee1111eeee1111ee
00000000000000000000000000000000dd0000dd8881881165dddd557d6666dd44444444222222222222222244464444ee1111eeee1111eeee1111ee8eeeeee8
000000000000000000000000000000000000000081818881d55555556ddddddd22222222222222222222222222262222ee1111eeee1111eeee1111ee88eeee88
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
15dd88dd30139444994442111760566699aa0c1cee2100f1777997774499aa77f828828f2222a0001777764467a211a000422200000000007770000000000000
53ddddd553333994a941422116000666e9909acc2ee000116799a977499a7777f2e22e2f2222a910117776446791199704277720002222000000000011110000
33d3ddd1253333391a742222161006688e00aaa71ee001110719a16749a47777fffeeffe22227aa9c1777444678999774271f170028888207770000010010110
3233d3512233333216777222111288882807777712ee21110600a017444477775feeeff52222777acc1764447788887724f1f1f028e888827770000011110110
2223333122533372116777611128888225777777e11ee21101009006444d77775feeee2522267777cd71444477e88877427fff44288181827770000011111111
2222232226557744411e1e111928882827777777ee12ee1100000010d6666777552eee2522267777d776444477788e7724777770282121820000000011111111
62626226d66d554424e11e11aa8889a805777777ee21ee211000001066666677555eeee222277777777444447777777702477700282222820000000010011001
6666626666666dd51224e421cca88caa00057777eee12ee110010000666666665552eeee22277777776444447777777700220220022222200000000001100110
11115d1111113b111111111111288e1110001111111eeee111167711111167111111eef111000011dccccd111111888111d66dd5007777000000000011100000
1115ddd1111333b111111111127078710779aa01111e7075116079a1111677711111f0ee1000000111c777c1117888811d6777dd070000700000000017110000
11152dd111130aa111111111127770770c799990e111ee151167799a1116079951111ff100a70999111d707d167779aa6777776d707744070000000017711000
5113dd7711133a991111441118870066077888892eeeee11100005191166777115544ff10000aa111111d771677077887772777d7077ff070000000017771000
56623331dddd334111414691aa88881100770118122ee1111000005166666671545544e100077611cd7ccc71677777787728e7767041f2070000000017111000
d566222116664441111461111baa821100000111117171110007000156666771feff4411000776111cd7c76166777761677877767044ff070000000011100000
1d666611116444111111111111cc2111100011111171711117700011157776111e11e11100776611117776111667761117777611070404700000000000000000
118181111191911111111111115151111c1c11111121211111911911111e1e111e11e11100755001111515111191911111761111007777000000000000000000
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
93939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393
8282928282829282828292828282928282829282828292828282928282829282c0829282c0829282c0829282c082c08282c082929292929292929282c0829282
82c08282c08282c08282c08282c09282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
61732232726102021212a161727272a172122290909090909090905272121212d0c1a0a0d0a0a0c1d0a0a0c1d0c3d02232d060c1c1c1c1c1c1c1c160d01272f2
13d0c3c1d0c3c1d0c3c1d0c3c1d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
7372233372727272727272727272727272132390909090909090905372020202d0727213d0727272d0727213d061d02333d0f28083838383838380f2d01272f2
13d07272d07272d07272d07372d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727261d272727272727290909090909090907272720202d072f3d3d072f3d3d0d3f372d072d07272d0f28083838383838380f2d01272f2
72d04182824182824182824182d012f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727372d2d2727272727273d173d3727272727272727272727272727272727202d0727272d0824182d0727272d073d07272d0f28083838383838380f2d01272f2
72d07272727272727272727272d072f2727272720000007200007272727272f2727272720000007200000072727272f2727272720000007200000072727272f2
727261d173d372727272726161727272727272727272727272727272727272728282418282a172a1828241828241827272d09090c1c1c1c1c1c19090d07272f2
72d07272727272727272727272d072f2727272727272007272007272727272f2727272727272007272720072727272f2727272727272007272720072727272f2
73727261d27272727372d3d261d37250727272c1a0a0a0a0a0a0c172727272727272727272727272727272727272727272d0a1a1a1a172727272f3d1d07272f2
72d0a1727272727272727272a1d072f2727272720000007272007272727272f2727272720000007200000072727272f2727272720000007272000072727272f2
7272d3d2d2d3727272727291517272727272d3d17272725072a1d272727272727272727272727272727272727272727272d0a1a1a1a1a172727272d3d07272f2
728282828282824141828282828272f2727272720072727272007272727272f2727272720072727200727272727272f2727272720072727272720072727272f2
72727291517272727272727272727261727272d2727272727272d1d37272727272727272c0824182c0824182c041c072728282828282828241418282827272f2
72a112121272727272727272127272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2
7272727272727272727272727272727272727291a0a0a0a0c1a051727272727272727202d0727291d0727272d012d002727272a11212223272722232727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
72137272727272c272d172617272727272727272d37272d372d372727272727272720312d04272f3d0f3a0f3d012d012727272727272233372722333727272f2
727272727272721272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
12121373127272c372d372e3727272a11272727272727272727272727272727272721362d0437212d072f312d013d012727272727272727272727272727272f2
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
72c2d1e272d02232a1d0c3d372d3e3f272637272d3d2f37250f3d1d3727262f2727272722232d00202037272727272f272f27272f272f27272f272f27213f272
727272909090909090909090907272f2727272727272007200720072727272f2727272727272007200720072727272f272727272727272727272727272319393
72c3d3e372d0233313d0a172727272f27262727272d1f37250f3d272727262f2727272722333d01203727272727272f272f22232f272f27272f272f27272f272
727272727272727272727272727272f2727272720000007200000072727272f2727272720000007200720072727272f260727272727272727272727272319393
7272727272f0721272d0c272d17272f272637272d3d272f3f372d2d3727263f2828241828282d08282824182827272f272f22333f272f27272f272f27272f272
7272c272d172e27272c272d172e272f2727272720072727272720072727272f2727272727272007200720072727272f260727272727272727272727272319393
7272727272f1727272d0c372d37272f2727272727291a0a0a0a05172727272f2d07272720262f0a172727272d07272f272f27272f272f21272f272f27272f272
7272c372d372e37272c372d372e372f2727272720000007272720072727272f2727272720000007200000072727272f2c0727272727272727272727272319393
727272727272727272d0a172727272f2727272727272727272727272727272f2d00372727272f17272727212d0a172f272c17272c1c1c11372c1c1c17203c172
727272727272727250727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2d07272727272727272727272c0829393
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffffffffffffffffffffffffffffffffffffffffffffff77ff77ff777f7ffff77ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
2222222222222222222222222222222222222222222ffffff7fff7f7ff7ff7fffff7ffffffffffffffffff4444444444444444444444444444444444444444ff
2877877887788777888787788777888888888888882ffffff7fff7f7ff73f7fffff7ffffffffffffffffff4977799977797779999999999999999999999994ff
2877777888788787887888788787888888888888882ffffff7fff7f7ff73f7fffff7ffffffffffffffffff4999999979997979999999999999999999999994ff
2877777888788787887888788787888888888888882ffffff77ff7f7f777f777ff77ffffffffffffffffff4977799977797979999999999999999999999994ff
2887778888788787887888788787888888888888882fffffffffffffffffffffffffffffffffffffffffff4977799999797979999999999999999999999994ff
2888788887778777878887778777888888888888882fffffffffffffffffffffffffffffffffffffffff774977799977797779999999999999999999999994ff
2222222222222222222222222222222222222222222fffffffffffffffffffffffffffffffffffffff77774444444444444444444444444444444444444444ff
22222222222222222222222222222222222222222222222222222222222222222222222222222222277777777777222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222777777777777722222222222222222222222222200000022
822222222888888888888888888888888222222228888888888888888888888882222222777877787777777777777888822222222888888888888888066d6088
82cc777c28888888888888888888888882cc777c28888888888888888888888882cc777777777777777777777000778882c0007c2888800088888888066d6088
82c777cc28888888888888888888888882c777cc28888888888888888888888882c7777777777777777777777060000082c06000008880600000008000dd0000
82777ddd28888888888888888888888882777ddd28888888888888888888888882777d77777777777777777770066660827006666088000d66666000d6666660
82222222288888888888888888888888822222222888888888888888888888888222227777777777777777770046ddd0820046ddd088044450440004d4440000
88888888888888888888888888888888888888888888888888888888888888888888888777777777777777770444500088044450008804400000080440500888
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7777777777777777044000hhhh044000h0bb00000hhhhh000000hhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7777777777777700007hhhhh0000hhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a7777777777777777hhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9a9777777777777hhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hh777777777hhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777ahha77777hhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777ahh9a77a9hhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hhh9aa9hhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9hhh9aa9hhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9hhh9a77a9hhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhh4222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hha7777ahhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhh427772hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777ahha7777ahhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhh427hfh7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777ahh9a77a9hhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhh24fhfhfhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hhh9aa9hhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhh427fff44hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhh2477777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9hhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhh24777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhh22h22hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhhh9aa9777ahhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hhh9a77a977ahhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777hha7777a7a9hhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7hhhh9aa97aa9hhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a99hhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa97ahhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa9hhhhh9a77a9ahhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh0000000000000009a77a9000ha7777a9hhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh000000000000000a7777a000ha7777ahhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh000000000000000a9aa9a000h9a77a9hhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh0000000000000009a77a9000hh9aa9hhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh000000000000000a7777a000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh000000000000000a7777a000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh0000000000000009a77a9aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh0000000000000000hhhhhhhhhhhhhhhh00000000000000009aa9a77a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh000a7777ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh0009aa97ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh009a77a99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh00a7777ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh009aa97ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh09a77a99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh0a7777a0hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh0a7777a0hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh000000000000000009a77a909aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh0000000000000000009aa909a77a9hhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000000000000000000a7777ahhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh000000000000000000000009aa97ahhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000000000000000009a77a99hhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000000000009aa900a7777ahhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh0000000000000009a77a90a7777ahhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh000000000000009aa977a09a77a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhh4222hhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhh9a77a97a009aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhh427772hhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhha7777aa9000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhh427hfh7hhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhha7777a90000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhh24fhfhfhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhh9a77a9aa900hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhh427fff44hhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhh9aa9a77a90hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhh2477777hhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh0a7777a0hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhh24777hhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhhh9aa977a0hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhh22h22hhhhh
hhhhhhhhhhhhhhhhhhhhhhhhh00000000hhhhhhhhhhhhhhhh00000000hhhhhhh9a77a9a90hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh000000000000000a7777a900hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh0000000000000009aa97a000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh000000000000009a77a99000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh00000000000000a7777a0000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh00000000000000a779aa9000hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh000000000000009a9a77a900hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh0000000000000009a7777a00hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhh000000000000000000000000hhhhhhhh0000000000000009aa977a00hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa977a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a97ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh99aa99hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9aa977ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhh4222h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a97ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhh427772
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777aa9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhh427hfh7
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha9aa9a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhh24fhfhf
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh9a77a9hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhh427fff4
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhha7777ahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhh2477777
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhh24777h
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh97777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhh22h22
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhh0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bbhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh547777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0bhhb000hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh567777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd566777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd6666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbhbbb00bhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh8h8hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbhhb0b0hhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhbbbbbbbbhhhhhhhhhhhhhhh
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
82222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888882222222288888888888888888888888
82cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c288888888888888888888888
82c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc288888888888888888888888
82777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd288888888888888888888888
82222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888882222222288888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
2222hhhhhhhhhh222222hhhhhhhhhh222222hhhhh44244244ffffffffhhhhh222222hhhhhhhhhh222222hhhhhhhhhh222222hhhhh44244244ffffffffhhhhh22
222222hhhhhhh222222222hhhhhhh222222222hhh44244244ffffffffhhhh222222222hhhhhhh222222222hhhhhhh222222222hhh44244244ffffffffhhhh222
hdhd222hhhh222hdhdhd222hhhh222hdhdhd222hh42244444ffffffffhh222hdhdhd222hhhh222hdhdhd222hhhh222hdhdhd222hh42244444ffffffffhh222hd
hdhhd22hhhh22dhdhdhhd22hhhh22dhdhdhhd22hh42444442ffffffffhh22dhdhdhhd22hhhh22dhdhdhhd22hhhh22dhdhdhhd22hh42444442ffffffffhh22dhd
ddhdhh22hh22dhdhddhdhh22hh22dhdhddhdhh22h42424442ffffffffh22dhdhddhdhh22hh22dhdhddhdhh22hh22dhdhddhdhh22h42424442ffffffffh22dhdh
22dfdd22f422444d22dfdd22f422444d22dfdd22f44424442ffffffff422444d22dfdd22f422444d22dfdd22f422444d22dfdd22f44424442ffffffff422444d
222dff22f422ddd2222dff22f422ddd2222dff22f44444444ffffffff422ddd2222dff22f422ddd2222dff22f422ddd2222dff22f44444444ffffffff422ddd2
222ddd22f42244d2222ddd22f42244d2222ddd22f44444244ffffffff42244d2222ddd22f42244d2222ddd22f42244d2222ddd22f44444244ffffffff42244d2
22d666226622dd6d22d666226622dd6d22d6662266666666666666666622dd6d22d666226622dd6d22d666226622dd6d22d6662266666666666666666622dd6d
dd6d6d22662266d6dd6d6d22662266d6dd6d6d226666666666666666662266d6dd6d6d22662266d6dd6d6d22662266d6dd6d6d226666666666666666662266d6
d6d6d22666622d66d6d6d22666622d66d6d6d226666666666666666666622d66d6d6d22666622d66d6d6d22666622d66d6d6d226666666666666666666622d66
d6d62226666222d6d6d62226666222d6d6d622266666666666666666666222d6d6d62226666222d6d6d62226666222d6d6d622266666666666666666666222d6
22222266666622222222226666662222222222666666666666666666666622222222226666662222222222666666222222222266666666666666666666662222
22227777777777222222777777777722222277777777777777777777777777222222777777777722222277777777772222227777777777777777777777777722
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000000040100040403040101010100000001030300110403030411030101030b0b0b010101040101010101030104030b0b0b01010100011101010103010400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404041339393939393939393939393939391539393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040c39393939393939393939393939390c28282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070739393939393939390707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000021212100000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000000021210000000000000404000000210000002100000000000004280707070739393939393907070707282727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000002100210000000000000404000000000000210000000000000004070707070808080808080808070707072727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000000210000000000000000040c07070707393939393939070707070c2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000021212121210000000004040000002121212121000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070717393939393939170707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000042817171739393939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
040000000000000000000000000000040400000000000000000000000000000404000000000000000000000000000004393939393939393939393939393939391c2a2a2b1c1c2a2a2b1c1c2a2a2b1c1c1c2a2a2b1c1c2a2a2b1c1c2a2a2b1c1c1c2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b3b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b
040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404393939393939393939393939393939391c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c
1339393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
0c39393939393939393939393939390c28282928282829282828292828282928282829280c282928280c2928282829282828292828282928282829282828292828282928282829280d282928282829282828292828282928282829282828292828280c2828282928282829282828292828282928282829282828292828282928
0d07070739393939393939390707070d21212223272121213131313131212727272731210d080b08080d2121272727271a271a27271a2d271c21211a27271a270d212121212131210d2c2d2e272c2d2e2627242521212425212127272425272727270d2121312727272727313127272727272721212727212127272121272727
0d07070707393939393939070707070d21213233212131273121212721313127272727270f081b08080f272727272727272727273d271d2727272727272727270d213131272121210d3c3d3e273c3d3e2027343536363435212727273435272727270d2127271a1a272727272727272727272e0c28282928282928280c2c2727
0d07070707040404040404070707070d212131302727272727273127272121312727271a1f090909091f1a2727272727272727272727190a0a0a0a0a1c27272728282828272828280d272727272727272027262727272425362026272720272727270d2727271a1a271a27272727272727273e0d3127272727273131283c2727
0d070707071c1c1c1c1c1c070707070d21263627272727272727272727273127272727272727272727272727272727272727272727272727272727272727272727272727272727270d272727272727272620263626273435272727272720263627270d271a271a1a271a27270e2727272727270d272727272727272727272727
0d07070707393939393939070707072826262027272727272727272721272721272c2d2e2727272727272c1d2e27272727272c2d2e27273d2727273d2727272727272727272727270d27272727272d272727272726272425272727272726272727270d271a271a1a1a1a27270d27272727273d0d27272727272727270c272727
0607070707040707070704070707070720242527272716272727272727272127273c3d3e2727270527273c3d3e27272727273c3d3e2727272727272727272727272c2d2e272c2d2e0f2c2d2e27272d272727272736273435272736272726272727270d271a1a1a1a1d2727270d27272727272728272c272a2b272e270d3d2727
0c07070707391717171739070707070c303435272727272727272727272731272727272727272727272727272727272727272727272727272727272c2d2e2727273c3d3e273c3d3e1f3c3d3e27272d273636272727272627272720272720272727270d27271d1a1a2d2727270d27272727272727273c273a3b273e270d272727
0d07070707393939393939070707070d303026272727272727272727312727312727272727272727272727272727272727272727272727272727273c3d3e272727272727272727272727272727273d272720272727272727272736272720272727270f2727190a0a152727270d27272727272e0c27272727272727270d2c2727
0d07070707040404040404070707070d362030212727272727272727272121212727272c2d2e27272c2d2e2727272727273d27273d27273d2727272727272727272727272727272727272727272727272736272727272027272726272727272727271f27273d3d3d3d2727210d21272727273e0d27272727272727270d3c2727
0d07070707393939393939070707070d263620202024252627222321213127272727273c3d3e27273c3d3e2727272727210a0a0a0a0a0a0a0a0a272727272727272c2d2e272c2d2e270a0a0a0a0a0a0a272627272727202727273627272727272727272727272727272727210d21272727272728282829282829282828272727
0d07070717393939393939170707070d263636202634353636323321212626272727272727272727272727272727272721272727272727272721272727272727273c3d3e273c3d3e2721272721272721272031212131262727272627272727272727272727272727272727210d21272727272721212727212127272121272727
2817171739393939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
3939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939393939
1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c
__sfx__
000100001a0601f000230002100000000000003400039000000003c000000000000029000290002d00036000000003b0003e0003c00000000300002200014000090001900022000260002400000000000001d000
