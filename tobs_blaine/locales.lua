Locales = {
    en = {
        start_heist = "Start bank heist",
        loot = "Loot the cash",
        unlock_door = "Unlock the door",
        lock_door = "Lock the door",
        using_card = "Using malicious card",
        hacking = "Hack in progress",
        hack_done = "Hacking complete!",
        hack_failed = "Hack failed! The alarm is still going off.",
        security_timer = "You have %s until the security system activates.",
        vault_closing_soon = "The vault door closes in %d seconds!",
        vault_closing = "Vault door closing!",
        police_alert = "A bank's alarms are triggered!",
        no_cops = "There is not enough police in the city.",
        no_card = "You don't have a malicious access card.",
        busy = "This bank is currently being robbed.",
        cooldown = "This bank was robbed recently. You need to wait %s.",
    },
    da = {
        start_heist = "Start bankrøveri",
        loot = "Tag pengene",
        unlock_door = "Lås døren op",
        lock_door = "Lås døren",
        using_card = "Bruger idkort",
        hacking = "Hacker...",
        hack_done = "Hacking udført!",
        hack_failed = "Hacking mislykkedes! Alarmen er stadig i gang.",
        security_timer = "Du har %s til sikkerhedssystemet aktiveres.",
        vault_closing_soon = "Bankboksen lukker om %d sekunder!",
        vault_closing = "Bankboksen lukker!",
        police_alert = "En alarm i banken er blevet udløst!",
        no_cops = "Der er ikke nok politi i byen.",
        no_card = "Du har ikke et idkort.",
        busy = "Der er et røveri i gang i banken.",
        cooldown = "Denne bank er for nylig blevet røvet. Du skal vente %s.",
    },
}

-- Returns the text for key in the language set by TOB.Locale, falling back to English
function L(key, ...)
    local text = (Locales[TOB.Locale] or Locales.en)[key] or Locales.en[key] or key
    if select("#", ...) > 0 then
        return text:format(...)
    end
    return text
end
