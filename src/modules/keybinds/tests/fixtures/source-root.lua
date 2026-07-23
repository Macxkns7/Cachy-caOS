-- Example binds
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))

hl.bind(
    "XF86HangupPhone",
    hl.dsp.exec_cmd("playerctl previous"),
    { long_press = true }
)
hl.bind(
    "XF86HangupPhone",
    hl.dsp.exec_cmd("playerctl next"),
    { repeating = false }
)

require("managed")
