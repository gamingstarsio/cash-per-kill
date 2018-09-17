


#if defined __allbyte_sql_included
	#endinput
#endif

#define __allbyte_sql_included

#define SQL_VAL_MAX_LENGTH 256
#define SQL_KEYVAL(%1) char %1[64][2][SQL_VAL_MAX_LENGTH]
#define SQL_KEYVAL_ARG SQL_KEYVAL(keyval)
#define SQL_KEYVAL_INIT(%1) SQL_KEYVAL(%1); sql_clear(%1)
#define SQL_QUERY_MAX_LENGTH 1024
#define SQL_QUERY(%1) char %1[SQL_QUERY_MAX_LENGTH]

Database sqldb = null;

stock void sql_cat_raw(char[] query, const char[] value)
{
    StrCat(query,SQL_QUERY_MAX_LENGTH, value);
}

stock void sql_cat_escape(char[] query, const char[] value)
{
    char escaped[SQL_VAL_MAX_LENGTH];
    sqldb.Escape(value, escaped, sizeof(escaped));
    sql_cat_raw(query, escaped);
}

stock void sql_cat_steamid(char[] query, int client)
{
    char tmp[128];
    GetClientAuthId(client, AuthId_Steam2, tmp, sizeof(tmp), true);
    sql_cat_escape(query, tmp);
}


stock void sql_log(const char[] query)
{
    LogMessage("Sql query constructed `%s`", query);
}

stock void sql_insert(char[] query, const char[] tableName, const SQL_KEYVAL_ARG)
{
    char tmp[128];
    Format(tmp, sizeof(tmp), "INSERT INTO `%s` (", tableName);
    sql_cat_raw(query, tmp);

    int keys = 0;

    for (int i=0;i<64;i++)
    {
        if (keyval[i][0][0] != 0)
        {
            if (keys != 0)
            {
                sql_cat_raw(query, ",");
            }

            Format(tmp, sizeof(tmp), "`%s`",keyval[i][0][0] );
            sql_cat_raw(query, tmp);
            keys++;
        }
    }

    sql_cat_raw(query, ") VALUES (");

    int values = 0;

    for (int i=0;i<keys;i++)
    {
        if (values != 0)
        {
            sql_cat_raw(query, ",");
        }

        Format(tmp, sizeof(tmp), "%s",keyval[i][1][0] );
        sql_cat_raw(query, tmp);
        values++;
    }

    sql_cat_raw(query, ")");
    sql_log(query);
}

stock void sql_update(char[] query, const char[] tableName, const SQL_KEYVAL_ARG)
{
    char tmp[128];
    Format(tmp, sizeof(tmp), "UPDATE `%s` SET ", tableName);
    sql_cat_raw(query, tmp);

    int keys = 0;

    for (int i=0;i<64;i++)
    {
        if (keyval[i][0][0] != 0)
        {
            if (keys != 0)
            {
                sql_cat_raw(query, ",");
            }

            Format(tmp, sizeof(tmp), "`%s`=",keyval[i][0][0] );
            sql_cat_raw(query, tmp);

            Format(tmp, sizeof(tmp), "%s",keyval[i][1][0] );
            sql_cat_raw(query, tmp);
            keys++;
        }
    }

    sql_cat_raw(query, " ");
}

stock void sql_where(char[] query, const SQL_KEYVAL_ARG)
{
    char tmp[128];
    int keys = 0;
    sql_cat_raw(query, " WHERE ");
    for (int i=0;i<64;i++)
    {
        if (keyval[i][0][0] != 0)
        {
            if (keys != 0)
            {
                sql_cat_raw(query, " AND ");
            }

            Format(tmp, sizeof(tmp), "`%s`=",keyval[i][0][0] );
            sql_cat_raw(query, tmp);

            Format(tmp, sizeof(tmp), "%s",keyval[i][1][0] );
            sql_cat_raw(query, tmp);
            keys++;
        }
    }
}

stock void sql_clear(SQL_KEYVAL_ARG)
{
    for (int i=0;i<64;i++)
    {
        keyval[i][0][0] = 0;
        keyval[i][1][0] = 0;
    }
}

stock int sql_find_empty(const SQL_KEYVAL_ARG)
{
    for (int i=0;i<64;i++)
    {
        if (keyval[i][0][0] == 0)
        {
            return i;
        }
    }
    return -1;
}

stock void sql_set(const char[] field, const char [] value, SQL_KEYVAL_ARG)
{
    int idx = sql_find_empty(keyval);
    strcopy(keyval[idx][0], SQL_VAL_MAX_LENGTH,field);
    strcopy(keyval[idx][1], SQL_VAL_MAX_LENGTH, value);
}

stock void sql_set_str(const char[] field, const char[] value, SQL_KEYVAL_ARG)
{
    char escaped[SQL_VAL_MAX_LENGTH];
    sqldb.Escape(value, escaped, sizeof(escaped));

    char tmp[SQL_VAL_MAX_LENGTH];
    Format(tmp, sizeof(tmp), "\"%s\"", escaped);
    sql_set(field, tmp,keyval );
}

stock void sql_set_steamid(const char[] field, int client, SQL_KEYVAL_ARG)
{
    char tmp[128];
    GetClientAuthId(client, AuthId_Steam2, tmp, sizeof(tmp), true);
    sql_set_str(field, tmp,keyval );
}

stock void sql_set_steamid64(const char[] field, int client, SQL_KEYVAL_ARG)
{
    char tmp[128];
    GetClientAuthId(client, AuthId_SteamID64, tmp, sizeof(tmp), true);
    sql_set_str(field, tmp,keyval );
}

stock void sql_set_name(const char[] field, int client, SQL_KEYVAL_ARG)
{
    char tmp[128];
    GetClientName(client, tmp, 128);
    sql_set_str(field, tmp,keyval );
}

stock void sql_set_int(const char[] field, int value, SQL_KEYVAL_ARG)
{
    char tmp[32];
    IntToString(value, tmp, sizeof(tmp));
    sql_set(field, tmp, keyval);
}

stock void sql_set_float(const char[] field, float value, SQL_KEYVAL_ARG)
{
    char tmp[32];
    FloatToString(value, tmp, sizeof(tmp));
    sql_set(field, tmp, keyval);
}

stock void sql_set_date_now(const char[] field, SQL_KEYVAL_ARG)
{
    sql_set(field, "NOW()", keyval);
}
