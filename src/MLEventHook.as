class ResetHook : MLHook::HookMLEventsByType {
    ResetHook() {
        super("RaceMenuEvent_NextMap");
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        if (scrubberMgr !is null) {
            scrubberMgr.ResetAll();
        }
    }
}

class ToggleHook : MLHook::HookMLEventsByType {
    ToggleHook() {
        super("TMGame_Record_ToggleGhost");
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        if (event.type.EndsWith("PB")) {
            OnTogglePB();
        } else {
            OnToggleGhost(event.data[0]);
        }
    }

    void OnTogglePB() {

    }
    void OnToggleGhost(const string &in wsid) {
        // we want to find the fastest ghost with this WSID so we can remove all instances of it

    }

    /**
     * research re finding ghost offset
     * from CPlugEntRecordData (0x911f000): 0x40,0x10
     *
     */
}

class SpectateHook : MLHook::HookMLEventsByType {
    SpectateHook() {
        super("TMGame_Record_Spectate");
    }

    void OnEvent(MLHook::PendingEvent@ event) override {
        startnew(CoroutineFuncUserdata(this.AfterSpectate), event);
    }

    uint lastLoadSpectate = Time::Now;
    string lastLoadWsid = "";
    void AfterSpectate(ref@ r) {
        auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        if (ps is null) return;

        auto mgr = GhostClipsMgr::Get(GetApp());
        auto nbGhosts = mgr.Ghosts.Length;

        auto event = cast<MLHook::PendingEvent>(r);
        if (event.data.Length < 1) return;
        string wsid = event.data[0];
        if (wsid.Length != 36) return;

        if (IsSpectatingGhost()) {
            auto currSpecId = GetCurrentlySpecdGhostInstanceId(ps);
            NGameGhostClips_SClipPlayerGhost@ g = GhostClipsMgr::GetGhostFromInstanceId(mgr, currSpecId);
            if (g !is null) {
                // we want to unspectate this player, but not load a ghost.
                if (LoginToWSID(g.GhostModel.GhostLogin) == wsid) {
                    // sleep(100);
                    ExitSpectatingGhost();
                    if (scrubberMgr !is null) scrubberMgr.ResetAll();
                    return;
                }
            }
        }

        @mgr = null;

        if (Time::Now - lastLoadSpectate <= 100 && lastLoadWsid == wsid) return;

        lastLoadSpectate = Time::Now;
        lastLoadWsid = wsid;

        // since we got a request to spectate a ghost, we want to undo that and manage it ourselves
        // wait a bit to give ML time to process request
        // sleep(100);

        // this abadons the load + spectate ghost request on ML size; we then want to re-spectate the ghost
        auto currSpec = GetCurrentlySpecdGhostInstanceId(ps);
        g_BlockNextGhostsSetTimeReset = true;
        g_BlockNextGhostsSetTimeAny = true;
        g_BlockNextClearForcedTarget = true;
        ExitSpectatingGhost();
        startnew(CoroutineFuncUserdataUint64(this.FindAndSpec), uint64(currSpec));

        // while (GetApp().PlaygroundScript !is null && mgr.Ghosts.Length == nbGhosts) yield();
        Cache::LoadGhostsForWsids({wsid}, CurrentMap);
        // ghost was added
        auto mgr2 = GhostClipsMgr::Get(GetApp());
        auto ps2 = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
        if (mgr2 is null || ps2 is null) return;

        // if (scrubberMgr !is null) {
        //     scrubberMgr.ResetAll();
        // }

        for (uint i = nbGhosts; i < mgr2.Ghosts.Length; i++) {
            if (wsid == LoginToWSID(mgr2.Ghosts[i].GhostModel.GhostLogin)) {
                g_SaveGhostTab.SpectateGhost(i);
                return;
            }
        }
        // test from 0 now instead of nbGhosts
        for (uint i = 0; i < mgr2.Ghosts.Length; i++) {
            if (wsid == LoginToWSID(mgr2.Ghosts[i].GhostModel.GhostLogin)) {
                g_SaveGhostTab.SpectateGhost(i);
                return;
            }
        }
    }

    void FindAndSpec(uint64 instId64) {
        yield();
        yield();
        yield();
        yield();
        auto id = uint(instId64);
        print("find inst id: " + id);
        if (id == 0x0FF00000) return;
        auto mgr = GhostClipsMgr::Get(GetApp());
        if (mgr is null) return;
        // scrubberMgr.SetProgress(lastExitPauseAt);
        for (uint i = 0; i < mgr.Ghosts.Length; i++) {
            if (GhostClipsMgr::GetInstanceIdAtIx(mgr, i) == id) {
                g_SaveGhostTab.SpectateGhost(i);
                print('inst id found at ix: ' + i);
                return;
            }
        }
        print('inst id not found');
    }
}

void Update_ML_SetSpectateID(const string &in wsid) {
    MLHook::Queue_MessageManialinkPlayground(SetFocusedRecord_PageUID, {"SetSpectating", wsid});
}

void Update_ML_SetGhostLoading(const string &in wsid) {
    MLHook::Queue_MessageManialinkPlayground(SetFocusedRecord_PageUID, {"SetGhostLoading", wsid});
}

void Update_ML_SetGhostLoaded(const string &in wsid) {
    MLHook::Queue_MessageManialinkPlayground(SetFocusedRecord_PageUID, {"SetGhostLoaded", wsid});
}

void Update_ML_SetGhostUnloaded(const string &in wsid) {
    MLHook::Queue_MessageManialinkPlayground(SetFocusedRecord_PageUID, {"SetGhostUnloaded", wsid});
}
