--!strict
--[=[
	@class PlayerData
	@server
]=]

export type WolfStats = {
	Hunger: number,
	Energy: number,
	Happiness: number,
}

export type WolfData = {
	Species: string,
	Stage: string,
	PlayDays: number,
	Name: string,
	CoatColor: string,
	Stats: WolfStats,
}

export type JournalData = {
	UnlockedEntries: { [string]: boolean },
	CompletedSections: { [string]: boolean },
}

export type HowlsData = {
	Unlocked: { string },
}

export type ZonesData = {
	Unlocked: { string },
}

export type CosmeticsData = {
	OwnedCollars: { string },
	OwnedDenItems: { string },
	EquippedCollar: string,
}

export type CareData = {
	FeedCount: number,
	GroomCount: number,
	PlayCount: number,
	FirstFed: boolean,
	FirstGroomed: boolean,
	FirstPlayed: boolean,
}

export type PlayerData = {
	-- Currencies
	Coins: number,
	Gems: number,

	-- Shop / Inventory
	Inventory: { [string]: number },

	-- Daily Login Rewards
	LoginStreak: number,
	LastLoginDate: string,
	LastLoginRewardClaimed: boolean,

	-- Analytics / Session tracking
	FirstJoinDate: string,
	TotalPlayTime: number,
	SessionCount: number,
	LastSessionStart: number,

	-- Monetization: processed receipt IDs to prevent double-processing
	ProcessedReceipts: { [string]: boolean },

	-- Wolf Sanctuary
	Wolf: WolfData,
	Journal: JournalData,
	Howls: HowlsData,
	Zones: ZonesData,
	Cosmetics: CosmeticsData,
	Care: CareData,
}

local playerDataTemplate: PlayerData = {
	Coins = 0,
	Gems = 0,

	Inventory = {},

	LoginStreak = 0,
	LastLoginDate = "",
	LastLoginRewardClaimed = false,

	FirstJoinDate = "",
	TotalPlayTime = 0,
	SessionCount = 0,
	LastSessionStart = 0,

	ProcessedReceipts = {},

	Wolf = {
		Species = "Gray",
		Stage = "Newborn",
		PlayDays = 0,
		Name = "",
		CoatColor = "Gray",
		Stats = {
			Hunger = 100,
			Energy = 100,
			Happiness = 100,
		},
	},

	Journal = {
		UnlockedEntries = {},
		CompletedSections = {},
	},

	Howls = {
		Unlocked = { "Rally" },
	},

	Zones = {
		Unlocked = { "Den" },
	},

	Cosmetics = {
		OwnedCollars = {},
		OwnedDenItems = {},
		EquippedCollar = "",
	},

	Care = {
		FeedCount = 0,
		GroomCount = 0,
		PlayCount = 0,
		FirstFed = false,
		FirstGroomed = false,
		FirstPlayed = false,
	},
}

return playerDataTemplate
