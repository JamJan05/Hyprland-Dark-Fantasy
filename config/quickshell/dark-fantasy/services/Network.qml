pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
// Quickshell's scanner stops reading the header at the first line
// containing "{", without stripping comments first - a brace
// in a comment would disable singleton registration. Details
// in services/Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  NETWORK - A SINGLE SOURCE OF WI-FI STATE.
//
//  The backend is NetworkManager via Quickshell.Networking. The module itself
//  says in its documentation that the only supported backend is
//  NetworkManager's D-Bus interface - and that one runs on your system anyway,
//  because the current "network" module on the bar uses it.
//
//  ---------------------------------------------------------------
//  WE DO NOT STORE PASSWORDS
//
//  A requirement from the brief, and that is also how the API works: connectWithPsk() passes
//  the password to NetworkManager, which stores it in its own credential
//  store. The shell does not keep it anywhere - not in a file, not
//  in memory any longer than the call lasts, not in a log.
//
//  ---------------------------------------------------------------
//  NOT EVERY NETWORK CAN BE JOINED WITH A PASSWORD
//
//  connectWithPsk() accepts ONLY WpaPsk, Wpa2Psk and Sae.
//  Checked in the sources (wifi.cpp): with any other security type
//  the function does nothing and prints a critical error to the log.
//
//  Enterprise networks (Wpa2Eap, WpaEap, Leap, DynamicWep...) require
//  certificates, an identity and a choice of EAP method - i.e. the full
//  NetworkManager form. The panel does not try to configure such networks;
//  it points to nmtui.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // The first Wi-Fi device. The laptop has one; with several cards
    // the first one wins, just as with the backlight the first
    // "backlight"-class device wins.
    readonly property var device: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) return d;
        }
        return null;
    }

    readonly property bool available: device !== null

    // Software Wi-Fi switch.
    readonly property bool enabled: Networking.wifiEnabled

    // Hardware one - the switch on the chassis or rfkill. When it is
    // off, the software one changes nothing, so the toggle in the panel
    // has to be disabled then, rather than letting you click into the void.
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled

    // The network we are connected to.
    readonly property var current: {
        if (device === null) return null;
        for (const s of device.networks.values) {
            if (s.connected) return s;
        }
        return null;
    }

    readonly property bool connected: current !== null

    // Network list: the connected one at the top, then saved ones, then the rest
    // by signal strength. Networks without a name (hidden SSID) are skipped - they cannot
    // be joined with a single click, and they would clutter the list.
    readonly property var networks: {
        if (device === null) return [];
        const lista = [];
        for (const s of device.networks.values) {
            if (s.name === "") continue;
            lista.push(s);
        }
        lista.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return lista;
    }

    // Whether this network can be joined with just a password.
    function pskMozliwe(siec): bool {
        if (siec === null) return false;
        return siec.security === WifiSecurityType.WpaPsk
            || siec.security === WifiSecurityType.Wpa2Psk
            || siec.security === WifiSecurityType.Sae;
    }

    // Open network - we connect without asking for anything.
    function otwarta(siec): bool {
        if (siec === null) return false;
        return siec.security === WifiSecurityType.Open
            || siec.security === WifiSecurityType.Owe;
    }

    // A network the panel cannot configure (enterprise, EAP).
    function wymagaMenedzera(siec): bool {
        if (siec === null) return false;
        if (siec.known) return false;
        return !pskMozliwe(siec) && !otwarta(siec);
    }

    // Short security description for the row subtitle.
    function opisZabezpieczen(siec): string {
        if (siec === null) return "";
        switch (siec.security) {
            case WifiSecurityType.Open:          return Tr.t("open", "otwarta");
            case WifiSecurityType.Owe:           return Tr.t("open (encrypted)", "otwarta (szyfrowana)");
            case WifiSecurityType.Sae:           return "WPA3";
            case WifiSecurityType.Wpa2Psk:       return "WPA2";
            case WifiSecurityType.WpaPsk:        return "WPA";
            case WifiSecurityType.Wpa3SuiteB192: return "WPA3 Enterprise";
            case WifiSecurityType.Wpa2Eap:       return "WPA2 Enterprise";
            case WifiSecurityType.WpaEap:        return "WPA Enterprise";
            case WifiSecurityType.StaticWep:
            case WifiSecurityType.DynamicWep:    return "WEP";
            case WifiSecurityType.Leap:          return "LEAP";
        }
        return "";
    }

    // ---------------------------------------------------------------
    //  ACTIONS
    // ---------------------------------------------------------------
    function setEnabled(wlaczone: bool) {
        if (!hardwareEnabled) return;
        Networking.wifiEnabled = wlaczone;
    }

    // Scanning runs only while the panel is open. NetworkManager
    // refreshes the list every now and then anyway; this forces more frequent
    // polling, so there is no reason to keep it on
    // when nobody is looking at the list.
    function setScanning(wlaczone: bool) {
        if (device === null) return;
        device.scannerEnabled = wlaczone;
    }

    // A saved network connects without asking - NetworkManager already has
    // its password. An open one too, because there is nothing to ask for.
    function connect(siec) {
        if (siec === null) return;
        siec.connect();
    }

    function connectWithPsk(siec, haslo: string) {
        if (siec === null || !pskMozliwe(siec)) return;
        siec.connectWithPsk(haslo);
    }

    function disconnect(siec) {
        if (siec === null) return;
        siec.disconnect();
    }

    // Forgetting a network deletes its saved password in NetworkManager.
    function forget(siec) {
        if (siec === null) return;
        siec.forget();
    }
}
