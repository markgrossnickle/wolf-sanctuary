--!strict
--[=[
	@class JournalData
	All journal entries with real wolf facts sourced from research.
	Sources: National Geographic Kids, International Wolf Center, Wolf Conservation Center,
	Smithsonian, NPS, and more. See docs/wolf-research.md for full citations.
]=]

export type JournalEntry = {
	id: string,
	section: string,
	title: string,
	factText: string,
	unlockCondition: string,
}

local JournalData: { JournalEntry } = {
	-- ══════════════════════════════════════
	-- WOLF BASICS (10 entries)
	-- ══════════════════════════════════════
	{
		id = "basics_eye_color",
		section = "WolfBasics",
		title = "Eye Color Change",
		factText = "Wolf pups are born with blue eyes that change to yellow or amber as they grow in the first few weeks of life.",
		unlockCondition = "Reach the EyesOpen growth stage",
	},
	{
		id = "basics_size_weight",
		section = "WolfBasics",
		title = "Size & Weight",
		factText = "Adult wolves measure 5 to 6.5 feet long including their tail and weigh 50 to 110 pounds. Northern wolves tend to be larger.",
		unlockCondition = "Reach the FullGrown growth stage",
	},
	{
		id = "basics_species_count",
		section = "WolfBasics",
		title = "Wolf Species",
		factText = "There are 3 recognized wolf species: Gray Wolf, Red Wolf, and Ethiopian Wolf. The Gray Wolf alone has over 30 subspecies!",
		unlockCondition = "Open the journal for the first time",
	},
	{
		id = "basics_fur_colors",
		section = "WolfBasics",
		title = "Not Always Gray",
		factText = "Gray wolves are not always gray! Their fur can be white, black, brown, gray, tan, or a mix. Arctic wolves are typically white.",
		unlockCondition = "Visit the Meadow zone",
	},
	{
		id = "basics_lifespan",
		section = "WolfBasics",
		title = "Wolf Lifespan",
		factText = "Wolves live 5 to 7 years in the wild, but can reach 12 to 15 years in captivity. Some have lived to 17!",
		unlockCondition = "Reach Day 10 with your wolf",
	},
	{
		id = "basics_scientific_name",
		section = "WolfBasics",
		title = "Canis Lupus",
		factText = "The scientific name for the gray wolf is Canis lupus. 'Lupus' is the Latin word for wolf.",
		unlockCondition = "Discover your first journal entry",
	},
	{
		id = "basics_born_helpless",
		section = "WolfBasics",
		title = "Born Helpless",
		factText = "Wolf pups are born completely blind, deaf, and unable to regulate their own body temperature. They weigh only about 1 pound at birth.",
		unlockCondition = "Start the game with a Newborn pup",
	},
	{
		id = "basics_birth_weight",
		section = "WolfBasics",
		title = "Tiny Beginnings",
		factText = "Newborn wolf pups weigh only about 1 pound but gain about 3 pounds per week! Female pups gain 2.6 lbs/week and males gain 3.3 lbs/week.",
		unlockCondition = "Reach the FirstSteps growth stage",
	},
	{
		id = "basics_dogs_and_wolves",
		section = "WolfBasics",
		title = "Dogs Are Wolves",
		factText = "All dogs descended from wolves 15,000 to 40,000 years ago. Dogs and wolves share more than 99% of their DNA!",
		unlockCondition = "Unlock 5 journal entries",
	},
	{
		id = "basics_teeth",
		section = "WolfBasics",
		title = "42 Teeth",
		factText = "Wolves have 42 teeth, including 4 canine teeth that can be over 1 inch long. Dogs have the same number, but wolf teeth are bigger and stronger.",
		unlockCondition = "Feed your wolf 5 times",
	},

	-- ══════════════════════════════════════
	-- PACK LIFE (8 entries)
	-- ══════════════════════════════════════
	{
		id = "pack_alpha_myth",
		section = "PackLife",
		title = "The Alpha Myth",
		factText = "The 'alpha wolf' idea was debunked. Wolf packs are led by mom and dad, not by dominance fights. The scientist who coined the term later retracted it!",
		unlockCondition = "Use the Rally howl for the first time",
	},
	{
		id = "pack_family",
		section = "PackLife",
		title = "A Pack Is a Family",
		factText = "A wolf pack is simply a family: a mom and dad (the breeding pair) and their pups from the current and sometimes previous year.",
		unlockCondition = "Reach the Rendezvous growth stage",
	},
	{
		id = "pack_size",
		section = "PackLife",
		title = "Pack Numbers",
		factText = "Wolf packs typically have 5 to 10 members, but can include up to 20 wolves. The parents lead through experience, not aggression.",
		unlockCondition = "Use Rally howl 3 times",
	},
	{
		id = "pack_alloparenting",
		section = "PackLife",
		title = "It Takes a Village",
		factText = "The whole pack helps raise the pups! Wolves are one of the few species where non-parent members help care for the young. Males even compete to babysit!",
		unlockCondition = "Play with your wolf 3 times",
	},
	{
		id = "pack_omega",
		section = "PackLife",
		title = "The Omega Wolf",
		factText = "The lowest-ranking wolf is the omega — the pack's 'class clown.' It promotes play and calms tensions during conflicts. It eats last but keeps the peace.",
		unlockCondition = "Reach the HuntTraining growth stage",
	},
	{
		id = "pack_leaving",
		section = "PackLife",
		title = "Going Solo",
		factText = "Young wolves leave their birth pack at 1 to 3 years old to find a mate and start their own pack. These brave travelers are called 'dispersers.'",
		unlockCondition = "Reach the YoungAdult growth stage",
	},
	{
		id = "pack_leadership",
		section = "PackLife",
		title = "Leading the Way",
		factText = "The breeding pair leads by experience and cooperation — they decide when to hunt, where to travel, and where to build the den. No fighting needed!",
		unlockCondition = "Complete the WolfBasics journal section",
	},
	{
		id = "pack_regurgitate",
		section = "PackLife",
		title = "Special Delivery",
		factText = "Adult wolves feed pups by eating food, traveling back to the den, and regurgitating it for the pups. Pups lick the adults' mouths to ask for food!",
		unlockCondition = "Feed your wolf 3 times",
	},

	-- ══════════════════════════════════════
	-- SENSES (5 entries)
	-- ══════════════════════════════════════
	{
		id = "senses_smell",
		section = "Senses",
		title = "Super Smell",
		factText = "Wolves have 200 million scent cells — 40 times more than humans! Their smell brain is the size of a fist. They can smell other animals from over 1 mile away.",
		unlockCondition = "Explore the Forest zone",
	},
	{
		id = "senses_hearing",
		section = "Senses",
		title = "Super Hearing",
		factText = "Wolves can hear frequencies up to 80 kHz — 4 times the range of human hearing! They can hear sounds up to 10 miles away in open terrain.",
		unlockCondition = "Use any howl 5 times",
	},
	{
		id = "senses_night_vision",
		section = "Senses",
		title = "Night Eyes",
		factText = "Wolves have a reflective layer behind their retinas called the tapetum lucidum. This 'mirror' gives them night vision 40-50% stronger than humans — and makes their eyes glow!",
		unlockCondition = "Play during nighttime in the sanctuary",
	},
	{
		id = "senses_motion",
		section = "Senses",
		title = "Motion Detector",
		factText = "Wolves can spot subtle movement of prey from nearly a mile away. They see fewer colors than humans but can distinguish more shades of gray.",
		unlockCondition = "Reach the OutsideDen growth stage",
	},
	{
		id = "senses_hearing_pups",
		section = "Senses",
		title = "When Ears Wake Up",
		factText = "Wolf pups are born deaf! Their hearing begins around 27 days old when their ears start to raise. Before that, they rely entirely on touch and smell.",
		unlockCondition = "Reach Day 5 with your wolf",
	},

	-- ══════════════════════════════════════
	-- PHYSICAL ABILITIES (6 entries)
	-- ══════════════════════════════════════
	{
		id = "physical_speed",
		section = "PhysicalAbilities",
		title = "Speed Burst",
		factText = "Wolves can run 40 mph in short bursts and cruise at 10-15 mph over long distances. They can travel 20 to 30 miles in a single day!",
		unlockCondition = "Reach the FirstSteps growth stage",
	},
	{
		id = "physical_jaw",
		section = "PhysicalAbilities",
		title = "Powerful Jaws",
		factText = "A wolf's bite force is about 400 PSI on average and can reach up to 1,200 PSI — 2 to 5 times stronger than a German Shepherd!",
		unlockCondition = "Feed your wolf 10 times",
	},
	{
		id = "physical_swimming",
		section = "PhysicalAbilities",
		title = "Strong Swimmers",
		factText = "Wolves can swim up to 8 miles without stopping at 3 to 5 mph. They have slight webbing between their toes and waterproof outer fur!",
		unlockCondition = "Visit the River zone",
	},
	{
		id = "physical_paws",
		section = "PhysicalAbilities",
		title = "Snowshoe Paws",
		factText = "Wolf paws can be over 4 inches wide — about the size of your palm! Their wide paws act like snowshoes, spreading weight over snow.",
		unlockCondition = "Explore 3 different zones",
	},
	{
		id = "physical_endurance",
		section = "PhysicalAbilities",
		title = "Marathon Runners",
		factText = "Wolves rank 7th among all animals worldwide for endurance running. One wolf was recorded traveling 124 miles (200 km) in just 24 hours!",
		unlockCondition = "Reach the HuntTraining growth stage",
	},
	{
		id = "physical_travel",
		section = "PhysicalAbilities",
		title = "Long-Distance Traveler",
		factText = "Famous wolf OR-7 ('Journey') traveled over 1,000 miles from Oregon looking for a mate. A movie and book were made about his adventure!",
		unlockCondition = "Reach the YoungAdult growth stage",
	},

	-- ══════════════════════════════════════
	-- DIET (5 entries)
	-- ══════════════════════════════════════
	{
		id = "diet_daily_needs",
		section = "Diet",
		title = "Daily Needs",
		factText = "A wolf needs about 5 to 7 pounds of meat per day, but they can survive several days without eating when prey is scarce.",
		unlockCondition = "Feed your wolf for the first time",
	},
	{
		id = "diet_feast_famine",
		section = "Diet",
		title = "Feast or Famine",
		factText = "A wolf can eat up to 20 pounds of meat in a single meal — that's like eating 80 hamburgers in one sitting!",
		unlockCondition = "Feed your wolf 5 times",
	},
	{
		id = "diet_prey",
		section = "Diet",
		title = "What's for Dinner?",
		factText = "Wolves mainly eat large hoofed animals like elk, deer, moose, and caribou. They also eat beavers, hares, fish, and even some fruits and vegetables!",
		unlockCondition = "Visit the Hunting Grounds zone",
	},
	{
		id = "diet_teamwork",
		section = "Diet",
		title = "Teamwork Hunters",
		factText = "Wolves hunt cooperatively. They identify weaker or slower prey, isolate it from the herd, and take turns chasing it to conserve energy.",
		unlockCondition = "Reach the HuntTraining growth stage",
	},
	{
		id = "diet_caching",
		section = "Diet",
		title = "Saving for Later",
		factText = "Wolves bury leftover food underground up to half a mile away and dig it up later. This is called food caching — like having a secret fridge!",
		unlockCondition = "Feed your wolf 8 times",
	},
}

-- Build lookup table by id for fast access
local JournalDataById: { [string]: JournalEntry } = {}
for _, entry in JournalData do
	JournalDataById[entry.id] = entry
end

-- Build lookup table by section
local JournalDataBySection: { [string]: { JournalEntry } } = {}
for _, entry in JournalData do
	if not JournalDataBySection[entry.section] then
		JournalDataBySection[entry.section] = {}
	end
	table.insert(JournalDataBySection[entry.section], entry)
end

return table.freeze({
	Entries = table.freeze(JournalData),
	ById = table.freeze(JournalDataById),
	BySection = table.freeze(JournalDataBySection),
})
