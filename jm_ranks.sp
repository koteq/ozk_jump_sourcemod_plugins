#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <jm_stocks>

#include "../jumpassist/include/jumpassist.inc"

public Plugin:myinfo = {
    name = "JM Ranks",
    author = "Reflex",
    description = "Ranks for players",
    version = "1.0"
};

new Handle:g_hDatabase = INVALID_HANDLE;

public OnPluginStart()
{
    SQL_TConnect(SQL_OnConnect, "jm_ranks");
}

public SQL_OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl != INVALID_HANDLE) {
        g_hDatabase = hndl;
    }
    else {
        SetFailState("Connection failed: %s", error);
    }
}

public JA_OnClientCapturedPoint(client, areaId, const String:areaName[])
{
    if (g_hDatabase != INVALID_HANDLE && IsValidClient(client)) {
        decl String:steamId[32];
        GetClientAuthString(client, steamId, sizeof(steamId));

        decl String:name[64];
        GetClientName(client, name, sizeof(name));

        decl String:mapName[64];
        GetCurrentMap(mapName, sizeof(mapName));

        new role = int:TF2_GetPlayerClass(client);

        decl String:nameSafe[64];
        SQL_EscapeString(g_hDatabase, name, nameSafe, sizeof(nameSafe));

        decl String:areaNameSafe[64];
        SQL_EscapeString(g_hDatabase, areaName, areaNameSafe, sizeof(areaNameSafe));

        decl String:query[255];
        Format(query, sizeof(query),
            "CALL playerCapturedPoint('%s', '%s', %d, '%s', %d, '%s');",
            steamId, nameSafe, role, mapName, areaId, areaNameSafe);

        SQL_TQuery(g_hDatabase, SQL_OnQueryExecuted, query);
    }
}

public SQL_OnQueryExecuted(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE) {
        LogError("Query failed: %s", error);
    }
}
