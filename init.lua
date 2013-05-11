receivers = {}
-- ================
-- Function declarations
 -- ================

 function getspec(node)
	print(tostring(node))
	if not minetest.registered_nodes[node.name] then return false end -- ignore unknown nodes
	return minetest.registered_nodes[node.name].wireless
end
 
 local on_digiline_receive = function (pos, node, channel, msg)
	print("digiline received")
	for i=1, #receivers do  -- Iterate over receivers
		-- print(tostring(receivers[i]))
		local target_meta = minetest.env:get_meta(receivers[i])
		local target_node = minetest.env:get_node(receivers[i])
		-- print(tostring(tar))
		local target_spec = getspec(target_node)
		if chan1~="" and msg1 ~= "" then  -- don't overwrite queued msgs
			target_meta:set_string("chan1", channel)
			target_meta:set_string("msg1", msg)
		end
		target_spec.receiver.action(receivers[i])
	end
end

local check_msgs = function (pos)
	local meta = minetest.env:get_meta(pos)
	local msg1 = meta:get_string("msg1")
	local chan1 = meta:get_string("chan1")
	if chan1~="" and msg1 ~= "" then  --don't send blank digiline msgs
		digiline:receptor_send(pos, digiline.rules.default,chan1, msg1)
	end
	meta:set_string("chan1", "")  -- clear msg so it won't be resent every second
	meta:set_string("msg1", "")  --
end

local register = function (pos)
	local meta = minetest.env:get_meta(pos)
	local RID = meta:get_int("RID")
	--print("was " .. #receivers .. " receivers")
	if receivers[RID] == nil then
		table.insert(receivers, pos)
	end
	--print("now " .. #receivers .. " receivers")
	meta:set_int("RID", #receivers)
	
end
-- ================
-- ABM declarations
 -- ================
minetest.register_abm({
nodenames = {"wireless:recv"},
interval=1.0,
chance=1,
action = function(pos) 
	--check_msgs(pos)
	register(pos)
end
})

-- ================
-- Node declarations
 -- ================

minetest.register_node("wireless:recv", {  -- Relays wireless to digiline
	paramtype = "light",
	description = "wireless digiline receiver",
	digiline = --declare as digiline-capable
	{
		receptor = {},
		--effector = {},
	},
	wireless = {
		receiver = {
			action = check_msgs 
		}
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.500000,-0.500000,-0.500000,0.500000,-0.125000,0.500000}, --Base
			{-0.062500,-0.125000,-0.062500,0.062500,0.500000,0.062500}, --Antenna
		}
	},
	tiles = {"recv_side.png"},
	groups = {oddly_breakable_by_hand=1},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "Wireless digiline receiver")
		meta:set_string("msg1","")
		meta:set_string("chan1","")
		 register(pos)  --register and record RID
	end,
	on_punch = function(pos)
		check_msgs(pos)
	end,
})

minetest.register_node("wireless:trans", { -- Relays digiline to wireless
	paramtype = "light",
	description = "wireless digiline transmitter",
	digiline = --declare as digiline-capable
	{
		receptor = {},
		effector = {
			action = on_digiline_receive
		},
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.500000,-0.500000,-0.500000,0.500000,-0.125000,0.500000}, --Base
			{-0.062500,-0.125000,-0.062500,0.062500,0.500000,0.062500}, --Antenna
		}
	},
	tiles = {"trans_side.png"},
	groups = {oddly_breakable_by_hand=1},
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "wireless digiline transmitter")
		print("trans construct")
	end,
	on_punch = function(pos)
		print("trans punched")
	end
	
})

-- ================
--Crafting recipes
 -- ================
 
 minetest.register_craft({
	 output = 'wireless:trans',
	 recipe = {
		{"mesecons_extrawires:vertical_off", "", ""},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"}
	 }
 })
 
 minetest.register_craft({
	 output = 'wireless:recv',
	 recipe = {
		{ "", "", "mesecons_extrawires:vertical_off"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"}
	 }
 })