#pragma semicolon 1

#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "JM MapCFG",
	author = "Reflex",
	description = "Forwards current map config to others plugins",
	version = "1.0"
};

#define CONFIG_FILE "umc_mapconfig.txt"
new Handle:g_hOnConfigLoadedForward = INVALID_HANDLE;

new TFClassType:g_mapPlayerClass;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("JM_MapConfig_GetMapPlayerClass", Native_GetMapPlayerClass);
	
	g_hOnConfigLoadedForward = CreateGlobalForward("JM_MapConfig_OnConfigLoaded", ET_Ignore, Param_String, Param_String, Param_String);
	
	RegPluginLibrary("jm_mapcfg");	
	
	return APLRes_Success;
}

/* native JM_MapConfig_GetMapPlayerClass(); */
public Native_GetMapPlayerClass(Handle:plugin, numParams)
{
	return _:g_mapPlayerClass;
}

public OnMapStart()
{
	new String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	new Handle:kv = CreateKeyValues("MapCFG");
	if (!FileToKeyValues(kv, CONFIG_FILE)) {
		return;
	}
	if (!KvJumpToKey(kv, map)) {
		return;
	}
	
	new String:team[8];
	new String:class[8];
	new String:difficulty[16];
	KvGetString(kv, "team", team, sizeof(team));
	KvGetString(kv, "class", class, sizeof(class));
	KvGetString(kv, "difficulty", difficulty, sizeof(difficulty));
	
	Call_StartForward(g_hOnConfigLoadedForward);
	Call_PushString(team);
	Call_PushString(class);
	Call_PushString(difficulty);
	Call_Finish();

	SetMapClass(class);
}

SetMapClass(const String:class[])
{
	g_mapPlayerClass = TFClass_Unknown;
	if (StrEqual(class, "solly")) {
		g_mapPlayerClass = TFClass_Soldier;
	}
	else if (StrEqual(class, "demo")) {
		g_mapPlayerClass = TFClass_DemoMan;
	}
}
