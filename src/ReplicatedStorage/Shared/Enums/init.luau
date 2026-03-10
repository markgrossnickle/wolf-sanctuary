local Environment = require(script.Environment)
local WolfStage = require(script.WolfStage)
local WolfSpecies = require(script.WolfSpecies)
local JournalSection = require(script.JournalSection)
local HowlType = require(script.HowlType)

local Enums = {
	Environment = Environment,
	WolfStage = WolfStage,
	WolfSpecies = WolfSpecies,
	JournalSection = JournalSection,
	HowlType = HowlType,
}

export type Enums = typeof(Enums)

export type Environment = Environment.Environment
export type WolfStage = WolfStage.WolfStage
export type WolfSpecies = WolfSpecies.WolfSpecies
export type JournalSection = JournalSection.JournalSection
export type HowlType = HowlType.HowlType

return Enums
