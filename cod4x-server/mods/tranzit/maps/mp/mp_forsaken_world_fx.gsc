#include maps\mp\_utility;
#include common_scripts\utility;

#include scripts\_include;
#include scripts\ambient;

main()
{
	level._effect["thin_black_smoke_L"] = loadfx("smoke/thin_black_smoke_L");
	level._effect["firelp_barrel_pm"] = loadfx("fire/firelp_barrel_pm");
	level._effect["explosion_electric"] = loadfx("props/securityCamera_explosion");
	
	level._effect["alien_hive_explode"] = loadfx("tranzit/easter_egg/alien_hive_explode");
	level._effect["orbs"] = loadfx("tranzit/easter_egg/orbs");

/#
	if(getdvar( "clientSideEffects" ) != "1" )
		maps\createfx\mp_forsaken_world_fx::main();
#/	

	thread buildAmbientFXArray();
	thread electricalBoxes();
	thread alienCrater();
}

buildAmbientFXArray()
{
	level.fxOrigins = [];
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, -5200, -173.988));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, -4200, -195.922));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, -3200, -251));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, -2200, -333.204));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, 2800, 172.96));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, 6800, 212));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4500, 7800, 212));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, -4200, -201));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, -3200, -196.167));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, -2200, -333.337));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, -1200, 556.434));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, -200, -257.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, 800, -114.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3500, 2800, 192.624));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, -6200, -54.1884));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, -3200, -389.321));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, -2200, -307.392));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, -1200, -339));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, 1800, -596.661));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2500, 2800, 247.865));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, -9200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, -6200, -206.705));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, -3200, -392.284));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, -2200, -313.181));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, -1200, -342.339));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, 1800, -633.962));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, 2800, 156.404));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, 3800, 355.072));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, 4800, 378.697));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1500, 6800, 162.251));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -9200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -7200, -112.91));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -6200, -385.838));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -3200, -373.381));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -2200, -261.798));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, -1200, -382.174));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 1800, -606.88));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 2800, 30.4508));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 3800, 108.368));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 4800, -12.233));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 5800, 13.435));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 6800, 32.0984));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-500, 7800, 117.503));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -9200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -8200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -7200, -280));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -6200, -260.666));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -5200, -386.291));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -3200, -251.452));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -2200, -204.005));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -1200, -280.346));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, -200, -334.347));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 800, -373.695));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 1800, -316.481));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 2800, -85.9549));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 3800, -89.4695));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 4800, -30.3429));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 5800, 6.42442));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 6800, 30.3873));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 7800, 131.451));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 8800, 305.279));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((500, 9800, 431.413));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -9200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -8200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -6200, -266.656));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -5200, -300));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -4200, -265.488));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -3200, -273.978));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -2200, -196));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -1200, -205.338));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, -200, -160.059));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 800, -220.231));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 1800, -277.126));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 2800, -229.503));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 3800, -135.868));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 4800, -86.154));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 5800, -55.6863));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 6800, 93.3995));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 7800, 168.864));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 8800, 264.912));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((1500, 9800, 462.91));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -6200, -467.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -5200, -467.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -4200, -460.591));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -3200, -444.214));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -2200, -331.459));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -1200, -268.453));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, -200, -226.004));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 800, -168.737));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 1800, -24.0426));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 2800, -109.481));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 3800, -81.8253));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 4800, -47.2335));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2500, 5800, -55.686));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, -4200, -126.125));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, -2200, -284));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, -1200, -281.132));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 800, -125.468));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 1800, -268.036));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 2800, -185.174));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 3800, -72.2577));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 4800, -28.4541));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 5800, -45.2454));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3500, 9800, 343.718));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, -5200, -301.066));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 1800, -48.7078));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 2800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 3800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 4800, -53.4331));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 5800, -69.868));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 6800, 53.662));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 7800, 263.89));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 8800, 317.583));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4500, 9800, 294.152));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, -5200, -251.9));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, -200, -2980));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 1800, -11.7754));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 2800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 3800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 4800, -97.7161));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 5800, -48.3874));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 6800, 91.0208));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 7800, 278.599));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 8800, 322.253));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5500, 9800, 326.586));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 1800, -101.529));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 2800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 3800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 4800, -63.0472));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 5800, -48.5373));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 6800, 77.9871));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 7800, 266.832));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6500, 9800, 377.959));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, -4200, -168.915));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, 1800, -100.543));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, 2800, -139.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, 3800, -58.7629));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, 4800, -80.7207));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7500, 5800, -40.3871));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, -1200, -88.0001));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, -200, -88.0001));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, 800, -60.0908));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, 1800, -102.205));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, 2800, -58.3047));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8500, 3800, -54.1768));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((10500, 5800, -68.8269));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((10500, 6800, -146.849));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((10500, 7800, -178.546));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((10500, 8800, -15.9872));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 2800, -134.275));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 3800, -125.101));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 4800, -115.927));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 5800, -101.761));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 6800, -55.8899));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 7800, -10.0184));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 8800, 35.8532));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 9800, 92.0824));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((11500, 10800, 153.938));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2399.94, 6360.86, -17.1737));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3577.64, 6482.88, 38.2704));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1583.7, -730.325, -378.876));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-2820.12, 1825.25, -496.252));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3646.91, 2006.11, -215.322));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4725.01, 1812.58, -177.939));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-4902.42, 543.658, -240.364));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-5097.04, -384.081, -236.132));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-5101.72, -1292.17, -258.65));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((887.207, -3725.46, -326.889));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3189.02, -2918.97, -459.714));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6587.29, 1083.67, -99.559));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5401.83, 1103.45, -141.465));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4267.52, 748.074, -116.005));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4295.36, -118.979, -237.484));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3693.67, -315.549, -189.17));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4375.08, -4873.1, -288.883));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6784.26, -4763.74, -303.075));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6095.36, -5004.41, -302.921));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7392.07, -3075.47, -178.363));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7420.24, 980.327, -70.2058));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2639.58, 6374.12, -24.0527));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3553.91, 6631.31, -2.29312));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4201.3, 7254.21, 140.188));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4254.07, 8659.45, 292.527));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1545.54, 5687.39, 181.446));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-1173.34, 7714.86, 171.749));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((5712.13, 10671, 329.349));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4798.97, 10681.3, 434.06));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((4008.16, 10510, 502.328));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3063.64, 10244.5, 494.174));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((2599.96, 9942.43, 308.27));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7208.4, 8644.28, 317.273));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((6799.6, 8489.69, 316.649));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8078.22, 4495.14, -87.1967));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7721.72, -3928.34, -143));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((7639.76, -2301.06, -108));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((8253.61, -1830.11, -108));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((3496.35, -5182.22, -487.875));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3719.93, -5778.82, -114.377));
	level.fxOrigins[level.fxOrigins.size] = prepareFxEntry((-3647.5, -4698.47, -266.948));
}

electricalBoxes()
{
	triggers = getEntArray("elekt", "targetname");
	
	for(i=0;i<triggers.size;i++)
		triggers[i] thread monitorBoxDamage(i);
}

monitorBoxDamage(boxID)
{
	box = getEnt(self.target, "targetname");
	boxDest = getentarray("brokenwindow" + (boxID+1), "targetname");
	
	for(j=0;j<boxDest.size;j++)
	{
		boxDest[j] notsolid();
		boxDest[j] hide();
	}
	
	box show();
	
	totaldamage = 0;
	while(1)
	{
		self waittill("damage", amount);
	
		totaldamage += amount;
		
		if(totaldamage >= 20)
			break;
	}
	
	self playsound("explo_2");
	
	PlayFX(level._effect["explosion_electric"], self.origin);
	
	for(j=0;j<boxDest.size;j++)
		boxDest[j] show();
	
	box delete();
	self delete();
}

alienCrater()
{
	meteors = getEntArray("alien_meteor", "targetname");
	for(i=0;i<meteors.size;i++)
		meteors[i] thread hoverMeteor();
	
	level.alienWeaponPickupTrigger = getEnt("alien_weapon_pickup", "targetname");
	
	hives = getEntArray("alien_hive", "targetname");
	level.hivesAlive = hives.size;
	for(i=0;i<hives.size;i++)
		hives[i] thread monitorHiveDamage();
		
	while(!isDefined(level.players))
		wait 1;
		
	thread monitorPlayerTeleport();
}

monitorPlayerTeleport()
{
	hero = undefined;
	level.rootOfEvilFound = false;
	
	while(!level.rootOfEvilFound)
	{
		wait 1;
		
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASurvivor() && isDefined(level.players[i].dwarfOnShoulders))
			{
				if(Distance((-3344, -5760, -400), level.players[i].origin) < 50)
				{
					hero = level.players[i];
					hero.dwarfOnShoulders suicide();
					
					random = RandomIntRange(100,300);
					target = level.alienWeaponPickupTrigger.origin + (random, random, 20);
					
					hero scripts\teleporter::teleportPlayer(target, VectorToAngles(target - level.alienWeaponPickupTrigger.origin));
					hero.isAtRootOfEvil = true;
	
					level.rootOfEvilFound = true;
					break;
				}
			}
		}
	}
	
	teleportTimer();
		
	if(isDefined(hero) && isPlayer(hero) && isAlive(hero))
	{
		spawnPoints = level.teamSpawnPoints[game["defenders"]];
		spawnPoint = hero scripts\spawnlogic::getSpawnpoint_NearTeam(spawnPoints);
		
		hero scripts\teleporter::teleportPlayer(spawnPoint.origin);
		hero.isAtRootOfEvil = undefined;
	}
}

teleportTimer()
{
	level endon("alien_weapon_found");
	
	wait 90;
}

hoverMeteor()
{
	self endon("death");

	wait randomFloatRange(0.05, 0.23);

	while(1)	
	{
		value = randomIntRange(10, 35);

		self moveZ(value, 2);
		wait 2.2;
		self moveZ(value *-1, 2);
		wait 2.2;
	}
}

monitorHiveDamage()
{
	self endon("death");

	self setCanDamage(true);

	self.visuals = getEntArray(self.target, "targetname");

	while(1)
	{
		self waittill("damage", amount);
	
		if(amount >= 150)
		{
			level.hivesAlive--;
		
			if(level.hivesAlive <= 0)
				thread createAlienWeaponPickup();
		
			for(i=0;i<self.visuals.size;i++)
			{
				if(isDefined(self.visuals[i].model) && self.visuals[i].model != "")
					PlayFXOnTag(level._effect["alien_hive_explode"], self.visuals[i], "tag_origin");
			}

			wait .05;
		
			for(i=0;i<self.visuals.size;i++)
				self.visuals[i] delete();
			
			self delete();
		}
	}
}

createAlienWeaponPickup()
{
	trigger = level.alienWeaponPickupTrigger;
	visuals[0] = getEnt(trigger.target, "targetname");

	alienWeaponPickup = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], trigger, visuals, (0,0,64), false);
	alienWeaponPickup maps\mp\gametypes\_gameobjects::setModelVisibility(true);
	alienWeaponPickup maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
	alienWeaponPickup maps\mp\gametypes\_gameobjects::allowUse("friendly");
	alienWeaponPickup maps\mp\gametypes\_gameobjects::setUseHintText("^7Press ^3&&1 ^7to pickup that object.");
	alienWeaponPickup maps\mp\gametypes\_gameobjects::setUseTime(0);
	alienWeaponPickup maps\mp\gametypes\_gameobjects::setUseText("");
	alienWeaponPickup maps\mp\gametypes\_gameobjects::enableObject();

	alienWeaponPickup.onUse = ::onUsedCraftedWeaponPickup;
}

onUsedCraftedWeaponPickup( player )
{
	player giveNewWeapon(getWeaponFromCustomName("alien_servant"));
	player playSound("weap_pickup");
	
	self maps\mp\gametypes\_gameobjects::disableObject();
	
	level notify("alien_weapon_found");
}