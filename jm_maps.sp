#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_URL  "http://games.ozerki.net/tf2jump/maps/"

public Plugin:myinfo = {
	name = "JM Maps",
	author = "Reflex",
	description = "Shows maplist",
	version = "1.0"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_maps", Command_ShowMaps);
}

public Action:Command_ShowMaps(client, args)
{
	decl String:buffer[255];
	GetCmdArgString(buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "%s?q=%s", PLUGIN_URL, buffer);
	ShowMOTDPanel(client, "Maplist", buffer, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}