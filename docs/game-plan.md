# Wolf Sanctuary — Game Design Plan

> A Roblox educational game where kids adopt, raise, and learn about wolves through play.
> Target audience: ages 5-12. Built on Knit framework with existing template services.

---

## Core Loop

```
Adopt Pup → Care & Train → Explore Sanctuary → Discover Facts → Unlock Abilities → Grow Wolf → Expand Territory
     ↑                                                                                              |
     └──────────────────────────── Start new pup / new species ←────────────────────────────────────┘
```

**Session loop (5-15 min):** Feed wolf → check pup milestones → do a minigame or patrol → discover a fact → earn journal entry → log off with progress saved.

---

## Design Pillars

1. **Care First, Learn By Caring** — Nurturing wolves IS the game. Facts are embedded in mechanics, not quizzes.
2. **Collection as Curriculum** — Every collectible slot = a fact learned. Field Journal, Howl Library, Coat Gallery.
3. **No Failure, Only Discovery** — No death, no lost items. Everything is forward progress.
4. **Real Science, Real Stories** — All facts sourced from National Geographic Kids, International Wolf Center, Smithsonian, NPS.

---

## Phase 1: Core Sanctuary (MVP)

The playable foundation. A single sanctuary biome with one wolf, basic care, and fact discovery.

### 1.1 Wolf Pup Adoption & Growth

**The hook feature.** Player adopts a wolf pup that grows through real developmental stages across play sessions.

| Stage | Real Age | In-Game Day | What Unlocks |
|-------|----------|-------------|--------------|
| Newborn | 0-10 days | Day 1 | Soft-focus view, muted audio (pup is blind/deaf) |
| Eyes Open | 11-15 days | Day 2 | Vision clears, world gets color — "Your pup can see!" |
| First Steps | 2-3 weeks | Day 3 | Walking ability, can explore den |
| Outside Den | 3 weeks | Day 5 | Den exit unlocked, first outdoor area |
| First Howl | 4-5 weeks | Day 10 | Howl ability, basic communication |
| Rendezvous | 8 weeks | Day 15 | Leave den permanently, full sanctuary access |
| Hunt Training | 12 weeks | Day 20 | Pup School minigames, pack hunt training |
| Young Adult | 6 months | Day 30 | Near-adult appearance, all abilities |
| Full Grown | 1 year | Day 45 | Mature wolf, can start own pack |

**Implementation:**
- `WolfService` — server-side wolf state (stage, stats, age tracked via play-session days)
- `WolfController` — client-side wolf rendering, milestone cutscenes
- `WolfData` module — stage definitions, unlock tables, visual configs
- Player data stores wolf stage progress (survives across sessions)
- Each milestone triggers celebration VFX + fact popup + journal entry

### 1.2 Sanctuary World

An open sanctuary environment with zones that unlock as the wolf grows.

| Zone | Unlocks At | Contains |
|------|-----------|----------|
| Den | Start | Birth den, warm lighting, cozy space |
| Meadow | Day 3 (First Steps) | Open grass, basic prey (rabbits), flowers |
| Forest | Day 5 (Outside Den) | Trees, scent trails, hiding spots |
| River | Day 10 (First Howl) | Water, fish, swimming area |
| Ridge | Day 15 (Rendezvous) | High viewpoint, territory overview, howl echo point |
| Hunting Grounds | Day 20 (Hunt Training) | Elk herds, cooperative hunt area |

**Implementation:**
- Zones built in Studio with unlock gates (invisible walls that dissolve on milestone)
- `ZoneService` manages unlock state per player
- Each zone has ambient wildlife, interactive objects, and discoverable facts

### 1.3 Care System

Basic wolf care that teaches real biology.

| Action | Mechanic | Teaches |
|--------|----------|---------|
| Feed | Bring food to wolf (drag from food station) | Diet: 5-7 lbs/day, elk/deer/fish/rabbits |
| Groom | Click-to-brush during shedding season | Seasonal fur cycle, two-layer coat system |
| Play | Throw toy / play bow triggers chase game | Play as learning — pups learn to hunt through play |
| Rest | Guide wolf to den at night | Sleep behavior, curling up, nose-under-tail |

**Implementation:**
- `CareService` — tracks hunger/energy/happiness (simple 3-stat system)
- `CareController` — UI for care actions, proximity-based interactions
- Stats decay slowly over real time — wolf is never "dying," just "could use attention"
- Each care action shows a fact tooltip: "Wolves eat 5-7 lbs of meat per day!"

### 1.4 Wolf Field Journal

The collection/progression spine. A book that fills as players discover facts.

**Sections:**
- Wolf Basics (10 entries) — size, weight, lifespan, eye color changes, etc.
- Pack Life (8 entries) — family structure, alpha myth debunked, omega role, etc.
- Senses (5 entries) — smell (200M cells), hearing (80 kHz), night vision, etc.
- Physical Abilities (6 entries) — speed (40 mph), jaw strength (400 PSI), swimming, etc.
- Diet (5 entries) — prey types, feast-or-famine, food caching, etc.

**How entries unlock:**
- Milestone events (pup eyes open → "Wolf Basics: Eye Color" entry)
- Care actions (feeding → "Diet: Daily Needs" entry)
- Zone exploration (finding a scent trail → "Senses: Smell" entry)
- Minigame completion

**Implementation:**
- `JournalService` — server-side tracking of unlocked entries
- `JournalController` — client UI, animated page fills, sparkle on new entry
- `JournalData` — all entries with facts, images/icons, unlock conditions
- Completing a section earns a cosmetic reward (collar color, fur pattern)

### 1.5 Basic Howl System

Wolf communication as the primary social mechanic.

**Howl types (Phase 1):**
- Rally Call — plays gathering howl, nearby NPC pack members come to you
- Location Ping — marks your position for other players (multiplayer)

**Implementation:**
- `HowlService` — howl type registry, cooldowns, range
- `HowlController` — howl wheel UI (radial menu), sound playback, visible sound-wave VFX
- Howls have real audio designed to match actual wolf vocalizations

---

## Phase 2: Social & Education Depth

Add multiplayer, deeper education, and the systems that drive long-term engagement.

### 2.1 Pack System (Multiplayer)

Players form packs of 2-6. Pack members share territory and can do cooperative activities.

- Pack creation (invite friends)
- Shared territory with combined scent coverage
- Pack Howl: 3+ wolves howling together triggers amplified effect + bonus VFX
- Alloparenting: pack members can help care for each other's pups

### 2.2 Scent Tracking ("The Nose Knows")

"Detective mode" that shifts the visual palette to show scent trails.

- Toggle "Scent Vision" — world becomes stylized, trails glow as colored ribbons
- Prey trails (amber), other packs (red), water (blue), pack members (green)
- Trails fade over time — follow before they disappear
- Leads to discoveries, hidden areas, and journal entries
- Fact: "Wolves have 200 million scent cells — 40x more than humans!"

### 2.3 Body Language Emotes

Replace standard chat with wolf body language.

| Emote | Wolf Behavior | Game Effect |
|-------|--------------|-------------|
| Play Bow | Front legs down, rear up | Triggers play minigame with nearby wolf |
| Tail High Wag | Confident greeting | Speed boost to nearby pack members |
| Ears Flat + Crouch | Submissive greeting | Calms aggressive NPC animals |
| Hackles Raised | Territorial display | Marks territory, warns NPC rivals |

### 2.4 Pup School Minigames

Teaching pups = teaching players.

| Minigame | Mechanic | Teaches |
|----------|----------|---------|
| Pounce Practice | Timing — pup pounces on mice under snow | Hunting through play |
| Howl Lessons | Simon Says — match howl patterns | Communication types |
| Play Fighting | Rhythm game — wrestling sequences | Social bonding |
| Scent School | Memory matching — identify scent types | Olfactory navigation |
| Swim Class | River navigation — dodge rocks | Wolves swim up to 8 miles |

### 2.5 Myth Busters Station

NPC "Wolf Scientist" presents myths. Players investigate through minigames.

- "Wolves howl at the moon" → False (they tilt heads to project sound)
- "Alphas fight to be leader" → Mostly false (pack = family, parents lead)
- "Wolves are dangerous to humans" → Extremely rare
- Each earns a "Truth Badge" — visible on player's wolf

---

## Phase 3: Ecosystem & World

The big systems that show wolves' role in nature.

### 3.1 Yellowstone Cascade Garden

The signature educational feature. A barren zone that regenerates as players manage wolves well.

**Progression over days:**
1. Overgrazed wasteland — bare soil, no trees
2. Grasses return — elk stop overgrazing because wolves keep them moving
3. Willows grow along river — real data: 1,500% increase in willow volume
4. Beavers arrive — build dams (1 colony → 9, real Yellowstone numbers)
5. River health improves — fish return, water clears
6. Songbirds nest in willows — new bird species appear
7. Full ecosystem — before/after comparison, Discovery Card for each stage

### 3.2 Territory Patrol

Claim and maintain territory by running borders and laying scent markers.

- Scent markers (glowing pawprints) fade over real time — must re-patrol
- Territory heat map shows coverage
- Faded markers let NPC rival packs encroach
- Random discoveries while patrolling (fossils, rare plants, hidden dens)
- Fact: "Wolf territories range from 31 to 1,200 square miles!"

### 3.3 Pack Hunt Rally

Cooperative multiplayer event (3-6 players) using real wolf strategies.

**Phases:**
1. **Scouting** — scent tracking to find herd
2. **Stalking** — stealth meter, stay downwind
3. **Targeting** — identify weakest elk (visual cues: limping, smaller)
4. **Herding** — cut off escape routes, surround
5. **Chase** — take turns leading to conserve stamina (real strategy)

- Targeting a healthy elk = hunt fails (teaches natural selection)
- 10-15% success rate (accurate) — failing is normal and expected
- Successful hunts earn major rewards

### 3.4 Seasonal Cycle

1 real week = 1 in-game season. Each changes gameplay and wolf appearance.

| Season | Wolf Change | World Change | Gameplay |
|--------|-----------|-------------|----------|
| Winter | Thick coat, larger silhouette | Snow, frozen river | Snow tracking, winter survival facts |
| Spring | Shedding (visible tufts) | Flowers, pup season | New pup milestones, nesting |
| Summer | Sleek coat | Green, full river | Fishing, swimming, exploration |
| Autumn | Coat thickening | Leaves falling, prey migrating | Food caching, territory expansion |

---

## Phase 4: Endgame & Monetization

Long-term engagement, cosmetics, and revenue.

### 4.1 Wolf Species Collection

After mastering gray wolf, unlock new species to raise:

| Species | Biome | Unique Mechanic |
|---------|-------|----------------|
| Gray Wolf | Temperate forest | Standard (tutorial species) |
| Arctic Wolf | Tundra/snow | Extreme cold survival, white camo |
| Red Wolf | Southeastern wetland | Conservation story (only ~30 in wild) |
| Ethiopian Wolf | Highland grassland | Rarest canid, solo hunting |
| Mexican Gray Wolf | Desert canyon | Reintroduction narrative |

Each species has unique journal pages, coat genetics, and conservation stories.

### 4.2 Coat Genetics Lab

"Breed" wolves by selecting parent pairs → pup coat colors follow real genetics.

- Gray = most common (dominant)
- Black = came from domestic dogs thousands of years ago (real fact!)
- White = Arctic adaptation
- Rare patterns are collectible goals
- Teaches: dominant vs. recessive traits, inheritance

### 4.3 Conservation Rescue Missions

Periodic story events based on real scenarios:

1. Wolf in trap → stealth approach, calm with body language, call ranger
2. Lone wolf in wildfire → follow scent trail through burnt forest
3. Territory threatened by road → collect evidence for NPC town council
4. Sick wolf needs vet → diagnosis puzzle

### 4.4 Monetization (via existing ShopService)

| Item Type | Examples | Price Range |
|-----------|---------|-------------|
| Cosmetic collars | Studded, flower crown, ranger badge | 50-200 Robux |
| Den decorations | Fairy lights, rock formations, pelts | 25-150 Robux |
| Special effects | Custom howl echo colors, paw trail effects | 75-250 Robux |
| Species unlocks | Early access to Arctic/Red/Ethiopian wolf | 299-499 Robux |
| Game Pass: Naturalist | 2x journal XP, exclusive night pages | 499 Robux |
| Game Pass: Pack Leader | Larger pack size (8), custom territory banner | 699 Robux |

**No pay-to-win.** All educational content and core gameplay is free. Monetization is cosmetics and convenience only.

---

## Technical Architecture

Built on existing template infrastructure:

```
ServerScriptService/Server/Services/
├── WolfService.luau          -- Wolf state, growth stages, stats
├── CareService.luau          -- Feeding, grooming, play interactions
├── JournalService.luau       -- Fact discovery, entry unlocks
├── HowlService.luau          -- Howl types, cooldowns, multiplayer sync
├── ZoneService.luau          -- Zone unlocks, exploration tracking
├── PackService.luau           -- Pack formation, membership (Phase 2)
├── TerritoryService.luau      -- Territory claiming, scent markers (Phase 3)
├── HuntService.luau           -- Cooperative hunt events (Phase 3)
├── EcosystemService.luau      -- Yellowstone cascade simulation (Phase 3)
├── PlayerDataService/         -- [EXISTS] Save/load wolf + journal progress
├── ShopService/               -- [EXISTS] Monetization
├── MonetizationService/       -- [EXISTS] Game passes, dev products
├── AnalyticsService/          -- [EXISTS] Track engagement metrics
└── LiveConfigService/         -- [EXISTS] Tune care rates, growth speed remotely

ReplicatedStorage/Shared/
├── Data/
│   ├── WolfData.luau          -- Stage definitions, stat configs
│   ├── JournalData.luau       -- All 34+ journal entries with facts
│   ├── HowlData.luau          -- Howl type definitions
│   └── ZoneData.luau          -- Zone configs, unlock requirements
├── Enums/
│   ├── WolfStage.luau         -- Newborn, EyesOpen, FirstSteps, etc.
│   ├── WolfSpecies.luau       -- Gray, Arctic, Red, Ethiopian, Mexican
│   ├── JournalSection.luau    -- Basics, PackLife, Senses, etc.
│   └── HowlType.luau          -- Rally, LocationPing, Territory, Danger
└── Types/                     -- [EXISTS] Type definitions

ReplicatedStorage/Client/Controllers/
├── WolfController.luau        -- Wolf rendering, animations, milestone VFX
├── CareController.luau        -- Care UI, proximity interactions
├── JournalController.luau     -- Journal book UI, page animations
├── HowlController.luau        -- Howl wheel, sound playback, wave VFX
├── ZoneController.luau        -- Zone transition effects, unlock animations
└── ScentController.luau       -- Scent Vision mode toggle + trail rendering (Phase 2)
```

### Player Data Schema (extends existing Template.luau)

```lua
{
    Wolf = {
        Species = "Gray",
        Stage = "Newborn",       -- WolfStage enum
        PlayDays = 0,            -- Incremented each session
        Name = "",
        CoatColor = "Gray",
        Stats = {
            Hunger = 100,
            Energy = 100,
            Happiness = 100,
        },
    },
    Journal = {
        UnlockedEntries = {},    -- Set of entry IDs
        CompletedSections = {},  -- Set of section names
    },
    Howls = {
        Unlocked = { "Rally" },  -- Howl types unlocked
    },
    Zones = {
        Unlocked = { "Den" },    -- Zones accessed
    },
    Cosmetics = {
        OwnedCollars = {},
        OwnedDenItems = {},
        EquippedCollar = nil,
    },
}
```

---

## Implementation Priority

### Sprint 1 (Week 1-2): Pup & Den
- Wolf pup model + basic animations (idle, walk, sit)
- Den zone built in Studio
- WolfService + WolfController with stage tracking
- Newborn → Eyes Open → First Steps milestones
- Basic fact popups on milestones

### Sprint 2 (Week 3-4): Care & Meadow
- Care system (feed, groom, play)
- Meadow zone with ambient rabbits/birds
- Hunger/Energy/Happiness stats with gentle decay
- Care action fact tooltips
- Journal UI (basic version — list of unlocked entries)

### Sprint 3 (Week 5-6): Exploration & Howls
- Forest + River zones
- Howl system with Rally Call + Location Ping
- Sound-wave VFX for howls
- Zone unlock transitions
- Journal entries for exploration discoveries

### Sprint 4 (Week 7-8): Polish & Launch Prep
- All 6 zones playable
- Full growth timeline (Newborn → Full Grown)
- 20+ journal entries implemented
- Milestone celebration cutscenes
- Mobile UI optimization
- Sound design pass
- Analytics events for key metrics

**Post-launch:** Phase 2 features (multiplayer packs, scent tracking, emotes, minigames) based on engagement data.

---

## Key Metrics to Track

| Metric | Target | Why |
|--------|--------|-----|
| D1 Retention | 40%+ | Did the pup hook work? |
| D7 Retention | 20%+ | Are milestones paced well? |
| Avg Session Length | 8-15 min | Age-appropriate session |
| Journal Entries/Session | 1-2 | Learning rate |
| Milestone Completion Rate | 70%+ reach Day 5 | Growth pacing |
| Care Actions/Session | 3-5 | Care loop engagement |

---

## What Makes This Different

Most Roblox animal games are collection-focused ("hatch eggs, get rare pets"). Wolf Sanctuary is **care-focused with embedded education**:

1. **One wolf, deep bond** — not 100 pets. Your wolf has a name, grows over weeks, has real biology.
2. **Facts ARE gameplay** — your pup's eyes literally open, teaching you that wolves are born blind. You don't read it; you experience it.
3. **The Yellowstone story** — no other Roblox game teaches trophic cascades. Watching a wasteland become a forest because your wolves exist is powerful and unique.
4. **Real science credibility** — every fact sourced from peer-reviewed and educational institutions. Parents can feel good about this game.
