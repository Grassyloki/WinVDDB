#Persistent
#SingleInstance, force
SetBatchLines, -1

; User-configurable variables
totalDisplays := 6  ; Total number of displays to cycle through (easily editable)
startingDisplay := 2  ; The first display number to start cycling from

; Path to the Virtual Desktop Accessor DLL
DllPath := "C:\Scripts\VirtualDesktopAccessor.dll"

; Load the Virtual Desktop Accessor DLL
if !DllCall("LoadLibrary", "Str", DllPath) {
    MsgBox, Failed to load VirtualDesktopAccessor.dll
    ExitApp
}

; Global variables
global paused := false
global displayTime := 120000  ; Duration each desktop is shown (in milliseconds), 60000 = 60 seconds
global desktopIndex := startingDisplay
global desktopSwitchCount := [0, 0, 0, 0, 0, 0]  ; Array to keep track of switch count for each desktop

; Initialize desktop actions
global desktopActions := []
desktopActions.Push({count: 0, action: ""})  ; Desktop 1: No action
desktopActions.Push({count: 0, action: ""})  ; Desktop 2: No action
desktopActions.Push({count: 0, action: ""})  ; Desktop 3: No action
desktopActions.Push({count: 8, action: "Send, {F5}"})  ; Desktop 4: Press F5 every 5 switches
desktopActions.Push({count: 0, action: ""})  ; Desktop 5: No action
desktopActions.Push({count: 0, action: ""})  ; Desktop 6: No action

; Setup hotkey for pausing/resuming rotation
Hotkey, F2, TogglePause

; Start the desktop rotation
SetTimer, RotateDesktops, %displayTime%

; Initialize taskbar auto-hide (enabled by default)
SetTaskbarAutoHide(true)

return

; Function to rotate between desktops
RotateDesktops:
if (!paused) {
    GoToDesktop(desktopIndex)

    ; Increment switch count for the current desktop
    desktopSwitchCount[desktopIndex] += 1

    ; Check if we need to perform an action for this desktop
    if (desktopActions[desktopIndex].count > 0 && desktopSwitchCount[desktopIndex] >= desktopActions[desktopIndex].count) {
        desktopSwitchCount[desktopIndex] := 0  ; Reset the count
        if (desktopActions[desktopIndex].action != "") {
            Execute(desktopActions[desktopIndex].action)
        }
    }

    ; Increment and wrap around desktop index
    desktopIndex := (desktopIndex >= (startingDisplay + totalDisplays - 1)) ? startingDisplay : (desktopIndex + 1)
}
return

; Function to switch to a specific desktop using Virtual Desktop Accessor
GoToDesktop(desktopNumber) {
    desktopNumber := desktopNumber - 1  ; Adjust to zero-based index
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "UInt", desktopNumber)
    Sleep, 2000  ; Allow some time for the desktop switch
}

; Function to execute the specified action
Execute(action) {
    if (action != "") {
        Send, %action%
    }
}

; Function to toggle the pause state and show notification
TogglePause:
paused := !paused
if (paused) {
    TrayTip, Desktop Rotation, Rotation is paused. Taskbar auto-hide disabled., 1, 1
    SetTaskbarAutoHide(false)
} else {
    TrayTip, Desktop Rotation, Rotation resumed. Taskbar auto-hide enabled., 1, 1
    SetTaskbarAutoHide(true)
}
return

; Function to set taskbar auto-hide
SetTaskbarAutoHide(enable) {
    VarSetCapacity(APPBARDATA, A_PtrSize=4 ? 36:48)
    NumPut(A_PtrSize=4 ? 36:48, APPBARDATA, 0, "uint")
    NumPut(enable ? 1:0, APPBARDATA, A_PtrSize=4 ? 32:40, "int")
    DllCall("Shell32.dll\SHAppBarMessage", "uint", 0xA, "ptr", &APPBARDATA)
}

; Ensure the script terminates when closed
ExitApp:
DllCall("FreeLibrary", "Ptr", DllPath)  ; Optionally free the DLL
ExitApp