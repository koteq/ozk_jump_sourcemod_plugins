#pragma semicolon 1

#include <sourcemod>
#include <scp>

public Plugin:myinfo = {
    name = "JM Chat",
    author = "Reflex",
    description = "Some tweaks for default chat done with scp.",
    version = "1.0"
};

// notice: OnChatMessage will get called for every recipient (multiple times)
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
    new flags = GetMessageFlags();
    if ((flags & CHATFLAGS_SPEC)) {
        // paint spectator's names in yellow
        Format(name, MAXLENGTH_NAME, "\x07FFFF7F%s", name);

        if (!(flags & CHATFLAGS_TEAM)) {
            // spectator messages are invisible for alive players
            // we have to fix that

            // we must change only one message to prevent message dublications
            // lets change the one adressed to it's author
            if (FindValueInArray(recipients, author) != -1) {
                for (new client = 1; client <= MaxClients; client++) {
                    if (IsClientInGame(client) && IsPlayerAlive(client)) {
                        PushArrayCell(recipients, client);
                    }
                }
            }
        }

        return Plugin_Changed;
    }

    return Plugin_Continue;
}
