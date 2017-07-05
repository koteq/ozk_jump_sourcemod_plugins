#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

public Plugin myinfo = {
    name = "JM RTD",
    author = "Reflex",
    description = "True roll the dice",
    version = "1.0"
};

public void OnPluginStart()
{
    AddCommandListener(Event_Say, "say");
    AddCommandListener(Event_Say, "say_team");
}

public Action Event_Say(int client, const char[] command, int args)
{
    if (client == 0) {
        return Plugin_Continue;
    }

    int startidx = 0;
    char text[192];
    if (GetCmdArgString(text, sizeof(text)) < 1) {
        return Plugin_Continue;
    }

    if (text[strlen(text) - 1] == '"') {
        text[strlen(text) - 1] = '\0';
        startidx = 1;
    }

    if (text[startidx] == '/' || text[startidx] == '!') {
        startidx += 1;
    }
    else {
        return Plugin_Continue;
    }

    int len = strlen(text[startidx]);
    if (text[len + startidx - 1] == '"') {
        text[len + startidx - 1] = '\0';
        len -= 1;
    }

    if ((strcmp(text[startidx], "rtd") == 0 && len == 3) ||
        (strcmp(text[startidx], "roll") == 0 && len == 4) ||
        (strcmp(text[startidx], "rollthedice") == 0)
    ) {
        Roll(client);
    }

    return Plugin_Continue;
}

void Roll(int client)
{
    int num = GetRandomInt(1, 6);
    PrintToChatAll("[SM] %N rolled %d", client, num);
}
