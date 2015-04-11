#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <jm_noob_mark>
#define REQUIRE_PLUGIN

// https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes
#define ITEM_INDEX_LOOSE_CANNON 996

public Plugin:myinfo =
{
    name = "JM Weapon Noob Mark",
    author = "Reflex",
    description = "Marks players wehen they use shitty weaps",
    version = "1.0"
};

new bool:g_bLibrary_JmNoobMark;

public OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt);
}

public OnAllPluginsLoaded()
{
	g_bLibrary_JmNoobMark = LibraryExists("jm_noob_mark");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "jm_noob_mark")) {
		g_bLibrary_JmNoobMark = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "jm_noob_mark")) {
		g_bLibrary_JmNoobMark = false;
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (g_bLibrary_JmNoobMark &&
        GetEventInt(event, "weaponid") == TF_WEAPON_CANNON &&
        GetEventInt(event, "userid") == GetEventInt(event, "attacker")
    ) {
        JM_NoobMark_Activate(GetClientOfUserId(GetEventInt(event, "userid")));
    }
}
