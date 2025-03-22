#SingleInstance Force
ProcessSetPriority "High"

global DllPath := "C:\Scripts\VirtualDesktopAccessor.dll"

; Load the Virtual Desktop Accessor DLL
if !DllCall("LoadLibrary", "Str", DllPath) {
    MsgBox "Failed to load VirtualDesktopAccessor.dll at: " DllPath
    ExitApp
}

; Load JSON library for handling post-launch key sequences
#Include JSON.ahk

; Main function to switch desktop, run program, and execute post-launch actions
Main(desktopIndex, program, args, postLaunchKeysJson) {
    GoToDesktop(desktopIndex)
    Run program " " args
    Sleep 10000  ; Allow some time for the program to initialize
    
    ; Process post-launch key sequences if provided
    if (postLaunchKeysJson != "") {
        try {
            ; Parse the JSON string into an object
            postLaunchKeys := JSON.Parse(postLaunchKeysJson)
            
            ; Execute each key sequence with specified delays
            for keyAction in postLaunchKeys {
                ; Sleep for the specified delay
                if (keyAction.HasOwnProp("delay") && keyAction.delay > 0) {
                    Sleep keyAction.delay
                } else {
                    Sleep 1000  ; Default delay if not specified
                }
                
                ; Send the key sequence
                if (keyAction.HasOwnProp("keys") && keyAction.keys != "") {
                    Send keyAction.keys
                }
            }
        } catch Error as e {
            ; Log error if JSON parsing fails
            FileAppend("Error processing post-launch keys: " e.Message "`n", A_ScriptDir "\error.log")
        }
    }
    
    ExitApp  ; Terminate script after launching the program and performing any conditional actions
}

; Function to switch to a specific desktop
GoToDesktop(desktopNumber) {
    desktopNumber := desktopNumber - 1  ; zero-based index for VDA
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "UInt", desktopNumber)
    Sleep 2000  ; Allow some time for the desktop to switch
}

; Accept command line arguments
desktopIndex := A_Args[1]
program := A_Args[2]
args := A_Args[3]
postLaunchKeysJson := A_Args.Length >= 4 ? A_Args[4] : ""

Main(desktopIndex, program, args, postLaunchKeysJson)