#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <smlib>
#include <jm_stocks>

#undef REQUIRE_PLUGIN
#include <jm_noob_mark>
#define REQUIRE_PLUGIN

public Plugin:myinfo = {
    name = "Miniclip",
    author = "CrancK",
    description = "Gives noclip for 10sec, and stops triggers",
    version = "1.0",
    url = ""
};

new bool:g_bMiniClipEnabled[MAXPLAYERS + 1];
new Float:g_vClientOrigin[MAXPLAYERS + 1][3];
new Float:g_vClientAngles[MAXPLAYERS + 1][3];
new Float:g_vClientVelocity[MAXPLAYERS + 1][3];

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_changeclass", Event_PlayerChangeClass);

    RegConsoleCmd("sm_mc", Command_MiniClip);
    RegConsoleCmd("sm_mclip", Command_MiniClip);
    RegConsoleCmd("sm_miniclip", Command_MiniClip);
}

public OnMapStart()
{
    for (new i = 0; i < MaxClients + 1; i++) {
        g_bMiniClipEnabled[i] = false;
    }
}

public OnClientConnected(client)
{
    g_bMiniClipEnabled[client] = false;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
    decl String:text[32];
    BreakString(sArgs, text, sizeof(text));
    
    if (StrEqual(text, "!ьс")) {
        FakeClientCommand(client, "%s !mc", command);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public JM_NoobMark_OnBeforeActivate(client)
{
    RemoveMiniClip(client, true);
}

public JM_NoobMark_OnBeforeDeactivate(client)
{
    RemoveMiniClip(client, false);
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    RemoveMiniClip(client, false);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    RemoveMiniClip(client, false);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (g_bMiniClipEnabled[client]) {
        buttons &= ~IN_ATTACK;
        buttons &= ~IN_ATTACK2;

        return Plugin_Changed;
    } 
    
    return Plugin_Continue;
}

public Action:Command_MiniClip(client, args)
{
    if (g_bMiniClipEnabled[client]) {
        RemoveMiniClip(client, true);
        ReplyToCommand(client, "Mini-clip deactivated");
    } else {
        AddMiniClip(client);
        ReplyToCommand(client, "Mini-clip activated for 10 seconds");
    }
    return Plugin_Handled;
}

public Action:Timer_RemoveMiniClip(Handle:timer, any:client)
{
    if (g_bMiniClipEnabled[client]) {
        RemoveMiniClip(client, true);
    }
}

public Action:Timer_RemoveMovementBlock(Handle:timer, any:client)
{
    new flags = GetEntityFlags(client);
    flags &= ~FL_FROZEN;
    SetEntityFlags(client, flags);
}

AddMiniClip(client)
{
    g_bMiniClipEnabled[client] = true;
    
    GetClientAbsOrigin(client, g_vClientOrigin[client]);
    GetClientEyeAngles(client, g_vClientAngles[client]);
    Entity_GetAbsVelocity(client, g_vClientVelocity[client]);
    
    new flags = GetEntityFlags(client);
    flags |= FL_FLY | FL_DONTTOUCH | FL_NOTARGET;
    SetEntityFlags(client, flags);
    SetEntityMoveType(client, MOVETYPE_NOCLIP);
    
    CreateTimer(10.0, Timer_RemoveMiniClip, client);
}

RemoveMiniClip(client, bool:teleport_back)
{
    g_bMiniClipEnabled[client] = false;
    
    new flags = GetEntityFlags(client);
    flags &= ~FL_FLY;
    flags &= ~FL_NOTARGET;
    flags &= ~FL_DONTTOUCH;
    
    if (teleport_back) {
        flags |= FL_FROZEN;
        CreateTimer(0.5, Timer_RemoveMovementBlock, client);
        TeleportEntity(client, g_vClientOrigin[client], g_vClientAngles[client], g_vClientVelocity[client]);
    }
    
    SetEntityFlags(client, flags);
    SetEntityMoveType(client, MOVETYPE_WALK);
}
