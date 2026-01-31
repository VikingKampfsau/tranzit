#include scripts\debug\drawdebuggers;
#include scripts\_include;

init()
{
	precacheModel("zmb_shield_worldmodel");
	level._effect["riotshield_impact"] = loadfx( "impacts/small_metalhit" );
	
	level.riotShieldHealth = 2500; //set this to 0 to disable the destruction
}

calculateCornerPos(tag, forward, right, up)
{
	origin = self getTagOrigin(tag);
	angles = self getTagAngles(tag);

	v_forward = AnglesToForward(angles) * forward;
	v_right = AnglesToRight(angles) * right;
	v_up = AnglesToUp(angles) * up;

	return (origin + v_forward + v_right + v_up);
}

attackerIsDamagingRiotShield(eInflictor, eAttacker, vPoint, vDir, sMeansOfDeath)
{
	if(!isDefined(vPoint))
		return true;

	if(sMeansOfDeath == "MOD_MELEE")
	{
		if(self isLookingAtEntity(eAttacker))
			return true;
	
		return false;
	}

	/**************************************
	***		Ebene aufspannen			***
	**************************************/
	//Eckpunkte des Riotshields definieren
	A = self calculateCornerPos("tag_weapon_left", 0, 15, -28);
	B = self calculateCornerPos("tag_weapon_left", 0, -15, -28);
	C = self calculateCornerPos("tag_weapon_left", 0, -15, 23);
	D = self calculateCornerPos("tag_weapon_left", 0, 15, 23);

	//Richtungsvektoren aufstellen
	//AB = B - A;
	//AD = D - A;
	
	//Parameterform der Ebene wäre: x = A + r*AB + s*AD
	//aus den beiden Richtungsvektoren den Normalenvektor berechnen (Kreuzprodukt): n = AB x AD
	//n = crossProduct(AB, AD);
	n = crossProduct(B - A, D - A);
	
	//anhand des Normalenvektors und dem Stützvektor der Ebene das Skalarprodukt berechnen
	dot = VectorDot(n, A);
	
	//Die Koordinatenform der Ebene wäre demnach: n[0]*x + n[1]*y + n[2]*z + dot = 0
	
	/**************************************
	***		Gerade definieren			***
	**************************************/
	//Richtungsvektor
	if(isDefined(eInflictor) && eInflictor != eAttacker)
		vDir = eInflictor.origin - self.origin;
	else
	{
		vDir = eAttacker getEye()/*getTagOrigin("tag_weapon_left")*/;
		
		if(isDefined(vDir))
			vDir = vDir - vPoint;
		else
			vDir = eAttacker.origin - self.origin; 
	}
	
	//Gerade in Parameterform wäre: vPoint + t*vDir
	
	//Gerade in Koordinatenform umwandeln:
	//x = vPoint[0] + vDir[0] * t
	//y = vPoint[1] + vDir[1] * t
	//z = vPoint[2] + vDir[2] * t
	
	/**************************************
	***		Lageprüfung von E und G		***
	**************************************/
	//Gerade und Ebene sind parallel, wenn n*v=0
	//n ist der Normalenvektor der Ebene
	//v ist der Richtungsvektoren der Geraden
	if(VectorDot(n, vDir) == 0)
	{
		//Die Gerade liegt gänzlich in der Ebene, wenn der Stützvektor der Gerade in der Ebene liegt
		//Dazu den Stützvektor in die Koordinatenform der Ebene einsetzen
		if((n[0]*vPoint[0] + n[1]*vPoint[1] + n[2]*vPoint[2] - dot) == 0)
			return true;

		return false;
	}
		
	/**************************************
	***			Durchstosspunkt			***
	**************************************/
	//Die Gerade ist also nicht parallel zur Ebene, d.h. sie durchstösst die Ebene an einem Punkt
	
	//Die Koordinatenformen der Gerade in die Koordinatenform der Ebene einsetzen
	//und nach t ausmultiplizieren
	t = (0-(n[0]*vPoint[0] + n[1]*vPoint[1] + n[2]*vPoint[2] - dot)) / (n[0]*vDir[0] + n[1]*vDir[1] + n[2]*vDir[2]);

	//Wurde der Spieler in den Rücken getroffen, dann ist es definitiv kein Schildtreffer!
	if(t < 0)
		return false;

	//t in die Koordinatenformen der Gerade einsetzen um die Koordinaten des Durchstosspunkts zu bekommen
	SP = vPoint + vDir * t;	
	
	if(game["debug"]["status"] && game["debug"]["riotshield_damageArea"])
	{
		self thread DebugRiotShield(A, B, C, D, vPoint, SP, eAttacker, eInflictor, 1, 5);
	}
	
	//Hier noch prüfen, ob der Durchstosspunkt innerhalb der Rechtecks liegt
	//Dazu die Richtungsvektoren des Rechtecks aufspannen
	//w wird nur benötigt, wenn das Rechteck keine Fläche, sondern ein Körper ist:
	u = B - A;
	v = D - A;
	//w = A_A - A;
	
	//Ein Punkt liegt im Rechteck, wenn alle (bei einer Fläche nur die ersten beiden) Bedingungen erfüllt sind:
	//Das Skalarprodukt von u.SP liegt zwischen dem Skalarprodukt von u.A um dem Skalarprodukt von u.B
	//Das Skalarprodukt von v.SP liegt zwischen dem Skalarprodukt von v.A um dem Skalarprodukt von v.D
	//Das Skalarprodukt von w.SP liegt zwischen dem Skalarprodukt von w.A um dem Skalarprodukt von w.A_A
	dots = [];
	dots["u"] = [];
	dots["u"]["x"] = VectorDot(u, SP);
	dots["u"]["A"] = VectorDot(u, A);
	dots["u"]["B"] = VectorDot(u, B);
	
	dots["v"] = [];
	dots["v"]["x"] = VectorDot(v,SP);
	dots["v"]["A"] = VectorDot(v,A);
	dots["v"]["D"] = VectorDot(v,D);
	
	//dots["w"] = [];
	//dots["w"]["x"] = VectorDot(w,SP);
	//dots["w"]["A"] = VectorDot(w,A);
	//dots["w"]["B"] = VectorDot(w,A_A);
	
	if((dots["u"]["A"] <= dots["u"]["x"] && dots["u"]["x"] <= dots["u"]["B"]) || (dots["u"]["B"] <= dots["u"]["x"] && dots["u"]["x"] <= dots["u"]["A"]))
	{
		if((dots["v"]["A"] <= dots["v"]["x"] && dots["v"]["x"] <= dots["v"]["D"]) || (dots["v"]["D"] <= dots["v"]["x"] && dots["v"]["x"] <= dots["v"]["A"]))
		{
			//if((dots["w"]["A"] <= dots["w"]["x"] && dots["w"]["x"] <= dots["w"]["A_A"]) || (dots["w"]["A_A"] <= dots["w"]["x"] && dots["w"]["x"] <= dots["w"]["A"]))
			{
				PlayFx(level._effect["riotshield_impact"], SP);
				return true;
			}
		}
	}

	return false;
}