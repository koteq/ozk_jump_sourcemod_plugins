#pragma semicolon 1

#include <sourcemod>
#include <scp>

public Plugin:myinfo = {
    name = "JM Chat",
    author = "Reflex",
    description = "Some tweaks for default chat done with scp.",
    version = "1.0"
};

// NOTICE: this callback MAY be called MULTIPLE times (may not)
//         for EVERY player on the server even for the author himself
// NOTICE: it's imposible to send message from within this hook
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
            if (InArray(recipients, author)) {
                for (new client = 1; client <= MaxClients; client++) {
                    if (
                        IsClientInGame(client) &&
                        IsPlayerAlive(client) &&
                        !InArray(recipients, client)
                    ) {
                        PushArrayCell(recipients, client);
                    }
                }
            }
        }

        return Plugin_Changed;
    }

    return Plugin_Continue;
}

stock bool:InArray(Handle:array, any:item)
{
    return FindValueInArray(array, item) != -1;
}
