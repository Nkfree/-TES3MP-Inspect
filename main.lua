local scriptConfig = {}


-- CHANGE THESE FREELY --
scriptConfig.inspectCommand = "gear"; -- Command usable in chat (usage: ```/gear <pid>``` or ```/gear <name>```)
scriptConfig.playerCooldown = 10; -- (default: 10) Time in seconds between inspect attempts (prevents spamming server with creation of new container)
scriptConfig.warningMessageColor = color.Yellow; -- See colors.lua in *server/scripts/* for reference
scriptConfig.useOnObjectActivate = false; -- (default: false) Use false if you're using scripts like kanaRevive or those that customize OnObjectActivate behaviour
-- you don't want to accidentaly inspect player when you pick him up from the downed state
-------------------------------------


scriptConfig.container = {
        refId = "party_inspect",
        name = "Inspecting %s ...",
        baseId = "dead rat",
        packetType = "spawn",
        type = "creature"
}

scriptConfig.lang = {}

scriptConfig.lang["cooldownMessage"] = "You have to wait " .. scriptConfig.warningMessageColor .. "%d" .. color.Default .. " seconds before inspecting again.\n";
scriptConfig.lang["errorMessage"] = scriptConfig.warningMessageColor ..  "%s " .. color.Default .. "couldn't be inspected.\n";
scriptConfig.lang["wrongCmdMessage"] = color.Red .. "Wrong command: \n" .. color.Yellow .. "/" .. scriptConfig.inspectCommand .. " <pid> OR /" .. scriptConfig.inspectCommand .. " <name>\n" .. color.Default;
scriptConfig.lang["forbidSelfMessage"] = scriptConfig.warningMessageColor .. "You can't inspect yourself.\n" .. color.Default;



local Methods = {};


Methods.instances = {};
Methods.records = {};
Methods.dynamicRecords = {};
Methods.playerCooldown = {};
Methods.playerCooldown.inspect = {};
Methods.playerCooldown.message = {};


Methods.createContainer = function(pid, targetPid)

local targetName

if Methods.validateNameOrPid(targetPid) then
	targetName = Players[targetPid].name
else
	return
end

local label = string.format(scriptConfig.container.name, targetName)

local recordStore = RecordStores[scriptConfig.container.type]
local generatedId = recordStore:GenerateRecordId()

Methods.dynamicRecords[pid] = generatedId
	
recordStore.data.generatedRecords[generatedId] = {
	baseId = scriptConfig.container.baseId,
	name = label
}

recordStore:Save()

recordStore:LoadGeneratedRecords(pid, recordStore.data.generatedRecords, {generatedId})

local recordId = ContainerFramework.createRecord(generatedId, scriptConfig.container.packetType);
local instanceId = ContainerFramework.createContainer(recordId);
local inventory = Methods.loadEquipment(targetPid)

ContainerFramework.setInventory(instanceId, inventory)

return instanceId, recordId

end


Methods.updateContainer = function(pid, instanceId)

    ContainerFramework.updateInventory(pid, instanceId)
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
    logicHandler.RunConsoleCommandOnPlayer(pid, "togglemenus", false)
    ContainerFramework.activateContainer(pid, instanceId)
	
end


Methods.removeContainer = function(pid)
	
	local cell = LoadedCells[ContainerFramework.config.storage.cell]
	local recordStore = RecordStores[scriptConfig.container.type]
	
	if Methods.instances[pid] then
		ContainerFramework.removeContainer(Methods.instances[pid])
		Methods.instances[pid] = nil
	end
	
	if Methods.records[pid] then
		ContainerFramework.removeRecord(Methods.records[pid])
		Methods.records[pid] = nil
	end
	
	if Methods.dynamicRecords[pid] then
		recordStore:DeleteGeneratedRecord(Methods.dynamicRecords[pid])
		
		if cell.data.recordLinks and cell.data.recordLinks[scriptConfig.container.type] and cell.data.recordLinks[scriptConfig.container.type][Methods.dynamicRecords[pid]] then			
				for _, uniqueIndex in pairs(cell.data.recordLinks[scriptConfig.container.type][Methods.dynamicRecords[pid]]) do
					tableHelper.removeValue(cell.data.packets["actorList"], uniqueIndex)
					tableHelper.removeValue(cell.data.packets[scriptConfig.container.packetType], uniqueIndex)
					cell.data.recordLinks[scriptConfig.container.type][Methods.dynamicRecords[pid]] = nil
					break
				end
				
			cell:QuicksaveToDrive()
			local next = next
			if next(recordStore.data.generatedRecords) == nil then
				recordStore:SetCurrentGeneratedNum(0)
			end
				
			Methods.dynamicRecords[pid] = nil
		end
	end
	
	
end


Methods.loadEquipment = function(targetPid)

local tempInv = {}
local targetInv = Players[targetPid].data.equipment

for index, item in pairs(targetInv) do
	tempInv[index] = item 
end

return tempInv

end


Methods.OnObjectActivate = function(EventStatus, pid, cellDescription, objects, players)
	
		if players[1] and players[1].pid then
	
			if Methods.playerCooldown.inspect[pid] == nil or (Methods.playerCooldown.inspect[pid] + scriptConfig.playerCooldown <= os.time()) then
			
				local targetPid = Methods.validateNameOrPid(players[1].pid)

				if targetPid then				
					Methods.removeContainer(pid)
					Methods.openInspectWindow(pid, targetPid)
				end
			else
				if Methods.playerCooldown.message[pid] == nil or (Methods.playerCooldown.message[pid] + 1 <= os.time()) then
					local tDifference = Methods.playerCooldown.inspect[pid] + scriptConfig.playerCooldown - os.time()
					tes3mp.SendMessage(pid, string.format(scriptConfig.lang["cooldownMessage"], tDifference), false)
					Methods.playerCooldown.message[pid] = os.time()
				end
			end
		end
end


Methods.OnPlayerDisconnect = function(EventStatus, pid)

if Methods.validateNameOrPid(pid) then
	Methods.removeContainer(pid)
	if Methods.playerCooldown.inspect[pid] then
		Methods.playerCooldown.inspect[pid] = nil
	end
end
end

Methods.useCommandInsteadOnObjectActivate = function(pid, cmd)

if cmd[2] then
	local validateCmd = Methods.validateNameOrPid(cmd[2])
	
	if validateCmd == pid then
		tes3mp.SendMessage(pid, scriptConfig.warningMessageColor .. scriptConfig.lang["forbidSelfMessage"], false)
		return
	end
	
	if validateCmd then
	
		if Methods.playerCooldown.inspect[pid] == nil or (Methods.playerCooldown.inspect[pid] + scriptConfig.playerCooldown <= os.time()) then
			Methods.removeContainer(pid)
			Methods.openInspectWindow(pid, validateCmd)
			
		else
			if Methods.playerCooldown.message[pid] == nil or (Methods.playerCooldown.message[pid] + 1 <= os.time()) then
				local tDifference = Methods.playerCooldown.inspect[pid] + scriptConfig.playerCooldown - os.time()
				tes3mp.SendMessage(pid, string.format(scriptConfig.lang["cooldownMessage"], tDifference), false)
				Methods.playerCooldown.message[pid] = os.time()
			end
		end
	end

else
	tes3mp.SendMessage(pid, scriptConfig.lang["wrongCmdMessage"], false)
	return
end
end
			


Methods.openInspectWindow = function(pid, targetPid)

	local playerName, targetName;
	
	pid = Methods.validateNameOrPid(pid)
	targetPid = Methods.validateNameOrPid(targetPid)
	
	if pid and targetPid then
		playerName = tes3mp.GetName(targetPid);
		targetName = tes3mp.GetName(pid);
		Methods.instances[pid], Methods.records[pid] = Methods.createContainer(pid, targetPid);
		Methods.updateContainer(pid, Methods.instances[pid]);
		Methods.playerCooldown.inspect[pid] = os.time() -- set cooldown only if the attempt was succesful
	else
		tes3mp.SendMessage(pid, string.format(scriptConfig.lang["errorMessage"], targetName));
		return false
	end
	
end


Methods.validateNameOrPid = function(NoP)-- checks whether pid used is logged in / converts player name to pid if that is logged in
	local targetPid = tonumber(NoP)
	if targetPid == nil then
		for id, _ in pairs(Players) do
			if NoP == tes3mp.GetName(id) then
				targetPid = id
				return targetPid
			end
		end
	end
	if targetPid ~= nil and Players[targetPid] ~= nil and Players[targetPid]:IsLoggedIn() then
		return targetPid
	end
	return false
end


customEventHooks.registerValidator("OnContainer", function(EventStatus, pid, cellDescription, objects)
	
	if cellDescription == ContainerFramework.config.storage.cell and Methods.validateNameOrPid(pid) then
	
		for n,object in pairs(objects) do
			
			local objectUniqueIndex = object.uniqueIndex
			local objectRefId = object.refId
			
			if objectRefId == Methods.dynamicRecords[pid] then
				Methods.removeContainer(pid)
				return customEventHooks.makeEventStatus(false,false)
			end
		end
	end
end)

customEventHooks.registerValidator("OnPlayerDisconnect", Methods.OnPlayerDisconnect)
customCommandHooks.registerCommand(scriptConfig.inspectCommand, Methods.useCommandInsteadOnObjectActivate)


if scriptConfig.useOnObjectActivate then
	customEventHooks.registerHandler("OnObjectActivate", Methods.OnObjectActivate)
end

return Methods
