pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- gbgj 8/22
-- matte l & brian b

player = {}
player.x = 16
player.speed_x = 0
player.y = 104
player.interactable = "nothing"

cam_x = 0
cam_y = 0

room_id = 1

k_left=0
k_right=1
k_up=2
k_down=3
k_interact=4
k_other=5

rooms = {}
-- Trigger format:
-- Upper Left Tile X,Y, Lower Right tile X,Y, Target Room, Target X, Target Y
rooms[1] = { {13,9,15,14,2,33,13} }
rooms[2] = { {29,9,31,4,1}, {48,9,50,14,3} }
rooms[3] = { {58,9,60,14,2}}

room_cam_bounds = {}
room_cam_bounds[1] = {0,50}
room_cam_bounds[2] = {224,292}

-- Interactables are single tiles that do something when you touch them:
interactables = {}
interactables["hingus"] = {4, 14}
interactables["bingus"] = {36, 14}

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
            return i
        end
    end
    return "nothing"
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

    player.interactable = check_interactable()
    
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

end

function _draw()
    cls()
    map(0, 0, 0, 0, 128, 64)

	--Set camera position
    local rcb = room_cam_bounds
	cam_x,cam_y = get_camera(approach(cam_x,rcb[room_id][1],25),approach(cam_x,rcb[room_id][2],25),0,128)

    camera(cam_x,cam_y)

    print("player x/8:"..player.x/8, cam_x+10, cam_y+5, 11)
	print("player y/8:"..player.y/8, cam_x+10, cam_y+11, 11)
	print("left_bound:"..(rcb[room_id][1]), cam_x+10, cam_y+17, 11)
	print("right_bound:"..(rcb[room_id][2]), cam_x+10, cam_y+23, 11)
    print("colliding with "..player.interactable, cam_x+10, cam_y+29, 11)
    sspr(0,32,8,16,player.x,player.y)
    if player.interactable != "nothing" then spr(32, player.x-8, player.y-8) end
end

function approach(x, target, max_delta)
	return x < target and min(x + max_delta, target) or max(x - max_delta, target)
end

function get_camera(left, right, top, bottom)
	return min(max(left,player.x-60),right), min(max(top,player.y-128),bottom)
end
__gfx__
0000000066666666aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066666666aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070066666666aaaaaaaa004440000fff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700066666666aaaaaaaa004f3f0000aa3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700066666666aaaaaaaa004fff0000aaff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070066666666aaaaaaaa044ff00004aaf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066666666aaaaaaaa000aa00000aaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066666666aaaaaaaa000aa000000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000aa000000aa0000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000011000000110000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000011000000110000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000011000001111000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000011000411011000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000011000410001000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00000000000000000000000000044400400004440000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
00677700000000000000000000000000000000000000000000000000000000000000000000000000888888889999999900000000bbbbbbbb0000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444445565555555555655000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445555566666655555000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442446555655555565556000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445556500000056555000007777770000066666666777777778888888899999999aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442445565000000005655000077777777000066666666777777778888888899999999aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445650000000000565000775777757700066666666777777778888888899999999aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
442442445650000000000565000775577557700066666666777777778888888899999999aaaaaaaabbbbbbbbd1d1d1d1ddddddddeeeeeeeeffffffff00000000
442442445650000000000565000777777777700066666666777777778888888899999999aaaaaaaabbbbbbbb1d1d1d1dddddddddeeeeeeeeffffffff00000000
444444445650000000000565000777757777700066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445650000000000565000077777777000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445650000000000565000007777770000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445565000000005655000007575750000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445556500000056555000007575750000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444446555655555565556000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445555566666655555000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444445565555555555655000000000000000066666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
444444441111111122222222333333335555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff00000000
26262626262626262610b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b110101010545454545454545454
54545454545454545454545454545454545454541054545454545454545454545454545454545454545454545454545454545454545454542626262626262626
__gff__
0000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000045454545010145454501010101010101010101010101010101010101010101014545454545454545454545454545010101010145000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c0101000000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c01010000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040404040404040404040404040404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c41424c4c4c4c4c4c41424c4c4c4c4c4c41424c4c4c4c4c4c41424c4c4c450000000000000000
000000000000000000014040404040404142404040404040404142404040404040404142404040404040414240404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c51524c4c4c4c4c4c51524c4c4c4c4c4c51524c4c4c4c4c4c51524c4c4c450000000000000000
000000000000000000014040404040405152404040404040405152404040404040405152404040404040515240404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040404040404040404040404040404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040404040404040404040404040404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
000000000000000000014040404040404040404040404040404040404040404040404040404040404040404040404001404000000000000000000000000000000000000000000000000000000000000000000000014c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c450000000000000000
