VorpInv = exports.vorp_inventory:vorp_inventoryApi()
VorpCore = exports.vorp_core:GetCore()

RegisterServerEvent('juSa_herbs:getJob')
AddEventHandler('juSa_herbs:getJob', function()
    local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter -- returns character data
    local job = Character.job
    local hasjob = false
    --checks player job
    for i, v in ipairs(Config.Jobs) do
        if v == job then
            hasjob = true
            break
        end
    end
    TriggerClientEvent("juSa_herbs:jobchecked", source, hasjob)
end)

RegisterServerEvent('juSa_herbs:hasHerbalNotes')
AddEventHandler('juSa_herbs:hasHerbalNotes', function()
    local hasnote = false
    local note = VorpInv.getItemCount(source, Config.HerbalNote) --checks for item herbal note
    if note > 0 then
        hasnote = true
    end
    TriggerClientEvent("juSa_herbs:notecheck", source, hasnote)
end)

RegisterServerEvent('juSa_herbs:addHerb')
AddEventHandler('juSa_herbs:addHerb', function(reward)
    local FinalLoot = LootToGive(source)
	local User = VorpCore.getUser(source).getUsedCharacter
	local book = VorpInv.getItemCount(source, Config.HerbalBook) --checks for item herbal book
	for k,v in pairs(Config.HerbItems) do
		if v.item == FinalLoot then --checks for the picked herb to find
            if book > 0 then --when player has the herbal book in inventory
                local herbs = Config.randomgiveHerb + 1
                local limit = exports.vorp_inventory:canCarryItems(source, herbs)
                if limit then
                    VorpInv.addItem(source, FinalLoot, herbs)
                    LootsToGive = {}
                    VorpCore.NotifyLeft(source, Config.Language.notifytitelherb, "" ..Config.Language.found.. "" ..herbs.. "x " ..v.name.. "", "INVENTORY_ITEMS", "consumable_herb_yarrow", 3000, "COLOR_GREEN")
                else
                    VorpCore.NotifyLeft(source, Config.Language.notifytitelherb, "" ..Config.Language.invfull.. "" , "BLIPS", "blip_destroy", 3000, "COLOR_RED")
                end
            else
                local limit = exports.vorp_inventory:canCarryItems(source, Config.randomgiveHerb)
                if limit then
                    VorpInv.addItem(source, FinalLoot, Config.randomgiveHerb)
                    LootsToGive = {}
                    VorpCore.NotifyLeft(source, Config.Language.notifytitelherb, "" ..Config.Language.found.. "" ..Config.randomgiveHerb.. "x " ..v.name.. "", "INVENTORY_ITEMS", "consumable_herb_yarrow", 3000, "COLOR_GREEN")
                else
                    VorpCore.NotifyLeft(source, Config.Language.notifytitelherb, "" ..Config.Language.invfull.. "" , "BLIPS", "blip_destroy", 3000, "COLOR_RED")
                end
            end
        end
	end
end)

function LootToGive(source)
	local LootsToGive = {}
	for k,v in pairs(Config.HerbItems) do
		table.insert(LootsToGive,v.item)
	end

	if LootsToGive[1] ~= nil then
		local value = math.random(1,#LootsToGive)
		local picked = LootsToGive[value]
		return picked
	end
end