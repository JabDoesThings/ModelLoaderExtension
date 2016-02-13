require 'ISUI/ISInventoryPaneContextMenu'
require 'TimedActions/ISInventoryTransferAction'
require 'TimedActions/ISUnequipAction'

local function addModelLoaderContextMenu(player, context, items)
    local isEquippable = true;
    local unequip = false;
    local count = 0;
    
    for i,v in ipairs(items) do
        local testItem = v;
        if not instanceof(testItem, "InventoryItem") then
            testItem = v.items[1];
        end
        
        if testItem:isEquippable() ~= true then
        	isEquippable = false;
        end
        
        if getSpecificPlayer(player):isEquipped(testItem) then
			unequip = true;
		end
        
        count = count + 1;
        if count > 1 then
            unequip = false;
        end        
    end
    
    if isEquippable and not unequip then
        context:addOption(getText("ContextMenu_Wear"), items, ISInventoryPaneContextMenu.onWearItemsModelLoader, player);
    end
end

ISInventoryPaneContextMenu.onWearItemsModelLoader = function(items, player)
    for i,k in pairs(items) do
        if not instanceof(k, "InventoryItem") then
            for i2,k2 in ipairs(k.items) do
                if i2 ~= 1 then
                    ISInventoryPaneContextMenu.wearItemModelLoader(k2, player);
                    break;
                end
            end
        else
            ISInventoryPaneContextMenu.wearItemModelLoader(k, player);
        end
        break;
    end
end

ISInventoryPaneContextMenu.wearItemModelLoader = function(item, player)
    local playerObj = getSpecificPlayer(player)
    if luautils.haveToBeTransfered(playerObj, item) then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), playerObj:getInventory()));
    end
    ISTimedActionQueue.add(ISModelLoaderWear:new(playerObj, item, 50));
end

local ISInventoryTransferAction_removeItemOnCharacter_old = ISInventoryTransferAction.removeItemOnCharacter;

function ISInventoryTransferAction:removeItemOnCharacter(...)
    if self.character:isEquipped(self.item) == true then
        local equipLocation = self.item:getEquipLocation();
        if equipLocation ~= nil then
            self.character:setEquipped(equipLocation, nil);
        else
            self.character:setUnEquipped(self.item)
        end
    end

    return ISInventoryTransferAction_removeItemOnCharacter_old(self, ...);
end

local ISUnequipAction_perform_old = ISUnequipAction.perform;
 
function ISUnequipAction:perform(...)
    if self.item:getEquipLocation() ~= nil then
    	local modData = self.item:getModData();
		modData["MODELLOADER_EQUIPPED"] = false;
    	self.character:setEquipped(self.item:getEquipLocation(), nil);
    end
    
    return ISUnequipAction_perform_old(self, ...);
end

Events.OnFillInventoryObjectContextMenu.Add(addModelLoaderContextMenu);