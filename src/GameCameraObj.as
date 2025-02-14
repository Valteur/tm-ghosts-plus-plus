// does not override mediatracker
const uint16 O_GAMECAM_ACTIVE_CAM_TYPE = 0x188;
// 0x24: c1, 0x25: c2, 0x26: c3
const uint16 O_GAMECAM_USE_ALT = 0x24;
const uint16 O_APP_GAMECAM = GetOffset("CGameCtnApp", "GameScene") + 0x10;

class GameCamera {
    GameCamera() {}

    protected CMwNod@ GetSelf() {
        return Dev::GetOffsetNod(GetApp(), O_APP_GAMECAM);
    }

    uint get_ActiveCam() {
        auto gc = GetSelf();
        if (gc is null) return uint(-1);
        auto ac = Dev::GetOffsetUint32(gc, O_GAMECAM_ACTIVE_CAM_TYPE);
        if (0 < ac && ac < 0x2E) return ac;
        warn_every_60_s("Active cam value on GameCamera struct seems wrong: " + Text::Format("0x%08x", ac));
        return uint(-1);
    }

    // does not override mediatracker, works for spectators
    void set_ActiveCam(uint value) {
        if (value < 0x12 || 0x15 < value) throw("Invalid active cam: range is 0x12 - 0x14 inclusive");
        auto gc = GetSelf();
        if (gc is null) return;
        auto ac = Dev::GetOffsetUint32(gc, O_GAMECAM_ACTIVE_CAM_TYPE);
        // check the value looks right
        if (0 < ac && ac < 0x2E) {
            Dev::SetOffset(gc, O_GAMECAM_ACTIVE_CAM_TYPE, value);
        } else {
            warn_every_60_s("Active cam value on GameCamera struct seems wrong: " + Text::Format("0x%08x", ac));
        }
    }

    void set_AltCam(bool alt) {
        _SetAltCam(alt, Math::Clamp(ActiveCam - 0x11, 1, 3));
    }

    // set alt status on cam 1, 2, or 3 -- 0 will set on all
    void _SetAltCam(bool alt, int cam123) {
        if (cam123 < 0 || cam123 > 3) throw('out of range');
        if (cam123 == 0) {
            _SetAltCam(alt, 1);
            _SetAltCam(alt, 2);
            _SetAltCam(alt, 3);
            return;
        }
        auto gc = GetSelf();
        if (gc is null) return;
        auto offset = O_GAMECAM_USE_ALT + cam123 - 1;
        auto _alt = Dev::GetOffsetUint8(gc, offset);
        if (_alt > 2) {
            warn_every_60_s("Alt cam value on GameCamera struct seems wrong: " + Text::Format("0x%02x", _alt));
        } else {
            Dev::SetOffset(gc, offset, uint8(alt ? 0x2 : 0x1));
        }
    }

    // void SetOffset(uint16 offset, uint value) {
    //     auto gc = GetSelf();
    //     if (gc is null) return;
    //     Dev::SetOffset(gc, offset, value);
    // }
}


dictionary warnTracker;
void warn_every_60_s(const string &in msg) {
    if (warnTracker is null) return;
    if (warnTracker.Exists(msg)) {
        uint lastWarn = uint(warnTracker[msg]);
        if (Time::Now - lastWarn < 60000) return;
    } else {
        NotifyWarning(msg);
    }
    warnTracker[msg] = Time::Now;
    warn(msg);
}

// We need to set this false to make free cam work properly in forced spectate mode
void SetDrivableCamFlag(CGameTerminal@ gt, bool canDrive) {
    if (gt is null) return;
    Dev::SetOffset(gt, GetOffset(gt, "GUIPlayer") + 0x40, canDrive ? 0x0 : 0x1);
}

// void SetAltCamFlag(CGameTerminal@ gt, bool isAlt) {
//     if (gt is null) return;
//     Dev::SetOffset(gt, GetOffset(gt, "GUIPlayer") + 0x10, isAlt ? 0x0 : 0x1);
// }
