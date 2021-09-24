Convars.SetValue("asw_skill", 3);
Convars.SetValue("asw_marine_ff_absorption", 0);
Convars.SetValue("asw_horde_override", 1);
Convars.SetValue("asw_wanderer_override", 1);
Convars.SetValue("rd_carnage_scale", 2);

const gs_DataName = "gs_dm_data";
const strDelimiter = ":";

asw_game_resource <- null;
asw_game_resource <- Entities.FindByClassname(asw_game_resource, "asw_game_resource");

bAI <- 1;
bOnslaught <- 1;

alienNamesArray <- [
	"asw_drone",
	"asw_buzzer",
	"asw_parasite",
	"asw_shieldbug",
	"asw_drone_jumper",
	"asw_harvester",
	"asw_parasite_defanged",
	"asw_boomer",
	"asw_ranger",
	"asw_mortarbug",
	"asw_shaman",
	"asw_drone_uber",
	"asw_alien_goo"
];

if (FileToString(gs_DataName) == "") {
	StringToFile(gs_DataName, "1" + strDelimiter + "1"); // AI, Onslaught
}
else {
	local strArrayContent = split(FileToString(gs_DataName), strDelimiter);
	bAI = strArrayContent[0].tointeger();
	bOnslaught = strArrayContent[1].tointeger();
}

function SetBotEmote(hBot, strEmote)
{
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 0.2 + 0.01 * RandomInt(0, 5));
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.hBot <- hBot;
	hTimerScope.strEmote <- strEmote;
	hTimerScope.TimerFunc <- function() {
		NetProps.SetPropInt(hBot, strEmote, 1);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}

function OnGameplayStart()
{
	LoopFunc();
}

function OnTakeDamage_Alive_Any(hVictim, hInflictor, hAttacker, hWeapon, iDamage, damageType, ammoName) 
{
	if (hAttacker != null && hVictim != null) {
		if (hAttacker.IsAlien() && hVictim.GetClassname() == "asw_marine" && !hVictim.IsInhabited()) {
			if (RandomInt(0, 1)) {
				SetBotEmote(hVictim, "bEmoteQuestion");
			}
		}
	}

	if (hVictim != null && hVictim.GetClassname() == "asw_marine" && !hVictim.IsInhabited() &&
		iDamage >= hVictim.GetHealth()) {
		hVictim.RemoveWeapon(0);
		hVictim.RemoveWeapon(1);
		hVictim.RemoveWeapon(2);
	}

	return iDamage;
}

function OnGameEvent_entity_killed(params)
{
	local hVictim = null;
	local hAttacker = null;
	
	if ("entindex_killed" in params) {
		hVictim = EntIndexToHScript(params["entindex_killed"]);
	}
	if ("entindex_attacker" in params) {
		hAttacker = EntIndexToHScript(params["entindex_attacker"]);
	}

	if (!hVictim || !hAttacker) {
		return;
	}

	if (hVictim.GetClassname() == "asw_marine" && hAttacker.GetClassname() == "asw_marine" &&
		!hAttacker.IsInhabited()) {
		local iTemp = RandomInt(0, 3);
		if (iTemp < 2) {
			if (iTemp) {
				SetBotEmote(hAttacker, "bEmoteSmile");
			}
			else {
				SetBotEmote(hAttacker, "bEmoteAnimeSmile");
			}
		}
	}
}

function OnGameEvent_marine_spawn(params)
{
	local hBot = null;
	
	if ("entindex" in params) {
		hBot = EntIndexToHScript(params["entindex"]);
	}
	
	if (hBot.IsInhabited()) {
		return;
	}
	
	hBot.RemoveWeapon(0);
	hBot.GiveWeapon(WeaponSpawner(hBot.GetMarineName()), 0);
	
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 0.1);
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.hBot <- hBot;
	hTimerScope.TimerFunc <- function() {
		hBot.RemoveWeapon(1);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}

function OnGameEvent_player_fullyjoined(params)
{
	if (!bAI) {
		return;
	}
	
	local bShouldAddBots = true;
	local userid = null;
	
	if ("userid" in params) {
		userid = params["userid"];
	}
	else {
		return;
	}
	
	local hMarine = null;
	while ((hMarine = Entities.FindByClassname(hMarine, "asw_marine")) != null) {
		bShouldAddBots = false;
	}
	
	if (bShouldAddBots) {
		for (local i = 1; i <= 8; ++i) {
			SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd " + i + "\"");
		}
		/*for (local i = 1; i <= 8; ++i) {
			SendToServerConsole("rd_botadd " + i);
		}*/
	}
}

function OnGameEvent_player_say(params)
{
	if (!("text" in params) || !("userid" in params)) {
		return;
	}
	else if (params["text"] == null) {
		return;
	}
	
	local userid = params["userid"];
	local strText = params["text"].tolower();
	
	switch (strText) {
		case "&help":
			DisplayMsg("==== List of Leader Chat Commands ====\n&ai  -  Enable / Disable AI Players.\n&alien  -  Enable / Disable Onslaught.");
			return;

		case "&ai":
			if (!IsLeader(userid)) {
				return;
			}
			if (bAI) {
				bAI = 0;
				SendToServerConsole("sm_cexec #" + userid + " rd_bots_kick");
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Disabled AI Players.");
			}
			else {
				bAI = 1;
				for (local i = 1; i <= 8; ++i) {
					SendToServerConsole("sm_cexec #" + userid + " \"rd_botadd " + i + "\"");
				}
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Enabled AI Players.");
			}
			return;

		case "&alien":
			if (!IsLeader(userid)) {
				return;
			}
			if (Convars.GetFloat("asw_horde_override")) {
				bOnslaught = 0;
				Convars.SetValue("asw_horde_override", 0);
				Convars.SetValue("asw_wanderer_override", 0);
				Convars.SetValue("rd_carnage_scale", 1);
				RemoveAliens();
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Disabled Onslaught.");
			}
			else {
				bOnslaught = 1;
				Convars.SetValue("asw_horde_override", 1);
				Convars.SetValue("asw_wanderer_override", 1);
				Convars.SetValue("rd_carnage_scale", 2);
				StringToFile(gs_DataName, bAI.tostring() + strDelimiter + bOnslaught.tostring());
				DisplayMsg("Enabled Onslaught.");
			}
			return;
	}
}

function RemoveAliens()
{
	foreach (strClassname in alienNamesArray) {
		local hAlien = null;
		while ((hAlien = Entities.FindByClassname(hAlien, strClassname)) != null) {
			hAlien.Destroy();
		}
	}
}

function IsLeader(userid)
{
	local player = null;
	while((player = Entities.FindByClassname(player, "player")) != null) {
		if (player.GetPlayerUserID() == userid) {
			if (player != NetProps.GetPropEntity(asw_game_resource, "m_Leader")) {
				DisplayMsg("You are not the leader.", 0);
				return false;
			}
			else {
				return true;
			}
		}
	}
}

function DisplayMsg(message, delay = 0.01)
{
	if (!delay) {
		local player = null;
		while ((player = Entities.FindByClassname(player, "player")) != null)
			ClientPrint(player, 3, message);
		return;
	}
	local timer = Entities.CreateByClassname("logic_timer");
	timer.__KeyValueFromFloat("RefireTime", delay);
	DoEntFire("!self", "Disable", "", 0, null, timer);
	timer.ValidateScriptScope();
	local timerScope = timer.GetScriptScope();
	
	timerScope.message <- message;
	timerScope.TimerFunc <- function() {
		local player = null;
		while ((player = Entities.FindByClassname(player, "player")) != null)
			ClientPrint(player, 3, message);
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	timer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, timer);
}

function WeaponSpawner(marineName)
{
	local weaponNamesArray = [
		"asw_weapon_rifle",
		"asw_weapon_railgun",
		"asw_weapon_pdw",
		"asw_weapon_sniper_rifle",
		"asw_weapon_grenade_launcher",
		"asw_weapon_combat_rifle",
		"asw_weapon_heavy_rifle"
	];

	if (marineName == "Sarge" || marineName == "Jaeger") {
		return weaponNamesArray[RandomInt(0, 6)];
	}
	else if (marineName == "Wildcat" || marineName == "Wolfe") {
		weaponNamesArray.push("asw_weapon_autogun");
		weaponNamesArray.push("asw_weapon_minigun");
		return weaponNamesArray[RandomInt(0, 8)];
	}
	else if (marineName == "Faith" || marineName == "Bastille") {
		weaponNamesArray.push("asw_weapon_medrifle");
		return weaponNamesArray[RandomInt(0, 7)];
	}
	else if (marineName == "Crash" || marineName == "Vegas") {
		weaponNamesArray.push("asw_weapon_prifle");
		return weaponNamesArray[RandomInt(0, 7)];
	}

	return "asw_weapon_rifle";
}

function LoopFunc()
{
	local hTimer = Entities.CreateByClassname("logic_timer");
	hTimer.__KeyValueFromFloat("RefireTime", 1);
	DoEntFire("!self", "Disable", "", 0, null, hTimer);
	hTimer.ValidateScriptScope();
	local hTimerScope = hTimer.GetScriptScope();
	
	hTimerScope.LoopFunc <- LoopFunc;
	hTimerScope.TimerFunc <- function() {
		local hParas = null;
		while ((hParas = Entities.FindByClassname(hParas, "asw_parasite")) != null) {
			hParas.Destroy();
		}

		local hBot = null;
		while ((hBot = Entities.FindByClassname(hBot, "asw_marine")) != null) {
			if (!hBot.IsInhabited()) {
				NetProps.SetPropInt(hBot, "m_ASWOrders", 3);
			}
		}
		
		LoopFunc();
		self.DisconnectOutput("OnTimer", "TimerFunc");
		self.Destroy();
	}
	hTimer.ConnectOutput("OnTimer", "TimerFunc");
	DoEntFire("!self", "Enable", "", 0, null, hTimer);
}
