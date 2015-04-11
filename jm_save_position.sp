#pragma semicolon 1

#include <colors>
#include <sdktools>
#include <sourcemod>
#include <jm_stocks>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <jm_ammo>

public Plugin:myinfo =
{
	name = "JM Save Position",
	author = "Reflex",
	description = "Allows players to save their positions",
	version = "$Rev: 43 $"
};

new Handle:g_DB = INVALID_HANDLE;
new Handle:g_Cvar_DisablePlugin = INVALID_HANDLE;

new bool:g_IsPluginDisabled;
new bool:g_IsRoundActive;
new bool:g_AmmoLibraryExists;

enum Sounds {
	Sound_Spawn = 0,
	Sound_Nope,
	Sound_Hint,
};
new String:g_Sounds[Sounds][32] = {
	"items/spawn_item.wav",
	"vo/engineer_no01.mp3",
	"ui/hint.wav"
};

public OnPluginStart() {
	LoadTranslations("jm_save_position.phrases");
	
	g_Cvar_DisablePlugin = CreateConVar("sm_save_position_disable", "0", "Disables position save functionary.", _, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_DisablePlugin, ConVarChange_DisablePlugin);

	RegConsoleCmd("sm_save", Command_Save, "Saves your current position. Optional argument may be specified to tag save.");
	RegConsoleCmd("sm_load", Command_Load, "Restores your saved position. Optional argument may be specified to restore tagged save.");
	RegConsoleCmd("sm_tele", Command_Load, "Restores your saved position. Optional argument may be specified to restore tagged save.");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("teamplay_round_win", Event_RoundEnd);

	g_AmmoLibraryExists = LibraryExists("jm_ammo");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "jm_ammo")) {
		g_AmmoLibraryExists = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "jm_ammo")) {
		g_AmmoLibraryExists = true;
	}
}

public OnMapStart() {
	DB_Init();
	
	for (new i = 0, len = sizeof(g_Sounds); i < len; i++) {
		PrecacheSound(g_Sounds[i]);
	}
}

public Event_RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_IsRoundActive = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_IsRoundActive = false;
}

public ConVarChange_DisablePlugin(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_IsPluginDisabled = GetConVarBool(g_Cvar_DisablePlugin);
}

public Action:Command_Say(client, args) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}

	decl String:text[192];
	if (IsChatTrigger() || GetCmdArgString(text, sizeof(text)) < 1) {
		return Plugin_Continue;
	}

	new startidx = 0;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (text[startidx] == '/' || text[startidx] == '!') {
		startidx += 1;
	} else {
		return Plugin_Continue;
	}

	if (0
		|| (strcmp(text[startidx], "s", false) == 0)
		|| (strcmp(text[startidx], "ы", false) == 0)
		|| (strcmp(text[startidx], "saveloc", false) == 0)
		|| (strcmp(text[startidx], "jm_saveloc", false) == 0)
		|| (strcmp(text[startidx], "cpsave", false) == 0)
		|| (strcmp(text[startidx], "ja_save", false) == 0)
		)
	{
		Command_Save(client, args);
		return Plugin_Stop;
	}
	if (0
		|| (strcmp(text[startidx], "l", false) == 0)
		|| (strcmp(text[startidx], "д", false) == 0)
		|| (strcmp(text[startidx], "t", false) == 0)
		|| (strcmp(text[startidx], "е", false) == 0)
		|| (strcmp(text[startidx], "teleport", false) == 0)
		|| (strcmp(text[startidx], "jm_teleport", false) == 0)
		|| (strcmp(text[startidx], "cptele", false) == 0)
		|| (strcmp(text[startidx], "ja_tele", false) == 0)
		)
	{
		Command_Load(client, args);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Command_Save(client, args) {
	// some checks
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if (g_IsPluginDisabled) {
		CPrintToChat(client, "%t", "save disabled");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if (!g_IsRoundActive) {
		CPrintToChat(client, "%t", "save temporaly disabled");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if (!(GetEntityFlags(client) & FL_ONGROUND)) {
		CPrintToChat(client, "%t", "on ground");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if ((GetEntityFlags(client) & FL_DUCKING)) {
		CPrintToChat(client, "%t", "crouched");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}

	// collect important info about client
	decl String:steamid[23];
	new Float:pos[3];
	new Float:ang[3];

	if (!GetClientAuthString(client, steamid, sizeof(steamid))) return Plugin_Handled;
	new team = GetClientTeam(client);
	new role = _:TF2_GetPlayerClass(client);
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, ang);

	// store collected info into database
	decl String:query[1024];
	Format(query,
		sizeof(query),
		"INSERT INTO jm_save_position (steamid, team, role, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z) VALUES ('%s', %d, %d, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)",
		steamid, team, role, pos[0], pos[1], pos[2], ang[0], ang[1], ang[2]
	);
	if (DB_Query(query)) {
		CPrintToChat(client, "%t", "saved");
		EmitSoundToClient(client, g_Sounds[Sound_Spawn]);
	}

	return Plugin_Handled;
}

public Action:Command_Load(client, args) {
	// some checks
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client)) {
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if (g_IsPluginDisabled) {
		CPrintToChat(client, "%t", "load disabled");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}
	if (!g_IsRoundActive) {
		CPrintToChat(client, "%t", "load temporaly disabled");
		EmitSoundToClient(client, g_Sounds[Sound_Nope]);
		return Plugin_Handled;
	}

	// collect important info about client
	decl String:steamid[23];

	if (!GetClientAuthString(client, steamid, sizeof(steamid))) return Plugin_Handled;
	new team = GetClientTeam(client);
	new role = _:TF2_GetPlayerClass(client);

	// build query
	decl String:query[512];
	Format(query,
		sizeof(query),
		"SELECT pos_x, pos_y, pos_z, ang_x, ang_y, ang_z FROM jm_save_position WHERE steamid = '%s' AND team = %d AND role = %d",
		steamid, team, role
	);

	// execute query
	new Handle:hQuery = SQL_Query(g_DB, query);
	if (hQuery == INVALID_HANDLE) {
		decl String:error[255];
		SQL_GetError(g_DB, error, sizeof(error));
		LogError("Query '%s' failed with error: %s", query, error);
		return Plugin_Handled;
	}

	// fetch row
	if (!SQL_FetchRow(hQuery)) {
		CPrintToChat(client, "%t", "save not found");
		CloseHandle(hQuery);
		return Plugin_Handled;
	}

	// fetch row columns
	new Float:pos[3];
	new Float:ang[3];
	new Float:vel[3] = {0.0, 0.0, 0.0};

	pos[0] = SQL_FetchFloat(hQuery, 0);
	pos[1] = SQL_FetchFloat(hQuery, 1);
	pos[2] = SQL_FetchFloat(hQuery, 2);

	ang[0] = SQL_FetchFloat(hQuery, 3);
	ang[1] = SQL_FetchFloat(hQuery, 4);
	ang[2] = SQL_FetchFloat(hQuery, 5);

	CloseHandle(hQuery);

	// teleport client
	TeleportEntity(client, pos, ang, vel);
	CPrintToChat(client, "%t", "loaded");

	if (g_AmmoLibraryExists) {
		GiveAmmo(client, true);
	}

	return Plugin_Handled;
}

DB_Init() {
	if (g_DB != INVALID_HANDLE) {
		CloseHandle(g_DB);
		g_DB = INVALID_HANDLE;
	}

	new Handle:kv = CreateKeyValues("");
	KvSetString(kv, "driver", "sqlite");
	KvSetString(kv, "database", "jm.sqlite");

	decl String:error[255];
	g_DB = SQL_ConnectCustom(kv, error, sizeof(error), false);
	CloseHandle(kv);

	if (g_DB == INVALID_HANDLE) {
		SetFailState("Could not connect to database: %s", error);
	}
	DB_Query("DROP TABLE IF EXISTS jm_save_position");
	DB_Query("CREATE TABLE jm_save_position ( \
	          	id      INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
	          	steamid TEXT NOT NULL, \
	          	team    INTEGER NOT NULL, \
	          	role    INTEGER NOT NULL, \
	          	pos_x   REAL NOT NULL, \
	          	pos_y   REAL NOT NULL, \
	          	pos_z   REAL NOT NULL, \
	          	ang_x   REAL NOT NULL, \
	          	ang_y   REAL NOT NULL, \
	          	ang_z   REAL NOT NULL, \
	          	UNIQUE (steamid, team, role) ON CONFLICT REPLACE \
	          )");
}

bool:DB_Query(const String:query[]) {
	if (g_DB == INVALID_HANDLE) {
		LogError("Database handle not ready yet");
		return false;
	}
	if (!SQL_FastQuery(g_DB, query)) {
		decl String:error[255];
		SQL_GetError(g_DB, error, sizeof(error));
		LogError("Query '%s' failed with error: %s", query, error);
		return false;
	}
	return true;
}
