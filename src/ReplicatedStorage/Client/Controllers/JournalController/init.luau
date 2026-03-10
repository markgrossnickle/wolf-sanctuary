local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local JournalData = require(ReplicatedStorage.Shared.Data.JournalData)

local JournalController = Knit.CreateController({
	Name = "JournalController",
	EntryUnlocked = Signal.new(), -- (entryId, section, title, factText)
	SectionCompleted = Signal.new(), -- (section)
})

-- Local cache of unlocked entries
JournalController._unlockedEntries = {} :: { [string]: boolean }
JournalController._completedSections = {} :: { [string]: boolean }

function JournalController:KnitInit() end

function JournalController:KnitStart()
	local JournalService = Knit.GetService("JournalService")

	-- Load initial state from server
	local ok, entries = JournalService:GetUnlockedEntries():await()
	if ok and entries then
		self._unlockedEntries = entries
	end

	-- Listen for new unlocks
	JournalService.EntryUnlocked:Connect(function(entryId, section, title, factText)
		self._unlockedEntries[entryId] = true
		self.EntryUnlocked:Fire(entryId, section, title, factText)
	end)

	-- Listen for section completions
	JournalService.SectionCompleted:Connect(function(section)
		self._completedSections[section] = true
		self.SectionCompleted:Fire(section)
	end)
end

--[=[
	Check if a specific entry is unlocked.
	@param entryId string
	@return boolean
]=]
function JournalController:IsEntryUnlocked(entryId: string): boolean
	return self._unlockedEntries[entryId] == true
end

--[=[
	Check if a section is fully completed.
	@param section string
	@return boolean
]=]
function JournalController:IsSectionComplete(section: string): boolean
	return self._completedSections[section] == true
end

--[=[
	Get all entries for a section with their unlock status.
	@param section string
	@return { { entry: JournalData.JournalEntry, unlocked: boolean } }
]=]
function JournalController:GetSectionEntries(section: string)
	local sectionEntries = JournalData.BySection[section]
	if not sectionEntries then
		return {}
	end

	local result = {}
	for _, entry in sectionEntries do
		table.insert(result, {
			entry = entry,
			unlocked = self._unlockedEntries[entry.id] == true,
		})
	end
	return result
end

--[=[
	Get count of unlocked entries vs total for a section.
	@param section string
	@return number unlocked
	@return number total
]=]
function JournalController:GetSectionProgress(section: string): (number, number)
	local sectionEntries = JournalData.BySection[section]
	if not sectionEntries then
		return 0, 0
	end

	local unlocked = 0
	for _, entry in sectionEntries do
		if self._unlockedEntries[entry.id] then
			unlocked += 1
		end
	end
	return unlocked, #sectionEntries
end

--[=[
	Get total unlocked entries across all sections.
	@return number unlocked
	@return number total
]=]
function JournalController:GetTotalProgress(): (number, number)
	local unlocked = 0
	for _ in self._unlockedEntries do
		unlocked += 1
	end
	return unlocked, #JournalData.Entries
end

return JournalController
