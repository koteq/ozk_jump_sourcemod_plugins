#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <jm_stocks>

#undef REQUIRE_PLUGIN
#include <jm_mapcfg>
#include <jm_noob_mark>
#define REQUIRE_PLUGIN

public Plugin:myinfo = {
	name = "JM Ammo",
	author = "Reflex",
	description = "Ammo resupply",
	version = "1.0"
};

new bool:g_bRefillClip[MAXPLAYERS+1];
new g_iClientPrimaryWeapon[MAXPLAYERS + 1];
new g_iClientSecondaryWeapon[MAXPLAYERS + 1];

new bool:g_bLibrary_JmMapcfg;
new bool:g_bLibrary_JmNoobMark;

public OnPluginStart()
{
	RegConsoleCmd("sm_ammo", Command_Ammo, "Toggle ammo regen");
	
	HookEvent("post_inventory_application", Event_PostInventoryApplication, EventHookMode_Post);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	
	CreateTimer(1.0, Timer_RegenAmmo, _, TIMER_REPEAT);
	
	LoadTranslations("jm_ammo.phrases");
	
	// late load
	for (new client = 1; client <= MaxClients; client++) {
		UpdateClientWeapons(client);
	}
}

public OnAllPluginsLoaded()
{
	g_bLibrary_JmMapcfg = LibraryExists("jm_mapcfg");
	g_bLibrary_JmNoobMark = LibraryExists("jm_noob_mark");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "jm_mapcfg")) {
		g_bLibrary_JmMapcfg = true;
	}
	else if (StrEqual(name, "jm_noob_mark")) {
		g_bLibrary_JmNoobMark = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "jm_mapcfg")) {
		g_bLibrary_JmMapcfg = false;
	}
	else if (StrEqual(name, "jm_noob_mark")) {
		g_bLibrary_JmNoobMark = false;
	}
}

public OnClientConnected(client)
{
	g_bRefillClip[client] = false;
}

public JM_NoobMark_OnBeforeDeactivate(client)
{
	g_bRefillClip[client] = false;
}

public Action:OnClientSayCommand(client, const String:command[], const String:args[])
{
	new pos;
	decl String:text[12];
	decl String:arg1[8];
	BreakString(args, text, sizeof(text));
	pos = BreakString(text, arg1, sizeof(arg1));
	
	if (StrEqual(arg1, "!regen") ||
		StrEqual(arg1, "/regen") ||
		StrEqual(arg1, "regen")
	) {
		decl String:arg2[4];
		BreakString(text[pos], arg2, sizeof(arg2));
		
		if (StrEqual(arg2, "on")) {
			g_bRefillClip[client] = true;
		}
		if (StrEqual(arg2, "off")) {
			g_bRefillClip[client] = false;
		}
	
		if (g_bRefillClip[client]) {
			if (g_bLibrary_JmNoobMark && !IsClientAllowedToUseAmmo(client)) {
				JM_NoobMark_Activate(client);
			}
			PrintToChat(client, "[JM] %t", "Ammo Regen Enabled");
		} else { 
			PrintToChat(client, "[JM] %t", "Ammo Regen Disabled");
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	UpdateClientWeapons(client);
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bRefillClip[client]) {
		g_bRefillClip[client] = false;
		PrintToChat(client, "[JM] %t", "Ammo Regen Disabled");
	}
}

public Action:Command_Ammo(client, args)
{
	g_bRefillClip[client] = !g_bRefillClip[client];
	if (g_bRefillClip[client]) {
		if (g_bLibrary_JmNoobMark && !IsClientAllowedToUseAmmo(client)) {
			JM_NoobMark_Activate(client);
		}
		ReplyToCommand(client, "[JM] %t", "Ammo Regen Enabled");
	} else { 
		ReplyToCommand(client, "[JM] %t", "Ammo Regen Disabled");
	}
	return Plugin_Handled;
}

public Action:Timer_RegenAmmo(Handle:timer)
{
	for (new client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && IsPlayerAlive(client)) {
			RegenClientAmmo(client, g_bRefillClip[client]);
		}
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("JM_Ammo_RegenClient", Native_RegenClientAmmo);
	RegPluginLibrary("jm_ammo");	
	
	return APLRes_Success;
}

/* native JM_Ammo_RegenClient(client, bool:clip_regen=false); */
public Native_RegenClientAmmo(Handle:plugin, numParams)
{	
	RegenClientAmmo(GetNativeCell(1), bool:GetNativeCell(2));
}

UpdateClientWeapons(client)
{
	if (IsValidClient(client)) {
		g_iClientPrimaryWeapon[client] = GetPlayerWeaponSlot(client, 0);
		g_iClientSecondaryWeapon[client] = GetPlayerWeaponSlot(client, 1);
	}
}

RegenClientAmmo(client, bool:clip_regen=false)
{
	RegenClientWeaponAmmo(client, g_iClientPrimaryWeapon[client], clip_regen);
	RegenClientWeaponAmmo(client, g_iClientSecondaryWeapon[client], clip_regen);
}

RegenClientWeaponAmmo(client, weapon, bool:clip_regen)
{
	if (!IsValidEntity(weapon)) {
		return;
	}
	switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) {
		// rocket launchers
		case 18, 205, 127, 414, 513, 658, 800, 809, 889, 898, 907, 916, 965, 974: {
			SetClientWeaponAmmo(client, weapon, 4, 20, clip_regen);
		}
		// rocket jumper
		case 237: {
			SetClientWeaponAmmo(client, weapon, 4, 60, clip_regen);
		}
		// black box, liberty launcher
		case 228, 1085: {
			SetClientWeaponAmmo(client, weapon, 3, 20, clip_regen);
		}
		// begger's bazooka
		case 730: {
			SetClientWeaponAmmo(client, weapon, 0, 20, false);
		}
		
		// stickybomb launchers
		case 20, 207, 661, 797, 806, 886, 895, 904, 913, 962, 971: {
			SetClientWeaponAmmo(client, weapon, 8, 24, clip_regen);
		}
		// scottish resistance
		case 130: {
			SetClientWeaponAmmo(client, weapon, 8, 36, clip_regen);
		}
		// sticky jumper
		case 265: {
			SetClientWeaponAmmo(client, weapon, 8, 72, clip_regen);
		}
		
		// soldier's shotguns
		case 10, 199: {
			SetClientWeaponAmmo(client, weapon, 6, 32, clip_regen);
		}
		case 415: {
			SetClientWeaponAmmo(client, weapon, 4, 32, clip_regen);
		}
		
		// for new weapons
		default: {
			decl String:weapon_class[64];
			GetEntityClassname(weapon, weapon_class, sizeof(weapon_class));
			
			if (StrEqual(weapon_class, "tf_weapon_rocketlauncher")) {
				SetClientWeaponAmmo(client, weapon, 4, 20, clip_regen);
			} else if (StrEqual(weapon_class, "tf_weapon_pipebomblauncher")) {
				SetClientWeaponAmmo(client, weapon, 8, 24, clip_regen);
			}
		}
	}
} /* RegenClientWeaponAmmo */

SetClientWeaponAmmo(client, weapon, clip_size, ammo, clip_regen)
{
	if (clip_regen) {
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip_size);
	}
	new ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammo_type != -1) {
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammo_type);
	}
}

bool:IsClientAllowedToUseAmmo(client)
{
	if (g_bLibrary_JmMapcfg) {
		new TFClassType:mapPlayerClass = JM_MapConfig_GetMapPlayerClass();
		if (mapPlayerClass == TFClass_Unknown) {
			// allow everyone to use ammo on trix maps
			return true;
		}
		
		new TFClassType:playerClass = TF2_GetPlayerClass(client);
		if (mapPlayerClass == TFClass_DemoMan && playerClass == TFClass_Soldier) {
			// allow solly to use ammo on demo maps
			return true;
		}
	}
	
	return false;
}
