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
    name = "JM AFK",
    author = "Reflex",
    description = "Kick AFK players",
    version = "1.0"
};

#define MAX_UNASSIGNED_TIME 300.0  // 5 min

public OnClientPutInServer(client)
{
    CreateTimer(MAX_UNASSIGNED_TIME, Timer_CheckPlayerTeam, GetClientUserId(client));
}

public Action:Timer_CheckPlayerTeam(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);

    if (IsClientInGame(client) &&
        IsClientUnassigned(client) &&
        !IsClientSourceTV(client) &&
        !IsClientReplay(client)
    ) {
        KickClient(client, "AFK");
    }
}

bool:IsClientUnassigned(client)
{
    return (GetClientTeam(client) == 0);
}
