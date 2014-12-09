#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <jm_noob_mark>
#define REQUIRE_PLUGIN

public Plugin:myinfo =
{
	name = "JM Noclip",
	author = "Reflex",
	description = "Noclip for admins"
};

new bool:g_bLibrary_JmNoobMark;

public OnPluginStart() {
	RegAdminCmd("sm_noclip", Command_Noclip, ADMFLAG_SLAY, "sm_noclip <#userid|name> - Toggles Noclip");
	LoadTranslations("common.phrases");
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

public Action:Command_Noclip(client, args)
{
	if (args < 1) {
		ToggleNoclip(client);
		ShowActivity2(client, "[SM] ", "Toggle Noclip to self");
		
		return Plugin_Handled;
	}
	
	decl String:arg[20];
	GetCmdArg(1, arg, sizeof(arg));
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new found_client = -1;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			1,
			COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0
	) {
		found_client = target_list[0];
	}
	else {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if (found_client != -1) {
		if (found_client != client && !CanEnableNoclipOnOthers(client)) {
			return Plugin_Handled;
		}
		
		ToggleNoclip(found_client);
		ShowActivity2(client, "[SM] ", "Toggle Noclip to %s", target_name);
	}

	return Plugin_Handled;
}

public JM_NoobMark_OnBeforeDeactivate(client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
}

ToggleNoclip(client)
{
	new MoveType:movetype = GetEntityMoveType(client);
	if (movetype != MOVETYPE_NOCLIP) {
		if (g_bLibrary_JmNoobMark) {
			JM_NoobMark_Activate(client);
		}
		
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	}
	else {
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

bool:CanEnableNoclipOnOthers(client)
{
    new AdminId:aidUserAdmin = INVALID_ADMIN_ID;

    aidUserAdmin = GetUserAdmin(client);
    if (aidUserAdmin != INVALID_ADMIN_ID) {
        return GetAdminFlag(aidUserAdmin, Admin_Ban, Access_Effective);
	}
			
    return false;
}
