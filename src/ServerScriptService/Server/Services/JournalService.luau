local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local JournalData = require(ReplicatedStorage.Shared.Data.JournalData)

local PlayerDataService

local JournalService = Knit.CreateService({
	Name = "JournalService",
	EntryUnlocked = Signal.new(),
	Client = {
		EntryUnlocked = Knit.CreateSignal(),
		SectionCompleted = Knit.CreateSignal(),
	},
})

function JournalService:KnitInit()
	PlayerDataService = Knit.GetService("PlayerDataService")
end

function JournalService:KnitStart() end

--[=[
	Unlock a journal entry for a player. Returns true if newly unlocked, false if already had it.
	@param player Player
	@param entryId string
	@return boolean
]=]
function JournalService:UnlockEntry(player: Player, entryId: string): boolean
	local entry = JournalData.ById[entryId]
	if not entry then
		warn(`JournalService: Unknown entry id "{entryId}"`)
		return false
	end

	local unlocked = PlayerDataService:Read(player, { "Journal", "UnlockedEntries" })
	if unlocked and unlocked[entryId] then
		return false
	end

	PlayerDataService:Write(player, { "Journal", "UnlockedEntries", entryId }, true)

	self.EntryUnlocked:Fire(player, entryId)
	self.Client.EntryUnlocked:Fire(player, entryId, entry.section, entry.title, entry.factText)

	self:_checkSectionComplete(player, entry.section)

	return true
end

--[=[
	Get all unlocked entry IDs for a player.
	@param player Player
	@return { [string]: boolean }
]=]
function JournalService:GetUnlockedEntries(player: Player): { [string]: boolean }
	local unlocked = PlayerDataService:Read(player, { "Journal", "UnlockedEntries" })
	return unlocked or {}
end

--[=[
	Check if a section is fully complete.
	@param player Player
	@param section string
	@return boolean
]=]
function JournalService:IsSectionComplete(player: Player, section: string): boolean
	local completed = PlayerDataService:Read(player, { "Journal", "CompletedSections" })
	return completed and completed[section] == true or false
end

--[=[
	Internal: check if all entries in a section are unlocked and fire SectionCompleted if so.
]=]
function JournalService:_checkSectionComplete(player: Player, section: string)
	if self:IsSectionComplete(player, section) then
		return
	end

	local sectionEntries = JournalData.BySection[section]
	if not sectionEntries then
		return
	end

	local unlocked = PlayerDataService:Read(player, { "Journal", "UnlockedEntries" }) or {}
	for _, entry in sectionEntries do
		if not unlocked[entry.id] then
			return
		end
	end

	PlayerDataService:Write(player, { "Journal", "CompletedSections", section }, true)
	self.Client.SectionCompleted:Fire(player, section)
end

function JournalService.Client:GetUnlockedEntries(player: Player)
	return self.Server:GetUnlockedEntries(player)
end

function JournalService.Client:IsSectionComplete(player: Player, section: string)
	return self.Server:IsSectionComplete(player, section)
end

return JournalService
