#if defined _jm_stocks_included
 #endinput
#endif
#define _jm_stocks_included

stock bool:IsValidClient(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool:IsAdmin(client, AdminFlag:flag = Admin_Generic)
{
    new AdminId:admin = GetUserAdmin(client);

    if (admin != INVALID_ADMIN_ID) {
        return GetAdminFlag(admin, flag);
    }
            
    return false;
}

stock Float:ZERO_VECTOR[3] = {0.0, 0.0, 0.0};

stock bool:IsZeroVector(const Float:vector[3])
{
    return vector[0] == 0.0 && vector[1] == 0.0 && vector[2] == 0.0;
}

stock DestroyClientProjectiles(client)
{
    new offset;
    new ent = -1;
    while ((ent = FindEntityByClassname(ent, "tf_projectile_*")) != -1) {
        // destroy rockets, arrows, bolts, etc
        offset = FindDataMapOffs(ent, "m_hOwnerEntity");
        if (offset != -1 && GetEntDataEnt2(ent, offset) == client) {
            AcceptEntityInput(ent, "Kill");
            continue;
        }
        
        // destroy pipes, stickies and other throwables
        offset = FindDataMapOffs(ent, "m_hThrower");
        if (offset != -1 && GetEntDataEnt2(ent, offset) == client) {
            AcceptEntityInput(ent, "Kill");
        }
    }
}
