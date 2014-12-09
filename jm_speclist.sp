#pragma semicolon 1

#include <sourcemod>
#include <jm_stocks>
#include <sdktools>
#include <clientprefs>

public Plugin:myinfo = {
	name = "JM SpecList",
	author = "Reflex",
	description = "Spectators list",
	version = "1.0"
};

#define SPECMODE_NONE        0
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_3RDPERSON   5
#define SPECMODE_FREELOOK    6

new bool:g_bShowSpecList[MAXPLAYERS + 1];
new Handle:g_hCookieSpecList = INVALID_HANDLE;
new Handle:g_hHudSynchronizer = INVALID_HANDLE;

public OnPluginStart()
{
	RegConsoleCmd("sm_speclist", Command_SpecList, "Toggle showing a spectators list");
	g_hHudSynchronizer = CreateHudSynchronizer();
	g_hCookieSpecList = RegClientCookie("jm_speclist", "Show spectators list", CookieAccess_Public);
	CreateTimer(1.0, Timer_RedrawSpecList, _, TIMER_REPEAT);
}

public OnClientConnected(client)
{
	g_bShowSpecList[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:value[2];
	GetClientCookie(client, g_hCookieSpecList, value, sizeof(value));
	if (strlen(value) < 1) {
		return;
	}
	g_bShowSpecList[client] = (StringToInt(value) != 0);
}

public OnAllPluginsLoaded()
{
	if (GetExtensionFileStatus("clientprefs.ext") == 1) {
		SetCookieMenuItem(CookieMenuHandler, 0, "");
		for (new client = 1; client <= MaxClients; client++) {
			if (AreClientCookiesCached(client)) {
				OnClientCookiesCached(client);
			}
		}
	}
}

public CookieMenuHandler(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption) {
		if (g_bShowSpecList[client]) {
			Format(buffer, maxlen, "Spectators list: On");
		} else {
			Format(buffer, maxlen, "Spectators list: Off");
		}
	} else if (action == CookieMenuAction_SelectOption) {
		g_bShowSpecList[client] = !g_bShowSpecList[client];
		if (g_bShowSpecList[client]) {
			SetClientCookie(client, g_hCookieSpecList, "1");
		} else {
			SetClientCookie(client, g_hCookieSpecList, "0");
		}
		ShowCookieMenu(client);
	}
}

public Action:Command_SpecList(client, args)
{
	if (g_bShowSpecList[client]) {
		g_bShowSpecList[client] = false;
		ClearSyncHud(client, g_hHudSynchronizer);
		SetClientCookie(client, g_hCookieSpecList, "0");
		PrintToChat(client, "[JA] Spectator list disabled");
	} else {
		g_bShowSpecList[client] = true;
		SetClientCookie(client, g_hCookieSpecList, "1");
		PrintToChat(client, "[JA] Spectator list enabled");
	}
	return Plugin_Handled;
}

public Action:Timer_RedrawSpecList(Handle:timer)
{
	new client;
	new observer;
	new client_target;
	new observer_target;
	new pos;
	decl String:buffer[256];
	for (client = 1; client <= MaxClients; client++) {
		if (!IsClientInGame(client) ||
			!g_bShowSpecList[client] ||
			GetClientButtons(client) & IN_SCORE
		) {
			continue;
		}
		pos = 0;
		buffer[0] = '\0';
		for (observer = 1; observer <= MaxClients; observer++) {
			if (!IsClientInGame(observer) ||
				!IsClientObserver(observer) ||
				IsAdmin(observer, Admin_Ban) ||
				observer == client
			) {
				//PrintToMe("observer s1 %N", observer);
				continue;
			}
			observer_target = GetObserverTarget(observer);
			if (!IsValidClient(observer_target)) {
				continue;
			}
			if (IsClientObserver(client)) {
				client_target = GetObserverTarget(client);
				if (!IsValidClient(client_target) ||
					client_target != observer_target
				) {
					continue;
				}
			} else if (observer_target != client) {
				continue;
			}
			pos += Format(buffer[pos], sizeof(buffer) - pos, "%N\n", observer);
		}
		if (pos > 0) {
			SetHudTextParams(0.75, 0.0, 1.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
			ClearSyncHud(client, g_hHudSynchronizer);
			ShowSyncHudText(client, g_hHudSynchronizer, buffer);
		}
	}
}

GetObserverTarget(client)
{
	if (!IsClientObserver(client)) {
		return -1;
	}
	new observer_mode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (observer_mode != SPECMODE_FIRSTPERSON &&
		observer_mode != SPECMODE_3RDPERSON
	) {
		return -2;
	}
	new observer_target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if (!IsValidClient(observer_target) || observer_target == client) {
		return -3;
	}
	return observer_target;
}
