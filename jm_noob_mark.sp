#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <morecolors>
#include <jm_stocks>
#include <jm_noob_mark>

public Plugin:myinfo =
{
    name = "JM Noob Mark",
    author = "Reflex",
    description = "Mark cheating players as noobs"
};

//#define YOU_WERE_ALWAYS_A_DISAPPOINTMENT "vo/announcer_am_lastmanforfeit02.mp3"
#define YOU_DISGUST_ME "vo/announcer_am_lastmanforfeit04.mp3"

new Handle:g_hOnBeforeActivateNoobMarkForward = INVALID_HANDLE;
new Handle:g_hOnBeforeDeactivateNoobMarkForward = INVALID_HANDLE;

new bool:g_bNoobMark[MAXPLAYERS + 1];
new g_ClientTeam[MAXPLAYERS + 1];
new Float:g_vClientOrigin[MAXPLAYERS + 1][3];
new Float:g_vClientAngles[MAXPLAYERS + 1][3];
new Float:g_vClientVelocity[MAXPLAYERS + 1][3];

public OnPluginStart() {
    LoadTranslations("jm_noob_mark.phrases");
    
    RegConsoleCmd("sm_unmark", Command_Unmark);
}

public OnMapStart()
{
    for (new client = 0; client < MaxClients + 1; client++) {
        g_bNoobMark[client] = false;
    }
    PrecacheSound(YOU_DISGUST_ME);
}

public OnClientConnected(client)
{
    g_bNoobMark[client] = false;
}

public Action:Command_Unmark(client, args)
{
    UnmarkClientAsNoob(client, true);
    
    return Plugin_Handled;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("JM_NoobMark_IsActive", Native_IsActive);
    CreateNative("JM_NoobMark_PrintWarning", Native_PrintWarning);
    CreateNative("JM_NoobMark_Activate", Native_Activate);
    CreateNative("JM_NoobMark_Deactivate", Native_Deactivate);
    
    g_hOnBeforeActivateNoobMarkForward = CreateGlobalForward("JM_NoobMark_OnBeforeActivate", ET_Ignore, Param_Cell);
    g_hOnBeforeDeactivateNoobMarkForward = CreateGlobalForward("JM_NoobMark_OnBeforeDeactivate", ET_Ignore, Param_Cell);
    
    RegPluginLibrary("jm_noob_mark");   
    
    return APLRes_Success;
}

/* native JM_NoobMark_IsActive(client); */
public Native_IsActive(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    if (!IsValidClient(client)) return _:false;
    
    return _:g_bNoobMark[client];
}

/* native JM_NoobMark_PrintWarning(client, bool:clip_regen=false); */
public Native_PrintWarning(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    if (IsValidClient(client)) {
        CPrintToChat(client, "[JM] %t", "Noob Mark Warning");
    }
}

/* native JM_NoobMark_Activate(client); */
public Native_Activate(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    MarkClientAsNoob(client);
}

/* native JM_NoobMark_Deactivate(client, bool:resetPosition); */
public Native_Deactivate(Handle:plugin, numParams)
{
    new client = GetNativeCell(1);
    new bool:resetPosition = GetNativeCell(2);
    UnmarkClientAsNoob(client, resetPosition);
}

public Action:Timer_TeleportClient(Handle:timer, any:client)
{
    TeleportEntity(client, g_vClientOrigin[client], g_vClientAngles[client], g_vClientVelocity[client]);
}

MarkClientAsNoob(client)
{
    if (IsValidClient(client) && !g_bNoobMark[client]) {
        CallOnBeforeActivateNoobMarkForward(client);
        
        g_bNoobMark[client] = true;
        
        g_ClientTeam[client] = GetClientTeam(client);
        GetClientAbsOrigin(client, g_vClientOrigin[client]);
        GetClientEyeAngles(client, g_vClientAngles[client]);
        Entity_GetAbsVelocity(client, g_vClientVelocity[client]);
        
        CPrintToChat(client, "[JM] %t", "Noob Mark Activated");
        EmitSoundToClient(client, YOU_DISGUST_ME, SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
    }
}

UnmarkClientAsNoob(client, bool:resetPosition)
{
    if (IsValidClient(client) && g_bNoobMark[client]) {
        CallOnBeforeDeactivateNoobMarkForward(client);
        
        g_bNoobMark[client] = false;
        
        if (resetPosition) {
            if (g_ClientTeam[client] == GetClientTeam(client)) {
                DestroyClientProjectiles(client);
                TeleportEntity(client, g_vClientOrigin[client], g_vClientAngles[client], g_vClientVelocity[client]);
            }
            else {
                ChangeClientTeam(client, g_ClientTeam[client]);
                CreateTimer(0.01, Timer_TeleportClient, client);
            }
        }
    
        CPrintToChat(client, "[JM] %t", "Noob Mark Deactivated");
    }
}

CallOnBeforeActivateNoobMarkForward(client)
{
    Call_StartForward(g_hOnBeforeActivateNoobMarkForward);
    Call_PushCell(client);
    Call_Finish();
}

CallOnBeforeDeactivateNoobMarkForward(client)
{
    Call_StartForward(g_hOnBeforeDeactivateNoobMarkForward);
    Call_PushCell(client);
    Call_Finish();
}
