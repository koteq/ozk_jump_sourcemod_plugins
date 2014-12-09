#pragma semicolon 1

#include <sourcemod>
#include <jm_stocks>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#define REQUIRE_EXTENSIONS

public Plugin:myinfo =
{
	name = "JM Health",
	author = "Reflex",
	description = "Disables self damage",
	version = "1.0"
};

new bool:g_bLibrary_SdkHooks;
new g_iRestoreHealthTo[MAXPLAYERS + 1];

public OnPluginStart() {
	HookEvent("player_hurt", Event_PlayerHurt);
	LoadTranslations("jm_health.phrases");
}

public OnAllPluginsLoaded()
{
	g_bLibrary_SdkHooks = LibraryExists("sdkhooks");

	if (g_bLibrary_SdkHooks) {
		SetHookOnTakeDamage();
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sdkhooks")) {
		g_bLibrary_SdkHooks = true;
		SetHookOnTakeDamage();
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sdkhooks")) {
		g_bLibrary_SdkHooks = false;
	}
}

public OnClientPutInServer(client)
{
	if (g_bLibrary_SdkHooks) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnClientSayCommand(client, const String:command[], const String:args[])
{
	decl String:arg1[8];
	BreakString(args, arg1, sizeof(arg1));
	
	if (StrEqual(arg1, "!health") ||
		StrEqual(arg1, "/health") ||
		StrEqual(arg1, "!hp") ||
		StrEqual(arg1, "/hp")
	) {
		PrintToChat(client, "[JM] %t", "Health Regen Permanently Enabled");
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker == victim || damagetype & DMG_FALL) {
		g_iRestoreHealthTo[victim] = GetClientHealth(victim);
	}		
	return Plugin_Continue;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bLibrary_SdkHooks) {
		if (IsValidClient(client) && g_iRestoreHealthTo[client] > 0) {
			SetEntProp(client, Prop_Send, "m_iHealth", g_iRestoreHealthTo[client]);
			//SetEntProp(client, Prop_Data, "m_iHealth", g_iRestoreHealthTo[client]);
			g_iRestoreHealthTo[client] = 0;
		}
	} else {
		// emergency health restore
		switch (TF2_GetPlayerClass(client)) {
			case TFClass_Soldier: {
				SetEntProp(client, Prop_Send, "m_iHealth", 200);
			}
			case TFClass_DemoMan: {
				SetEntProp(client, Prop_Send, "m_iHealth", 175);
			}
		}
	}
}

SetHookOnTakeDamage()
{
	for (new client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}
