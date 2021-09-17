*****************************************************
*		  TranZit by Viking		    *
*		  steam: vikingkampfsau		    *
*		  discord: viking#1191		    *
*****************************************************

*****************************************************
*		  Installation			    *
*****************************************************

Install cod4x and add the required plugins to it.
Copy the mod to your mods folder and the map to your usermap folder, if you already have an older version then remove it.

*****************************************************
*		  Important Notes & Troubleshooting		    *
*****************************************************

1) CoD4x and some custum plugins are required to run this mod.
-> Get cod4x from www.cod4x.me or compile it with the source on github.

2) The plugin handler of CoD4x changed and the plugins do not work anymore
-> You have to recompile the plugins using the source of the plugins and cod4x.
-> The source code of all required plugins are included within this package.

3) Server / Clients crash with the error: "file sum/name mismatch"
-> Keep the name of the modfolder and the name of the iwd file/s inside as short as possible.
-> If you still get the "file sum/name mismatch" error try to split the iwd into seperated pieces.

4) The server crashs with an error like this:
^1Error: unknown function: (file 'scripts/barricades.gsc', line 65)
 addWpNeighbour(getNearestWp(waypoints[0].origin, 0), getNearestWp(waypoints[1].origin, 0));
-> Make sure the lua scripts are in the correct folder and loaded correctly.
-> Place the lua_scripts folder where your server generated the sys_error.txt

*****************************************************
*		     Notes			    *
*****************************************************
Since the mod has lots of new weapons and models,
some maps are not compatible.
To get them running please increase the xmodel limit with cod4x.
I recommend the following line within your start parameter:
+set r_xassetnum "material=2560 xmodel=1200 xanim=3200 image=3000" 

Also read the Credits.txt and the Weapons.txt to
get further informations about the new/replaced
weapons and their authors.

*****************************************************
*	       Additional Notes	    		    *
*****************************************************

All original and composed textures or assets in this 
modification remain property of the sources respective
owners.

All used sound tracks are licensed by it's original
owners and were used for promotional use only.

*****************************************************
*		Changelog			    *
*****************************************************
v 1.03 (August - September 2021)
- Added a ranksystem
- Added the Wunderwaffe (misterybox) and it's electric damage
- Added the electric avogardo zombie with it's anims and effects
- Added an emp grenade, it will also shut down machines when thrown badly
- Added more light to the houses in mp_forsaken_world
- Added background lights to the wallweapons for easier find
- Added german translation
- Added the wavegun as a craftable object to the map
- Added new hud icons for the craftable monkey bomb
- Fixed the translation spelling mistakes
- Fixed the language selection menu
- Fixed some waypoints
- Fixed the calculation of the craftable object rotation in map
- Fixed the destruction of generator
- Changed the perk system - bought perks are now disabled when the power of the perk machine is lost
- Changed the misterybox - No teddy for the first 4 usages!
- Changed the time to enable the power - it's now a bit faster
- Removed the powerup drop when killing a wasteland dwarf
- Removed some unused animations

v 1.02 (July 2021)
- Added russian translations
- Added a credits page in main menu and esc menu
- Added a tutorial page to main menu, esc menu and for new players
- Added a new spawn system for the zombies
- Added flamethrower sounds
- Added a max distance check to the monkey bomb
- Fixed the flamethrower fx
- Fixed the flamethrower tank position
- Fixed the model of the ammobox and the openening fx
- Fixed the light indicator of the mistery box
- Fixed the background light of zombie drops
- Fixed the minigun overheat hud display
- Fixed the zombie spawn fx

v 1.01 (June 2021)
- Fixed the not updating ready-up status text
- Fixed heavy lags when players are in fog
- Fixed some broken weapon upgrades
- Fixed zombies get stuck in stairs
- Fixed double perk display
- Added a tutorial menu popup on first visit

March 2021 (first alpha test)

March 2020 (started to develop the mod and map mp_forsaken_world)