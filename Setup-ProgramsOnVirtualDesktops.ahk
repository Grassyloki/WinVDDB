#SingleInstance Force
ProcessSetPriority "High"

; Initialize error log file
logFilePath := A_ScriptDir "\Logs\AHK_Program_Setup_Error.log"
SplitPath logFilePath, , logDir
if !DirExist(logDir)
    DirCreate(logDir)

FileAppend("Program Setup Script started: " A_Now "`n", logFilePath)

global DllPath := "C:\Scripts\VirtualDesktopAccessor.dll"

; Log DLL path
FileAppend("DLL Path: " DllPath "`n", logFilePath)

; Load the Virtual Desktop Accessor DLL
if !DllCall("LoadLibrary", "Str", DllPath) {
    errorMsg := "Failed to load VirtualDesktopAccessor.dll at: " DllPath
    FileAppend(errorMsg "`n", logFilePath)
    MsgBox errorMsg
    ExitApp
}

FileAppend("DLL loaded successfully`n", logFilePath)

try {
    ; Load JSON library for handling post-launch key sequences
    #Include JSON.ahk
    FileAppend("JSON library loaded successfully`n", logFilePath)
} catch Error as e {
    FileAppend("Error loading JSON library: " e.Message " " e.Extra "`n", logFilePath)
    MsgBox "Error loading JSON library: " e.Message
    ExitApp
}

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