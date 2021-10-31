pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- -- birds with guns --
--by gouspourd,yolwoocle,notgoyome

function _init()
	--mouse
	mx=0
	my=0
	
	--camera
	camx=0
	camy=0
	targetcamx=0
	cam_follow_player=true
	shake = 0
	
	trainpal = {{8,2},{11,3},{7,13},{10,9}}
	pal_n = 1
	
	menu = "main"
	
	wagonlen = 4
	
	debug=""
	cde = 5
	
	actors = {}
	init_enemies()
	
	init_ptc()
	
	gen_train()
	update_room()
	random = {}
	
	enemies = {}
	parcourmap()
	
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
	
	if menu == "game" then
		delchecker()
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
	
	cls()
	
	--draw map
	draw_map()
	
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
		birdchoice=flr(rnd(12))
	end
	init_player(112+birdchoice)
	
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
	add(players, 
	{
		n=1,
		
		x=-64,y=-64,
		dx=0,dy=0,
		a=0,
		
		spd=.4,
		fric=0.75,
		
		bx=2,by=2,
		bw=4,bh=4,
		r=2,
		
		life=10,
		maxlife=10,
		ammo=250,
		maxammo=250,
		
		spr=bird,
		
		gun=copy(guns.revolver),
		gunn=guns.revolver,
		gunls={guns.revolver,guns.shotgun,guns.sniper,guns.machinegun,guns.assaultrifle}
	})
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
		if(p.a<.75and.25<p.a)p.flip=true
		
		--shooting
		if stat(36) ==1 or stat(36) ==-1 then
		sfx(0)
			p.ammo -= 1
			p.gunn = nextgun(p)
			p.gun=copy(p.gunn)
			p.gun.timer = p.gun.cooldown/2
		end
		
		local fire=stat(34)&1 > 0
		local active=stat(34)&2 > 0
		
		p.gun:update()
		if fire and p.gun.timer<=0 
		and p.ammo > 0 then
			make_ptc(p.x+cos(p.a)*6+4, 
			p.y+sin(p.a)*3+4, rnd(3)+6,7,.7)
			
			p.gun:fire(p.x+4,p.y+4,p.a)
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
	rectfill(camx+87,1,camx+126,7,4)
	rectfill(camx+88,2,camx+125,6,9)
	s = tostr(p.ammo-200)
	spr(110,camx+89,2)
	print(s, camx+95,2,7)
	--weapon list
	for i=1,#p.gunls do
		ospr(p.gunls[i].spr, 
		camx+90+(i-1)*10, 10)
	end
end

function nextgun(p)

 local f = 0
 for i=1,#p.gunls do
 if p.gunls[i] == p.gunn then
 if (((i+stat(36))%#p.gunls)<1) f = #p.gunls
	 return p.gunls[(i+stat(36))%(#p.gunls)+f]
	end
	end
end

-->8
--gun & bullet

function make_gun(name,spr,cd,
spd,oa,dmg,is_enemy,fire)
	--todo:not have 3000 args
	local gun = {
		name=name,
		spr=spr,
		spd=spd,
		oa=oa,--offset angle in [0,1[
		dmg=dmg,
		shake=shake,
		
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
		if not gun.is_enemy then
			if(shake<3)shake+=1 
		end
		
		spd = spd or gun.spd
		spawn_bullet(x,y,dir,
		spd,3,s,dmg,is_enemy)
		gun.timer = gun.cooldown
	end
	
	gun.update=function(gun)
		gun.timer = max(gun.timer-1,0)
		if gun.burst > 0 then
			gun:shoot(gun.x,gun.y,gun.dir)
			gun.burst -= 1
		end
	end
	
	return gun
end

guns = {
	debuggun = make_gun("debuggun",
--spr cd spd oa dmg isenemy
		64, 1, 3, .02,10, false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),

	revolver = make_gun("revolver",
--spr cd spd oa dmg is_enemy
		64, 15,3, .02,3   ,false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	shotgun = make_gun("shotgun",
--spr cd spd oa dmg is_enemy
	 65, 60,4, .05,1,  false,
	 function(gun,x,y,dir)
	 	for i=1,8 do
	 		local o=rnd(.1)-.05
	 		local ospd=gun.spd*(rnd(.2)+.9)
	 		gun:shoot(x,y,dir+o, ospd)
	 	end
	 end),
	 
	machinegun = make_gun("machinegun",
--spr cd spd oa dmg is_enemy
		66, 7, 3, .05,2   ,false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	assaultrifle = make_gun("assault rifle",
--spr cd spd oa dmg is_enemy
		67, 30,4, .02,1   ,false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun.burst = 4
			gun.x, gun.y = x, y
			gun.dir = dir
			gun:shoot(x,y,dir)
		end
	),
	
	sniper = make_gun("sniper",
--spr cd spd oa dmg is_enemy
		68, 40,7, .0, 5  ,false,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	),
	
	gunslime = make_gun("gunslime",
--spr cd spd oa  dmg is_enemy
		64, 100,0.9, .02,1,  true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	,true),
	
	snipeurpisto = make_gun("gunslime",
--spr cd spd oa  dmg is_enemy
		64, 100,2.5, 0, 5, true,
		function(gun,x,y,dir)
			dir+=rnd(2*gun.oa)-gun.oa
			gun:shoot(x,y,dir)
		end
	,true),
	
	shotgunmechant = make_gun("shotgunmechant",
--spr cd spd oa dmg is_enemy
	 65, 60,2, .05,1,  true,
	 function(gun,x,y,dir)
	 	for i=1,8 do
	 		local o=rnd(.1)-.05
	 		local ospd=gun.spd*(rnd(.2)+.9)
	 		gun:shoot(x,y,dir+o, ospd)
	 	end
	 end),
}

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
			if circ_coll(p,b) then
				p.life -= b.dmg
				p.dx+=b.dx*b.spd*2
				p.dy+=b.dy*b.spd*2
				make_ptc(b.x,b.y,rnd(4)+6,7,.8)
				b.destroy_flag = true
			end
		end
		
	else
		
		for e in all(enemies)do
			-- circle coll (dist squared)
			if circ_coll(e,b) then
				e.life -= b.dmg
				if (e.dx+e.dy<30) then
				e.dx+=b.dx*b.spd*.1
				e.dy+=b.dy*b.spd*.1
				end
			
				e.timer = 5
				make_ptc(b.x,b.y,rnd(4)+6,7,.8)
				b.destroy_flag = true
				return
			end
		end
	end
	
	--destroy on collision
	if is_solid(b.x,b.y) or b.x+11<camx or b.x>camx+128+11 then
		if check_flag(1,b.x,b.y) then
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
			if(#nums>0)n=nums[flr(rnd(6))]--#nums
			train[w+j]=n
			del(nums,n)
			
		end
		train[w+wagonlen-1] = 8
	end
	
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
		
		shake += 10
		
	end 
end

function update_room()
	for i=0,3 do
		local w=wagon_n*wagonlen + i
		clone_room(train[w],i)
	end
end

function draw_map()
	if(pal_n>#trainpal) pal_n=1
	pal(8,trainpal[pal_n][1])
	pal(14,trainpal[pal_n][2])
	
	draw_ghost_connector()
	map()
	reset_pal()
	draw_random()
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
      if fget(mget(x,y),2) and ceil(rnd(20))==1 then
       
       spenemie(x * 8,y * 8,enemy.slime)
      end
      if mget(x,y)==5  then
       spenemie(x * 8,y * 8,enemy.juggernaut)
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
		r=5,
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
	
 slime=make_enemy(
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
	 x,y,98    ,1.5  ,30  ,2.5   ,  
--chase,seerange
  true,8, 
	 guns.shotgunmechant),


}

end

function spenemie(x,y,name)
 local a=copy(name)
 a.x = x
 a.y = y
 a.gun = copy(a.gun)
 a.gun.cooldown += rnd(180)-60
 if a.x<175 then
  a.gun.timer += 60
  a.timer = 60
 end
 
	add(enemies,a)
end

function update_enemy(e)
	for i in all(enemies) do
	if(i.life<1)  make_ptc(i.x+4,i.y+4,rnd(4)+10,8,.8) del(enemies,i)
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
		
		i.x += i.dx
		i.y += i.dy
	end
	end
end

function draw_enemy(e)
	spr(e.spr, e.x,e.y)
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
  
  e.dx+=x*(e.spd/30)
  e.dy+=y*(e.spd/30)
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
end

function make_ptc(x,y,r,col,fric,dx,dy)
	fric=fric or rnd(.1)+.85
	dx=dx or 0
	dy=dy or 0
	add(particles, {
		x=x,  y=y,
		dx=dx,dy=dy,
		fric=fric,
		
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
	circfill(p.x,p.y,p.r,p.col)
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


__gfx__
0000000000000000000000000000000000000000181811816666666d7777777644444444444444444444444444444444eeeeeeeeee1111ee11eeee11ee1111ee
00000000000000000000000000000000000000008118111165d11d557d6666dd24444422444444444444444424400422eeeeeeeeee1111ee1eeeeee1ee1111ee
0070070000000000000000000000000000000000181811816d1111d57666666d22244444222222224444444422200444ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000000000000811881816d1111d57666666d444442242222222244444444444d0224ee1111eeee1111eeee1111eeee1111ee
0007700000000000000000000000000000000000111111116dd11dd57666666d444444444444444444444444444d4444ee1111eeee1111eeee1111eeee1111ee
0070070000000000000000000000000000000000818188816dd11dd57666666d422244444444444444444444422d4444ee1111eeee1111eeee1111eeee1111ee
00000000000000000000000000000000000000008881881165dddd557d6666dd44444444222222222222222244464444ee1111eeee1111eeee1111ee8eeeeee8
000000000000000000000000000000000000000081818881d55555556ddddddd22222222222222222222222222262222ee1111eeee1111eeee1111ee88eeee88
00000000000000000000000000000000000000004444444112211111555555554424424414444444111bb111444644446666666614444441eeeeeeee888e8ee8
00000000000000000000000000000000000000004444444121124111555555554424424414444444111331b1244644226666666614444441eeeeeeee888e8ee8
00000000000000000000000000000000000000004444444111444421ffffffff42244444144444441b13313122264444666666661444444111111111888e8ee8
00000000000000000000000000000000000000004444444112244421ffffffff42444442144444441313333144464004666666661446444111111111888e8ee8
00000000000000000000000000000000000000004444444124224221ffffffff424244421444444413333411444d0440666666661443444111111111888e8ee8
00000000000000000000000000000000000000004444442124422211ffffffff44424442124444441143341142ddd4407777777714b3344111111111188e8ee1
00000000000000000000000000000000000000002222222112424421ffffffff44444444122222221144441100444404dddddddd14bb3441eeeeeeee118e8e11
00000000000000000000000000000000000000002222221112212221ffffffff44444244112222221122221122000022dddddddd14b33441eeeeeeee11111111
44444441ffffffff111111111111111111111111111111114444444111111111eeeeeeeeeeeeeeee111112222221111166111111144444411111116611755d11
44444441f444444ffffff1111111111111111111111111114444444111111111eeeeeeeeeeeeeeee111122222222211166611111144444411111166611765d11
44444441f4f4f4fff44ff111111111111444444444444411444444411111111188888888eeeeeeee112221d1d1d2221166611111144444411111166611765d11
22222221f4f4f4fff4ffffffffffffff1444444444444411222222211111111188888888ecc777ce1122d1d1d11d221166611111144444411111166611765d11
d16161d1fffffffff4f4ff444444444f1444444444444411d16861d11111111188888888ec777cce122d1d1dd1d1122155611111144444411111165511755d11
6161d1d144444444fff4ff4f4f4f4f4f14444444444444116868d9d11111111188888888e777ddde422444d22dfdd22f66566611144444411166656611756d11
61d1d1d142424244ff44ff4f4f4f4f4f122222222222221161d9d1d11111111188888888eeeeeeee422ddd2222dff22f66666661144444411666666611756d11
2222222144444444ffffff4f4f4f4f4f1d1d1d1d1d1616112222222111111111888888888888888842244d2222ddd22f66666661144444411666666611756d11
666666611111111144444fffffffffff1d1d1d16161717114444444111111111ffffffffffffffff622dd6d22d66622666666661144444411666666611111111
66666661ffffffff42224444444444441d161617b71717114444444111411441ffffffffffffffff62266d6dd6d6d226556555611444444116555655111dd111
6666666177777777422fffff222222241617c79717b616114444444114444144ff3fffffffffffff6622d66d6d6d226655566651144444411566655511dddd11
ddddddd177777777444f4f4f2424242417c717a6b6b6bd112222222112424214ff3f3fffffffffff66222d6d6d62226655566661144444411666655511dddd11
51d1d151ffffffff111fffff4444444417c6c626b6bd2d11d16a61d122222411ff3f3fffffffffff6662222222222666555666611222222116666555115dd511
d1d1515144444444111444441111111116c6262d2d2d2d11d9da6a6124424441ffffffffffffffff777772222227777755566661122222211666655511155111
d1515151411141441114222411111111162d2d2d2d2d2d11d1d9d16112422421ffffffffffffffffdddddddddddddddd55555551111661111555555511111111
ddddddd144444444111444441111111112222222222222112222222111211211ffffffffffffffffdddddddddddddddd55555551111661111555555511111111
000000000000000000000000000000000066d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000066d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000060000000000000000ddd000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0066660000d666660446d6d6446664000d6666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
046ddd00444504404440500044ddd4dd4d4440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44450000440000004400500040405000440500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44000000000000000000000000405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111222222221111111111111111222222221111111155555555444444445555555522222222444444445555552800000000000000000000000000000000
1111111122222222111111111111111122222222112ee21155555555444444445555555522222222cd4444445555288800000000009aa90000000000008ee800
115dd511222222221111111111288821222222221eeeee215567765544446776555eee5522222210cccd4444555288880000000009a77a900000000008e77e80
17dddd51225335221111111112888882222222102eeeffe157777775444777775efffff2222220007cccd44455d888e7000000000a7777a0000000000e7777e0
557d22d12333339a111111111822888892222100ee1ef0e1d677766d446777dd2fffff2222210000c77ccd4455667777000000000a7777a0000000000e7777e0
157d882553333aaa1111111112678866aa92009aee1ee7e1ddd77ddd44777d0622ff22052100000070dc1114566777770000000009a77a900000000008e77e80
1dd8188d33339aa21111111116772666aaaaa0cce2127f7190077009447776065028e00549994000700c0111510aa77700000000009aa90000000000008ee800
1dd8188d3003a44211242111177066119aaa0c1cee11fff17909a097444977665f8888fe21109990777cc044d0a22a7000000000000000000000000000000000
15dd88dd30139444994442111760566699aa0c1cee2100f1777997774499aa77f822228f2222a0001777764467a211a000000000000000007770000000000000
53ddddd553333994a941422116000666e9909acc2ee000116799a977499a777782e8882f2222a910117776446791199700222200002222000000000011110000
33d3ddd1253333391a742222161006688e00aaa71ee001110719a16749a67777fffeeffe22227aa9c17774446789997702888820028888207770000010010110
3233d3512233333216777222111288882807777712ee21110600a017444677775feeeff52222777acc1764447788887728e8888228e888827770000011110110
2223333122533372116777611128888225777777e11ee2110100900644d677775eeeee2522267777cd71444477e8887728818182288181827770000011111111
2222232226557744411e1e111928882827777777ee12ee1100000010d6666777552eee2522267777d776444477788e7728212182282121820000000011111111
62626226d66d554424e11e11aa8889a805777777ee21ee211000001066666677555eeee222277777777444447777777728222282282222820000000010011001
6666626666666dd51224e421cca88caa00057777eee12ee110010000666666665552eeee22277777776444447777777702222220022222200000000001100110
11115d1111113b111111111111288e1110001111111eeee111167711111167111111eef111000011dccccd111111888111d66dd5000000000000000011100000
1115ddd1111333b111111111127078710779aa01111e7075116079a1111677711111f0ee1000000111c777c1117888811d6777dd000000000000000017110000
11152dd111130aa111111111127770770c799990e111ee151167799a1116079951111ff100a70999111d707d167779aa6777776d000000000000000017711000
5113dd7711133a991111441118870066077888892eeeee11100005191166777115544ff10000aa111111d771677077887772777d000000000000000017771000
56623331dddd334111414691aa88881100770118122ee1111000005166666671545544e100077611cd7ccc71677777787728e776000000000000000017111000
d566222116664441111461111baa821100000111117171110007000156666771feff4411000776111cd7c7616677776167787776000000000000000011100000
1d666611116444111111111111cc2111100011111171711117700011157776111e11e11100776611117776111667761117777611000000000000000000000000
118181111191911111111111115151111c1c11111121211111911911111e1e111e11e11100755001111515111191911111761111000000000000000000000000
93939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939393939383839393939383939393839393
93939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939393939383839393939383939393839393
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
7273223272617272727272727272a1f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727223337272727261d27272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
7272727272727273d173d372727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272d2d272727261617272727272f2727272720000727200000072727272f2727272720000727200000072727272f2727272720000727200000072727272f2
727272720000007200000072727272f2727272720000007200007272727272f2727272720000007200000072727272f2727272720000007200000072727272f2
727273d173d372d3d261d372727272f2727272727200727272720072727272f2727272727200727200720072727272f2727272727200727200720072727272f2
727272727272007200720072727272f2727272727272007272007272727272f2727272727272007272720072727272f2727272727272007272720072727272f2
72727261d272727291517272725072f2727272727200727272720072727272f2727272727200727200000072727272f2727272727200727200000072727272f2
727272720000007200720072727272f2727272720000007272007272727272f2727272720000007200000072727272f2727272720000007272000072727272f2
7272d3d2d2d3727272727272727272f2727272727200727272720072727272f2727272727200727200720072727272f2727272727200727272720072727272f2
727272720072727200720072727272f2727272720072727272007272727272f2727272720072727200727272727272f2727272720072727272720072727272f2
727272915172727272727272727272f2727272720000007272720072727272f2727272720000007200000072727272f2727272720000007200000072727272f2
727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
72727272727272c272d17261727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
72721373127272c372d372e37272a1f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
93a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b281
93a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b281
c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1
c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1
93939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939393939383839393939383939393839393
93939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939393939383839393939383939393839393
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272720000007200720072727272f2727272720000007200000072727272f2727272720000007200727272727272f2727272720000007200000072727272f2
727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200007272727272f2
727272727272007200720072727272f2727272727272007200727272727272f2727272727272007200727272727272f2727272727272007272720072727272f2
727272727272007200720072727272f2727272727272007200720072727272f2727272727272007200720072727272f2727272727272007272007272727272f2
727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007272720072727272f2
727272720000007200000072727272f2727272720000007200000072727272f2727272720000007200720072727272f2727272727200007272007272727272f2
727272720072727272720072727272f2727272720072727272720072727272f2727272720072727200720072727272f2727272720072727272720072727272f2
727272720072727200720072727272f2727272720072727272720072727272f2727272727272007200720072727272f2727272727272007272007272727272f2
727272720000007272720072727272f2727272720000007200000072727272f2727272720000007200000072727272f2727272720000007272720072727272f2
727272720000007200000072727272f2727272720000007272720072727272f2727272720000007200000072727272f2727272720000007200000072727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
82829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282
93a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b281
93a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b28193a2b2a2b2a2b281
c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1
c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1c1a3b3a3b3a3b3c1
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
6ffff66fffff3fffffff3fffffffffffffffffffffffffffffffffffffff3fffffffffffffffffffffffffffffff3fffffffffffffffffffffffffffffffffff
6fffff6fffff3f3fffff3f3fffffffffffffffffffffffffffffffffffff3f3fffffffffffffffffffffffffffff3f3fffffffffffffffffffffffffffffffff
6fffff6fffff3f3fffff3f3fffffffffffffffffffffffffffffffffffff3f3fffffffffffffffffffffffffffff3f3fffffffffffffffffffffffffffffffff
6fffff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
666ff66fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
88222222228888888888888888888888882222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888
882cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c28888888888888888888888
882c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc28888888888888888888888
882777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd28888888888888888888888
88222222228888888888888888888888882222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
ffhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhh2222hhhhhhhh
4ffffffhhhhhhhhhhhhhhhhhhhf444444ff444444ff444444ffffffffffffffffffffffffffffffffffffffffff444444fhhhhhhhhhhhhhhhhh288882hhhhhhh
fff44ffhhhhhhhhhhhhhhhhhhhf4f4f4fff4f4f4fff4f4f4ff7777777777777777777777777777777777777777f4f4f4ffhhhhhhhhhhhhhhhh28e88882hhhhhh
fff4ffffffffffffffhhhhhhhhf4f4f4fff4f4f4fff4f4f4ff7777777777777777777777777777777777777777f4f4f4ffhhhhhhhhhhhhhhhh288h8h82hhhhhh
fff4f4ff444444444fhhhhhhhhffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffhhhhhhhhhhhhhhhh282h2h82hhhhhh
44fff4ff4f4f4f4f4fhhhhhhhh444444444444444444444444444444444444444444444444444444444444444444444444hhhhhhhhhhhhhhhh28222282hhhhhh
44ff44ff4f4f4f4f4fhhhhhhhh4242424442424244424242444hhh4h444hhh4h444hhh4h444hhh4h444hhh4h4442424244hhhhhhhhhhhhhhhhh222222hhhhhhh
44ffffff4f4f4f4f4fhhhhhhhh444444444444444444444444444444444444444444444444444444444444444444444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
ff44444fffffffffffffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
4f4222444444444444f444444ff444444fffffffffhhhhhhhhfffffffff444444ff444444fhhhhhhhhf444444fffffffffffffffffhhhhhhhhhhhhhhhhhhhhhh
ff422fffff22222224f4f4f4fff4f4f4ff77777777hhhhhhhh77777777f4f4f4fff4f4f4ffhhhhhhhhf4f4f4ff7777777777777777hhhhhhhhhhhhhhhhhhhhhh
ff444f4f4f24242424f4f4f4fff4f4f4ff77777777hhhhhhhh77777777f4f4f4fff4f4f4ffhhhhhhhhf4f4f4ff7777777777777777hhhhhhhhhhhhhhhhhhhhhh
ffhhhfffff44444444ffffffffffffffffffffffffhhhhhhhhffffffffffffffffffffffffhhhhhhhhffffffffffffffffffffffffhhhhhhhhhhhhhhhhhhhhhh
44hhh44444hhhhhhhh444444444444444444444444hhhhhhhh444444444444444444444444hhhhhhhh444444444444444444444444hhhhhhhhhhhhhhhhhhhhhh
44hhh42224hhhhhhhh42424244424242444hhh4h44hhhhhhhh4hhh4h444242424442424244hhhhhhhh424242444hhh4h444hhh4h44hhhhhhhhhhhhhhhhhhhhhh
44hhh44444hhhhhhhh444444444444444444444444hhhhhhhh444444444444444444444444hhhhhhhh444444444444444444444444hhhhhhhhhhhhhhhhhhhhhh
ffhhhhhhhh6666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffhhhhhhhhhhhhhhhhhhhhhh
4fffffffff6666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhf444444ff444444fffffffffhhhhhhhhhhhhhh
ff777777776666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhf4f4f4fff4f4f4ff77777777hhhhhhhhhhhhhh
ff77777777dddddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhf4f4f4fff4f4f4ff77777777hhhhhhhhhhhhhh
ffffffffff5hdhdh5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffffffffffffffffffffhhhhhhhhhhhhhh
4444444444dhdh5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh444444444444444444444444hhhhhhhhhhhhhh
444hhh4h44dh5h5h5hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhh42424244424242444hhh4h44hhhhhhhhhhhhhh
4444444444dddddddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh444444444444444444444444hhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhhhhhhh
2h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhhhhhhh
dhdh6a6hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
dhd9da6a6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
dhdhd9dh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhhhhhhhh
2h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444fhhhhhhhhhhhhhhhhf444444fhhhhhhhhhhhhhh
4h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhh
2h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhh
dhdh6h6hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhh
dh6h6hdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhh
dh6hdhdhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh42424244hhhhhhhhhhhhhhhh42424244hhhhhhhhhhhhhh
2h2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444fhhhhhhhhhhhhhhhhhhhhhh
44444444hhhhhhhhhhhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhhhhhhh
44444444hhhhhhhhhhhhhhhhhhhhhhhhhh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4ffhhhhhhhhhhhhhhhhhhhhhh
44444444hhhhhhhhhhhhhhhhhhhhhhhhhhdh686hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
44444444hhhhhhhhhhhhhhhhhhhhhhhhhh6868d9dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
22222222hhhhhhhhhhhhhhhhhhhhhhhhhh6hd9dhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh42424244hhhhhhhhhhhhhhhhhhhhhh
hdhdh6h6hhhhhhhhhhhhhhhhhhhhhhhhhh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
h6h6h7h7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
h7b7h7h7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
97h7b6h6hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhhhhhhh
a6b6b6bdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4446dddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhhhhhhhhhhhhhhhhh
26b6bd2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4h46945hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhhhhhhh
2d2d2d2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4644hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
2d2d2d2dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhhhhhhhh
22222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhhhhhhhh
6h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
6h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhhhhffffffffhhhhhhhhhhhhhh
6h4444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhh7hhhhhhhh77777777hhhhhhhhhhhhhh
dh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77777777hhhhhhh77hhhhhhh77777777hhhhhhhhhhhhhh
5hdh686hdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffhhhhhhh777hhhhhhffffffffhhhhhhhhhhhhhh
5h6868d9dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhh7hhhhhhhh44444444hhhhhhhhhhhhhh
5h6hd9dhdhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhhhh4hhh4h44hhhhhhhhhhhhhh
dh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhhhh44444444hhhhhhhhhhhhhh
4h6666666hffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffffffffffhhhhhhhhhhhhhh
4h6666666hf444444fhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf444444ff444444ff444444fhhhhhhhhhhhhhh
4h6666666hf4f4f4ffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4fff4f4f4fff4f4f4ffhhhhhhhhhhhhhh
2hdddddddhf4f4f4ffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhf4f4f4fff4f4f4fff4f4f4ffhhhhhhhhhhhhhh
dh5hdhdh5hffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffffffffffhhhhhhhhhhhhhh
dhdhdh5h5h44444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh444444444444444444444444hhhhhhhhhhhhhh
dhdh5h5h5h42424244hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh424242444242424442424244hhhhhhhhhhhhhh
2hdddddddh44444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh444444444444444444444444hhhhhhhhhhhhhh
4h4444444h4444444h4444444hhhhhhhhhhhhhhhhh4444444hhhhhhhhhhhhhhhhhhhhhhhhhffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
4h4444444h4444444h4444444hhhhhhhhhhhhhhhhh4444444hhhhhhhhhfffffhhhhhhhhhhhf444444ff444444fffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
4h4444444h4444444h4444444hh4444444444444hh4444444hhhhhhhhhf44ffhhhhhhhhhhhf4f4f4fff4f4f4ff77777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
2h2222222h2222222h2222222hh4444444444444hh2222222hhhhhhhhhf4fffffffffffffff4f4f4fff4f4f4ff77777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
dhdh6h6hdhdh6h6hdhdh6h6hdhh4444444444444hhdh686hdhhhhhhhhhf4f4ff444444444fffffffffffffffffffffffffhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
6h6h6hdhdh6h6hdhdh6h6hdhdhh4444444444444hh6868d9dhhhhhhhhhfff4ff4f4f4f4f4f444444444444444444444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
6h6hdhdhdh6hdhdhdh6hdhdhdhh2222222222222hh6hd9dhdhhhhhhhhhff44ff4f4f4f4f4f42424244424242444hhh4h44hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
2h2222222h2222222h2222222hhdhdhdhdhdh6h6hh2222222hhhhhhhhhffffff4f4f4f4f4f444444444444444444444444hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
4h4444444h4444444h4444444hhdhdhdh6h6h7h7hh4444444h4444444h44444fffffffffffffffffffffffffff4444444h4444444hhhhhhhhhhhhhhhhhhhhhhh
4h4444444h4444444h4444444hhdh6h6h7b7h7h7hh4444444h4444444h4222444444444444f444444ff444444f4444444h4444444hhhhhhhhhhhhhhhhhhhhhhh
4h4444444h4444444h4444444hh6h7c797h7b6h6hh4444444h4444444h422fffff22222224f4f4f4fff4f4f4ff4444444h4444444hhhhhhhhhhhhhhhhhhhhhhh
2h2222222h2222222h2222222hh7c7h7a6b6b6bdhh2222222h2222222h444f4f4f24242424f4f4f4fff4f4f4ff2222222h2222222hhhhhhhhhhhhhhhhhhhhhhh
dhdh6a6hdhdh6h6hdhdh686hdhh7c6c626b6bd2dhhdh6a6hdhdh6a6hdhhhhfffff44444444ffffffffffffffffdh686hdhdh686hdhhhhhhhhhhhhhhhhhhhhhhh
6hd9da6a6h6h6hdhdh6868d9dhh6c6262d2d2d2dhhd9da6a6hd9da6a6hhhh44444hhhhhhhh44444444444444446868d9dh6868d9dhhhhhhhhhhhhhhhhhhhhhhh
6hdhd9dh6h6hdhdhdh6hd9dhdhh62d2d2d2d2d2dhhdhd9dh6hdhd9dh6hhhh42224hhhhhhhh42424244424242446hd9dhdh6hd9dhdhhhhhhhhhhhhhhhhhhhhhhh
2h2222222h2222222h2222222hh2222222222222hh2222222h2222222hhhh44444hhhhhhhh44444444444444442222222h2222222hhhhhhhhhhhhhhhhhhhhhhh
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
88222222228888888888888888888888882222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888
882cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c28888888888888888888888882cc777c28888888888888888888888
882c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc28888888888888888888888882c777cc28888888888888888888888
882777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd28888888888888888888888882777ddd28888888888888888888888
88222222228888888888888888888888882222222288888888888888888888888822222222888888888888888888888888222222228888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
22222hhhhhhhhhh222222hhhhhhhhhh222222hhhhh44244244ffffffffhhhhh222222hhhhhhhhhh222222hhhhhhhhhh222222hhhhh44244244ffffffffhhhhh2
2222222hhhhhhh222222222hhhhhhh222222222hhh44244244ffffffffhhhh222222222hhhhhhh222222222hhhhhhh222222222hhh44244244ffffffffhhhh22
dhdhd222hhhh222hdhdhd222hhhh222hdhdhd222hh42244444ffffffffhh222hdhdhd222hhhh222hdhdhd222hhhh222hdhdhd222hh42244444ffffffffhh222h
dhdhhd22hhhh22dhdhdhhd22hhhh22dhdhdhhd22hh42444442ffffffffhh22dhdhdhhd22hhhh22dhdhdhhd22hhhh22dhdhdhhd22hh42444442ffffffffhh22dh
hddhdhh22hh22dhdhddhdhh22hh22dhdhddhdhh22h42424442ffffffffh22dhdhddhdhh22hh22dhdhddhdhh22hh22dhdhddhdhh22h42424442ffffffffh22dhd
d22dfdd22f422444d22dfdd22f422444d22dfdd22f44424442ffffffff422444d22dfdd22f422444d22dfdd22f422444d22dfdd22f44424442ffffffff422444
2222dff22f422ddd2222dff22f422ddd2222dff22f44444444ffffffff422ddd2222dff22f422ddd2222dff22f422ddd2222dff22f44444444ffffffff422ddd
2222ddd22f42244d2222ddd22f42244d2222ddd22f44444244ffffffff42244d2222ddd22f42244d2222ddd22f42244d2222ddd22f44444244ffffffff42244d
d22d666226622dd6d22d666226622dd6d22d6662266666666666666666622dd6d22d666226622dd6d22d666226622dd6d22d6662266666666666666666622dd6
6dd6d6d22662266d6dd6d6d22662266d6dd6d6d226666666666666666662266d6dd6d6d22662266d6dd6d6d22662266d6dd6d6d226666666666666666662266d
6d6d6d22666622d66d6d6d22666622d66d6d6d226666666666666666666622d66d6d6d22666622d66d6d6d22666622d66d6d6d226666666666666666666622d6
6d6d62226666222d6d6d62226666222d6d6d622266666666666666666666222d6d6d62226666222d6d6d62226666222d6d6d622266666666666666666666222d
22222226666662222222222666666222222222266666666666666666666662222222222666666222222222266666622222222226666666666666666666666222
22222777777777722222277777777772222227777777777777777777777777722222277777777772222227777777777222222777777777777777777777777772
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0000000404040100040403040101010100000004040300010403030401030101030303030101010401010101010301000303030301010100010101010103010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404041339383939393939393939393939391539393938383939393938393939383939393939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040c39393939383939393939393839390c28282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070739393939393839390707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393938070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000021212100000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000000021210000000000000404000000210000002100000000000004280707070739393939393907070707282727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
040000000021000021000000000000040400000000002100210000000000000404000000000000210000000000000004070707070808080808080808070707072727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000210000210000000000000404000000000000002100000000000004040000000000210000000000000000040c07070707393939393939070707070c2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000002121000000000000000404000000000021212121210000000004040000002121212121000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070707393939393939070707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000040d07070717393939393939170707070d2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f2727272727272727272727272727272f
0400000000000000000000000000000404000000000000000000000000000004040000000000000000000000000000042817171739383939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
040000000000000000000000000000040400000000000000000000000000000404000000000000000000000000000004393939393939393939393939393939393b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b3b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b3b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b3b2a2a2b3b3b2a2a2b3b3b2a2a2b3b3b
040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404393939393939393939393938393939393a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a
1339383939393939393939393939393939393938383939393938393939383939393939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939393939383839393939383939393839393939393838393939393839393938393939393938383939393938393939383939
0c39393939383939393939393839390c28282928282829282828292828282928282829280c282928280c2928282829282828292828282928282829282828292828282928282829280d282928282829282828292828282928282829282828292828280c2828282928282829282828292828282928282829282828292828282928
0d07070739393939393839390707070d21212223272121213131313131212727272731210d080b08080d2121272727271a271a27271a2d151c21211a27271a270d212121212131210d2c2d2e272c2d2e2627242521212425212127272425272727270d2121312727272727313127272727272721212727212127272121272727
0d07070707393939393938070707070d21213233212131273121212721313127272727270f081b08080f272727272727272727273d271d2727152727272727270d213131272121210d3c3d3e273c3d3e2027343536363435212727273435272727270d2127271a1a272727272727272727272e0c28282928282928280c2c2727
0d07070707393939393939070707070d212131302727272727273127272121312727271a1f090909091f1a2727272727272727272727190a0a0a0a0a1c27272728282828272828280d272727272727272027262727272425362026272720272727270d2727271a1a271a27272727272727273e0d3127272727273131283c2727
0d07070707393939393939070707070d21263627272727272727272727273127272727272727272727272727272727272727272727272727272727272727272727272727272727270d272727272727272620263626273435272727272720263627270d271a271a1a271a27270e2727272727270d272727272727272727272727
0d07070707393939393939070707072826262027272727272727272721272721272c2d2e2727272727272c1d2e27272727272c2d2e27273d2727273d2727272727272727272727270d27272727272d272727272726272425272727272726272727270d271a271a1a1a1a27270d27272727273d0d27272727272727270c272727
0607070708080808080808080707070720242527272716272727272727272127273c3d3e2727272727273c3d3e27272727273c3d3e2727272727272727272727272c2d2e272c2d2e0f2c2d2e27272d272727272736273435272736272726272727270d271a1a1a1a1d2727270d27272727272728272c272a2b272e270d3d2727
0c07070707393939393939070707070c303435272727272727272727272731272727272727272727272727272727272727272727272727272727272c2d2e2727273c3d3e273c3d3e1f3c3d3e27272d273636272727272627272720272720272727270d27271d1a1a2d2727270d27272727272727273c273a3b273e270d272727
0d07070707393939393939070707070d303026272727272727272727312727312727272727272727272727272727272727272727272727272727273c3d3e272727272727272727272727272727273d272720272727272727272736272720272727270f2727190a0a152727270d27272727272e0c27272727272727270d2c2727
0d07070707393939393939070707070d362030212727272727272727272121212727272c2d2e27272c2d2e2727272727273d27273d27273d2727272727272727272727272727272727272727272727272736272727272027272726272727272727271f27273d3d3d3d2727210d21272727273e0d27272727272727270d3c2727
0d07070707393939393939070707070d263620202024252627222321213127272727273c3d3e27273c3d3e2727272727210a0a0a0a0a0a0a0a0a272727272727272c2d2e272c2d2e270a0a0a0a0a0a0a272627272727202727273627272727272727272727272727272727210d21272727272728282829282829282828272727
0d07070717393939393939170707070d263636202634353636323321212626272727272727272727272727272727272721272715272715272721272727272727273c3d3e273c3d3e2721272721272721272031212131262727272627272727272727272727272727272727210d21272727272721212727212127272121272727
2817171739383939393939391717172828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928282829282828292828282928
39393939393939393939393939393939392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18392a2b2a2b2a2b18
393939393939393939393938393939391c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c1c3a3b3a3b3a3b1c
__sfx__
000100001a0601f000230002100000000000003400039000000003c000000000000029000290002d00036000000003b0003e0003c00000000300002200014000090001900022000260002400000000000001d000
