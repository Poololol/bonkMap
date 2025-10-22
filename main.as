vec3[] positions;
string g_currentMapUid = "";
float g_mapActiveTimeSeconds = 0.0f;
bool g_wasInActivePlayStateLastFrame = false;

void Main(){
    BonkTracker::Initialize();
}

void Update(float dt) {
    // Taken from B++
    CGameCtnApp@ app = GetApp();
    if (app is null) {
        if (g_currentMapUid != "") {
            g_currentMapUid = ""; 
        }
        return;
    }

    // --- Map Change Detection ---
    string currentMapUidInFrame = "";
    CGameCtnChallengeInfo@ mapInfo = null;
    CGameCtnPlayground@ playground = cast<CGameCtnPlayground>(app.CurrentPlayground);
    bool foundInfoViaPlayground = false;

    if (playground !is null) {
        auto smArenaPlayground = cast<CSmArenaClient>(playground);
        if (smArenaPlayground !is null) {
                CGameCtnChallenge@ currentMap = smArenaPlayground.Map;
                if (currentMap !is null) {
                @mapInfo = currentMap.MapInfo;
                if (mapInfo !is null) foundInfoViaPlayground = true;
                }
        }
    }
    if (!foundInfoViaPlayground) {
        if (app.RootMap !is null) {
                @mapInfo = app.RootMap.MapInfo;
        }
    }

    if (mapInfo !is null) {
        currentMapUidInFrame = mapInfo.MapUid;
        if (currentMapUidInFrame == "") currentMapUidInFrame = mapInfo.IdName;
    }

    if (currentMapUidInFrame != "" && currentMapUidInFrame != g_currentMapUid) {
        Debug::Print("Main", "Map changed from '" + g_currentMapUid + "' to '" + currentMapUidInFrame + "'");
        SaveMapBonks(g_currentMapUid);
        g_currentMapUid = currentMapUidInFrame;
        LoadMapBonks(g_currentMapUid);
    } else if (currentMapUidInFrame == "" && g_currentMapUid != "") {
        Debug::Print("Main", "Current map UID became invalid (left server/map?), resetting stats.");
        SaveMapBonks(g_currentMapUid);
        g_currentMapUid = "";
    }

    // --- Active Playtime Tracking ---
    bool isActiveNow = IsPlayerActivelyPlaying();
    float dtSeconds = dt / 1000.0f;

    if (isActiveNow) {
        if (g_wasInActivePlayStateLastFrame) {
                g_mapActiveTimeSeconds += dtSeconds;
        }
        g_wasInActivePlayStateLastFrame = true;
    } else {
        g_wasInActivePlayStateLastFrame = false;
    }
    // Stop B++ code;

    if (isActiveNow) {
        BonkTracker::BonkEventInfo@ bonkInfo = BonkTracker::UpdateDetection(dt);
        if (bonkInfo !is null) {
            auto vehicleState = VehicleState::ViewingPlayerState();
            positions.InsertLast(vehicleState.Position);
            print("Bonk detected at: " + positions[positions.Length - 1]);
        }
    }
}

void Render() {
    if (!Setting_Render) {
        return;
    }
    nvg::StrokeColor(vec4(1., 1., 1., 1.));
    nvg::FillColor(vec4(1., 0., 1., 1.));
    for (int i = 0; i < positions.Length; i++){
        if (!Camera::IsBehind(positions[i])) {
            vec2 screenPos = Camera::ToScreenSpace(positions[i]);
            nvg::BeginPath();
            //nvg::Circle(screenPos, 5);
            //nvg::Stroke();
            nvg::BeginPath();
            vec2 size = vec2(Setting_Size);
            nvg::Rect(screenPos - size/2, size);
            nvg::FillPaint(nvg::RadialGradient(screenPos, size.x/4, size.x/2, 
                                               Setting_Color, vec4(1, 1, 0, 0)));
            nvg::Fill();
            nvg::ClosePath();
        }
    }
}

CSmPlayer@ GetLocalPlayerHandle(CGameCtnApp@ app, CGameCtnPlayground@ playground) {
    // Taken from B++
    if (app is null || playground is null) {
        return null;
    }
    if (playground.GameTerminals.Length == 0) {
        Debug::Print("GetLocalPlayerHandle", "Playground.GameTerminals is empty.");
        return null;
    }
    CGameTerminal@ terminal = playground.GameTerminals[0];
    if (terminal is null) {
        Debug::Print("GetLocalPlayerHandle", "Playground.GameTerminals[0] is null.");
        return null;
    }
    CSmPlayer@ player = cast<CSmPlayer>(terminal.GUIPlayer);
    if (player is null) {
        @player = cast<CSmPlayer>(terminal.ControlledPlayer);
        if (player is null) {
            Debug::Print("GetLocalPlayerHandle", "Terminal's GUIPlayer and ControlledPlayer are null or not CSmPlayer.");
            return null;
        }
    }
    return player;
}

bool IsPlayerActivelyPlaying() {
    // Taken from B++
    CGameCtnApp@ app = GetApp();
    if (app is null) return false;
    CGameCtnPlayground@ playground = cast<CGameCtnPlayground>(app.CurrentPlayground);
    if (playground is null) return false;
    CSmPlayer@ localPlayer = GetLocalPlayerHandle(app, playground);
    CSmPlayer@ viewingPlayer = VehicleState::GetViewingPlayer();
    if (localPlayer is null) return false; // Cannot determine if playing without local player handle
    if (viewingPlayer is null || viewingPlayer !is localPlayer) return false; // Spectating or in editor/replay
    // Add other checks like pause state if necessary
    return true;
}

void SaveMapBonks(string MapUid) {
    if (MapUid == "") {
        print("Empty map uid when saving");
        return;
    }
    IO::File file;
    string filePath = IO::FromStorageFolder(MapUid+".json");
    Json::Value json = Json::Object();
    float[][] posBroken;
    for (int i = 0; i < positions.Length; i++) {
        float[] te = {positions[i].x, positions[i].y, positions[i].z};
        posBroken.InsertLast(te);
    }
    json["positions"] = posBroken;
    file.Open(filePath, IO::FileMode::Write);
    file.Write(Json::Write(json));
    file.Close();
    print("Saved " + posBroken.Length + " bonks to file!");
}

void LoadMapBonks(string MapUid) {
    if (MapUid == "") {
        print("Empty map uid when loading");
        return;
    }
    IO::File file;
    string filePath = IO::FromStorageFolder(MapUid+".json");
    if (IO::FileExists(filePath)) {
        file.Open(filePath, IO::FileMode::Read);
        Json::Value json = Json::Parse(file.ReadToEnd());
        file.Close();
        positions = {};
        for (int i = 0; i < json["positions"].Length; i++) {
            auto pos = json["positions"][i];
            positions.InsertLast(vec3(pos[0], pos[1], pos[2]));
        }
        print("Loaded " + positions.Length + " bonks from file!");
    }
}