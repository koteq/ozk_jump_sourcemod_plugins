#pragma semicolon 1

#include <sourcemod>
#include <jm_stocks>

public Plugin:myinfo =
{
	name = "JM Enforce Team",
	author = "Reflex",
	description = "Enforces players to be in one specified team",
	version = "$Rev: 42 $"
};

new Handle:g_Cvar_ForceTeam;

public OnPluginStart() {
	g_Cvar_ForceTeam = CreateConVar("sm_enforce_team", "0", "Enforces players to be in one specified team. 0 - disabled, 1 - red, 2 - blue", _, true, 0.0, true, 2.0);
		
	HookEvent("player_team", Event_ChangeTeam);
}

public Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client))
	{
		new new_team = GetEventInt(event, "team");
		new force_team = GetConVarInt(g_Cvar_ForceTeam) + 1;

		if (IsValidTeam(new_team) &&
		    IsValidTeam(force_team) &&
			!IsAdmin(client, Admin_Ban) &&
			new_team != force_team)
		{
			CreateTimer(0.01, Timer_SetTeam, client);
		}
	}
}

public Action:Timer_SetTeam(Handle:timer, any:client)
{
	if (IsValidClient(client)) {
		new force_team = GetConVarInt(g_Cvar_ForceTeam) + 1;
		ChangeClientTeam(client, force_team);
	}
}

stock bool:IsValidTeam(team)
{
	// 0 - unassigned
	// 1 - spectator
	// 2 - red
	// 3 - blue
	return team == 2 || team == 3;
}

