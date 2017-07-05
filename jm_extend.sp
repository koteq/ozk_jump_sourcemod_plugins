#pragma semicolon 1

#include <sourcemod>
#include <sdktools_sound>

public Plugin:myinfo = {
    name = "JM Extend",
    author = "Reflex",
    description = "Allow admins to extend timelimit",
    version = "1.0"
};

#define MAX_ALLOWED_EXTENSION 60
#define VO_TIME_ADDED "vo/announcer_time_added.mp3"

new Handle:g_hTimelimit;
new g_iIntitalTimelimit;

public OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("jm_extend.phrases");

    RegAdminCmd("sm_extend", Command_Extend, ADMFLAG_CHANGEMAP);
    RegAdminCmd("sm_addtime", Command_Extend, ADMFLAG_CHANGEMAP);
    
    g_hTimelimit = FindConVar("mp_timelimit");
}

public OnMapStart()
{
    PrecacheSound(VO_TIME_ADDED);
}

public OnConfigsExecuted()
{
    g_iIntitalTimelimit = GetConVarInt(g_hTimelimit);
}

public Action:Command_Extend(client, args)
{
    if (args < 1) {
        ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
        return Plugin_Handled;
    }

    new String:buff[4];
    GetCmdArg(1, buff, sizeof(buff));
    new extension = StringToInt(buff);

    if (extension == 0) {
        ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
        return Plugin_Handled;
    }

    new timelimit = GetConVarInt(g_hTimelimit);
    if (extension > 0 &&
        timelimit >= g_iIntitalTimelimit + MAX_ALLOWED_EXTENSION
    ) {
        ReplyToCommand(client, "[SM] %t", "Extension Limit Reached");
        return Plugin_Handled;
    }

    if (timelimit + extension <= g_iIntitalTimelimit + MAX_ALLOWED_EXTENSION) {
        timelimit += extension;
    }
    else {
        extension = g_iIntitalTimelimit + MAX_ALLOWED_EXTENSION - timelimit;
        timelimit = g_iIntitalTimelimit + MAX_ALLOWED_EXTENSION;
    }

    SetConVarInt(g_hTimelimit, timelimit);

    if (extension > 0) {
        ShowActivity2(client, "[SM] ", "%t", "Extends timelimit", extension);
        LogAction(client, -1, "extends timelimit by %d minutes", extension);
        EmitSoundToAll(VO_TIME_ADDED, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    }
    else {
        ShowActivity2(client, "[SM] ", "%t", "Reduces timelimit", extension * -1);
        LogAction(client, -1, "deducted timelimit by %d minutes", extension * -1);
    }

    return Plugin_Handled;
}
