# Project Structure Notes

- The project uses Godot `4.7`.
- The project's main scene is `core/main.tscn`.
- `core/main.tscn` has one attached node: a screen container.
- Screen examples live in the `screens` folder, such as the start screen and game screen scenes.
- Switching between screens is handled by the global autoload `ScreenManager`.
- Existing global autoloads include `ScreenManager` and `Type`.
- The project assumes the main screen container exists.
- When the game opens, the start screen is attached to the main screen container.

# Entity Organization

- Game entities such as players, enemies, and materials live in the `entities` folder.
- Each entity should have its own subfolder.

# UI Organization

- UI-related scenes such as buttons, menus, cards, and similar components live in the `UI` folder.
- Each UI component should have its own subfolder.

# Scripts And Buses

- If a script is assigned to a scene, place the script beside that scene.
- Manager scripts live in the `managers` folder.
- Signal buses live in the `buses` folder.
- Only global autoload managers, buses, or similar scripts should be stored in the `autoloads` folder.
- Screen-dependent scripts, managers, or buses should be placed beside their respective screen scene.

# Game Loop

- Each stage contains three entities:
  - The knight.
  - The porter.
  - The stage enemy.
- Killing the stage enemy advances the stage by one.
- Clearing stage 100 wins the game.

# Game Architecture

- Use a global state autoload for stage, gold, inventory, upgrades, and save/load coordination.
- Autosave stage progress, inventory, gold, locked loot, and upgrades after important changes.
- Define combat, loot, stage scaling, loot values, and upgrade costs through Godot resources or data files.

## Stage Enemy

- The stage enemy has health and damage stats.
- The stage enemy contains a set of loot.
- As the knight damages the stage enemy, the enemy drops loot behind the knight.
- When killed, the stage enemy drops all remaining loot and advances the stage by one.
- The stage enemy attacks the knight once in a while.
- Every 10th stage is a boss stage.
- Boss enemies have considerably higher health, but are only a little stronger than every 9th stage enemy.
- Enemy loot drops happen at configured health percentage thresholds.
- If the stage enemy kills the knight, the knight returns to the stage after the last cleared boss stage.

## Knight

- The knight only attacks the stage enemy.

## Porter

- The porter always follows the knight.
- The porter collects all dropped loot behind the knight.
- The porter has two abilities: Heal and Power-up.
- Heal and Power-up are player-triggered buttons, not automatic abilities.
- Heal restores 80% of the knight's health.
- Only Heal's cooldown is upgradable.
- Power-up boosts the knight's damage.
- Power-up's damage multiplier and cooldown can be upgraded.
- The porter walks faster if the user swipes, presses, or taps the loot.
- The loot interaction is intended to motivate the player to interact more with the game.

# Viewport And UI Layout

- The game is aimed at phones and should use a portrait viewport.
- The target portrait viewport is `360x640`.
- The visual style should be cozy pixel RPG with readable phone-first UI.
- The upper half of the screen shows the knight fighting the stage enemy.
- The lower half of the screen contains inventory, upgrades, and special upgrades.
- The lower half should use tabs for Inventory, Upgrades, and Special Upgrades.
- The end or congratulations screen should tell the player they cleared the game and encourage them to screenshot it and tell Kent they beat the game.

## Inventory

- Inventory stores collected loot.
- Inventory displays counters for each collected loot type.
- Inventory can only hold a certain amount of loot.
- Inventory capacity can be upgraded.
- The player can sell all loot of a certain kind.
- The player can sell the entire inventory.
- The player can lock certain loot so it is not accidentally sold when selling all.
- Locked loot is useful when the player wants to save materials for upgrades.
- The player does not control how many of each loot type to sell.
- Selling is either all loot of a selected kind or all unlocked loot in the inventory.

## Gold Upgrades

- Gold upgrades are paid for with gold earned by selling materials.
- Knight's Damage.
- Knight's Health.
- Bag Capacity.

## Special Upgrades

- Special upgrades are paid for with materials.
- Knight's Attack Speed.
- Knight's Health Regen per Second.
- Knight's Health Multiplier.
- Porter's Potion Cooldown.
- Porter's Tonic Effect Multiplier.
- Porter's Tonic Cooldown.

# GitHub Workflow

## Issue Creation

- When the user says they want to post an issue, create an issue in the GitHub repository.
- Add an appropriate label to the issue.

## Issue Handling

- When tackling an issue, create a separate branch for the work.
- Work on the issue only on that branch.
- Update the README documentation on the same branch when the issue changes documented behavior, structure, or workflows.
- Commit the implementation and README documentation together, or as related commits on the same branch.
- Create a pull request for the branch.
- Attach the issue to the pull request.
- Merge the pull request to `main` when the issue is ready to complete and the user has asked for the full issue workflow.
- Use squash merge when merging issue pull requests into `main`.
