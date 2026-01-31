@echo off
echo Starting CoD4x Dedicated Server...

start "" cod4x18_dedrun.exe ^
+set net_port 28960 ^
+set fs_homepath C:/Users/Viking/cod4_server/ ^
+set fs_game mods/_tranzit ^
+exec server.cfg ^
+set rcon_password "hello-world" ^
+set r_xassetnum "xmodel=1200 xanim=3200 image=3000 fx=500" ^
+set g_gametype "tranzit" ^
+set sv_maxclients "64" ^
+set ui_maxclients "64" ^
+map mp_forsaken_world

echo Server command executed. Check server console for status.
pause