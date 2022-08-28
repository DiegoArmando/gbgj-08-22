pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- gbgj 8/22
-- matte l & brian b

--sounds:
--0: computer
--1: pump
--2: yell
--3: crack
--4: tape

player = {}
player.x = 224 
player.speed_x = 0
player.y = 240
player.interactable = "nothing"
player.holding = "nothing"
player.torso = 3
player.legs = 19
player.bobble = 2
player.flip = false

water_level = 0
walk_counter = 0

cam_x = 0
cam_y = 0

room_id = 3

k_left=0
k_right=1
k_up=2
k_down=3
k_interact=4
k_other=5

pump = {}
pump.active = false
pump.timer = 0

computer = {}
computer.progress = 0
computer.cooldown = 0

rooms = {}
-- Trigger format:
-- Upper Left Tile X,Y, Lower Right tile X,Y, Target Room, Target X, Target Y
rooms[1] = { {13,9,15,14,2,33,13} }
rooms[2] = { {29,9,31,4,1}, {48,9,50,14,3} }
rooms[3] = { {58,9,60,14,2}}
rooms[4] = {}
rooms[5] = {}

-- Format: Xmin, Xmax, Ymin, YMax
room_cam_bounds = {}
room_cam_bounds[1] = {0,50}
room_cam_bounds[2] = {224,292}
room_cam_bounds[3] = {32,272,140,252}
room_cam_bounds[4] = {0,50}
room_cam_bounds[5] = {0,50}

-- Interactables are single tiles that do something when you touch them:
interactables = {}
interactables["tape"] = {48, 30, true}
interactables["computer"] = {40, 30, false}
interactables["pump"] = {11,30,false}

-- Bubbles have: Xpos, Age, Size
bubbles = {}

-- Skeletons have: Xpos, Age
skeletons = {}

-- Skeletons pick from this table for x pos
spawn_points = {12,13,17,18,19,20,21,22,23,24,25,
                30,31,32,33,34,35,36,37,
                41,42,43}

-- A skeleton spawns every n seconds
skeleton_timer = 179

-- Cracks in the window can appear in front of skeletons
-- Cracks are key value pairs in the form of XPos,Age
cracks = {}

-- Drips fall from cracks and hit the floor,
-- which increases the water level
drips = {}

-- Frames since last yell
yell_counter = 0
yelling = false

yells = {"shoo!", "git!", "off with you!", "boo!", "begone!"}
cur_yell = ""

input_x = 0
input_interact = false
input_interact_p = false
prev_input_interact = false
input_interact_pressed = 0
axis_x_value = 0
axis_x_turned = false
input_other = false
input_other_p = false
prev_input_other = false
input_other_pressed = 0

function _init()
end

function update_input()
    -- axes
	local prev_x = axis_x_value
	prev_input_interact = input_interact_p
	prev_input_other = input_other_p
	if btn(k_left) then
		if btn(k_right) then
            if axis_x_turned then
                axis_x_value = prev_x
				input_x = prev_x
			else
                axis_x_turned = true
                axis_x_value = -prev_x
                input_x = -prev_x
			end
		else
            axis_x_turned = false
            axis_x_value = -1
            input_x = -1
		end
	elseif btn(k_right) then
        axis_x_turned = false
        axis_x_value = 1
        input_x = 1
	else
        axis_x_turned = false
        axis_x_value = 0
        input_x = 0
    end

    if input_x == 0 then
        walk_counter = 0
    else
        walk_counter += 1
        if walk_counter > 20 then
            walk_counter = 0
        end
    end

	-- input_interact
	local interact = btn(k_interact)		
	input_interact_p = btnp(k_interact)

	if interact and not input_interact then		
		input_interact_pressed = 4
	else
		input_interact_pressed = interact and max(0, input_interact_pressed - 1) or 0
	end
	input_interact = interact

	-- input_other
	local other = btn(k_other)
	input_other_p = btnp(k_other)
	if other and not input_other then		
		input_other_pressed = 1
	else
		input_other_pressed = other and max(0, input_other_pressed - 1) or 0
    end
	input_other = other

end

function check_interactable()
    for i,v in pairs(interactables) do
        if player.x <= (v[1]*8)+8 and player.x+8 >= v[1]*8 and player.y <= (v[2]*8)+8 and player.y+16 >= v[2]*8 then
            return {i,v[1],v[2],v[3]}
        end
    end
    return {"nothing",0,0,false}
end

function _update60()
    -- running
	update_input()
    local target, accel = 0, 0.2
    if abs(player.speed_x) > 2 and input_x == sgn(player.speed_x) then
        target,accel = 2, 0.1
    elseif on_ground then
        target, accel = 2, 0.8
    elseif input_x != 0 then
        target, accel = 2, 0.4
    end
    player.speed_x = approach(player.speed_x, input_x * target, accel)

    player.x += player.speed_x
    if player.x < 80 then player.x = 80 end
    if player.x > 384 then player.x = 384 end
    player.interactable = check_interactable()
    if input_interact then
        if player.interactable[4] then player.holding = player.interactable[1]
        elseif player.interactable[1] == "pump" then pump_activate()
        elseif player.interactable[1] == "computer" then computer_activate()
        end
    end

    animate_player()
    update_pump()
    computer_update()

    if input_other and not yelling then
        yelling = true
        yell_counter = 0
        cur_yell = rnd(yells)
        for key,s in pairs(skeletons) do
            if abs((s[1]*8) - player.x) < 12 and s[2] >= 240 then
                add(spawn_points,s[1])
                skeletons[key] = nil
            end
        end
    end

    if input_interact and player.holding == "tape" then
        for xpos,age in pairs(cracks) do
            if abs((xpos*8) - player.x) < 12 then
                cracks[xpos] = nil
                player.holding = "nothing"
                for s in all(skeletons) do
                    if abs((s[1]*8) - player.x) < 12 and s[2] >= 240 then
                        s[2] = 240
                    end
                end
            end
        end
    end

    if yelling then
        yell_counter += 1
        if yell_counter >= 60 then
            yelling = false
            yell_counter = 0
        end
    end
    
    -- Check for room triggers
    for trigger in all(rooms[room_id]) do
        if player.x > (trigger[1] * 8) and
        player.x < (trigger[3] * 8) and
        player.y > (trigger[2] * 8) and
        player.y < (trigger[4] * 8) then
            room_id = trigger[5]
            player.x = trigger[6] * 8
            player.y = trigger[7] * 8
        end
    end

    -- Every frame we have a 1 in 3 chance of spawning a bubble
    if rnd({1,2,3,4,5}) == 3 then
        add(bubbles, {rnd(392),0,rnd({1,1,1,2,2,3})})
    end

    for b in all(bubbles) do
        b[2] += 1
        if b[2] > 360 then
            del(bubbles, b)
        end
    end

    -- Spawn a skeleton every three seconds
    skeleton_timer += 1
    if skeleton_timer == 180 and count(spawn_points) > 0 then
        local new_skel = {rnd(spawn_points),0}
        add(skeletons, new_skel)
        del(spawn_points,new_skel[1])
        skeleton_timer = 0
    end

    for s in all(skeletons) do
        s[2] +=1
        if s[2] > 600 and cracks[s[1]] == nil then
            cracks[s[1]] = 0
        end
    end

    for k,v in pairs(cracks) do
        cracks[k]+=1
        if cracks[k] == 120 then
            add(drips,{k,0})
            cracks[k] = 0
        end
    end

    for d in all(drips) do
        d[2] += 1
        if d[2] == 24 then
            del(drips, d)
            water_level += 1
        end
    end 
end

--player sprites are 3/4 (torso) and 19/20 (legs)
function animate_player()
    if player.holding == "nothing" then
        player.torso = 3
    else
        player.torso = 4
    end
    if walk_counter > 10 and player.legs == 19 then
        player.legs = 20
        player.bobble = 2
    elseif walk_counter <= 10 then
        player.legs = 19
        player.bobble = 1
    end
    if player.speed_x < 0 then player.flip = true
    elseif player.speed_x > 0 then player.flip = false
    end
end

function draw_water()
    fillp(0b1010010110100101.1)
    local top = (water_level / 100) * 27
    rectfill(80,255-top,391,255,12)
    fillp()
end

function computer_activate()
    if computer.cooldown == 0 then
        computer.cooldown = 90
        computer.progress += 1
        sfx(0)
    end
end

function computer_update()
    if computer.cooldown > 0 then computer.cooldown -= 1 else computer.cooldown = 0 end
    if computer.progress >=25 then exit() end
end

function draw_computer()
    print(computer.progress.."/25",320,230,8)
    line(320,237,320+((computer.progress/25)*8),237,8)
end

function pump_activate()
    pump.active = true
    pump.timer = 1200
    sfx(1,3)
end

function update_pump()
    if pump.active then
        pump.timer -= 1
        if pump.timer % 12 == 0 then water_level -= 1 end
        if water_level < 0 then water_level = 0 end
    end
    if pump.timer == 0 then
        pump.active = false
        sfx(-2,3)
    end
end

function draw_pump()
    if pump.active then
        if rnd({1,2}) == 1 then
            add(bubbles, {rnd(8)+56,0,rnd({1,1,1,2,2})})
        end
    end
end


function _draw()
    cls(1)
    for b in all(bubbles) do
        circ(b[1]+(sin(b[2] / 60)),248-(b[2]/3),b[3],12)
    end
    for s in all(skeletons) do
        local sprite = 3
        if s[2] < 120 then
            sprite = 7
        elseif s[2] < 240 then
            sprite = 5
        end
        sspr(sprite*8,32,16,16,s[1]*8,28*8)
    end
    map(0, 0, 0, 0, 128, 64)

    for k,v in pairs(cracks) do
        spr(12,k*8,28*8)
    end
    for d in all(drips) do
        pset(d[1]*8,(28*8)+d[2],12)
    end

	--Set camera position
    local rcb = room_cam_bounds
	cam_x,cam_y = get_camera(approach(cam_x,rcb[room_id][1],25),
        approach(cam_x,rcb[room_id][2],25),
        rcb[room_id][3],
        rcb[room_id][4])

    camera(cam_x,cam_y)

    if count(skeletons) > 0 then
        --print("skeleton x:"..skeletons[1][1]*8, cam_x+10, cam_y+5, 11)
    end
	--print("debug string:"..debug_string, cam_x+10, cam_y+11, 11)
    	--print("skeletons:"..(count(skeletons)), cam_x+10, cam_y+17, 11)
	--print("right_bound:"..(rcb[room_id][2]), cam_x+10, cam_y+23, 11)
    --print("holding "..player.holding, cam_x+10, cam_y+29, 11)
    pal(4,0)
    spr(player.torso,player.x,player.y+player.bobble,1,1,player.flip)
    spr(player.legs,player.x,player.y+9,1,1,player.flip)
    pal()
    if player.holding == "tape" then
        spr(5,player.x,player.y-6+player.bobble)
    end
    if player.interactable[1] != "nothing" then spr(32, player.x-8, player.y-8) end
    if(yelling) then
	    print(cur_yell, player.x, player.y-5, 14)
    end

    draw_water()
    draw_pump()
    draw_computer()
end

function approach(x, target, max_delta)
	return x < target and min(x + max_delta, target) or max(x - max_delta, target)
end

function get_camera(left, right, top, bottom)
	return min(max(left,player.x-60),right), player.y-104
end
__gfx__
0000000066666666aaaaaaaa00000000000000000000000000000000000000004333333444444444000000000000000000d00d00000000000000000000000000
0000000066666666aaaaaaaa0000000000000000000700000000000000000000355333334499994400000000000000000d0000d0000000000000000000000000
0070070066666666aaaaaaaa004440000fff4000007770000000000000000000333333354498a9440000000000000000d0d00d00000000000000000000000000
0007700066666666aaaaaaaa004f3f0000aa3f0007777700000000000000000033333335449999440000000000000000000d0000000000000000000000000000
0007700066666666aaaaaaaa004fff0000aaff000077777000000000000000003333333544455444000000000000000000d0d0d0000000000000000000000000
0070070066666666aaaaaaaa044ff00004aaf000000777770000000000000000666666664464465400000000000000000d000d00000000000000000000000000
0000000066666666aaaaaaaa000aa00000aaa00000007770000000000000000033333335446666540000000000000000dd000d00000000000000000000000000
0000000066666666aaaaaaaa000aa000000aa0000000070000000000000000003333333544999944000000000000000000d000d0000000000000000000000000
000000002222222200000000000aa000000aa0004444444444444444444444443333333577777777777777777777777700000000000000000000000000000000
00000000222222220000000000011000000110004498998489949989499899443333333577777777777777777777777700000000000000000000000000000000
00000000222222220000000000011000000110004888888888888888888888843333333546666666666666666666666400000000000000000000000000000000
00000000222222220000000000011000001111004998998989989989899899843333333546666656666655666666666400000000000000000000000000000000
00000000222222220000000000011000411011009444444444444444444444493333333546666656666665666666566400000000000000000000000000000000
00000000222222220000000000011000410001009999999999999999999999993333333546666656666665666666566400000000000000000000000000000000
00000000222222220000000000044400400004449888888888888888888888883333333346666666666666666666666400000000000000000000000000000000
00000000222222220000000000000000000000009989989999899899998998993333333345555555555555555555555400000000000000000000000000000000
00677700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06711770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67711777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77711777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07711770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444445565555555555655000000000000000000000000000000000000000000000000aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
44444444556555555555565500000000000000000000000000000000000000000000000000000000bbbbbbbb0000000000000000000000000000000000000000
442442445555566666655555000000000000000000000066660000000000000000000000aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442446555655555565556000000000000000000000666666000000000000000000000aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445556500000056555000007777770000000000666666000000000000000000000aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442445565000000005655000077777777000006006656656600000000005550000000aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445650000000000565000775777757700006006666666600000000005550000000aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442445650000000000565000775577557700006000665666000000005000500000000aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445650000000000565000777777777700006000066660000000005055055000000aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
444444445650000000000565000777757777700006000065650000000000500500500000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442445650000000000565000077777777000006600006600000000000005550050000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442445650000000000565000007777770000000066660066660000000000500050000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442445565000000005655000007575750000000000006600060000000005550000000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
992992995556500000056555000007575750000000000666666006000000050005000000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442446555655555565556000000000000000000000006600006000000050005000000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442445555566666655555000000000000000000000666666006000000050005000000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
442442445565555555555655000000000000000000000006600006000000000005000000aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000556555650000000055444444444444446666666644444444444444444444444466666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000666666660000000055555444448888446666666622222222222222222222222266666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000655565550000000055555544466666646666666664424242444244424242444666666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000000000000000000055555544eeeeeeee6666666662444444424442424244424666666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000000000000000000055555554eeeeeeee6666666662424242424242424244424666666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000000000006555655555555554ea9a9aee6666666664424442444242444242424666666666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000000000006666666655555554eeeeeeee6666666662424244444242444442444671117666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
00000000000000005565556554555554eeeeeeee6666666664444242424444424242424671111666bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0600000056500000000005654eeeeeeee55ee55e6666666666666666666666669999999955511555bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555566500000000005654eeeeeeee55ee55e6666666666666666666777769999999951511515bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555556500000000005664e555555eeeeeeee666666666666777c666755779999999955111115bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555556500000000005654e5eeee5e555555e66666666777775cc666755779999999977711114bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555556500000000005654e5eeee5e5eeee5e99999999566677cc6667777b9999999955577742bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555566500000000005654e5eeee5e5eeee5e66666666cccccccc667555559999999964454442bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0655555556500000000005664e555555e555555e66666666cccccccc665757579999999962575244bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
0600000056500000000005654eeeeeeeeeeeeeee666666666ccccccc657575759999999965454542bbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
11111111111111111110a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a41010101010545454545454545454
54545454545454545454545454545454545454541054545454545454545454545454545454545454545454545454545454545454545454542626262626262626
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000001000000000000000000000000001d000000000000000101010100000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000101010101000000000000000000000000000000000000000000000000000000000001000000000000000000000000001d000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000001010101000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000010101000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000010101000000000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000010101010000000000000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000001d0000000000000001000000000000000000000000001d000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000
0000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000001d1a1a1a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000010100000000000000000000000000000000000000000000
0000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000001d1a001a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000
0000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000001d1a001a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000000000010101000000000000000000000000000000000000
0000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000001d1a001a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000
0000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000001d1a001a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000
0000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d1a1a1a0000000001000000000000000000000000001d000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000
0000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d1d1d1d1d1d1d1d011d1d1d1d1d1d1d1d1d1d1d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000
0000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010000000000000000000000
0000000000000000000101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000
000000000000000000016565656565656565656565656565656565656565656565656565656565656565656565654001010100000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c0101000000000000000000
000000000000000000016565656565656565656565656565656565656565656565656565656565656565656565654001010100000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c01010000000000000000
000000000000000000016565656565656565656565656565656565656565656565656565656565656565656565654001010100000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000016565656565656565656565656565656565656565656565656565656565656565656565654001010100000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000016565656565656565656565656565656565656565656565650101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040414240404041424040404142404040414240010141420101010141420101010101014c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040515240404051524040405152404040515240010151520101010151520101010101014c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040656565656565656565656565656501014c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040656565656565656565656565656501014c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c41424c4c4c4c4c4c41424c4c4c4c4c4c41424c4c4c4c4c4c41424c4c4c450000000000000000
000000000000000000014041616142404161616161616161616142404041616161616161616142654161616161426501014c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c51524c4c4c4c4c4c51524c4c4c4c4c4c51524c4c4c4c4c4c51524c4c4c450000000000000000
000000000000000000015071000072507100000000000000000072505071000000000000000072757100000000727575754c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014051626252405162626262626262626252404051626262626262626252655162626262526565654c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000070016364404040404040404040404040094040084040404040656565656565697765656565656501764c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
0000000000000000000173744040404040401516174040191a1a1b18191a1a1a1b656565656565796767686566686566684c00000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
__sfx__
000100002e0502e0502e0502e0502e0502e0502e0502e0502e0502e0502e050310503105031050310503105031050310503105031050310503105031050310503105031050310503105031050310503105031050
00100020046100661008610096100b6100c6100d6100e6100f61010610106101161011610116101161011610106100f6100f6100e6100d6100c6100b6100a6100961008610076100761007610066100661004610
000200002b3502b3502b3502a3502c3502c3502d3502b35029350273502135025350273502a350323502f350283502335021350213502135021350283502a3502b350283502635026350213501c350133501a350
00010d003f650366503565024650206501a65016650156501465013650136501365012650126500f6500000000000225500000000000000002255000000000000000022550000000000000000000000000000000
0001000001650026500365004650056500765008650096500a6500c6500d6500e6500f650106501165012650146501565016650186501a6501b6501d6501f6502265024650276502a6502d65031650346503f650
010500000c0500000000000000000c050000000000000000070500000000000000000a0500000000000000000c0500000000000000000c050000000000000000070500000000000000000a050000000000000000
010500000c0530c6000c6000c6000c0530000000000000002b6550000000000000000c0530000000000000000c0530000000000000000c0530000000000000002b6550000000000000000c053000000000000000
010500002215000000000000000022150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002110222100000000000022152000000000000000211520000000000000001f1522110223102000002115200000000002210200000221020000000000221520000000000000001f102000000000000000
010500001f1520000000000000001f15200000000000000022102000000000000000000000000000000000001f102000000000000000000000000000000000001f10200000000000000000000000000000000000
0105000011050000000000000000110500000000000000000c0500000000000000000f05000000000000000011050000000000000000110500000000000000000c0500000000000000000f050000000000000000
0105000013050000000000000000130500000000000000000e0500000000000000001105000000000000000013050000000000000000130500000000000000000e05000000000000000011050000000000000000
010500000000000000000000000013050000000000000000130500000000000000001305000000000000000013050000000000000000130500000000000000001305000000000000000013050000000000000000
010500001d1500000000000000001d150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000211022210000000000001d1520000000000000001b1520000000000000001a1522110223102000001b152000000000022102000002210200000000001d1520000000000000001f102000000000000000
010500001f1500000000000000001f150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001f15000000221000000022150000002210000000241500000000000000002215000000000000000027150000000000000000000000000024150000001f15000000000000000022150000000000000000
010500001f1500000000000000001d1500000000000000001b150000000000000000000000000000000000001d1500000000000000001b1501b10000000000001815000000000000000000000000000000000000
010500001815000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 05064744
00 05064744
00 05060744
00 05060844
00 05060944
00 05064344
00 0a060d44
00 0a060e44
00 05060f44
00 05064344
00 0b061044
00 0a061144
00 05061244
00 0c424344

