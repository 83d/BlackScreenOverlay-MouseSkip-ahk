#Requires AutoHotkey v2.0
#SingleInstance Force

; 屏幕2右侧黑色死区 + 鼠标跳过
; Ctrl+Alt+F11：显示/隐藏黑框
; Ctrl+Alt+F12：退出脚本

deadZoneWidth := 1800
showBlack := true

CoordMode("Mouse", "Screen")

; 统一显示器 API、鼠标和 GUI 的坐标系
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

monitorCount := MonitorGetCount()
primary := MonitorGetPrimary()
if (monitorCount < 2) {
    MsgBox("只检测到一块显示器，无法创建屏幕2死区。", "屏幕死区", "Icon!")
    ExitApp
}

; 选择位于主屏左侧、最靠左的非主显示器作为屏幕2
targetIndex := 0
targetLeft := 2147483647
Loop monitorCount {
    i := A_Index
    MonitorGet(i, &left, &top, &right, &bottom)
    if (i != primary && left < targetLeft) {
        targetIndex := i
        targetLeft := left
        targetTop := top
        targetRight := right
        targetBottom := bottom
    }
}

if (!targetIndex) {
    MsgBox("无法确定屏幕2。", "屏幕死区", "Icon!")
    ExitApp
}

deadL := Max(targetRight - deadZoneWidth, targetLeft)
deadT := targetTop
deadR := targetRight
deadB := targetBottom
deadW := deadR - deadL
deadH := deadB - deadT

Black := Gui("-DPIScale +AlwaysOnTop -Caption +ToolWindow +E0x20")
Black.BackColor := "000000"
BlackShown := false

ShowOverlay() {
    global Black, BlackShown, deadL, deadT, deadW, deadH
    Black.Show("x" deadL " y" deadT " w" deadW " h" deadH " NoActivate")
    BlackShown := true
}

HideOverlay() {
    global Black, BlackShown
    Black.Hide()
    BlackShown := false
}

if (showBlack)
    ShowOverlay()

SetTimer(WatchMouse, 10)
TrayTip("屏幕死区已启动", "屏幕2右侧 " deadW "px 已遮黑，鼠标会跳过到另一侧。`nCtrl+Alt+F11 切换黑框 | Ctrl+Alt+F12 退出", 1)

WatchMouse() {
    global deadL, deadR, deadT, deadB, previousX
    MouseGetPos(&x, &y)

    ; 只在“跨入”黑区时跳转，避免定时器反复处理同一次跳转。
    if (x >= deadL && x < deadR && y >= deadT && y < deadB) {
        if (previousX < deadL) {
            ; 屏幕2可见区域 -> 黑区：跳过黑区到主屏右侧
            MouseMove(deadR + 1, y, 0)
            previousX := deadR + 1
            return
        }
        if (previousX >= deadR) {
            ; 主屏 -> 黑区：跳过黑区到屏幕2可见区域
            MouseMove(deadL - 1, y, 0)
            previousX := deadL - 1
            return
        }
    }
    previousX := x
}

previousX := 0

^!F11:: {
    global BlackShown
    if (BlackShown)
        HideOverlay()
    else
        ShowOverlay()
}

^!F12::ExitApp








