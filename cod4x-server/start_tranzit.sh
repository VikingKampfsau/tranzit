#!/bin/bash

./cod4x18_dedrun \
  +set net_port "28960" \
  +set fs_homepath /home/cod4x-server/tranzit/ \
  +set fs_game mods/tranzit \
  +exec server.cfg \
  +set rcon_password "hello-world" \
  +set r_xassetnum "xmodel=1200 xanim=3200 image=3000 fx=500" \
  +set g_gametype "tranzit" \
  +set sv_maxclients "64" \
  +set ui_maxclients "64" \
  +map mp_forsaken_world \
"$@"
