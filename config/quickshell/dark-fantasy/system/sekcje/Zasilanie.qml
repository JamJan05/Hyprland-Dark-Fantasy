// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  POWER - power profile, charge limit and battery state.
//
//  Backend unchanged from the former PowerSection.qml section: profile from
//  power-profiles-daemon over D-Bus (PowerProfiles), battery from UPower -
//  only UPower knows the time until discharge.
//
//  The "performance" profile is listed only when the hardware reports it;
//  an entry that does nothing would be a lie. The same profile is toggled by
//  SUPER+B (shell.qml).
//
//  The charge limit is written by services/Ladowanie.qml via the
//  local/bin/limit-ladowania script. The row shows only for a battery
//  with charge_control_* files in sysfs (on a ThinkPad: thinkpad_acpi).
//
//  The CPU power limit - one slider per profile - is applied by
//  services/LimitMocy.qml. The rows show once its script has answered;
//  with the script installed but not working, an error line says what is missing.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    readonly property var bateria: UPower.displayDevice

    // On a desktop PC UPower returns a placeholder device - we don't show that.
    readonly property bool maBaterie:
        bateria !== null && bateria.isLaptopBattery && bateria.isPresent

    readonly property var profile: {
        const l = [
            { kod: PowerProfile.PowerSaver, nazwa: Tr.t("power saver", "oszczędny") },
            { kod: PowerProfile.Balanced,   nazwa: Tr.t("balanced", "zrównoważony") }
        ];
        if (PowerProfiles.hasPerformanceProfile)
            l.push({ kod: PowerProfile.Performance, nazwa: Tr.t("performance", "wydajność") });
        return l;
    }

    function czas(sekundy: real): string {
        const minuty = Math.round(sekundy / 60);
        const h = Math.floor(minuty / 60);
        return h <= 0 ? minuty % 60 + " min" : h + " h " + minuty % 60 + " min";
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Power profile", "Profil zasilania")
        typ: "wybor"
        opcje: root.profile
        indeks: Math.max(0, root.profile.findIndex(p => p.kod === PowerProfiles.profile))
        onZmieniono: function (i) { PowerProfiles.profile = root.profile[i].kod; }
    }

    // Thresholds are read on every section open - sysfs does not report changes.
    Component.onCompleted: Ladowanie.odswiez()

    WierszOpcji {
        width: root.width
        visible: LimitMocy.obslugiwany
        etykieta: Tr.t("CPU power limit", "Limit mocy procesora")
        typ: "info"
        tekst: Math.round(LimitMocy.obecny) + " W"
            + Tr.t(" (factory ", " (fabrycznie ") + Math.round(LimitMocy.fabryczny) + " W)"
    }

    // One step above LimitMocy.maksimum = the factory limit of that profile.
    Repeater {
        model: LimitMocy.obslugiwany ? root.profile : []

        delegate: WierszOpcji {
            required property var modelData

            width: root.width
            etykieta: Tr.t("Limit: ", "Limit: ") + modelData.nazwa
            typ: "suwak"; od: 5; doo: LimitMocy.maksimum + 1; krok: 1
            wartosc: {
                const w = UstawieniaPowloki.limitMocy(modelData.kod);
                return w > 0 ? Math.min(w, LimitMocy.maksimum) : LimitMocy.maksimum + 1;
            }
            formatuj: v => Math.round(v) > LimitMocy.maksimum
                ? Tr.t("factory", "fabryczny") : Math.round(v) + " W"
            onZmieniono: function (v) {
                const w = Math.round(v);
                UstawieniaPowloki.ustawLimitMocy(modelData.kod, w > LimitMocy.maksimum ? 0 : w);
            }
        }
    }

    Label {
        width: root.width
        visible: LimitMocy.zainstalowany && LimitMocy.blad !== ""
        leftPadding: Theme.spacingMd
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.ember
        text: LimitMocy.blad
    }

    WierszOpcji {
        width: root.width
        visible: Ladowanie.obslugiwany
        etykieta: Tr.t("Charge limit", "Limit ładowania")
        typ: "suwak"; od: 50; doo: 100; krok: 5
        dostepny: !Ladowanie.zapisuje
        wartosc: Ladowanie.limit
        formatuj: v => Math.round(v) + " %"
        onZmieniono: function (v) { Ladowanie.ustaw(v); }
    }

    WierszOpcji {
        width: root.width
        visible: Ladowanie.obslugiwany && Ladowanie.start >= 0
        etykieta: Tr.t("Resume charging", "Wznowienie ładowania")
        typ: "info"
        tekst: Tr.t("below ", "poniżej ") + (Ladowanie.roboczy >= 0 ? Ladowanie.roboczy - 5 : Ladowanie.start) + " %"
    }

    WierszOpcji {
        width: root.width
        visible: root.maBaterie
        etykieta: Tr.t("Battery", "Bateria")
        typ: "info"
        tekst: root.maBaterie ? Math.round(root.bateria.percentage * 100) + " %" : ""
    }

    WierszOpcji {
        width: root.width
        visible: root.maBaterie
        etykieta: Tr.t("State", "Stan")
        typ: "info"
        tekst: {
            if (!root.maBaterie) return "";
            const s = root.bateria.state;
            if (s === UPowerDeviceState.FullyCharged || s === UPowerDeviceState.PendingCharge)
                return Tr.t("plugged in", "z gniazdka");
            if (s === UPowerDeviceState.Charging)
                return root.bateria.timeToFull > 0
                    ? Tr.t("full in ", "do pełna ") + root.czas(root.bateria.timeToFull)
                    : Tr.t("charging", "ładowanie");
            return root.bateria.timeToEmpty > 0
                ? (Tr.pl ? "zostało " + root.czas(root.bateria.timeToEmpty)
                         : root.czas(root.bateria.timeToEmpty) + " left")
                : Tr.t("on battery", "na baterii");
        }
    }

    // Write status or a hint about the udev rule. Ember only on error.
    Label {
        width: root.width
        visible: Ladowanie.obslugiwany
        topPadding: Theme.spacingMd
        leftPadding: Theme.spacingMd
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        font.pixelSize: Theme.fontSizeSmall
        color: Ladowanie.blad !== "" ? Theme.ember : Theme.textMuted
        text: Ladowanie.zapisuje ? Tr.t("Saving charge limit…", "Zapisuję limit ładowania…")
            : Ladowanie.blad !== "" ? Ladowanie.blad
            : Ladowanie.zapisywalny
                ? Tr.t("Charging will stop at the limit and resume 5 points lower.",
                       "Ładowanie zatrzyma się na limicie i ruszy znowu 5 punktów niżej.")
                : Tr.t("Without the udev rule every limit change asks for the administrator password "
                       + "(README: “Power profile and charge limit”).",
                       "Bez reguły udev każda zmiana limitu pyta o hasło administratora "
                       + "(README: „Profil zasilania i limit ładowania”).")
    }
}
