#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name = "JM MOTD",
	author = "Reflex, psychonic",
	description = "Allows dynamicly generated MOTD urls",
	version = "1.0"
};

enum /* Ep2vMOTDCmd */ {
	Cmd_None,
	Cmd_JoinGame,
	Cmd_ChangeTeam,
	Cmd_Impulse101,
	Cmd_MapInfo,
	Cmd_ClosedHTMLPage,
	Cmd_ChooseTeam,
};

//#define USE_BIG_MOTD
#define TOKEN_LANGUAGE "{LANGUAGE}"
#define TOKEN_STEAM_ID "{STEAM_ID}"
#define TOKEN_STEAM_ID32_ENC "{STEAM_ID32_ENC}"
#define MOTD_URL "http://cs.ozerki.net/files/tf2/tfjump_motd/?sid={STEAM_ID}&lng={LANGUAGE}&key={STEAM_ID32_ENC}"

new bool:g_bIgnoreNextVGUI;
new Handle:g_cmdQueue[MAXPLAYERS + 1];
new bool:g_bFirstMOTDNext[MAXPLAYERS + 1] = {false, ...};

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("VGUIMenu"), OnMsgVGUIMenu, true);

	AddCommandListener(OnClose, "closed_htmlpage");

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i)) {
			g_cmdQueue[i] = CreateArray();
		}
	}
}

public Action:OnClose(client, const String:command[], argc)
{
	if (!GetArraySize(g_cmdQueue[client])) {
		// this one isn't for us i guess
		return Plugin_Continue;
	}
	new cmd = GetArrayCell(g_cmdQueue[client], 0);
	RemoveFromArray(g_cmdQueue[client], 0);

	switch (cmd) {
		// TF2 doesn't have joingame or chooseteam
		case Cmd_ChangeTeam:
			ShowVGUIPanel(client, "team");
		case Cmd_MapInfo:       // no server cmd equiv
			ShowVGUIPanel(client, "mapinfo");
	}

	return Plugin_Continue;
} /* OnClose */

public OnClientConnected(client)
{
	g_bFirstMOTDNext[client] = true;
	g_cmdQueue[client] = CreateArray();
}

public OnClientDisconnect(client)
{
	CloseHandle(g_cmdQueue[client]);
	g_cmdQueue[client] = INVALID_HANDLE;
}

public Action:DoMOTD(Handle:hTimer, Handle:pack)
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	new Handle:kv = Handle:ReadPackCell(pack);

	if (client == 0) {
		CloseHandle(kv);
		return Plugin_Stop;
	}

	#if defined USE_BIG_MOTD
	KvSetNum(kv, "customsvr", 1);
	new cmd;
	// tf2 doesn't send the cmd on the first one. it displays the mapinfo and team choice first, behind motd (so cmd is 0).
	// we can't rely on that since closing bigmotd clobbers all vgui panels,
	if ((cmd = KvGetNum(kv, "cmd")) != Cmd_None) {
		PushArrayCell(g_cmdQueue[client], cmd);
		KvSetNum(kv, "cmd", Cmd_ClosedHTMLPage);
	} else if (g_bFirstMOTDNext[client] == true) {
		PushArrayCell(g_cmdQueue[client], Cmd_ChangeTeam);
		KvSetNum(kv, "cmd", Cmd_ClosedHTMLPage);
	}
	#endif //BIG_MOTD

	KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);

	decl String:url[256];
	BuildMotdUrl(client, url);

	KvSetString(kv, "msg", url);

	g_bIgnoreNextVGUI = true;
	ShowVGUIPanel(client, "info", kv, true);

	CloseHandle(kv);

	return Plugin_Stop;
} /* DoMOTD */

public Action:OnMsgVGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (g_bIgnoreNextVGUI) {
		g_bIgnoreNextVGUI = false;
		return Plugin_Continue;
	}

	decl String:buffer1[64];
	decl String:buffer2[256];

	// check menu name
	BfReadString(bf, buffer1, sizeof(buffer1));
	if (strcmp(buffer1, "info") != 0) {
		return Plugin_Continue;
	}

	// make sure it's not a hidden one
	if (BfReadByte(bf) != 1) {
		return Plugin_Continue;
	}

	new count = BfReadByte(bf);

	// we don't one ones with no kv pairs.
	// ones with odd amount are invalid anyway
	if (count == 0) {
		return Plugin_Continue;
	}

	new Handle:kv = CreateKeyValues("data");
	for (new i = 0; i < count; i++) {
		BfReadString(bf, buffer1, sizeof(buffer1));
		BfReadString(bf, buffer2, sizeof(buffer2));

		if (strcmp(buffer1, "customsvr") == 0 ||
		    (strcmp(buffer1, "msg") == 0 && strcmp(buffer2, "motd") != 0)
		) {
			// not pulling motd from stringtable. must be a custom
			CloseHandle(kv);
			return Plugin_Continue;
		}

		KvSetString(kv, buffer1, buffer2);
	}

	new Handle:pack;
	CreateDataTimer(0.001, DoMOTD, pack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, GetClientUserId(players[0]));
	WritePackCell(pack, _:kv);

	return Plugin_Handled;
} /* OnMsgVGUIMenu */

BuildMotdUrl(client, String:motdurl[256])
{
	//Format(motdurl, sizeof(motdurl), "%s", MOTD_URL);
	strcopy(motdurl, sizeof(motdurl), MOTD_URL);
	
	decl String:steamId[64];
	if (GetClientAuthString(client, steamId, sizeof(steamId))) {
		ReplaceString(steamId, sizeof(steamId), ":", "%3a");
		ReplaceString(motdurl, sizeof(motdurl), TOKEN_STEAM_ID, steamId);
	} else {
		ReplaceString(motdurl, sizeof(motdurl), TOKEN_STEAM_ID, "");
	}

	decl String:language[32];
	if (GetClientInfo(client, "cl_language", language, sizeof(language))) {
		decl String:encLanguage[sizeof(language) * 3];
		UrlEncodeString(encLanguage, sizeof(encLanguage), language);
		ReplaceString(motdurl, sizeof(motdurl), TOKEN_LANGUAGE, encLanguage);
	} else {
		ReplaceString(motdurl, sizeof(motdurl), TOKEN_LANGUAGE, "");
	}
	
	decl String:steamId32Enc[128];
	GetSteamId32Enc(client, steamId32Enc, sizeof(steamId32Enc));
	ReplaceString(motdurl, sizeof(motdurl), TOKEN_STEAM_ID32_ENC, steamId32Enc);
} /* BuildMotdUrl */

// loosely based off of PHP's urlencode
UrlEncodeString(String:output[], size, const String:input[])
{
	new icnt = 0;
	new ocnt = 0;

	for (;; ) {
		if (ocnt == size) {
			output[ocnt - 1] = '\0';
			return;
		}

		new c = input[icnt];
		if (c == '\0') {
			output[ocnt] = '\0';
			return;
		}

		// Use '+' instead of '%20'.
		// Still follows spec and takes up less of our limited buffer.
		if (c == ' ') {
			output[ocnt++] = '+';
		} else if ((c < '0' && c != '-' && c != '.') ||
		           (c < 'A' && c > '9') ||
		           (c > 'Z' && c < 'a' && c != '_') ||
		           (c > 'z' && c != '~')
		) {
			ocnt += Format(output[ocnt], size - strlen(output[ocnt]), "%%%02x", c);
		} else {
			output[ocnt++] = c;
		}

		icnt++;
	}
} /* UrlEncodeString */

GetSteamId32Enc(client, String:buffer[], size)
{
	new i;
	new chr;
	new cursor = 0;
	new time = GetTime();
	new steamId32 = GetSteamAccountID(client);

	SetURandomSeedSimple(time);
	
	// pack time (int32)
	for (i = 0; i < 4; i++) {
		chr = (time >> (8 * i)) & 0xFF;
		cursor += UrlEncodeChar(buffer[cursor], size - cursor, chr);
	}

	// pack steamid (int32, encrypted)
	for (i = 0; i < 4; i++) {
		chr = (steamId32 >> (8 * i)) & 0xFF;
		chr = chr ^ (GetURandomInt() & 0xFF);
		cursor += UrlEncodeChar(buffer[cursor], size - cursor, chr);
	}
	
	buffer[cursor] = '\0';
}

UrlEncodeChar(String:buffer[], size, chr)
{
	if (chr == ' ') {
		return Format(buffer[0], size, "+");
	}
	if ((chr < '0' && chr != '-' && chr != '.') ||
	    (chr < 'A' && chr > '9') ||
	    (chr > 'Z' && chr < 'a' && chr != '_') ||
	    (chr > 'z' && chr != '~')
	) {
		return Format(buffer[0], size, "%%%02x", chr);
	}
	return Format(buffer[0], size, "%c", chr);
}

/*
<?
function encode($steamId32)
{
    $result = "";
    $time = time();
    srand($time);
    for ($i = 0; $i < 4; $i++) {
        $chr = ($time >> (8 * $i)) & 0xFF;
        $result .= chr($chr);
    }
    for ($i = 0; $i < 4; $i++) {
        $chr = ($steamId32 >> (8 * $i)) & 0xFF;
        $result .= chr($chr ^ rand(0, 0xFF));
    }
    $result = urlencode($result);
    var_dump(array(
        'time' => $time,
        'result' => $result,
    ));

    return $result;
}

function decode($str)
{
    $result = 0;
    $str = urldecode($str);
    list($time, $data) = array_values(unpack("i2", $str));
    srand($time);
    for ($i = 0; $i < 4; $i++) {
        $chr = ($data >> (8 * $i)) & 0xFF;
        $result += ($chr ^ rand(0, 0xFF)) << (8 * $i);
    }
    var_dump(array(
        'time' => $time,
        'result' => $result,
    ));

    return $result;
}

decode(encode(1));
//test(1);
//test(33517206);
//test(2147483647);


*/