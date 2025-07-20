# TranZit Zombies - A mapping guide

## Requirements

- A working cod4x linux server running the TranZit mod
- The CoD4 custom client of xoxor4d: https://github.com/xoxor4d/iw3xo-dev/tree/develop
- CoD4 together with its modtools
- A map you created and want to make ready for TranZit

## Configuration

Download the content of https://github.com/VikingKampfsau/tranzit/tree/main/cod4-modtools and paste into your CoD4 modtools installation.

## Step 1: Prepare your map for tranZit

Once you are done with the geometry of your map you are ready to add all the things required for proper TranZit gameplay.

This includes:
- Barriers at windows and doors where zombies have to break through. (Keep in mind - once the barrier is down players can move through too!)
- Blockers and doors to limit the play ground and give players the choice where to go first.
- Buildables which should be spread around the map to force the player to search their parts before crafting at the associated workbench.
- The triggers that determinate the locations of the play areas where players are not attacked by screechers.
- Path nodes for the vehicle driveway.
- The vehicle itself.

Feel free to create new barriers and blockers if those coming with the source do not fit your needs.
Just make sure the layout is identical, otherwise they will not work.

The path nodes for the zombie movement will be added in next step.

## Step 2: Prepare your map for compilation

With the latest release I completely changed the logic of waypointing and also moved the vehicle from a 'simple rotating' xmodel to an engine build-in solution.
This means that you don't have to place and connect waypoints manually, like you might know from pezbots, rotu or other bot mods.
Things are now similar to mapping for Singleplayer - You add nodes directly in radiant and the compiler connects them.

In order for the compiler to create and connect the waypoints, the map must be compiled in singleplayer mode.
The final result will be compiled in multiplayer mode.

Therefor create a subfolder in 'map_source' and give it the name of your multiplayer map.
Save your map without its worldspawn settings in this directory.

Within the 'map_source' folder create two new .map files:
# 1. mp_yourmapname
- Add the worldspawn settings
- Add your real map - the one you previously saved in the subfolder - as a prefab
- Add the player spawns (TDM) within the play areas
- Add the team start spawns for players (mp_tdm_spawn_allies_start) within the first play area
- Add the zombie spawns (DM) and a zombie team spawn (mp_tdm_spawn_axis_start) which is not used in TranZit but required by CoD4

# 2. sp_yourmapname
- Add the worldspawn settings
- Add your real map - the one you previously saved in the subfolder - as a prefab
- Add a singleplayer spawn (info_player_start)
- Add the path nodes for the zombie movement

## Step 3: Compile your map for Singleplayer

Compile your map for Singleplayer and launch it with the original Singleplayer of CoD4.
Enable developer mode and the dvars for the ai path development.
For easier access you can check or execute the aidev configs coming with the source.

You will now see the waypoints and their connections.
Waypoints that have dead ends or single links only will appear in red.
Move (or noclip) through the map and check for bad connections.

If necessary fix the bad path nodes in radiant and repeat step 3.

## Step 4: Extract the waypoints of your Singleplayer map

In 'mods/spmod/mapents' create a new file sp_yourmapname.ents and open it with notepad.
Insert this shema:
<code>
{
"sundiffusecolor" "0 0 0"
"suncolor" "0 0 0"
"classname" "worldspawn"
"diffusefraction" "0"
"ambient" "0"
"sunlight" "0"
"sundirection" "0 0 0"
"_color" "0 0 0"
"contrastgain" "0"
}
{
"origin" "XXX"
"angles" "0 0 0"
"classname" "mp_dm_spawn"
}
{
"origin" "XXX"
"angles" "0 0 0"
"classname" "mp_global_intermission"
}
</code>

From radiant copy the origins of the SP player spawn and replace XXX in the above origin values of the 'mp_dm_spawn' and the 'global_intermission'.

Launch iw3xo and select the spmod from the list of mods.
Start the map and use the command '/xasset_spworld 1'.

The game will freeze for a second and export the waypoints to 'cod4-root\iw3xo\spworld\node_dump.txt' IS THAT FILE NAME CORRECT?
Close the game.

Head over to the folder 'cod4-root\iw3xo\spworld\' and rename the 'node_dump.txt' file to 'mp_yourmapname_waypoints.csv'.
Copy this file and paste it into 'cod4-root\mods\_tranzit\navmeshtool\import'.

Go back to radiant and open your mp_yourmapname.map
Select all spawns and save the selection to 'cod4-root\mods\_tranzit\navmeshtool\import' too.
Name it 'mp_yourmapname_spawns.map'

## Step 5: Compile your map for Multiplayer

After building the fastfiles for the first time update the zone file and overwrite its content with this:
<code>
ignore,code_post_gfx_mp
ignore,common_mp
ignore,localized_code_post_gfx_mp
ignore,localized_common_mp

col_map_mp,maps/mp/XXX.d3dbsp

rawfile,maps/mp/XXX.gsc
rawfile,maps/mp/XXX.gsc
rawfile,maps/createfx/XXX.gsc

//sound,common,XXX,!all_mp
//sound,generic,XXX,!all_mp
//sound,voiceovers,XXX,!all_mp
//sound,multiplayer,XXX,!all_mp
sound,custom_map_ff_sounds_as_stream,XXX,!all_mp

fx,fire/firelp_barrel_pm
fx,props/securityCamera_explosion
fx,smoke/thin_black_smoke_L
fx,weather/fog_river_200
fx,tranzit/weather/fog_river_1000x1000
fx,tranzit/weather/rain
fx,tranzit/weather/thunderstorm

impactfx,XXX

xmodel,body_mp_usmc_specops
xmodel,head_mp_usmc_tactical_mich_stripes_nomex
xmodel,body_mp_usmc_sniper
xmodel,head_mp_usmc_tactical_baseball_cap
xmodel,body_mp_usmc_recon
xmodel,head_mp_usmc_nomex
xmodel,body_mp_usmc_assault
xmodel,head_mp_usmc_tactical_mich
xmodel,body_mp_usmc_support
xmodel,head_mp_usmc_shaved_head
xmodel,body_mp_arab_regular_cqb
xmodel,head_mp_arab_regular_headwrap
xmodel,viewhands_desert_opfor
xmodel,body_mp_arab_regular_sniper
xmodel,head_mp_arab_regular_sadiq
xmodel,body_mp_arab_regular_engineer
xmodel,head_mp_arab_regular_ski_mask
xmodel,body_mp_arab_regular_assault
xmodel,head_mp_arab_regular_suren
xmodel,body_mp_arab_regular_support
xmodel,head_mp_arab_regular_asad

# VEHICLE (FOR THE NEW SYSTEM)
rawfile,vehicles/humvee
xmodel,defaultvehicle_mp
xmodel,pb_vehicle_truck
</code>

Replace every instance of XXX with mp_yourmapname.

Warning: Compiling reflections will not work when the TranZit vehicle is added.
For compiling reflections you have to remove it (or change its classname from script_vehicle_mp to script_vehicle_mpZ), recompile bsp and then compile the reflections.
Build the fastfiles.

The information about reflections are written into the bsp, so you won't have to do this again unless you change the geometry.
After this you can add the vehicle (or rename the classname) again and compile bsp and fastfiles.

## Step 6: Transform waypoint and spawn files for usage in TranZit

No worries - the mod/server will do the job for you.

Add these three commands to your start.sh or server.cfg:
+set create_spawnfile 1
+set create_navmesh 1
+set navmeshtool_cleanup 2

explanations:
<code>
//create_spawnfile 0/1/2
//	1 -> convert the radiant spawns into csv
//	2 -> add the mapareas to an existing spawn csv of step 1

//create_navmesh 0/1
//	1 -> add the mapareas to an existing waypoint csv

//navmeshtool_cleanup 0/1/2
//	1 -> delete all temp files but dont move the output to the waypoints folder
//	2 -> delete all temp files and move the output to the waypoints folder
</code>

Boot the server with your map and check the console log for errors.
The server will auto quit when it succeeded.

When all went good you will have working waypoint and spawn files in 'cod4-root\mods\_tranzit\navmeshtool\export'.
With navmeshtool_cleanup 2 they were copied to 'cod4-root\mods\_tranzit\waypoints' as well.
This is the place the mod expects them when starting a server for playing.

Remove the previous commands from the startparameter (or set them all to 0) and you can go for a first test play of your map!

## Support
For bug reports and issues, please visit the "Issues" tab at the top.<br/>
First look through the issues, maybe your problem has already been reported.<br/>
If not, feel free to open a new issue.<br/>

**Keep in mind that we only support the current state of the repository - older versions are not supported anymore!**

However, for any kind of question, feel free to visit our discord server at https://discord.gg/wDV8Eeu!