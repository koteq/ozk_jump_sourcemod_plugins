#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
    name = "JM Voice Subtitle",
    author = "Reflex",
    description = "Some tweaks for voice subtitles.",
    version = "1.0"
};

new g_Author;
new g_FirstMenuId;
new g_SecondMenuId;
new bool:g_Broadcast;

public OnPluginStart()
{
    HookUserMessage(GetUserMessageId("VoiceSubtitle"), OnVoiceSubtitle, true, OnVoiceSubtitlePost);
}

public Action:OnVoiceSubtitle(UserMsg:msg_id, Handle:bf, const clients[], numClients, bool:reliable, bool:init)
{
    g_Author = BfReadByte(bf);
    g_FirstMenuId = BfReadByte(bf);
    g_SecondMenuId = BfReadByte(bf);

    if ((g_FirstMenuId == 0 && g_SecondMenuId == 1) ||  // thanks
        (g_FirstMenuId == 0 && g_SecondMenuId == 6) ||  // yes
        (g_FirstMenuId == 0 && g_SecondMenuId == 7) ||  // no
        (g_FirstMenuId == 2 && g_SecondMenuId == 0)     // help
    ) {
        g_Broadcast = true;
        return Plugin_Handled;
    }

    g_Broadcast = false;
    return Plugin_Continue;
}

public OnVoiceSubtitlePost(UserMsg:msg_id, bool:sent)
{
    if (g_Broadcast) {
        new playersNum = 0;
        decl players[MaxClients];

        for (new client = 1; client <= MaxClients; client++) {
            if (IsClientInGame(client)) {
                players[playersNum++] = client;
            }
        }

        if (playersNum > 0) {
            new Handle:VoiceSubtitle = StartMessage("VoiceSubtitle", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

            if (VoiceSubtitle != INVALID_HANDLE) {
                BfWriteByte(VoiceSubtitle, g_Author);
                BfWriteByte(VoiceSubtitle, g_FirstMenuId);
                BfWriteByte(VoiceSubtitle, g_SecondMenuId);
                EndMessage();
            }
        }
    }
}
