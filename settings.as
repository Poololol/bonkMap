// --- settings.as ---

// General Settings
[Setting category="General" name="Overlay Enabled" description="Show the bonks on the map."]
bool Setting_Render = true;
// --- Detection Parameters ---
[Setting category="General" name="Jerk Sensitivity (Grounded)" description="Required impact sharpness when on 4 wheels.  **LOWER values are MORE sensitive (detects lighter hits)**" min=0.1 max=50 beforerender="RenderDetectionHeader"]
float Setting_SensitivityGrounded = 4f;

[Setting category="General" name="Jerk Sensitivity (Air/Other)" description="Required impact sharpness when airborne or on fewer wheels.  **LOWER values are MORE sensitive (detects lighter hits)**" min=0.1 max=50]
float Setting_SensitivityAirborne = 4f;

[Setting category="General" name="Deceleration Threshold (Base)" description="Base value for detecting a significant slowdown. Higher values require a harder stop." min=1 max=50 hidden]
float Setting_DecelerationThreshold = 16f;

[Setting category="General" name="Time Between Bonks (ms)" description="Minimum time (milliseconds) before another bonk can be played after the previous one." min=300 max=5000]
uint Setting_BonkDebounce = 400;

// Visual Settings
[Setting category="Visual" name="Color" color]
vec4 Setting_Color = vec4(1, 0, 0, 0.5);
[Setting category="Visual" name="Size" min=4 max=100]
int Setting_Size = 16;

// --- Debug Settings (Debug) ---
// Master toggle for all debug logs
[Setting category="Debug" name="Enable Debug Logging" description="Show detailed logs for debugging." hidden]
bool Setting_Debug_EnableMaster = false;

// Individual toggles for specific log categories, only visible if master toggle is enabled
[Setting category="Debug" name="Debug: Crash Detection (warning: spams the logs)" if="Setting_Debug_EnableMaster" description="Log details about impact detection." hidden]
bool Setting_Debug_Crash = false;
[Setting category="Debug" name="Debug: Sound Loading" if="Setting_Debug_EnableMaster" description="Log details about finding and loading sound files." hidden]
bool Setting_Debug_Loading = false;
[Setting category="Debug" name="Debug: Sound Playback" if="Setting_Debug_EnableMaster" description="Log details about sound selection and playback attempts." hidden]
bool Setting_Debug_Playback = false;
[Setting category="Debug" name="Debug: SoundPlayer (Core)" if="Setting_Debug_EnableMaster" description="Log general details from the SoundPlayer module (initialization, list building)." hidden]
bool Setting_Debug_SoundPlayer = false;
[Setting category="Debug" name="Debug: Visual Effect" if="Setting_Debug_EnableMaster" description="Log details about visual effect triggering/rendering." hidden]
bool Setting_Debug_Visual = false;
[Setting category="Debug" name="Debug: Main Loop" if="Setting_Debug_EnableMaster" description="Log details from the main coordination logic." hidden]
bool Setting_Debug_Main = false;
[Setting category="Debug" name="Debug: Settings" if="Setting_Debug_EnableMaster" description="Log details from the settings." hidden]
bool Setting_Debug_Settings = false;
[Setting category="Debug" name="Debug: GUI" if="Setting_Debug_EnableMaster" description="Log details from the BonkStatsUI rendering." hidden]
bool Setting_Debug_GUI = false;


[SettingsTab name="Data"]
void RenderSettings() {
    if (UI::Button("Reset Map Data")) {
        if (g_currentMapUid == "") {
            print("Can't delete map data, not in a map!");
            return;
        }
        string fileName = IO::FromStorageFolder(g_currentMapUid + ".json");
        if (IO::FileExists(fileName)) {IO::Delete(fileName);}
        positions = {};
        print("Deleted map data!");
    }
    UI::PushStyleColor(UI::Col::Button, vec4(0.8f, 0f, 0f, 1f)); UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.9f, 0.1f, 0.1f, 1f)); UI::PushStyleColor(UI::Col::ButtonActive, vec4(1f, 0.2f, 0.2f, 1f));
    if (UI::Button("Reset All Data")) {
        UI::OpenPopup("Confirm All-Time Reset");
    }
    UI::PopStyleColor(3);
    if (UI::BeginPopupModal("Confirm All-Time Reset", UI::WindowFlags::AlwaysAutoResize)) {
        UI::TextWrapped("Do you really want to delete all of your bonk locations across every map?"); UI::Separator();
        UI::PushStyleColor(UI::Col::Text, vec4(1f, 0f, 0f, 1f)); UI::Text("THIS ACTION CANNOT BE UNDONE."); UI::PopStyleColor(); UI::Separator();
        UI::PushStyleColor(UI::Col::Button, vec4(0.8f, 0f, 0f, 1f)); UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.9f, 0.1f, 0.1f, 1f)); UI::PushStyleColor(UI::Col::ButtonActive, vec4(1f, 0.2f, 0.2f, 1f));
        if (UI::Button("YES, DELETE DATA", vec2(220, 0))) { 
            string path = IO::FromStorageFolder("test");
            IO::DeleteFolder(path.SubStr(0, path.Length - 5), true);
            positions = {};
            print("Deleted all data!"); 
            UI::ShowNotification("All data deleted!"); 
            UI::CloseCurrentPopup(); 
        }
        UI::PopStyleColor(3); UI::SameLine();
        if (UI::Button("Cancel", vec2(100, 0))) { UI::CloseCurrentPopup(); }
        UI::EndPopup();
    }
}

// --- Debug Logging Namespace (unchanged) ---
namespace Debug {
    void Print(const string &in category, const string &in message) {
        if (!Setting_Debug_EnableMaster) return;
        bool categoryEnabled = false;
        if (category == "Crash") categoryEnabled = Setting_Debug_Crash;
        else if (category == "Loading") categoryEnabled = Setting_Debug_Loading;
        else if (category == "Playback") categoryEnabled = Setting_Debug_Playback;
        else if (category == "SoundPlayer") categoryEnabled = Setting_Debug_SoundPlayer;
        else if (category == "Visual") categoryEnabled = Setting_Debug_Visual;
        else if (category == "Main") categoryEnabled = Setting_Debug_Main;
        else if (category == "Settings") categoryEnabled = Setting_Debug_Settings;
        else if (category == "GUI") categoryEnabled = Setting_Debug_GUI;
        // Add other categories here with 'else if' if needed.
        //if (categoryEnabled) print("[Bonk++ DBG:" + category + "] " + message);
    }
}

void RenderDetectionHeader() { UI::Dummy(vec2(0, 0)); UI::SeparatorText("Detection Parameters"); UI::Dummy(vec2(0, 5)); }