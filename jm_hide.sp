#pragma semicolon 1

#include <sourcemod>
//#include <sdkhooks>
#include <tf2_stocks>
#include <clientprefs>

#include <jm_stocks>

public Plugin:myinfo = {
	name = "JM Hide Players",
	author = "[GNC] Matt",
	description = "Adds commands to show/hide other players.",
	version = "1.0",
}

new bool:g_bObserver[MAXPLAYERS + 1];
new bool:g_bHidePlayers[MAXPLAYERS + 1];
new bool:g_bHideExplosions[MAXPLAYERS + 1];
new Handle:g_hCookieHideExplosions = INVALID_HANDLE;

public OnPluginStart()
{
	//RegConsoleCmd("sm_hide", Command_Hide, "Hide other players");
	RegConsoleCmd("sm_explosions", Command_HideExplosions, "Hide explosions");
	
	HookEvent("player_team", Event_ChangeTeam);

	AddNormalSoundHook(NormalSHook:SoundHook);
	AddTempEntHook("TFExplosion", TEHook:Hook_Explosion);
	
	g_hCookieHideExplosions = RegClientCookie("jm_hide_explosions", "Hide explosions", CookieAccess_Public);
	
	/*for (new client = 1; client <= MaxClients; client++) {
		if (IsValidClient(client)) {
			SDKHook(client, SDKHook_SetTransmit, Hook_TransmitToClient);
		}
	}*/
}

public OnClientConnected(client)
{
	g_bHidePlayers[client] = false;
	g_bHideExplosions[client] = false;
	//SDKHook(client, SDKHook_SetTransmit, Hook_TransmitToClient);
}

public OnClientCookiesCached(client)
{
	decl String:value[2];
	GetClientCookie(client, g_hCookieHideExplosions, value, sizeof(value));
	if (strlen(value) < 1) {
		return;
	}
	g_bHideExplosions[client] = (StringToInt(value) != 0);
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
		if (g_bHideExplosions[client]) {
			Format(buffer, maxlen, "Hide explosions: On");
		} else {
			Format(buffer, maxlen, "Hide explosions: Off");
		}
	} else if (action == CookieMenuAction_SelectOption) {
		g_bHideExplosions[client] = !g_bHideExplosions[client];
		if (g_bHideExplosions[client]) {
			SetClientCookie(client, g_hCookieHideExplosions, "1");
		} else {
			SetClientCookie(client, g_hCookieHideExplosions, "0");
		}
		ShowCookieMenu(client);
	}
}

public Action:Command_Hide(client, args)
{
	g_bHidePlayers[client] = !g_bHidePlayers[client];
	if (g_bHidePlayers[client]) {
		ReplyToCommand(client, "[JM] Other players are now hidden.");
	} else {
		ReplyToCommand(client, "[JM] Other players are now visible.");
	}
}

public Action:Command_HideExplosions(client, args)
{
	g_bHideExplosions[client] = !g_bHideExplosions[client];
	if (g_bHideExplosions[client]) {
		SetClientCookie(client, g_hCookieHideExplosions, "1");
		ReplyToCommand(client, "[JM] Explosions are now hidden.");
	} else {
		SetClientCookie(client, g_hCookieHideExplosions, "0");
		ReplyToCommand(client, "[JM] Explosions are now visible.");
	}
}

public Action:Hook_TransmitToClient(entity, client)
{
	if (g_bHidePlayers[client] && client != entity && !g_bObserver[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:SoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new client;
	new Action:result = Plugin_Continue;
	for (new i = 0; i < numClients; i++) {
		client = clients[i];
		if (g_bHidePlayers[client] && !g_bObserver[client]) {
			clients[i] = -1;
			result = Plugin_Changed;
		}
	}
	return result;
}

public Action:Hook_Explosion(const String:te_name[], const clients[], numClients, Float:delay)
{
	new client;
	new num_override;
	new clients_override[numClients];
	new Action:result = Plugin_Continue;
	for (new i; i < numClients; i++) {
		client = clients[i];
		if ((g_bHideExplosions[client] || g_bHidePlayers[client]) && !g_bObserver[client]) {
			result = Plugin_Stop;
		} else {
			clients_override[num_override++] = client;
		}
	}
	if (result == Plugin_Stop) {
		TE_Send(clients_override, num_override, delay);
	}
	return result;
}

public Action:Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");

	g_bObserver[client] = (team == 1);
}

/*public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "tf_projectile_") != -1) {
		SDKHook(entity, SDKHook_Spawn, Hook_ProjectileSpawn);
	}
}*/

/*public Hook_ProjectileSpawn(entity)
{
	SDKHook(entity, SDKHook_SetTransmit, Hook_TransmitProjectileToClient);
}*/

/*public Action:Hook_TransmitProjectileToClient(entity, client)
{
	if (g_bHidePlayers[client] && !g_bObserver[client]) {
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(owner) && owner != client) {
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}*/
