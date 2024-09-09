#Persistent
#SingleInstance, force  ; Force only one instance of the script to run
SetBatchLines, -1
DllPath := "C:\Scripts\VirtualDesktopAccessor.dll"

; Load the Virtual Desktop Accessor DLL
if !DllCall("LoadLibrary", "Str", DllPath)
{
    MsgBox, Failed to load VirtualDesktopAccessor.dll
    ExitApp
}

; Main function to switch desktop, run program, and exit
Main(desktopIndex, program, args) {
    GoToDesktop(desktopIndex)
    Run, % program " " args
    Sleep, 10000  ; Allow some time for the program to initialize

    ; Check if the program is Firefox, then press F11 for full screen
    if (program = "firefox.exe") {
        Sleep, 10000  ; Wait an additional time before sending F11
        ; Send, {F11}
        ; Disabled due to kisok mode on firefox
    }

    ExitApp  ; Terminate script after launching the program and performing any conditional actions
}

; Function to switch to a specific desktop
GoToDesktop(desktopNumber) {
    desktopNumber := desktopNumber - 1  ; zero-based index for VDA
    DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "UInt", desktopNumber)
    Sleep, 2000  ; Allow some time for the desktop to switch
}

; Accept command line arguments
desktopIndex := A_Args[1]
program := A_Args[2]
args := A_Args[3]

Main(desktopIndex, program, args)
