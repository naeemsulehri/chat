# Shuffle Up 🃏

A mobile-first (portrait) **card games hub** built with **Godot 4.3 (GDScript)**.
UI in **English and Urdu (اردو)**.

| Game | Status |
|---|---|
| Rang / Court Piece | ✅ Playable: 1 human + 3 bots, teams of 2 |
| Seep | ✅ Playable: 4 players (teams) or 2 (head to head) |
| Poker | Coming soon |
| Bluff | Coming soon |
| Daketi | Coming soon |

## Run it

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → choose `project.godot` in this folder.
3. Press **F5**. The window is a portrait phone (720×1280 design size, stretches to any aspect).

For Android, install the Android export template in Godot and export with *Project → Export*.
The renderer is *Compatibility* (OpenGL ES 3), so it runs on low-end phones too.

## Project layout

```
core/                     Shared engine for every game
  card_data.gd            CardData: suit + rank (pure data)
  deck.gd                 Deck: 52 cards, seeded shuffle
  card.gd / card_face.gd  Card visual: move / flip / glow / shine / dim tweens, vector-drawn faces
  hand.gd                 Hand: fan / row / column layouts, sorting, selection
  card_table_game.gd      Base for every table screen: layout per seat, deal / shuffle / sweep
                          animations, tap-to-select input, pause, game over
  ui/table_hud.gd         Shared HUD: score bar, info box, seat tags, banners, choice picker, overlays
  suit_shapes.gd          Vector suit symbols (no font glyphs needed)
  game_rules.gd           GameRules: the interface every game implements
  bot_player.gd           BotPlayer base: Easy / Medium / Hard
  game_registry.gd        List of games shown on the menu
  fx/                     Screen shake camera, confetti + sparkle particles
  autoload/               Settings, I18n (EN/UR), UITheme, Sound (synthesised SFX), Router
games/rang/               Rang / Court Piece module
  rang_rules.gd           Rules engine (no visuals, fully testable)
  rang_bot.gd             AI: easy (random-ish), medium (heuristics), hard (card counting, voids)
  rang_game.gd/.tscn      Table controller and animations
games/seep/               Seep module (rules, bot, table)
ui/                       Main menu, generic game-setup screen, felt background
assets/shaders/           Card shine/dim, card glow, table felt
assets/fonts/             Nunito + Noto Naskh Arabic (Urdu), SIL OFL
tests/                    Headless rules/AI tests + visual preview scenes
```

### Adding a new game

1. Create `games/<id>/<id>_rules.gd` extending `GameRules`. Implement `get_options()`, `setup()`,
   `start_round()`, `get_valid_moves()`, `play_card()`, `score_round()`, `is_game_over()`, `get_winner()`.
2. Add a bot extending `BotPlayer` and a table scene extending `CardTableGame`
   (implement `_setup_game()` and `_run_match()`; see `rang_game.gd` / `seep_game.gd`).
3. Add an entry to `core/game_registry.gd` with `available: true`.
   The setup screen builds itself from `get_options()`.
4. Add UI strings (English + Urdu) to `core/autoload/i18n.gd`.

## Rang / Court Piece: house rules implemented

- 4 players, partners sit opposite each other (You + Sara vs Bilal + Hamza). Play goes counter-clockwise.
- The deal passes to the next player each round. The player after the dealer gets **5 cards first and picks trump**,
  then everyone gets the remaining 8 (4 + 4).
- The caller leads the first trick. You must follow suit if you can; the highest trump wins, otherwise the highest card of the led suit.
- **Selectable before each game:**
  - **Trick counting:** *Simple* (every trick counts, first team to 7 tricks wins the round) ·
    *Sar* (tricks pile up in the middle; win 2 in a row to collect the pile; the last trick takes what's left) ·
    *Sar, no Ace* (like Sar, but a trick won with an Ace can't collect).
  - **Two in a row by:** the same player or the same team (Sar modes).
  - **Points to win the match:** 5 / 7 / 10.
  - **Court bonus:** 2 or 3 points.
  - **Computer level:** Easy / Medium / Hard.
- **Scoring:** a round win is 1 point. Winning the first 7 tricks before the other team takes one is a **Court** (bonus points).
  Taking all 13 is a **Bavan Court** (double the Court bonus). In Simple mode, play continues after a Court to try for a Bavan.

## Seep: rules implemented

Classic rules as described on pagat.com. Card values: A = 1, 2–10, J = 11, Q = 12, K = 13.

- **Bidding:** the player after the dealer gets 4 cards and bids a house value from 9 to K; they must hold that card
  (redeal if they hold none). Four cards go face up on the table, then the bidder must play their bid:
  build a house of that value, capture with that card, or throw it.
  Then everyone is dealt up to 12 cards.
- **On your turn** you play one card to:
  - **Throw** it loose on the table.
  - **Capture** every loose card and house equal to its value, plus combinations of loose cards that add up to it.
  - **Build** a house (card + loose cards), holding another card of the house value to capture it later.
  - **Cement (pakka)** a house of the same value, which then can't be raised.
  - **Raise** an opponent's open house to a higher value you hold.
- **Points per deal (100 total):** each spade = its value, other Aces = 1, the 10 of Diamonds = 6.
  A **Seep** (clearing the table) earns a bonus. Clearing it on the very last play doesn't count.
  Cards left at the end go to the last side that captured.
- **Selectable before each game:**
  - **Players:** 4 (teams) or 2 (head to head, 24 cards each in two halves).
  - **Match length:** *Baazi*, play until one side leads by 100 (classic) · first to 200 · one deal.
  - **Seep bonus:** 50 or 25.
  - **House values:** 9–K (classic) or any value.
  - **House owner can't throw:** while you own a house you must capture, build or cement instead.
  - **Computer level:** Easy / Medium / Hard.
- **On mobile:** tap a card and the possible moves pop up as buttons ("Take 3 cards", "Build house J·11", "Throw"…).
  Table cards the first move would use glow.

## Tests

```bash
godot --headless --import
godot --headless -s res://tests/test_rang.gd          # rules + 360 bot matches + AI strength check
godot --headless -s res://tests/test_seep.gd          # every Seep variant, 2 & 4 players, card/point totals
godot res://games/rang/rang_game.tscn -- --autoplay   # watch 4 bots play a full match
godot res://tests/card_gallery.tscn                   # all 52 card faces
```

Dev flags (after `--`): `--autoplay`, `--speed=3`, `--opt=players=2` (override an option),
`--shot=/path.png@2.5` (save a screenshot after 2.5 s), `--tap=360,1150@3` (simulate a tap).
