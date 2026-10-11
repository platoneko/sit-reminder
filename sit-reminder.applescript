-- 久坐提醒
-- stay-open + 非模态 NSPanel：对话框在前时 Dock / 「退出」也能真正结束进程。
-- 点「已知晓」才开始下一段计时；再点 Dock / App 会显示剩余时间。

use AppleScript version "2.8"
use framework "Foundation"
use framework "AppKit"
use scripting additions

property intervalMinutes : 45
property nextFire : missing value
property isTiming : false
property activePanel : missing value
property intervalField : missing value
property statusLabel : missing value

on run
    current application's NSApplication's sharedApplication()'s setActivationPolicy:(current application's NSApplicationActivationPolicyRegular)
    my hideAppletChrome()
    my showStartPanel()
end run

on reopen
    if activePanel is not missing value then
        my raisePanels()
        return
    end if
    if isTiming then my showStatusPanel()
end reopen

on idle
    if isTiming and (activePanel is missing value) and ((current date) ≥ nextFire) then
        my showReminderPanel()
    end if
    return 1
end idle

on quit
    set isTiming to false
    my dismissPanel()
    display notification "已停止" with title "久坐提醒"
    continue quit
end quit

on showStartPanel()
    my dismissPanel()
    set intervalField to my makeField((intervalMinutes as text), {{16, 44}, {156, 24}})
    intervalField's setAlignment:1
    set startBtn to my makeBtn("开始计时", {{184, 10}, {84, 28}}, "startClicked:")
    startBtn's setKeyEquivalent:(ASCII character 13)
    set exitBtn to my makeQuitBtn("退出", {{108, 10}, {68, 28}})
    exitBtn's setKeyEquivalent:(ASCII character 27)
    set thePanel to my makePanel("久坐提醒", 284, 82)
    my addView(thePanel, intervalField)
    my addView(thePanel, my makeLabel("分钟", {{178, 47}, {90, 18}}))
    my addView(thePanel, startBtn)
    my addView(thePanel, exitBtn)
    my presentPanel(thePanel)
    thePanel's makeFirstResponder:intervalField
end showStartPanel

on showReminderPanel()
    my dismissPanel()
    set msg to "已经坐了 " & intervalMinutes & " 分钟，站起来活动一下。" & return & return & "点「已知晓」后重新开始计时；不点就不会开始下一段。"
    set thePanel to my makePanel("该站起来了", 420, 210)
    my addView(thePanel, my makeLabel(msg, {{20, 70}, {380, 100}}))
    my addView(thePanel, my makeBtn("已知晓", {{300, 18}, {100, 32}}, "ackClicked:"))
    my addView(thePanel, my makeQuitBtn("结束今天", {{190, 18}, {100, 32}}))
    my presentPanel(thePanel)
end showReminderPanel

on showStatusPanel()
    set remainSec to nextFire - (current date)
    if remainSec < 0 then set remainSec to 0
    set remainMin to remainSec div 60
    set msg to "正在计时：每 " & intervalMinutes & " 分钟提醒一次。" & return & "大约还剩 " & remainMin & " 分钟。"
    my dismissPanel()
    set thePanel to my makePanel("久坐提醒", 380, 180)
    my addView(thePanel, my makeLabel(msg, {{20, 62}, {340, 80}}))
    my addView(thePanel, my makeBtn("继续等待", {{250, 18}, {110, 32}}, "keepWaitingClicked:"))
    my addView(thePanel, my makeQuitBtn("结束今天", {{140, 18}, {100, 32}}))
    my presentPanel(thePanel)
end showStatusPanel

on startClicked_(sender)
    set raw to (intervalField's stringValue() as text)
    try
        set n to raw as integer
        if n < 1 then error "间隔至少 1 分钟"
        set intervalMinutes to n
        set isTiming to true
        set nextFire to (current date) + (intervalMinutes * minutes)
        my dismissPanel()
        display notification "计时已开始，" & intervalMinutes & " 分钟后提醒。点「已知晓」才会开始下一次计时。" with title "久坐提醒"
    on error
        intervalField's setTextColor:(current application's NSColor's systemRedColor())
        beep
    end try
end startClicked_

on ackClicked_(sender)
    set nextFire to (current date) + (intervalMinutes * minutes)
    my dismissPanel()
    display notification "已重新开始计时，" & intervalMinutes & " 分钟后再提醒。" with title "久坐提醒"
end ackClicked_

on keepWaitingClicked_(sender)
    my dismissPanel()
end keepWaitingClicked_

on makePanel(theTitle, w, h)
    set thePanel to current application's NSPanel's alloc()'s initWithContentRect:{{0, 0}, {w, h}} styleMask:1 backing:2 defer:false
    thePanel's setTitle:theTitle
    thePanel's setFloatingPanel:true
    thePanel's setBecomesKeyOnlyIfNeeded:false
    thePanel's setHidesOnDeactivate:false
    thePanel's setReleasedWhenClosed:false
    return thePanel
end makePanel

on presentPanel(thePanel)
    set activePanel to thePanel
    thePanel's setLevel:25
    thePanel's setCollectionBehavior:273
    thePanel's |center|()
    thePanel's makeKeyAndOrderFront:(missing value)
    thePanel's |orderFrontRegardless|()
end presentPanel

on dismissPanel()
    if activePanel is missing value then return
    try
        activePanel's orderOut:(missing value)
    end try
    set activePanel to missing value
    set intervalField to missing value
    set statusLabel to missing value
end dismissPanel

on addView(thePanel, theView)
    thePanel's |contentView|()'s addSubview:theView
end addView

on makeLabel(theText, theFrame)
    set v to current application's NSTextField's alloc()'s initWithFrame:theFrame
    v's setStringValue:theText
    v's setBezeled:false
    v's setDrawsBackground:false
    v's setEditable:false
    v's setSelectable:false
    v's setFont:(current application's NSFont's systemFontOfSize:13)
    v's setUsesSingleLineMode:true
    return v
end makeLabel

on makeField(theText, theFrame)
    set v to current application's NSTextField's alloc()'s initWithFrame:theFrame
    v's setStringValue:theText
    v's setEditable:true
    v's setSelectable:true
    return v
end makeField

on makeBtn(theTitle, theFrame, theAction)
    set v to current application's NSButton's alloc()'s initWithFrame:theFrame
    v's setTitle:theTitle
    v's setBezelStyle:1
    v's setTarget:me
    v's setAction:(current application's NSSelectorFromString(theAction))
    return v
end makeBtn

on makeQuitBtn(theTitle, theFrame)
    set v to current application's NSButton's alloc()'s initWithFrame:theFrame
    v's setTitle:theTitle
    v's setBezelStyle:1
    v's setTarget:(current application's NSApp)
    v's setAction:(current application's NSSelectorFromString("terminate:"))
    return v
end makeQuitBtn

on raisePanels()
    if activePanel is missing value then return
    try
        activePanel's setLevel:25
        activePanel's makeKeyAndOrderFront:(missing value)
        activePanel's |orderFrontRegardless|()
    end try
end raisePanels

on hideAppletChrome()
    set nsApp to current application's NSApplication's sharedApplication()
    set theWins to nsApp's |windows|()
    repeat with theWin in (theWins as list)
        try
            if (theWin's |level|() as integer) is 0 then theWin's orderOut:(missing value)
        end try
    end repeat
end hideAppletChrome
