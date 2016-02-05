--***********************************************************
--**                    ROBERT JOHNSON (Edited by Jab)     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISModelLoaderWear = ISBaseTimedAction:derive("ISModelLoaderWear");

function ISModelLoaderWear:isValid()
	return self.character:getInventory():contains(self.item);
end

function ISModelLoaderWear:update()
	self.item:setJobDelta(self:getJobDelta());
end

function ISModelLoaderWear:start()
	self.item:setJobType(getText("ContextMenu_Wear") .. ' ' .. self.item:getName());
	self.item:setJobDelta(0.0);
end

function ISModelLoaderWear:stop()
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function ISModelLoaderWear:perform()
    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
	
	print("Equipping ModelLoader item.");
	local modData = self.item:getModData();
	modData["MODELLOADER_EQUIPPED"] = true;
	self.character:initSpritePartsEmpty();
	self.character:setEquipped(self.item:getEquipLocation(), self.item);
	triggerEvent("OnClothingUpdated", self.character);
	ISBaseTimedAction.perform(self);
end

function ISModelLoaderWear:new(character, item, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = item;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	return o;
end
