#include scripts\_include;

init()
{
	thread scripts\debug\valuedebugging::valueDebugHuds();

	/*while(!isDefined(level.players) || level.players.size < 1)
		wait 1;
		
	while(level.aliveCount["allies"] <= 0 && !game["tranzit"].playersReady)
		wait 1;
		
	wait 5;*/
}