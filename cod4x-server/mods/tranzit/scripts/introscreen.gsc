#include scripts\_include;

init()
{
	level.intro_linefeed_delay = 10;
	level.intro_linefeed_lines = 2;
}

createIntroLines()
{
	self endon("disconnect");

	if(level.intro_linefeed_lines <= 0)
		return;

	for(i=0;i<=level.intro_linefeed_lines;i++)
	{
		delay = (i + 1) + 2;

		self thread introscreenCornerLine(i, delay);
	}
}

introscreenCornerLine(curLine, delay)
{
	self endon("disconnect");

	wait delay;
	
	intro_hudelem = newClientHudElem(self);
	intro_hudelem.x = 20;
	intro_hudelem.y = (((curLine) * 20) - 82);
	intro_hudelem.alignX = "left";
	intro_hudelem.alignY = "bottom";
	intro_hudelem.horzAlign= "left";
	intro_hudelem.vertAlign = "bottom";
	intro_hudelem.sort = 1;
	intro_hudelem.foreground = true;
	intro_hudelem.alpha = 1;
	intro_hudelem.hidewheninmenu = true;
	intro_hudelem.fontScale = 1.7;
	intro_hudelem.color = (0.8, 0, 0);
	intro_hudelem.font = "objective";
	intro_hudelem.glowColor = (0.3, 0, 0);
	intro_hudelem.glowAlpha = 1;
	intro_hudelem SetPulseFX(40, level.intro_linefeed_delay * 1000, 2000);
	
	if(curLine == 0)
	{
		startValue = 7;
		for(seconds=1;seconds<=level.intro_linefeed_delay;seconds++)
		{
			if((startValue + seconds) < 10)
				intro_hudelem.label = &"Day X - 01:37:0&&1";
			else
				intro_hudelem.label = &"Day X - 01:37:&&1";
			
			intro_hudelem setValue((startValue + seconds));
			
			wait 1;
		}
	}
	else
	{
		intro_hudelem.label = self getLocTextString("INTRO_LINE" + curLine);
		wait level.intro_linefeed_delay;
	}
	
	intro_hudelem destroy();
}