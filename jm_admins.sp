#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
    name = "JM Admins",
    author = "Reflex",
    description = "List admins count",
    version = "1.0"
};

public OnPluginStart()
{
    LoadTranslations("jm_admins.phrases");
    RegConsoleCmd("sm_admins", Command_Admins);
}

public Action:Command_Admins(client, args)
{
    new adminsCount;
    for (new i = 1; i < MaxClients; i++) {
        if (IsClientInGame(i)) {
            new AdminId:admin = GetUserAdmin(i);
            if (admin != INVALID_ADMIN_ID) {
                if (GetAdminFlag(admin, Admin_Generic) &&
                    !GetAdminFlag(admin, Admin_Root)
                ) {
                    adminsCount++;
                }
            }
        }
    }

    if (adminsCount == 0) {
        ReplyToCommand(client, "[SM] %t", "Admins Count Zero");
    }
    else if (adminsCount % 10 == 1 && adminsCount % 100 != 11) {
        ReplyToCommand(client, "[SM] %t", "Admins Count One", adminsCount);
    }
    else if (adminsCount % 10 >= 2 && adminsCount % 10 <= 4 && 
        (adminsCount % 100 < 10 || adminsCount % 100 >= 20)
    ) {
        ReplyToCommand(client, "[SM] %t", "Admins Count Two", adminsCount);
    }
    else {
        ReplyToCommand(client, "[SM] %t", "Admins Count Five", adminsCount);
    }

    return Plugin_Handled;
}
