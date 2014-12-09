/*
 * ============================================================================
 *
 *  SourceMod AllChat Plugin
 *
 *  File:          allchat.sp
 *  Description:   Relays chat messages to all players.
 *
 *  Copyright (C) 2011  Frenzzy
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#pragma semicolon 1

/* SM Includes */
#include <sourcemod>

/* Plugin Info */
#define PLUGIN_NAME "AllChat"
#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Frenzzy",
	description = "Relays chat messages to all players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1593727"
};

/* Chat Message */
new g_msgAuthor;
new bool:g_msgIsChat;
new String:g_msgType[64];
new String:g_msgName[64];
new String:g_msgText[512];
new bool:g_msgIsTeammate;
new bool:g_msgTarget[MAXPLAYERS + 1];

public OnPluginStart()
{
	// Events.
	new UserMsg:SayText2 = GetUserMessageId("SayText2");
	
	if (SayText2 == INVALID_MESSAGE_ID)
	{
		SetFailState("This game doesn't support SayText2 user messages.");
	}
	
	HookUserMessage(SayText2, Hook_UserMessage);
	HookEvent("player_say", Event_PlayerSay);
	
	//AutoExecConfig(true, "allchat");
	
	// Commands.
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public Action:Hook_UserMessage(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	g_msgAuthor = BfReadByte(bf);
	g_msgIsChat = bool:BfReadByte(bf);
	BfReadString(bf, g_msgType, sizeof(g_msgType), false);
	BfReadString(bf, g_msgName, sizeof(g_msgName), false);
	BfReadString(bf, g_msgText, sizeof(g_msgText), false);
	
	for (new i = 0; i < playersNum; i++)
	{
		g_msgTarget[players[i]] = false;
	}
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (GetClientOfUserId(GetEventInt(event, "userid")) != g_msgAuthor)
	{
		return;
	}
	
	if (g_msgIsTeammate)
	{
		return;
	}
	
	decl players[MaxClients];
	new playersNum = 0;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && g_msgTarget[client])
		{
			players[playersNum++] = client;
		}
		
		g_msgTarget[client] = false;
	}
	
	if (playersNum == 0)
	{
		return;
	}
	
	new Handle:SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	
	if (SayText2 != INVALID_HANDLE)
	{
		BfWriteByte(SayText2, g_msgAuthor);
		BfWriteByte(SayText2, g_msgIsChat);
		BfWriteString(SayText2, g_msgType);
		BfWriteString(SayText2, g_msgName);
		BfWriteString(SayText2, g_msgText);
		EndMessage();
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		g_msgTarget[target] = true;
	}
	
	if (StrEqual(command, "say_team", false))
	{
		g_msgIsTeammate = true;
	}
	else
	{
		g_msgIsTeammate = false;
	}
	
	return Plugin_Continue;
}


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
	
	Format(msg, sizeof(msg), "\x05%s\x01 :  %s", name, text);
	
	
	
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