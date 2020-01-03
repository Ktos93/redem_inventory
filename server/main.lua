RegisterServerEvent("player:getItems")
RegisterServerEvent('player:savInvSv')
RegisterServerEvent("item:giveItem")
local invTable = {}
AddEventHandler("player:getItems", function()
    local _source = source

    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        --print(identifier)

        MySQL.Async.fetchAll('SELECT * FROM user_inventory WHERE `identifier`=@identifier AND `charid`=@charid;', {identifier = identifier, charid = charid}, function(inventory)

                if inventory[1] ~= nil then
                    print("doing stuff")
                    local inv = json.decode(inventory[1].items)
                    table.insert(invTable, {id = identifier, charid = charid , inventory = inv})
                    for i,k in pairs(invTable) do
                        if k.id == identifier and k.charid == charid then
                            TriggerClientEvent("gui:getItems", _source, k.inventory)
                            break
                        end
                    end

                else
                    local test = {
                        ["water"] = 3,
                        ["bread"] = 3,
                    }  MySQL.Async.execute('INSERT INTO user_inventory (`identifier`, `charid`, `items`) VALUES (@identifier, @charid, @items);',
                        {
                            identifier = identifier,
                            charid = charid,
                            items = json.encode(test)
                        }, function(rowsChanged)
                        end)
                    table.insert(invTable, {id = identifier, charid = charid , inventory = test})
                    for i,k in pairs(invTable) do
                        if k.id == identifier and k.charid == charid then
                            TriggerClientEvent("gui:getItems", _source, k.inventory)
                            break
                        end
                    end
                end
        end)

    end)
end)


AddEventHandler('player:savInvSv', function(source, id)
    local _source = source
    local _id = id

    if _id ~= nil then
        _source = tonumber(_id)
        print(source, 'forcing save for', _source, '...')
    end
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        --print(identifier)
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                MySQL.Async.execute('UPDATE user_inventory SET items = @items WHERE identifier = @identifier AND charid = @charid', {
                    ['@identifier']  = identifier,
                    ['@charid']  = charid,
                    ['@items'] = json.encode(k.inventory)
                }, function (rowsChanged)
                    if rowsChanged == 0 then
                        print(('user_inventory: Something went wrong saving %s!'):format(identifier .. ":" .. charid))
                    else
                        print("saved")
                    end
                end)

                break
            end
        end

    end)
end)

AddEventHandler("item:add", function(arg, identifier , charid)

        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then

                local name = tostring(arg[1])
                local qty = arg[2]
                local val = k.inventory[name]
                newVal = val + qty
                print(val)
                print(qty)
                print(newVal)
                k.inventory[name]= tonumber(math.floor(newVal))
                break
            end
        end
    
end)

AddEventHandler("item:new", function(item, quantity, identifier , charid)

        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then

                local name = tostring(item)
                local qty = tonumber(quantity)
                k.inventory[(name)] = qty
                break
            end
        end
   
end)

AddEventHandler("item:delete", function(arg, identifier , charid)

        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local name = tostring(arg[1])
                local qty = tonumber(arg[2])
                local val = tonumber(k.inventory[name])
                newVal = val - qty
                k.inventory[name]= tonumber(newVal)
                break
            end
        end
end)


RegisterServerEvent("item:onpickup")
AddEventHandler("item:onpickup", function(id)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local pickup  = Pickups[id]
                local _source = source
                if k.inventory[pickup.name] ~= nil then
                    TriggerEvent("item:add", {pickup.name, pickup.amount}, identifier , charid)
                else
                    TriggerEvent("item:new",  pickup.name, pickup.amount, identifier , charid)
                end
                 TriggerClientEvent("item:Sharepickup", -1, pickup.name, pickup.obj , pickup.amount, x, y, z, 2) 
                TriggerClientEvent('item:removePickup', -1, pickup.obj)
                Pickups[id] = nil
                TriggerClientEvent("gui:getItems", _source, k.inventory)
                TriggerClientEvent('gui:ReloadMenu', _source)
                TriggerEvent("player:savInvSv", _source)
                break
            end
        end
    end)
end)



RegisterCommand('giveitem', function(source, args)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local test = false
                local item = args[1]
                local amount = args[2]
                for k, v in pairs(k.inventory) do
                    if k == item then
                        TriggerEvent("item:add", {item, amount}, identifier , charid)
                        print("add")
                        test = true
                        break
                    end
                end
                if test == false then
                    TriggerEvent("item:new", item, amount, identifier , charid)
                end
                TriggerClientEvent("gui:getItems", _source, k.inventory)
                TriggerClientEvent('gui:ReloadMenu', _source)
                TriggerEvent("player:savInvSv", _source)
                break
            end
        end
    end)
end)


RegisterServerEvent("item:use")
AddEventHandler("item:use", function(val)
    local _source = source
    local name = val
    local amount = 1
    print("poszlo")
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                TriggerEvent("item:delete",{ name , amount}, identifier , charid)
                TriggerClientEvent("gui:getItems", _source, k.inventory)
                TriggerEvent("RegisterUsableItem:"..name)
                TriggerClientEvent("redemrp_notification:start", _source, "Item used: "..name, 3, "success")
                TriggerClientEvent('gui:ReloadMenu', _source)
                TriggerEvent("player:savInvSv", _source)
                break
            end
        end
    end)
end)



RegisterServerEvent("item:drop")
AddEventHandler("item:drop", function(val, amount)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local name = val
                local value = k.inventory[name]
                print(value)
                print(amount)
                local all = value-amount
                print(all)
                if all >= 0 then
                    TriggerClientEvent('item:pickup',_source, name, amount)
                    TriggerEvent("item:delete", {name , amount}, identifier , charid)
                    TriggerClientEvent("gui:getItems", _source, k.inventory)
                    TriggerClientEvent('gui:ReloadMenu', _source)
                    TriggerEvent("player:savInvSv", _source)
                end
                break
            end
        end
    end)
end)

RegisterServerEvent("item:SharePickupServer")
AddEventHandler("item:SharePickupServer", function(name, obj , amount, x, y, z)
   TriggerClientEvent("item:Sharepickup", -1, name, obj , amount, x, y, z, 1) 
   print("poszlo server")
    Pickups[obj] = {
        name = name,
        obj = obj,
        amount = amount,
        inRange = false,
        coords = {x = x, y = y, z = z}
    }
end)

RegisterServerEvent("test_lols")
AddEventHandler("test_lols", function(name, amount , target)
    local _target = target
     local _source = source
    local _name = name
    local _amount = amount
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                TriggerEvent("item:delete",{ name , amount}, identifier , charid)
                TriggerClientEvent("gui:getItems", _source, k.inventory)          
                TriggerEvent('test_lols222', _target , name , amount)
                TriggerClientEvent('gui:ReloadMenu', _source)
                TriggerEvent("player:savInvSv", _source)
				TriggerClientEvent("redemrp_notification:start", _source, "You have given: [X"..tonumber(amount).."]"..name.. " to " ..GetPlayerName(_target), 3, "success")
				TriggerClientEvent("redemrp_notification:start", _target, "You've received [X"..tonumber(amount).."]"..name.. " from " ..GetPlayerName(_source), 3, "success")
                break
            end
        end
    end)
end)

RegisterServerEvent("test_lols222")
AddEventHandler("test_lols222", function(source, name, amount)
    local _source = source
    local _name = name
    local _amount = amount
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
				if k.inventory[(name)] ~= nil then
					TriggerEvent("item:add", {name, amount}, identifier , charid)
				else
					TriggerEvent("item:new", name, amount, identifier , charid)
				end
					TriggerClientEvent("gui:getItems", _source, k.inventory)          
					TriggerClientEvent('gui:ReloadMenu', _source)
					TriggerEvent("player:savInvSv", _source)
					
                break
            end
        end
    end)
end)

-----------------Register Usable item---------------
RegisterServerEvent("RegisterUsableItem:wood")
AddEventHandler("RegisterUsableItem:wood", function()
    print("test")
end)
----------------------------------------------------


