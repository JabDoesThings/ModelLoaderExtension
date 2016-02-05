require 'ISUI/ISInventoryPaneContextMenu'
require 'TimedActions/ISInventoryTransferAction'
require 'TimedActions/ISUnequipAction'
ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, x, y, origin)
    if ISInventoryPaneContextMenu.dontCreateMenu then return; end
	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
		return;
	end
    local context = ISContextMenu.get(player, x, y);
    context.origin = origin;
	local itemsCraft = {};
    local c = 0;
    local isAllFood = true;
	local isWeapon = nil;
	local isHandWeapon = nil;
	local isAllPills = true;
	local isAllClothing = true;
	local recipe = nil;
    local evorecipe = nil;
    local baseItem = nil;
	local isAllLiterature = true;
	local canBeActivated = false;
	local isAllBandage = true;
	local unequip = false;
    local isReloadable = false;
	local waterContainer = nil;
	local canBeDry = nil;
	local canBeEquippedBack = false;
	local twoHandsItem = false;
    local brokenObject = nil;
    local canBeRenamed = nil;
    local canBeRenamedFood = nil;
    local pourOnGround = nil
    local canBeWrite = nil;
    local force2Hands = false;
    local remoteController = nil;
    local remoteControllable = nil;
    local generator = nil;
    -- MODELLOADER CODE
    local isEquippable = true;
	-- END
    local playerObj = getSpecificPlayer(player)
	ISInventoryPaneContextMenu.removeToolTip();
	getCell():setDrag(nil, player);
    local containerList = ISInventoryPaneContextMenu.getContainers(playerObj)
    for i,v in ipairs(items) do
        local testItem = v;
        if not instanceof(v, "InventoryItem") then
            testItem = v.items[1];
        end
        -- MODELLOADER CODE
        if testItem:isEquippable() ~= true then
        	isEquippable = false;
        end 
        -- END
        if instanceof(testItem, "Key") or testItem:getType() == "KeyRing" then
            canBeRenamed = testItem;
        end
		if not testItem:isCanBandage() then
			isAllBandage = false;
		end
        if testItem:getCategory() ~= "Food" then
            isAllFood = false;
        end
		if testItem:getCategory() ~= "Clothing" then
            isAllClothing = false;
		end
		if testItem:getType() == "DishCloth" or testItem:getType() == "BathTowel" and getSpecificPlayer(player):getBodyDamage():getWetness() > 0 then
			canBeDry = true;
        end
        if testItem:isBroken() or testItem:getCondition() < testItem:getConditionMax() then
            brokenObject = testItem;
        end
        if getSpecificPlayer(player):isEquipped(testItem) then
			unequip = true;
		end
		if testItem:getCategory() ~= "Literature" or testItem:canBeWrite() then
            isAllLiterature = false;
        end
        if testItem:getCategory() == "Literature" and testItem:canBeWrite() then
            canBeWrite = testItem;
        end
		if testItem:canBeActivated() and (testItem == getSpecificPlayer(player):getSecondaryHandItem() or testItem == getSpecificPlayer(player):getPrimaryHandItem()) then
            canBeActivated = true;
        end
		if (instanceof(testItem, "HandWeapon") and testItem:getCondition() > 0) or (instanceof(testItem, "InventoryItem") and not instanceof(testItem, "HandWeapon")) then
            isWeapon = testItem;
        end
        if instanceof(testItem, "HandWeapon") then
            isHandWeapon = testItem
        end
        if testItem:isRemoteController() then
            remoteController = testItem;
        end
        if isHandWeapon and isHandWeapon:canBeRemote() and isHandWeapon:getRemoteControlID() == -1 then
            remoteControllable = isHandWeapon;
        end
		if instanceof(testItem, "InventoryContainer") and testItem:canBeEquipped() == "Back" then
			canBeEquippedBack = true;
        end
        if instanceof(testItem, "InventoryContainer") then
            canBeRenamed = testItem;
        end
        if testItem:getType() == "Generator" then
            generator = testItem;
        end
        if instanceof(testItem, "Food")  then
            for i=0,getEvolvedRecipes():size()-1 do
                local evoRecipeTest = getEvolvedRecipes():get(i);
                if evoRecipeTest:getResultItem() == testItem:getType() and testItem:getExtraItems():size() >= 3 then
                    canBeRenamedFood = testItem;
                end
            end
        end
		if testItem:isTwoHandWeapon() and testItem:getCondition() > 0 then
			twoHandsItem = true;
        end
        if testItem:isRequiresEquippedBothHands() and testItem:getCondition() > 0 then
            force2Hands = true;
        end
		if(ReloadUtil:isReloadable(testItem, getSpecificPlayer(player))) then
			isReloadable = true;
		end
		if not ISInventoryPaneContextMenu.startWith(testItem:getType(), "Pills") then
            isAllPills = false;
        end
        if testItem:isWaterSource() then
            waterContainer = testItem;
        end
        if not instanceof(testItem, "Literature") and ISInventoryPaneContextMenu.canReplaceStoreWater(testItem) then
            pourOnGround = testItem
        end
        evorecipe = RecipeManager.getEvolvedRecipe(testItem, getSpecificPlayer(player), containerList, true);
        if evorecipe then
            baseItem = testItem;
        end
        itemsCraft[c + 1] = testItem;
        c = c + 1;
        if c > 1 then
            isHandWeapon = nil
            isAllClothing = false;
            isAllLiterature = false;
            canBeActivated = false;
            isReloadable = false;
            unequip = false;
            canBeEquippedBack = false;
            brokenObject = nil;
        end
    end
    triggerEvent("OnPreFillInventoryObjectContextMenu", player, context, items);
    context.blinkOption = ISInventoryPaneContextMenu.blinkOption;
    if #itemsCraft > 0 then
        local sameType = true
        for i=2,#itemsCraft do
            if itemsCraft[i]:getFullType() ~= itemsCraft[1]:getFullType() then
                sameType = false
                break
            end
        end
        if sameType then
            recipe = RecipeManager.getUniqueRecipeItems(itemsCraft[1], playerObj, containerList);
        end
    end
    if c == 0 then
        return;
    end
    local loot = getPlayerLoot(player);
	if not isInPlayerInventory then
		for i,k in pairs(items) do
			if not isInPlayerInventory then
				if not instanceof(k, "InventoryItem") then
					if #k.items > 2 then
						context:addOption(getText("ContextMenu_Grab_one"), items, ISInventoryPaneContextMenu.onGrabOneItems, player);
						context:addOption(getText("ContextMenu_Grab_half"), items, ISInventoryPaneContextMenu.onGrabHalfItems, player);
						context:addOption(getText("ContextMenu_Grab_all"), items, ISInventoryPaneContextMenu.onGrabItems, player);
						break;
					else
						context:addOption(getText("ContextMenu_Grab"), items, ISInventoryPaneContextMenu.onGrabItems, player);
						break;
					end
				else
					context:addOption(getText("ContextMenu_Grab"), items, ISInventoryPaneContextMenu.onGrabItems, player);
					break;
				end
			end
		end
    end
    if evorecipe then
        for i=0,evorecipe:size()-1 do
            local listOfAddedItems = {};
            local evorecipe2 = evorecipe:get(i);
            local items = evorecipe2:getItemsCanBeUse(getSpecificPlayer(player), baseItem, containerList);
            if items:size() == 0 then
                break;
            end
            local cookingLvl = getSpecificPlayer(player):getPerkLevel(Perks.Cooking);
            local subOption = nil;
            if baseItem:haveExtraItems() then
                subOption = context:addOption(getText("ContextMenu_EvolvedRecipe_" .. evorecipe2:getUntranslatedName()), nil);
            else
                subOption = context:addOption(getText("ContextMenu_Create_From_Ingredient") .. getText("ContextMenu_EvolvedRecipe_" .. evorecipe2:getUntranslatedName()), nil);
            end
            local subMenuRecipe = context:getNew(context);
            context:addSubMenu(subOption, subMenuRecipe);
            for i=0,items:size() -1 do
                local evoItem = items:get(i);
                local extraInfo = "";
                if instanceof(evoItem, "Food") then
                    if evoItem:isSpice() then
                        extraInfo = getText("ContextMenu_EvolvedRecipe_Spice");
                    elseif evoItem:getPoisonLevelForRecipe() then
                        extraInfo = getText("ContextMenu_EvolvedRecipe_Poison");
                    elseif not evoItem:isPoison() then
                        local use = evorecipe2:getItemRecipe(evoItem):getUse();
                        if use > math.abs(evoItem:getHungerChange() * 100) then
                            use = math.floor(math.abs(evoItem:getHungerChange() * 100));
                        end
                        if evoItem:isRotten() then
                            if cookingLvl == 7 or cookingLvl == 8 then
                                use = math.abs(round(evoItem:getBaseHunger() - (evoItem:getBaseHunger() - ((5/100) * evoItem:getBaseHunger())), 3)) * 100;
                            else
                                use = math.abs(round(evoItem:getBaseHunger() - (evoItem:getBaseHunger() - ((10/100) * evoItem:getBaseHunger())), 3)) * 100;
                            end
                        end
                        extraInfo = " (" .. use .. ")";
                        if listOfAddedItems[evoItem:getType()] and listOfAddedItems[evoItem:getType()] == use then
                            evoItem = nil;
                        else
                            listOfAddedItems[evoItem:getType()] = use;
                        end
                    end
                end
                if evoItem then
                    if baseItem:haveExtraItems() then
                        subMenuRecipe:addOption(getText("ContextMenu_Add_Ingredient") .. evoItem:getName() .. extraInfo, evorecipe2, ISInventoryPaneContextMenu.onAddItemInEvoRecipe, baseItem, evoItem, player);
                    else
                        subMenuRecipe:addOption(getText("ContextMenu_From_Ingredient") .. evoItem:getName() .. extraInfo, evorecipe2, ISInventoryPaneContextMenu.onAddItemInEvoRecipe, baseItem, evoItem, player);
                    end
                end
            end
        end
    end
    if(isInPlayerInventory and loot.inventory ~= nil and loot.inventory:getType() ~= "floor" ) then
        context:addOption(getText("ContextMenu_Put_in_Container"), items, ISInventoryPaneContextMenu.onPutItems, player);
    end
    local moveItems = {}
    for i,k in pairs(items) do
        if not instanceof(k, "InventoryItem") then
            for i2,k2 in ipairs(k.items) do
                if i2 ~= 1 then
                    table.insert(moveItems, k2)
                end
            end
        else
            table.insert(moveItems, k)
        end
    end
    if #moveItems and playerObj:getJoypadBind() ~= -1 then
        local subMenu = nil
        local moveTo1 = ISInventoryPaneContextMenu.canMoveTo(moveItems, playerObj:getClothingItem_Back())
        local moveTo2 = ISInventoryPaneContextMenu.canMoveTo(moveItems, playerObj:getPrimaryHandItem())
        local moveTo3 = ISInventoryPaneContextMenu.canMoveTo(moveItems, playerObj:getSecondaryHandItem())
        local moveTo4 = ISInventoryPaneContextMenu.canMoveTo(moveItems, ISInventoryPage.floorContainer[player+1])
        local keyRings = {}
        local inventoryItems = playerObj:getInventory():getItems()
        for i=1,inventoryItems:size() do
            local item = inventoryItems:get(i-1)
            if item:getType() == "KeyRing" and ISInventoryPaneContextMenu.canMoveTo(moveItems, item) then
                table.insert(keyRings, item)
            end
        end
        if moveTo1 or moveTo2 or moveTo3 or moveTo4 or (#keyRings > 0) then
            local option = context:addOption(getText("ContextMenu_Move_To"))
            local subMenu = context:getNew(context)
            context:addSubMenu(option, subMenu)
            if moveTo1 then
                subMenu:addOption(moveTo1:getName(), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, moveTo1:getInventory(), player)
            end
            if moveTo2 then
                subMenu:addOption(moveTo2:getName(), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, moveTo2:getInventory(), player)
            end
            if moveTo3 then
                subMenu:addOption(moveTo3:getName(), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, moveTo3:getInventory(), player)
            end
            for _,moveTo in ipairs(keyRings) do
                subMenu:addOption(moveTo:getName(), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, moveTo:getInventory(), player)
            end
            if moveTo4 then
                subMenu:addOption(getText("ContextMenu_Floor"), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, moveTo4, player)
            end
        end
    end
    if #moveItems and playerObj:getJoypadBind() ~= -1 then
        if ISInventoryPaneContextMenu.canUnpack(moveItems, player) then
            context:addOption(getText("ContextMenu_Unpack"), moveItems, ISInventoryPaneContextMenu.onMoveItemsTo, playerObj:getInventory(), player)
        end
    end
	if canBeEquippedBack and not unequip and not getSpecificPlayer(player):getClothingItem_Back() then
		context:addOption(getText("ContextMenu_Equip_on_your_Back"), items, ISInventoryPaneContextMenu.onWearItems, player);
	end
    if isAllFood then
        local foodItems = {}
        for i,k in pairs(items) do
            if not instanceof(k, "InventoryItem") then
                for i2,k2 in ipairs(k.items) do
                    if i2 ~= 1 then
                        table.insert(foodItems, k2)
                    end
                end
            else
                table.insert(foodItems, k)
            end
        end
        local foodByCmd = {}
        local cmd = nil
        local hungerNotZero = 0
        for i,k in ipairs(foodItems) do
            cmd = k:getCustomMenuOption() or getText("ContextMenu_Eat")
            foodByCmd[cmd] = true
            if k:getHungChange() < 0 then
                hungerNotZero = hungerNotZero + 1
            end
        end
        local cmdCount = 0
        for k,v in pairs(foodByCmd) do
            cmdCount = cmdCount + 1
        end
        if cmdCount == 1 then
            if hungerNotZero > 0 then
                local eatOption = context:addOption(cmd, items, nil)
                local subMenuEat = context:getNew(context)
                context:addSubMenu(eatOption, subMenuEat)
                subMenuEat:addOption(getText("ContextMenu_Eat_All"), items, ISInventoryPaneContextMenu.onEatItems, 1, player)
                subMenuEat:addOption(getText("ContextMenu_Eat_Half"), items, ISInventoryPaneContextMenu.onEatItems, 0.5, player)
                subMenuEat:addOption(getText("ContextMenu_Eat_Quarter"), items, ISInventoryPaneContextMenu.onEatItems, 0.25, player)
            elseif cmd ~= getText("ContextMenu_Eat") then
                local eatOption = context:addOption(cmd, items, ISInventoryPaneContextMenu.onEatItems, 1, player)
            end
        end
    end
	if (twoHandsItem or force2Hands) and not unequip then
		context:addOption(getText("ContextMenu_Equip_Two_Hands"), items, ISInventoryPaneContextMenu.OnTwoHandsEquip, player);
	end
	if isWeapon and not isAllFood and not unequip and not force2Hands then
        if not getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_R):isDeepWounded() and (getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_R):getFractureTime() == 0 or getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_R):getSplintFactor() > 0) then
            context:addOption(getText("ContextMenu_Equip_Primary"), items, ISInventoryPaneContextMenu.OnPrimaryWeapon, player);
        end
        if not getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_L):isDeepWounded() and (getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_L):getFractureTime() == 0 or getSpecificPlayer(player):getBodyDamage():getBodyPart(BodyPartType.Hand_L):getSplintFactor() > 0) then
		    context:addOption(getText("ContextMenu_Equip_Secondary"), items, ISInventoryPaneContextMenu.OnSecondWeapon, player);
        end
    end
    isWeapon = isHandWeapon
    if isWeapon and instanceof(isWeapon, "HandWeapon") and getSpecificPlayer(player):getInventory():getItemFromType("Screwdriver") then
        local weaponParts = getSpecificPlayer(player):getInventory():getItemsFromCategory("WeaponPart");
        if weaponParts and not weaponParts:isEmpty() then
            local subMenuUp = context:getNew(context);
            local doIt = false;
            local addOption = false;
            local alreadyDoneList = {};
            for i=0, weaponParts:size() - 1 do
                local part = weaponParts:get(i);
                if part:getMountOn():contains(isWeapon:getDisplayName()) and not alreadyDoneList[part:getName()] then
                    if part:getPartType() == getText("Tooltip_weapon_Scope") and not isWeapon:getScope() then
                        addOption = true;
                    elseif part:getPartType() == getText("Tooltip_weapon_Clip") and not isWeapon:getClip() then
                        addOption = true;
                    elseif part:getPartType() == getText("Tooltip_weapon_Sling") and not isWeapon:getSling() then
                        addOption = true;
                    elseif part:getPartType() == getText("Tooltip_weapon_Stock") and not isWeapon:getStock() then
                        addOption = true;
                    elseif part:getPartType() == getText("Tooltip_weapon_Canon") and not isWeapon:getCanon() then
                        addOption = true;
                    elseif part:getPartType() == getText("Tooltip_weapon_RecoilPad") and not isWeapon:getRecoilpad() then
                        addOption = true;
                    end
                end
                if addOption then
                    doIt = true;
                    subMenuUp:addOption(weaponParts:get(i):getName(), isWeapon, ISInventoryPaneContextMenu.onUpgradeWeapon, part, getSpecificPlayer(player));
                    addOption = false;
                    alreadyDoneList[part:getName()] = true;
                end
            end
            if doIt then
                local upgradeOption = context:addOption(getText("ContextMenu_Add_Weapon_Upgrade"), items, nil);
                context:addSubMenu(upgradeOption, subMenuUp);
            end
        end
        if  getSpecificPlayer(player):getInventory():getItemFromType("Screwdriver") and (isWeapon:getScope() or isWeapon:getClip() or isWeapon:getSling() or isWeapon:getStock() or isWeapon:getCanon() or isWeapon:getRecoilpad()) then
            local removeUpgradeOption = context:addOption(getText("ContextMenu_Remove_Weapon_Upgrade"), items, nil);
            local subMenuRemove = context:getNew(context);
            context:addSubMenu(removeUpgradeOption, subMenuRemove);
            if isWeapon:getScope() then
                subMenuRemove:addOption(isWeapon:getScope():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getScope(), getSpecificPlayer(player));
            end
            if isWeapon:getClip() then
                subMenuRemove:addOption(isWeapon:getClip():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getClip(), getSpecificPlayer(player));
            end
            if isWeapon:getSling() then
                subMenuRemove:addOption(isWeapon:getSling():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getSling(), getSpecificPlayer(player));
            end
            if isWeapon:getStock() then
                subMenuRemove:addOption(isWeapon:getStock():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getStock(), getSpecificPlayer(player));
            end
            if isWeapon:getCanon() then
                subMenuRemove:addOption(isWeapon:getCanon():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getCanon(), getSpecificPlayer(player));
            end
            if isWeapon:getRecoilpad() then
                subMenuRemove:addOption(isWeapon:getRecoilpad():getName(), isWeapon, ISInventoryPaneContextMenu.onRemoveUpgradeWeapon, isWeapon:getRecoilpad(), getSpecificPlayer(player));
            end
        end
    end

    if isHandWeapon and isHandWeapon:getExplosionTimer() > 0 then
        if isHandWeapon:getSensorRange() == 0 then
            context:addOption(getText("ContextMenu_TrapSetTimerExplosion"), isHandWeapon, ISInventoryPaneContextMenu.onSetBombTimer, player);
        else
            context:addOption(getText("ContextMenu_TrapSetTimerActivation"), isHandWeapon, ISInventoryPaneContextMenu.onSetBombTimer, player);
        end
    end
    if isHandWeapon and isHandWeapon:canBePlaced() then
        context:addOption(getText("ContextMenu_TrapPlace", isHandWeapon:getName()), isHandWeapon, ISInventoryPaneContextMenu.onPlaceTrap, getSpecificPlayer(player));
    end
    if remoteController or remoteControllable then
        for i = 0, getSpecificPlayer(player):getInventory():getItems():size() -1 do
            local item = getSpecificPlayer(player):getInventory():getItems():get(i);
            if (remoteController and instanceof(item, "HandWeapon") and item:canBeRemote() and item:getRemoteControlID() == -1 and remoteController:getRemoteControlID() == -1) or (remoteControllable and item:isRemoteController()) then
                context:addOption(getText("ContextMenu_TrapControllerLinkTo", item:getName()), item, ISInventoryPaneContextMenu.OnLinkRemoteController, remoteControllable, remoteController, player);
            end
        end
    end
    if remoteController and remoteController:getRemoteControlID() ~= -1 then
        context:addOption(getText("ContextMenu_TrapControllerTrigger"), remoteController, ISInventoryPaneContextMenu.OnTriggerRemoteController, player);
    end
	if isInPlayerInventory and isReloadable then
		local item = items[1];
		if not instanceof(items[1], "InventoryItem") then
			item = items[1].items[1];
		end
		context:addOption(ReloadUtil:getReloadText(item, playerObj), items, ISInventoryPaneContextMenu.OnReload, player);
	end
    if waterContainer and getSpecificPlayer(player):getStats():getThirst() > 0.1 then
        local drinkOption = context:addOption(getText("ContextMenu_Drink"), items, nil)
        local subMenuDrink = context:getNew(context)
        context:addSubMenu(drinkOption, subMenuDrink)
        subMenuDrink:addOption(getText("ContextMenu_Eat_All"), items, ISInventoryPaneContextMenu.onDrink, waterContainer, 1, player)
        subMenuDrink:addOption(getText("ContextMenu_Eat_Half"), items, ISInventoryPaneContextMenu.onDrink, waterContainer, 0.5, player)
        subMenuDrink:addOption(getText("ContextMenu_Eat_Quarter"), items, ISInventoryPaneContextMenu.onDrink, waterContainer, 0.25, player)
    end
	if c == 1 and waterContainer ~= nil then
		for i = 0, getSpecificPlayer(player):getInventory():getItems():size() -1 do
			local item = getSpecificPlayer(player):getInventory():getItems():get(i);
			if item ~= waterContainer and item:canStoreWater() and not item:isWaterSource() then
				context:addOption(getText("ContextMenu_Pour_into") .. item:getName(), items, ISInventoryPaneContextMenu.onTransferWater, waterContainer, item, player);
			end
			if item ~= waterContainer and item:canStoreWater() and item:isWaterSource() and instanceof(item, "DrainableComboItem") and (1 - item:getUsedDelta()) >= item:getUseDelta() then
				context:addOption(getText("ContextMenu_Pour_into") .. item:getName(), items, ISInventoryPaneContextMenu.onTransferWater, waterContainer, item, player);
			end
		end

		context:addOption(getText("ContextMenu_Pour_on_Ground"), items, ISInventoryPaneContextMenu.onEmptyWaterContainer, waterContainer, player);
	end
	if c == 1 and pourOnGround and not waterContainer then
		context:addOption(getText("ContextMenu_Pour_on_Ground"), items, ISInventoryPaneContextMenu.onDumpContents, pourOnGround, 40.0, player);
	end
	if isAllPills then
		context:addOption(getText("ContextMenu_Take_pills"), items, ISInventoryPaneContextMenu.onPillsItems, player);
	end
	if isAllLiterature and not getSpecificPlayer(player):HasTrait("Illiterate") then
		context:addOption(getText("ContextMenu_Read"), items, ISInventoryPaneContextMenu.onLiteratureItems, player);
	end
    -- MODELLOADER CODE
    if isEquippable and not unequip then
        context:addOption(getText("ContextMenu_Wear"), items, ISInventoryPaneContextMenu.onWearItemsModelLoader, player);
    end
    -- END
	if (isAllClothing) and not unequip then
		context:addOption(getText("ContextMenu_Wear"), items, ISInventoryPaneContextMenu.onWearItems, player);
	end
	if unequip then
		context:addOption(getText("ContextMenu_Unequip"), items, ISInventoryPaneContextMenu.onUnEquip, player);
	end
	if recipe ~= nil then
		ISInventoryPaneContextMenu.addDynamicalContextMenu(itemsCraft[1], context, recipe, player, containerList);
    end
	local light = items[1];
	if items[1] and not instanceof(items[1], "InventoryItem") then
		light = items[1].items[1];
	end
	if canBeActivated and light ~= nil and (not instanceof(light, "Drainable") or light:getUsedDelta() > 0) then
		local txt = getText("ContextMenu_Turn_On");
		if light:isActivated() then
			txt = getText("ContextMenu_Turn_Off");
		end
		context:addOption(txt, light, ISInventoryPaneContextMenu.onActivateItem, player);
	end
	if isAllBandage then
		local bodyPartDamaged = ISInventoryPaneContextMenu.haveDamagePart(player);
		if #bodyPartDamaged > 0 then
			local bandageOption = context:addOption(getText("ContextMenu_Apply_Bandage"), bodyPartDamaged, nil);
			local subMenuBandage = context:getNew(context);
			context:addSubMenu(bandageOption, subMenuBandage);
			for i,v in ipairs(bodyPartDamaged) do
				subMenuBandage:addOption(BodyPartType.getDisplayName(v:getType()), items, ISInventoryPaneContextMenu.onApplyBandage, v, player);
			end
		end
	end
	if canBeDry then
		context:addOption(getText("ContextMenu_Dry_myself"), items, ISInventoryPaneContextMenu.onDryMyself, player);
	end
	if isInPlayerInventory and not unequip then
        context:addOption(getText("ContextMenu_Drop"), items, ISInventoryPaneContextMenu.onDropItems, player);
    end
    if brokenObject then
        local fixing = FixingManager.getFix(brokenObject);
        if fixing then
            local fixOption = context:addOption(getText("ContextMenu_Repair") .. getItemText(brokenObject:getName()), items, nil);
            local subMenuFix = ISContextMenu:getNew(context);
            context:addSubMenu(fixOption, subMenuFix);
            ISInventoryPaneContextMenu.buildFixingMenu(brokenObject, player, fixing, fixOption, subMenuFix)
        end
    end
    if canBeRenamed then
        context:addOption(getText("ContextMenu_RenameBag"), canBeRenamed, ISInventoryPaneContextMenu.onRenameBag, player);
    end
    if canBeRenamedFood then
        context:addOption(getText("ContextMenu_RenameFood") .. canBeRenamedFood:getName(), canBeRenamedFood, ISInventoryPaneContextMenu.onRenameFood, player);
    end
    if canBeWrite then
		local editable = getSpecificPlayer(player):getInventory():contains("Pencil") or getSpecificPlayer(player):getInventory():contains("Pen")
		if canBeWrite:getLockedBy() and canBeWrite:getLockedBy() ~= getSpecificPlayer(player):getUsername() then
			editable = false
		end
		if not editable then
			context:addOption(getText("ContextMenu_Read_Note") .. canBeWrite:getName(), canBeWrite, ISInventoryPaneContextMenu.onWriteSomething, false, player);
		else
			context:addOption(getText("ContextMenu_Write_Note") .. canBeWrite:getName(), canBeWrite, ISInventoryPaneContextMenu.onWriteSomething, true, player);
		end
    end
    triggerEvent("OnFillInventoryObjectContextMenu", player, context, items);
    return context;
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
function ISInventoryTransferAction:removeItemOnCharacter()
	if self.character:getPrimaryHandItem() == self.item then
		self.character:setPrimaryHandItem(nil);
	end
	if self.character:getSecondaryHandItem() == self.item then
		self.character:setSecondaryHandItem(nil);
	end
	if self.character:getClothingItem_Torso() == self.item then
		self.character:setClothingItem_Torso(nil);
	end
	if self.character:getClothingItem_Torso() == self.item then
		self.character:setClothingItem_Torso(nil);
	end
	if self.character:getClothingItem_Legs() == self.item then
		self.character:setClothingItem_Legs(nil);
	end
	if self.character:getClothingItem_Feet() == self.item then
		self.character:setClothingItem_Feet(nil);
	end
	if self.character:getClothingItem_Back() == self.item then
		self.character:setClothingItem_Back(nil);
	end
	if self.item and self.item:getCategory() == "Clothing" then
		triggerEvent("OnClothingUpdated", self.character)
	end
    -- MODELLOADER CODE
    if self.character:isEquipped(self.item) == true then
        local equipLocation = self.item:getEquipLocation();
        if equipLocation ~= nil then
            self.character:setEquipped(equipLocation, nil);
        else
            self.character:setUnEquipped(self.item)
        end
    end
    -- END
end
function ISUnequipAction:perform()
    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
	if instanceof(self.item, "InventoryContainer") and self.item:canBeEquipped() == "Back" and self.character:getClothingItem_Back() == self.item then
		self.character:setClothingItem_Back(nil);
	elseif self.item:getCategory() == "Clothing" then
		if self.item:getBodyLocation() == ClothingBodyLocation.Top and self.item == self.character:getClothingItem_Torso() then
			self.character:setClothingItem_Torso(nil);
		elseif self.item:getBodyLocation() == ClothingBodyLocation.Shoes and self.item == self.character:getClothingItem_Feet() then
			self.character:setClothingItem_Feet(nil);
		elseif self.item:getBodyLocation() == ClothingBodyLocation.Bottoms and self.item == self.character:getClothingItem_Legs() then
			self.character:setClothingItem_Legs(nil);
		elseif self.item == self.character:getPrimaryHandItem() then
			self.character:setPrimaryHandItem(nil);
		elseif self.item == self.character:getSecondaryHandItem() then
			self.character:setSecondaryHandItem(nil);
		end
		triggerEvent("OnClothingUpdated", self.character)
    end
    if self.item == self.character:getPrimaryHandItem() then
        if (self.item:isTwoHandWeapon() or self.item:isRequiresEquippedBothHands()) and self.item == self.character:getSecondaryHandItem() then
            self.character:setSecondaryHandItem(nil);
        end
		self.character:setPrimaryHandItem(nil);
    end
    -- MODELLOADER CODE
    if self.item:getEquipLocation() ~= nil then
    	local modData = self.item:getModData();
		modData["MODELLOADER_EQUIPPED"] = false;
    	self.character:setEquipped(self.item:getEquipLocation(), nil);
    end
    -- END
    if self.item == self.character:getSecondaryHandItem() then
        if (self.item:isTwoHandWeapon() or self.item:isRequiresEquippedBothHands()) and self.item == self.character:getPrimaryHandItem() then
            self.character:setPrimaryHandItem(nil);
        end
		self.character:setSecondaryHandItem(nil);
    end
    if self.item:getType() == "Generator" or self.item:getType() == "CorpseMale" or self.item:getType() == "CorpseFemale" then
       self.character:getInventory():Remove(self.item);
       self.character:getCurrentSquare():AddWorldInventoryItem(self.item,0,0,0);
    end
	getPlayerData(self.character:getPlayerNum()).playerInventory:refreshBackpacks();
	ISBaseTimedAction.perform(self);
end