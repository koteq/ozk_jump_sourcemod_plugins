#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <jm_mapcfg>
#define REQUIRE_PLUGIN

public Plugin:myinfo = {
	name = "JM Hostname",
	author = "Reflex",
	description = "More information to hostname",
	version = "1.0"
};

#define HOSTNAME_PREFIX "OZK Jump"
#define HOSTNAME_UPDATE_FREQUENCY 7.0

new String:g_sMapInfo[32];
new Handle:g_hCvarHostname;

public OnPluginStart()
{
	g_hCvarHostname = FindConVar("hostname");
}

public OnMapStart()
{
	UpdateHostname();
	CreateTimer(HOSTNAME_UPDATE_FREQUENCY, TimerUpdateHostname, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public OnConfigsExecuted()
{
	UpdateHostname();
}

public JM_MapConfig_OnConfigLoaded(const String:team[], const String:class[], const String:difficulty[])
{
	if (strlen(class) && strlen(difficulty)) {
		Format(g_sMapInfo, sizeof(g_sMapInfo), "%s, %s", class, difficulty);
	} else if (strlen(class)) {
		Format(g_sMapInfo, sizeof(g_sMapInfo), "%s", class);
	} else if (strlen(difficulty)) {
		Format(g_sMapInfo, sizeof(g_sMapInfo), "%s", difficulty);
	} else {
		g_sMapInfo = "";
	}
	UpdateHostname();
}

public Action:TimerUpdateHostname(Handle:timer)
{
	UpdateHostname();
	return Plugin_Continue;
}

UpdateHostname()
{
	new timeleft;
	if (!GetMapTimeLeft(timeleft) || timeleft <= 0) {
		timeleft = 0;
	}
	
	decl String:hostname[256];
	if (timeleft && strlen(g_sMapInfo)) {
		Format(hostname, sizeof(hostname), "%s [%s, %d:%02d left]", HOSTNAME_PREFIX, g_sMapInfo, (timeleft / 60), (timeleft % 60));
	} else if (timeleft && !strlen(g_sMapInfo)) {
		Format(hostname, sizeof(hostname), "%s [%d:%02d left]", HOSTNAME_PREFIX, (timeleft / 60), (timeleft % 60));
	} else if (!timeleft && strlen(g_sMapInfo)) {
		Format(hostname, sizeof(hostname), "%s [%s]", HOSTNAME_PREFIX, g_sMapInfo);
	} else {
		Format(hostname, sizeof(hostname), "%s", HOSTNAME_PREFIX);
	}
	SetConVarString(g_hCvarHostname, hostname);
}

public OnMapEnd()
{
	SetConVarString(g_hCvarHostname, HOSTNAME_PREFIX);
}

public OnPluginEnd()
{
	SetConVarString(g_hCvarHostname, HOSTNAME_PREFIX);
}