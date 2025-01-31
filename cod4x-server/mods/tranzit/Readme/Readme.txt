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