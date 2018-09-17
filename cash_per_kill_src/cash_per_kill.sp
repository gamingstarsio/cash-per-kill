
#pragma semicolon 1

#pragma dynamic 131072

#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include "tools/allbyte_sql.inc"
#include "tools/cashpk_version.inc"



public Plugin:myinfo = {
    name = "Cash per kill gamemode",
    author = "Allbyte Ltd.",
    description = "",
    version = PLUGIN_VERSION,
    url = "http://www.allbyte.co.uk/"
};

#define DATABASE_CONFIG_NAME "default"

ConVar g_KillAward;

public Action:Command_Balance(client, args)
{
    CPK_GetBalance(client);
    return Plugin_Handled;
}


bool string_StartsWith(char[] haystack, char[] needle)
{
    int index = StrContains(haystack,needle,false);
    return index == 0;
}

public Action CPK_Command_Say(int client, const char[] command, int argc)
{
    if (IsChatTrigger()) return Plugin_Continue;

    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    if (string_StartsWith(text, "!balance"))
    {
        Command_Balance(client,0);

        return Plugin_Continue;
    }

    return Plugin_Continue;
}


public void sql_onConnect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("Database failure: %s", error);
    }
    else
    {
        LogMessage("Connected to `%s` database", DATABASE_CONFIG_NAME);
        sqldb = db;
    }
}

public void sql_connect()
{
    LogMessage("Connecting to `%s` database", DATABASE_CONFIG_NAME);
    Database.Connect(sql_onConnect, DATABASE_CONFIG_NAME);
}

public void CPK_UpdateBalance(int client, int amount)
{
    char tmp[128];
    IntToString(amount, tmp, sizeof(tmp));

    SQL_QUERY(updateQuery);

    sql_cat_raw(updateQuery,"UPDATE player SET balance=balance + ");
    sql_cat_raw(updateQuery,tmp);
    sql_cat_raw(updateQuery," WHERE steam_id=");
    GetClientAuthId(client, AuthId_SteamID64, tmp, sizeof(tmp), true);
    sql_cat_raw(updateQuery, tmp );
    sql_cat_raw(updateQuery,";");
    sql_log(updateQuery);
    sqldb.Query(sql_OnUpdateBalance, updateQuery, client );
}

public void CPK_GetBalance(int client)
{
    char tmp[128];
    SQL_QUERY(selectQuery);
    sql_cat_raw(selectQuery,"SELECT * FROM player WHERE steam_id=");
    GetClientAuthId(client, AuthId_SteamID64, tmp, sizeof(tmp), true);
    sql_cat_raw(selectQuery,tmp);
    sql_cat_raw(selectQuery,";");
    sql_log(selectQuery);
    sqldb.Query(sql_OnGetBalance, selectQuery, client);
}

public void CPK_SqlInsertPlayer(int client)
{
    SQL_QUERY(insertQuery);
    SQL_KEYVAL_INIT(keyval);

    sql_set_steamid64("steam_id", client, keyval);
    sql_set_name("name", client, keyval);
    sql_set_int("balance", 0, keyval);
    //sql_set_date_now("first_seen", keyval);

    sql_insert(insertQuery, "player", keyval);
    sql_log(insertQuery);
    sqldb.Query(sql_OnInsertPlayer, insertQuery, client );
}

public void sql_OnGetBalance(Database db, DBResultSet results, const char[] error, any id)
{
    if (results == null)
    {
        LogError("Query failed! %s", error);
        return;
    }

    if (results.RowCount == 0)
    {
        LogMessage("Player not available in database (0 rows)");
    }
    else
    {
        int balance_col = -1;

        results.FieldNameToNum("balance", balance_col);

        while (results.FetchRow())
        {
            int balance = results.FetchInt(balance_col);
            PrintToChatAll(" \x0B%N\x01 has balance of \x04%i\x01", id, balance);
            LogMessage("Player %N has balance of %i", id, balance);
        }
    }
}

public void sql_OnUpdateBalance(Database db, DBResultSet results, const char[] error, any id)
{
    if (results == null)
    {
        LogError("Query failed! %s", error);
        return;
    }

    int rows = results.AffectedRows;
    LogMessage("Player balance '%N' updated (%i rows affected)",id,  rows);
    CPK_GetBalance(id);
}


public void sql_OnInsertPlayer(Database db, DBResultSet results, const char[] error, any id)
{
    if (results == null)
    {
        LogError("Query failed! %s", error);
        return;
    }

    int rows = results.AffectedRows;
    LogMessage("New player '%N' added (%i rows affected)", id, rows);
}

stock bool:IsValidClient(client, bool:nobots = true)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false;
    }
    return IsClientInGame(client);
}

public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int userid = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    if (IsValidClient(attacker) && !IsFakeClient(attacker) && userid != attacker)
    {
        // TODO: make sure players dont receive money when they kill bots
        CPK_UpdateBalance(attacker, g_KillAward.IntValue);
        if (!IsFakeClient(userid))
        {
            
            CPK_UpdateBalance(userid, -g_KillAward.IntValue);
        }
    }

    return Plugin_Continue;
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (IsFakeClient(client))
    {
        return;
    }
    // TODO: check if player exist in database first, insert if not
    CPK_SqlInsertPlayer(client);
}

public OnPluginStart()
{
    g_KillAward  = CreateConVar("kill_award", "1.0", "Amount of award that will be given when player kills another enemy.", FCVAR_ARCHIVE | FCVAR_REPLICATED | FCVAR_NOTIFY);
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
    AddCommandListener(CPK_Command_Say,"say");
    RegConsoleCmd("get_balance", Command_Balance);
    sql_connect();
}
