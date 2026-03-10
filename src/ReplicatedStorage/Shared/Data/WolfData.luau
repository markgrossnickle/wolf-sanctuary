--!strict
local WolfStage = require(script.Parent.Parent.Enums.WolfStage)

export type StageDefinition = {
	Name: string,
	Description: string,
	PlayDaysRequired: number,
	UnlocksDescription: string,
	FactText: string,
	StatDecayRates: {
		Hunger: number,
		Energy: number,
		Happiness: number,
	},
}

-- Ordered list of stages for progression lookup
local StageOrder: { WolfStage.WolfStage } = {
	WolfStage.Newborn,
	WolfStage.EyesOpen,
	WolfStage.FirstSteps,
	WolfStage.OutsideDen,
	WolfStage.FirstHowl,
	WolfStage.Rendezvous,
	WolfStage.HuntTraining,
	WolfStage.YoungAdult,
	WolfStage.FullGrown,
}

-- Decay rates are per-minute values subtracted from stats (0-100 scale)
local Stages: { [string]: StageDefinition } = {
	[WolfStage.Newborn] = {
		Name = "Newborn",
		Description = "A tiny, helpless pup. Eyes and ears are sealed shut.",
		PlayDaysRequired = 0,
		UnlocksDescription = "Your wolf journey begins! Your pup needs warmth and milk.",
		FactText = "Wolf pups are born blind and deaf, weighing only about 1 pound. They rely completely on their mother for warmth and food.",
		StatDecayRates = {
			Hunger = 0.3,
			Energy = 0.1,
			Happiness = 0.2,
		},
	},
	[WolfStage.EyesOpen] = {
		Name = "Eyes Open",
		Description = "Your pup can see! The world is full of blurry shapes and colors.",
		PlayDaysRequired = 2,
		UnlocksDescription = "Vision unlocked! The world gains color and clarity.",
		FactText = "Wolf pups open their eyes at 11-15 days old. They are blue at first! Their eyes will change to yellow or amber as they grow.",
		StatDecayRates = {
			Hunger = 0.4,
			Energy = 0.15,
			Happiness = 0.25,
		},
	},
	[WolfStage.FirstSteps] = {
		Name = "First Steps",
		Description = "Wobbly legs carry your pup on its first adventure around the den.",
		PlayDaysRequired = 3,
		UnlocksDescription = "Walking unlocked! Explore the den. Meadow zone opens.",
		FactText = "Wolf pups begin walking at 2-3 weeks old. They are wobbly at first but quickly gain coordination through constant play with their siblings.",
		StatDecayRates = {
			Hunger = 0.5,
			Energy = 0.2,
			Happiness = 0.3,
		},
	},
	[WolfStage.OutsideDen] = {
		Name = "Outside the Den",
		Description = "Your pup ventures outside for the first time. So many smells!",
		PlayDaysRequired = 5,
		UnlocksDescription = "Den exit unlocked! Forest zone opens.",
		FactText = "At about 3 weeks, wolf pups emerge from the den for the first time. The whole pack gets excited and greets them with tail wags and face licks!",
		StatDecayRates = {
			Hunger = 0.6,
			Energy = 0.25,
			Happiness = 0.3,
		},
	},
	[WolfStage.FirstHowl] = {
		Name = "First Howl",
		Description = "Your pup finds its voice! A tiny, squeaky howl echoes through the sanctuary.",
		PlayDaysRequired = 10,
		UnlocksDescription = "Howl ability unlocked! River zone opens.",
		FactText = "Wolf pups start howling at 4-5 weeks old. Their first howls are high-pitched squeaks! Wolves howl to communicate — not at the moon. They tilt their heads up to project sound farther.",
		StatDecayRates = {
			Hunger = 0.7,
			Energy = 0.3,
			Happiness = 0.35,
		},
	},
	[WolfStage.Rendezvous] = {
		Name = "Rendezvous",
		Description = "Your wolf leaves the den permanently and joins the pack at a rendezvous site.",
		PlayDaysRequired = 15,
		UnlocksDescription = "Full sanctuary access! Ridge zone opens.",
		FactText = "At 8 weeks, pups move to a 'rendezvous site' — an open area where they wait while adults hunt. A babysitter wolf stays behind to watch them!",
		StatDecayRates = {
			Hunger = 0.8,
			Energy = 0.35,
			Happiness = 0.35,
		},
	},
	[WolfStage.HuntTraining] = {
		Name = "Hunt Training",
		Description = "Your wolf begins learning to hunt through play and observation.",
		PlayDaysRequired = 20,
		UnlocksDescription = "Pup School minigames! Hunting Grounds zone opens.",
		FactText = "At 12 weeks, wolf pups start following adults on short trips. They learn hunting by watching and playing — pouncing on grasshoppers and chasing each other is serious training!",
		StatDecayRates = {
			Hunger = 0.9,
			Energy = 0.4,
			Happiness = 0.4,
		},
	},
	[WolfStage.YoungAdult] = {
		Name = "Young Adult",
		Description = "Nearly full-grown, your wolf is strong and confident.",
		PlayDaysRequired = 30,
		UnlocksDescription = "All abilities available. Near-adult appearance.",
		FactText = "At 6 months, wolves are nearly full-sized but still learning. Young wolves play-fight to establish their place in the pack. Play is how wolves build bonds that last a lifetime.",
		StatDecayRates = {
			Hunger = 1.0,
			Energy = 0.45,
			Happiness = 0.4,
		},
	},
	[WolfStage.FullGrown] = {
		Name = "Full Grown",
		Description = "A magnificent adult wolf. Your bond is unbreakable.",
		PlayDaysRequired = 45,
		UnlocksDescription = "Mature wolf! Can start own pack. New species available.",
		FactText = "Adult gray wolves weigh 70-145 lbs and can run up to 40 mph! They live 6-8 years in the wild. A wolf's strongest trait isn't its bite — it's its loyalty to the pack.",
		StatDecayRates = {
			Hunger = 1.0,
			Energy = 0.5,
			Happiness = 0.4,
		},
	},
}

-- Minimum stat value — wolf never "dies"
local MIN_STAT_VALUE = 20

-- How much each care action restores
local CareValues = {
	Feed = { Hunger = 30 },
	Groom = { Happiness = 20 },
	Play = { Happiness = 25, Energy = -10 },
}

local WolfData = {
	Stages = Stages,
	StageOrder = StageOrder,
	MinStatValue = MIN_STAT_VALUE,
	CareValues = CareValues,
}

function WolfData.GetStageIndex(stage: string): number
	for i, s in StageOrder do
		if s == stage then
			return i
		end
	end
	return 1
end

function WolfData.GetNextStage(stage: string): string?
	local index = WolfData.GetStageIndex(stage)
	if index < #StageOrder then
		return StageOrder[index + 1]
	end
	return nil
end

return WolfData
