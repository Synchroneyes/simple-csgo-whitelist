#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Synchroneyes"
#define PLUGIN_VERSION "0.00"

#define ADMFLAG_RESERVATION			(1<<0)		/**< Convenience macro for Admin_Reservation as a FlagBit */
#define ADMFLAG_GENERIC				(1<<1)		/**< Convenience macro for Admin_Generic as a FlagBit */
#define ADMFLAG_KICK				(1<<2)		/**< Convenience macro for Admin_Kick as a FlagBit */
#define ADMFLAG_BAN					(1<<3)		/**< Convenience macro for Admin_Ban as a FlagBit */
#define ADMFLAG_UNBAN				(1<<4)		/**< Convenience macro for Admin_Unban as a FlagBit */
#define ADMFLAG_SLAY				(1<<5)		/**< Convenience macro for Admin_Slay as a FlagBit */
#define ADMFLAG_CHANGEMAP			(1<<6)		/**< Convenience macro for Admin_Changemap as a FlagBit */
#define ADMFLAG_CONVARS				(1<<7)		/**< Convenience macro for Admin_Convars as a FlagBit */
#define ADMFLAG_CONFIG				(1<<8)		/**< Convenience macro for Admin_Config as a FlagBit */
#define ADMFLAG_CHAT				(1<<9)		/**< Convenience macro for Admin_Chat as a FlagBit */
#define ADMFLAG_VOTE				(1<<10)		/**< Convenience macro for Admin_Vote as a FlagBit */
#define ADMFLAG_PASSWORD			(1<<11)		/**< Convenience macro for Admin_Password as a FlagBit */
#define ADMFLAG_RCON				(1<<12)		/**< Convenience macro for Admin_RCON as a FlagBit */
#define ADMFLAG_CHEATS				(1<<13)		/**< Convenience macro for Admin_Cheats as a FlagBit */
#define ADMFLAG_ROOT				(1<<14)		/**< Convenience macro for Admin_Root as a FlagBit */
#define ADMFLAG_CUSTOM1				(1<<15)		/**< Convenience macro for Admin_Custom1 as a FlagBit */
#define ADMFLAG_CUSTOM2				(1<<16)		/**< Convenience macro for Admin_Custom2 as a FlagBit */
#define ADMFLAG_CUSTOM3				(1<<17)		/**< Convenience macro for Admin_Custom3 as a FlagBit */
#define ADMFLAG_CUSTOM4				(1<<18)		/**< Convenience macro for Admin_Custom4 as a FlagBit */
#define ADMFLAG_CUSTOM5				(1<<19)		/**< Convenience macro for Admin_Custom5 as a FlagBit */
#define ADMFLAG_CUSTOM6				(1<<20)		/**< Convenience macro for Admin_Custom6 as a FlagBit */


#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

char lastConnected[32];

public Plugin myinfo = 
{
	name = "Server whitelister",
	author = PLUGIN_AUTHOR,
	description = "Ce plugin permet d'instaurer une whitelist sur un serveur.",
	version = PLUGIN_VERSION,
	url = "https://monvoisin-kevin.fr"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	HookEvent("player_connect_full", Event_FullConnect);
	
	RegAdminCmd("sm_whitelist_add", handleWhitelistCommand, ADMFLAG_ROOT, "Permet de whitelister un joueur");
}


public Action handleWhitelistCommand(int client, int args){

    char full[256];
    
    char err_no_last[] = "Personne ne s'est connecté dans le passé. Argument last invalide";
    char err_invalid_arg[] = "Erreur: utilisation invalide, il faut préciser un argument: last ou STEAM_ID";
    
    char user_saved[] = "Utilisateur whitelisté avec succès.";
    char err_user_saved[] = "Erreur lors de l'ajout à la whitelist";
 
    GetCmdArgString(full, sizeof(full));
    if(args != 1) {
    	if (client == 0) PrintToServer(err_invalid_arg);
    	else PrintToChat(client, err_invalid_arg);
   		return Plugin_Handled;
  	}
    
    
    char user[32];
    
    if (strcmp(full[0], "last", false) == 0) {
    	
    	if(strlen(lastConnected) < 1) {
    		if (client == 0) PrintToServer(err_no_last);
    		else PrintToChat(client, err_no_last);
    		return Plugin_Handled;
   		}
   		strcopy(user, sizeof(user), lastConnected);
   		strcopy(lastConnected, sizeof(lastConnected), "");
   	} else {
   		strcopy(user, sizeof(user), full[0]);
  	}
  	
  	if(whitelist(user) == 0) {
  		if (client == 0) PrintToServer(user_saved);
		else PrintToChat(client, user_saved);
  	}else{
  		if (client == 0) PrintToServer(err_user_saved);
		else PrintToChat(client, err_user_saved);
  	}
    
    return Plugin_Handled;
}


public int whitelist(char[] steamid){
	char error[255];
	Handle db;
	db = SQL_Connect("whitelist", true, error, sizeof(error));
	
	Handle preparedQ = SQL_PrepareQuery(db, "INSERT INTO whitelist SET steamid = ?, username = ?, allowed = true", error, sizeof(error));
	if(preparedQ == null) {
		PrintToServer("[ERREUR_DB] Erreur requête préparé %s\n", error);
		strcopy(lastConnected, sizeof(lastConnected), steamid);
		return 1;
	}
	
	SQL_BindParamString(preparedQ, 0, steamid, true);
	SQL_BindParamString(preparedQ, 1, "", true);
	
	SQL_Execute(preparedQ);
	return 0;
	
	
}


public Action Event_FullConnect(Event event, char[] name, bool dontBroadcast) {
	

	int clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	// récupération du steamId
	char steamid[32];
	GetClientAuthId(clientId, AuthId_Steam2, steamid, sizeof(steamid));
	
	
	char not_whitelisted[] = "Vous n êtes pas autorisé à rejoindre ce serveur. Raison: vous n êtes pas whitelisté";
	char add_to_whitelist[] = "Un utilisateur a tenté de se connecté mais n'est pas whitelisté. pour l'ajouter faites: sm_whitelist_add last";
	
	// Vérification si whitelisté ou non
	/*
		CREATE TABLE `whitelist` (
		`id` INT NOT NULL AUTO_INCREMENT,
		`steamid` VARCHAR(30),
		`username` VARCHAR(255),
		`allowed` BOOLEAN,
		`allowed_since` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`)
		);
	*/
	
	char error[255];
	Handle db;
	db = SQL_Connect("whitelist", true, error, sizeof(error));
	
	if(strlen(error) > 1) {
		PrintToServer("[ERREUR_DB] %s\n", error);
		return Plugin_Error;
	}
	
	Handle preparedQ = SQL_PrepareQuery(db, "SELECT allowed FROM whitelist WHERE steamid = ?", error, sizeof(error));
	if(preparedQ == null) {
		PrintToServer("[ERREUR_DB] Erreur requête préparé %s\n", error);
		strcopy(lastConnected, sizeof(lastConnected), steamid);
		return Plugin_Error;
	}
	
	SQL_BindParamString(preparedQ, 0, steamid, true);
	if(!SQL_Execute(preparedQ)) {
		PrintToServer("[ERREUR_DB_EXECUTE] Erreur ! %s", error);
		return Plugin_Error;
	}
	
	
	if(SQL_GetRowCount(preparedQ) == 0) {
		KickClient(clientId, not_whitelisted);
		strcopy(lastConnected, sizeof(lastConnected), steamid);
		PrintToServer(add_to_whitelist);
		return Plugin_Handled;
	}
	
	while(SQL_FetchRow(preparedQ)) {
		
		if(SQL_FetchInt(preparedQ, 0) == 0) {
			KickClient(clientId, not_whitelisted);
			strcopy(lastConnected, sizeof(lastConnected), steamid);
			PrintToServer(add_to_whitelist);
			return Plugin_Handled;

		}

		return Plugin_Handled;
	
	}
	
	return Plugin_Handled;
	
	
	
}
