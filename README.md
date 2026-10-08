Bizhawk Script for messing with Stale Reference Manipulation (SRM) in the Legend of Zelda: Phantom Hourglass. Work in progress! The graphics code is not very optimized yet so it make the game real slow when there are lots of actor loaded.

## How to Install
1. Download actor_script.lua
2. Open with the Lua Console in Bizhawk 2.10+

## What can it do?
On launch the `Actor Viewer` shows some useful info about what actors are loaded in a scene. There are plenty that have not been labeled yet. It highlights what slot in memory link is holding when you have a stale reference, and lets you select actors for doing stuff with them.
The `SRM Toolkit` window shows some SRM related info, like the next actor index and link's current held actor. There are currently 3 buttons.
- `Delete`: Deletes the currently selected actor from the scene.
- `Hold`: Matches the reference for link's held actor to the selected actor, as if you'd put it there with SRM. For testing what's possible after SRM-ing it, or for being silly and putting your boat on land.
- `Overflow`: Maxes out the next actor index, as if you're performing SRM. For finding viable setups.

## How to perform SRM in Phantom Hourglass
1. Hold an actor, and remove it without playing any animations that reset Link's reference. There are currently 4(ish) known methods:
    - Hold a bomb, and have it explode while you have invulnerability frames.
    - Hold a bomb, and have it explode while standing in a safe zone.
    - Hold a bomb, and have it explode while running such that you outrun the explosion without taking damage.
    - Hold any actor, and swap to Gongoron
2. You goal is now to load your desired actor into the same memory slot that link was holding, with the same actor index, to create a link.
Each new actor that is created is assigned the next actor index.
The only known way to assign the same index multiple times is to overflow it.
Since this is an unsigned 32bit integer, this can take a long time.
    - The fastest known way is to reload the rupoor room on Isle of the dead over and over, since it has 0x75 actors. This takes approximately 9 years.
    - For more precision, most of links items create new actors each time you use them. Boomerang, grapple, arrows, bombs, bombchus and sword beams all work.
3. Congratulations! You've now holding something that you shouldn't! Place it near link to move it to that position, taking into account any collision and gravity checks on the way.
This does not remove the reference from link, so you can repeat it until the actor despwans. Throw it to reset the reference, without updating the position.

## Known SRM Applications
Nothing! so far... happy glitchhunting!

## Images
<img width="1359" height="801" alt="image" src="https://github.com/user-attachments/assets/01473a2e-ebca-4bc5-acfe-65438dd786f7" />
<img width="1340" height="794" alt="image" src="https://github.com/user-attachments/assets/a52eb117-14ad-4d5d-b31e-fa41af86bcf3" />

