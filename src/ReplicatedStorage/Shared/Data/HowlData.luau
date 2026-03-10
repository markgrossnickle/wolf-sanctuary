--!strict
--[=[
	@class HowlData
	Howl type definitions with real wolf communication facts.
]=]

export type HowlDefinition = {
	id: string,
	name: string,
	description: string,
	cooldown: number,
	range: number,
	factText: string,
}

local HowlData: { [string]: HowlDefinition } = {
	Rally = {
		id = "Rally",
		name = "Rally Call",
		description = "Assemble the pack before and after hunts",
		cooldown = 10,
		range = 200,
		factText = "Wolves howl to assemble the pack before and after hunts, to locate each other during storms, and to communicate across great distances. A howl can travel up to 10 miles!",
	},
	LocationPing = {
		id = "LocationPing",
		name = "Location Ping",
		description = "Mark your position for pack members",
		cooldown = 5,
		range = 150,
		factText = "Each wolf has a distinctive howl, like a human fingerprint. Wolves can identify each other by their individual howl and use it to find one another.",
	},
}

return table.freeze(HowlData)
