#pragma semicolon 1

#include <sourcemod>
#include <jm_stocks>
#include <morecolors>
#include <clientprefs>

public Plugin:myinfo = {
	name = "JM Skeys",
	author = "Reflex",
	description = "Show client keys",
	version = "1.0"
};

#define SPECMODE_NONE        0
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_3RDPERSON   5
#define SPECMODE_FREELOOK    6

#define SKEYS_BUFFER_LEN 64
#define SKEYS_BUTTONS_FILTER (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP | IN_DUCK | IN_SCORE)

new g_iButtons[MAXPLAYERS + 1];
new g_iShownButtons[MAXPLAYERS + 1];
new bool:g_bShowHudKeys[MAXPLAYERS + 1];
new Handle:g_hCookieSkeys = INVALID_HANDLE;
new Handle:g_hSkeysHudSynchronizer = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("jm_skeys.phrases");
	RegConsoleCmd("sm_skeys", Command_ShowKeys, "Toggle showing a clients keys");
	g_hSkeysHudSynchronizer = CreateHudSynchronizer();
	g_hCookieSkeys = RegClientCookie("jm_skeys", "Show keys pressed by observed player", CookieAccess_Public);
}

public OnClientConnected(client)
{
	g_bShowHudKeys[client] = true;
}

public OnClientCookiesCached(client)
{
	decl String:value[2];
	GetClientCookie(client, g_hCookieSkeys, value, sizeof(value));
	if (strlen(value) < 1) {
		return;
	}
	g_bShowHudKeys[client] = (StringToInt(value) != 0);
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
		if (g_bShowHudKeys[client]) {
			Format(buffer, maxlen, "Skeys: On");
		} else {
			Format(buffer, maxlen, "Skeys: Off");
		}
	} else if (action == CookieMenuAction_SelectOption) {
		g_bShowHudKeys[client] = !g_bShowHudKeys[client];
		if (g_bShowHudKeys[client]) {
			SetClientCookie(client, g_hCookieSkeys, "1");
		} else {
			SetClientCookie(client, g_hCookieSkeys, "0");
		}
		ShowCookieMenu(client);
	}
}

public Action:Command_ShowKeys(client, args)
{
	if (!IsClientObserver(client)) {
		ReplyToCommand(client, "[JM] %t", "Showkeys_OnlyForSpectators");
		return Plugin_Handled;
	}
	if (g_bShowHudKeys[client]) {
		g_bShowHudKeys[client] = false;
		ClearSyncHud(client, g_hSkeysHudSynchronizer);
		SetClientCookie(client, g_hCookieSkeys, "0");
		CPrintToChat(client, "[JA] %t", "Showkeys_Off");
	} else {
		g_bShowHudKeys[client] = true;
		SetClientCookie(client, g_hCookieSkeys, "1");
		CPrintToChat(client, "[JA] %t", "Showkeys_On");
	}
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	g_iButtons[client] = buttons & SKEYS_BUTTONS_FILTER;
}

public OnGameFrame()
{
	new iPos;
	new buttons;
	new iObserverMode;
	new iObserverTarget;
	decl String:sOutput[SKEYS_BUFFER_LEN];
	
	SetHudTextParams(0.53, 0.4, 60.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	
	for (new client = 1; client < MaxClients; client++) {
		if (g_bShowHudKeys[client] &&
			IsValidClient(client) &&
			IsClientObserver(client)
		) {
			buttons = 0;
			
			if (g_iButtons[client] & IN_SCORE) {
				continue; // do not update while client hide, in score
			}
			
			iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
			if (iObserverMode != SPECMODE_FIRSTPERSON) {
				buttons = -1;  // hide, in free look and 3rd person
			}
			
			if (buttons != -1) {
				iObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (IsValidClient(iObserverTarget)) {
					buttons = g_iButtons[iObserverTarget];
				} else {
					buttons = -1;
				}
			}
			
			if (buttons == g_iShownButtons[client]) {
				continue;  // for network optimization
			}
			
			g_iShownButtons[client] = buttons;
			
			if (buttons == -1) {
				ClearSyncHud(client, g_hSkeysHudSynchronizer);
				continue;
			}

			// Is he pressing "w"?
			iPos = 0;
			if (buttons & IN_FORWARD) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "      W     ");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "      _      ");
			}

			// Is he pressing "space"?
			if (buttons & IN_JUMP) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "     JUMP\n");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "\n");
			}

			// Is he pressing "a"?
			if (buttons & IN_MOVELEFT) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  A");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "s"?
			if (buttons & IN_BACK) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  S");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "d"?
			if (buttons & IN_MOVERIGHT) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  D");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "  _");
			}

			// Is he pressing "ctrl"?
			if (buttons & IN_DUCK) {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "       DUCK\n");
			} else {
				iPos += Format(sOutput[iPos], SKEYS_BUFFER_LEN - iPos, "\n");
			}

			ShowSyncHudText(client, g_hSkeysHudSynchronizer, sOutput);
		}
	}
} /* OnGameFrame */
