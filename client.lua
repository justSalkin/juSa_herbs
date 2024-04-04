local CollectPrompt
local active = false
local oldHerb = {}
local herb
local itemSet
local is_prompt_active = false
local pickup_anim_name = "mech_pickup@plant@berries"
local collect_prompt_is_enabled = false
local Herbgroup = GetRandomIntInRange(0, 0xffffff)
local jobChance = false
local noteChance = false

function createPromptGroup()
    Citizen.CreateThread(function()
        local str = Config.Language.prompt
        CollectPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(CollectPrompt, Config.SearchKey)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(CollectPrompt, str)
        PromptSetEnabled(CollectPrompt, true)
        PromptSetVisible(CollectPrompt, true)
        PromptSetStandardizedHoldMode(CollectPrompt, GetHashKey("MEDIUM_TIMED_EVENT"))
        PromptSetGroup(CollectPrompt, Herbgroup)
        PromptRegisterEnd(CollectPrompt)
    end)
end

function initializeItemSet()
    itemSet = CreateItemset(true)
end

---@param player_ped_id number @Optional
---@return boolean
isPlayerValid = function(player_ped_id)
    player_ped_id = player_ped_id or PlayerPedId()
    if IsPedOnMount(player_ped_id) then
        return false
    end
    if IsPedInAnyVehicle(player_ped_id) then
        return false
    end
    if IsPedDeadOrDying(player_ped_id) then
        return false
    end
    return true
end

---@param _herb table<number>
---@return boolean
function isHerbChopped(_herb)
    return oldHerb[tostring(_herb)] == true
end

---@param _herb table<number>
function setHerbChopped(_herb)
    oldHerb[tostring(_herb)] = true
end

Citizen.CreateThread(function()
    createPromptGroup()
    initializeItemSet()
    while true do --check for herb
        local player_ped_id = PlayerPedId()
        if isPlayerValid(player_ped_id) then
            herb = GetClosestHerb()
            if isHerbChopped(_herb) then
                herb = nil
            end
        else
            herb = nil
        end

        if herb ~= nil then
            startPrompts()
        else
            stopPrompts()
        end
        Citizen.Wait(500)
    end
end)

function stopPrompts()
    is_prompt_active = false
end

function startPrompts()
    if is_prompt_active then
        return
    end
    is_prompt_active = true
    local player_ped_id = PlayerPedId()
    Citizen.CreateThread(function()
        while herb ~= nil and is_prompt_active do
            checkPromptsHerb(player_ped_id)
            Citizen.Wait(0)
        end
    end)
end

function enableCollectPrompt()
    if collect_prompt_is_enabled then
        return
    end
    collect_prompt_is_enabled = true
    PromptSetEnabled(CollectPrompt, true)
end

function disableCollectPrompt()
    if not collect_prompt_is_enabled then
        return
    end
    collect_prompt_is_enabled = false
    PromptSetEnabled(CollectPrompt, false)
end

---@param player_ped_id number @Optional
function checkPromptsHerb(player_ped_id)
    player_ped_id = player_ped_id or PlayerPedId()
    if active == false then
        local HerbgroupName = CreateVarString(10, 'LITERAL_STRING', Config.Language.promptherb)
        PromptSetActiveGroupThisFrame(Herbgroup, HerbgroupName)
    end
    if IsPedStopped(player_ped_id) then
        enableCollectPrompt()
        if PromptHasHoldModeCompleted(CollectPrompt) then
            stopPrompts()
            SetCurrentPedWeapon(player_ped_id, GetHashKey('WEAPON_UNARMED'), true)
            Wait(50)
            active = true
            setHerbChopped(herb)
            goCollectHerb()
        end
    else
        disableCollectPrompt()
    end
end

---@param _anim_name string
function loadAnimation(_anim_name)
    RequestAnimDict(_anim_name)
    while not HasAnimDictLoaded(_anim_name) do
        Wait(50)
    end
end

---@param player_ped_id number @Optional
function lockPlayer(player_ped_id)
    player_ped_id = player_ped_id or PlayerPedId()
    FreezeEntityPosition(player_ped_id, true)
end

---@param player_ped_id number @Optional
function playPickAnimation(player_ped_id)
    player_ped_id = player_ped_id or PlayerPedId()
    loadAnimation(pickup_anim_name)
    TaskPlayAnim(player_ped_id, pickup_anim_name, "enter_lf", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(800)
    TaskPlayAnim(player_ped_id, pickup_anim_name, "base", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(2000)
    TaskPlayAnim(player_ped_id, pickup_anim_name, "exit_stow", 8.0, -0.5, -1, 0, 0, true, 0, false, 0, false)
    Wait(1000)
end

---@param player_ped_id number @Optional
---@param wait_in_ms number @Optional
function releasePlayer(player_ped_id, wait_in_ms)
    player_ped_id = player_ped_id or PlayerPedId()
    ClearPedTasks(player_ped_id)
    if wait_in_ms then
        Wait(wait_in_ms)
    end
    FreezeEntityPosition(player_ped_id, false)
end

function goCollectHerb()
    local player_ped_id = PlayerPedId()
    if not isPlayerValid(player_ped_id) then
        return
    end
    Wait(50)
    TriggerServerEvent('juSa_herbs:getJob') --checks for extra chance to find herbs
    TriggerServerEvent('juSa_herbs:hasHerbalNotes') --checks for extra chance to find herbs
    Wait(100)
    lockPlayer(player_ped_id)
    playPickAnimation(player_ped_id)

    local itemChance = Config.ChanceHerbs
    if jobChance then
        itemChance = itemChance + Config.extraChance
    end
    if noteChance then
        itemChance = itemChance + Config.JobChance
    end
    
    if (math.random(1, 100) < itemChance) then
        TriggerServerEvent('juSa_herbs:addHerb')
        active = false
        releasePlayer(player_ped_id, 200)
    else
        TriggerEvent('vorp:NotifyLeft', Config.Language.notifytitelherb, Config.Language.notfoundherb, "BLIPS", "blip_destroy", 2000, "COLOR_RED")
        active = false
        releasePlayer(player_ped_id, 200)
    end
end

RegisterNetEvent("juSa_herbs:jobchecked")
AddEventHandler("juSa_herbs:jobchecked", function(hasjob) --checks if chance gets bonus from players job
    if hasjob then
        jobChance = true
    else
        jobChance = false
    end
end)

RegisterNetEvent("juSa_herbs:notecheck") --checks if chance gets bonus from item
AddEventHandler("juSa_herbs:notecheck", function(hasnote)
    if hasnote then
        noteChance = true
    else
        noteChance = false
    end
end)

function GetClosestHerb()
    _clearItemSet(itemSet)
    local playerped = PlayerPedId()
    local size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(playerped), 1.5, itemSet, 3, Citizen.ResultAsInteger())
    if not IsItemsetValid(itemSet) then
        return nil
    end
    local found_entity
    if size > 0 then
        for index = 0, size - 1 do
            local entity = GetIndexedItemInItemset(index, itemSet)
            local model_hash = GetEntityModel(entity)
            if (model_hash == 482937074 or model_hash == 1195851715 or model_hash == -817930893 or model_hash == 1043610176 or model_hash == 1199023171 or model_hash == -1025671301 or model_hash == 1519255796) and not oldHerb[tostring(entity)] then
                found_entity = entity
                break
            end
        end
    end
    _clearItemSet(itemSet)
    return found_entity
end

---@param _item_set table
function _clearItemSet(_item_set)
    Citizen.InvokeNative(0x20A4BF0E09BEE146, _item_set)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if IsItemsetValid(itemSet) then
        DestroyItemset(itemSet)
    end

    stopPrompts()
    releasePlayer()
end)