#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
    name = "AllChat",
    author = "Frenzzy & Reflex",
    description = "Relays chat messages to all players",
    version = "1.1.1",
    url = "http://forums.alliedmods.net/showthread.php?p=1593727"
};

new g_msgAuthor;
new bool:g_msgIsChat;
new String:g_msgType[64];
new String:g_msgName[64];
new String:g_msgText[512];
new bool:g_msgIsTeammate;
new bool:g_msgTarget[MAXPLAYERS + 1];

public OnPluginStart()
{
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
    
    HookUserMessage(GetUserMessageId("SayText2"), Hook_UserMessage);
    
    HookEvent("player_say", Event_PlayerSay);
}

// call order: first
public Action:Command_Say(client, const String:command[], argc)
{
    for (new target = 1; target <= MaxClients; target++) {
        g_msgTarget[target] = true;
    }

    if (StrEqual(command, "say_team", false)) {
        g_msgIsTeammate = true;
    }
    else {
        g_msgIsTeammate = false;
    }

    return Plugin_Continue;
}

// call order: second
// may be called multiple times for single say command
public Action:Hook_UserMessage(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    g_msgAuthor = BfReadByte(bf);
    g_msgIsChat = bool:BfReadByte(bf);
    BfReadString(bf, g_msgType, sizeof(g_msgType), false);
    BfReadString(bf, g_msgName, sizeof(g_msgName), false);
    BfReadString(bf, g_msgText, sizeof(g_msgText), false);

    for (new i = 0; i < playersNum; i++) {
        g_msgTarget[players[i]] = false;
    }
}

// call order: third
public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetClientOfUserId(GetEventInt(event, "userid")) != g_msgAuthor) {
        return;
    }

    if (g_msgIsTeammate) {
        return;
    }

    new playersNum = 0;
    decl players[MaxClients];

    for (new client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && g_msgTarget[client]) {
            players[playersNum++] = client;
        }

        g_msgTarget[client] = false;
    }

    if (playersNum == 0) {
        return;
    }

    new Handle:SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

    if (SayText2 != INVALID_HANDLE) {
        BfWriteByte(SayText2, g_msgAuthor);
        BfWriteByte(SayText2, g_msgIsChat);
        BfWriteString(SayText2, g_msgType);
        BfWriteString(SayText2, g_msgName);
        BfWriteString(SayText2, g_msgText);
        EndMessage();
    }
} /* Event_PlayerSay */

// TODO ref: create plugin for this
/*public Event_PlayerSay(Handle:event, const String:Event_mtype[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client || !IsClientObserver(client)) return;

    decl String:name[NAME_LEN];
    decl String:text[MSG_LEN];
    decl String:msg[NAME_LEN + MSG_LEN + 6];

    decl tx_clients[MAXPLAYERS];
    new tx_count = 0;

    if (!GetClientName(client, name, sizeof(name))) return;

    GetEventString(event, "text", text, sizeof(text));

    Format(msg, sizeof(msg), "\x07FFFF7F%s\x01 :  %s", name, text);



    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && IsPlayerAlive(i)) tx_clients[tx_count++] = i;

    if (!tx_count) return;

    new Handle:h_saytext2 = StartMessage("SayText2", tx_clients, tx_count, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

    if (h_saytext2 != INVALID_HANDLE)
    {
        BfWriteByte(h_saytext2, client);
        BfWriteByte(h_saytext2, true);
        BfWriteString(h_saytext2, msg);
        EndMessage();
    }

    return;
}*/