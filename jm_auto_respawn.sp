#pragma semicolon 1

#include <sourcemod>
#include <jm_stocks>
#include <tf2>

public Plugin:myinfo =
{
	name = "JM Auto Respawn",
	author = "Reflex",
	description = "Respawns players without delay",
	version = "$Rev: 42 $"
};

public OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_Respawn, client);
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (IsValidClient(client) &&
	    IsValidTeam(client) &&
	    !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
}

stock bool:IsValidTeam(client)
{
	// 0 - unassigned
	// 1 - spectator
	// 2 - red
	// 3 - blue
	new team = GetClientTeam(client);
	return team == 2 || team == 3;
}