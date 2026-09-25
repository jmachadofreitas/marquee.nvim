# Record with: vhs assets/demo.tape  (run from the repository root)
# The first run clones telescope.nvim, plenary.nvim and which-key.nvim into assets/demo/.deps.
#
# Captions: assets/demo/init.lua defines :Caption, which sets the text in the
# bar at the top and resets the keys shown next to it. Each caption is typed
# between Hide and Show, so the typing itself is not recorded.
Output assets/demo.gif

Require nvim
Require git

Set Shell "bash"
Set FontSize 18
Set Width 1100
Set Height 700
Set Padding 16
Set Theme "Catppuccin Mocha"
# Keep this above replay_ms in assets/demo/init.lua (30 ms), or the key
# overlay drops repeated keys.
Set TypingSpeed 80ms

Hide
Type "nvim --clean -u assets/demo/init.lua assets/demo/sample.lua"
Enter
# The first run clones the plugins, so wait for the file instead of sleeping.
Wait+Screen@120s /function M.greet/
Sleep 500ms
Type@10ms ":Caption m{char} sets a mark: each one shows as a sign in the gutter" Enter Sleep 300ms
Show
Sleep 1.5s

Type "3G" Sleep 300ms Type "ma" Sleep 600ms
Type "7G" Sleep 300ms Type "mb" Sleep 600ms
Type "15G" Sleep 300ms Type "mA" Sleep 600ms
Type "10G" Sleep 300ms Type "mc" Sleep 1s

Hide Type@10ms ":Caption Uppercase marks are global: set B in another file" Enter Sleep 300ms Show
Sleep 1.2s
Type ":e assets/demo/util.lua" Enter Sleep 500ms
Type "5G" Sleep 300ms Type "mB" Sleep 800ms
Type ":b sample.lua" Enter Sleep 1s

Hide Type@10ms ":Caption which-key: ' lists only the letter marks, then b jumps to one" Enter Sleep 300ms Show
Sleep 1.2s
Type "'" Sleep 2.5s
Type "b" Sleep 1.5s

Hide Type@10ms ":Caption which-key: <Space>' still lists every mark" Enter Sleep 300ms Show
Sleep 1.2s
Type " '" Sleep 2.5s
Escape Sleep 600ms

Hide Type@10ms ":Caption Telescope: <Space>mm searches the letter marks and jumps" Enter Sleep 300ms Show
Sleep 1.2s
Type " mm" Sleep 2.5s
Type "util" Sleep 1.5s
Enter Sleep 1.2s
Type ":b sample.lua" Enter Sleep 800ms

Hide Type@10ms ":Caption dm{char} deletes one mark" Enter Sleep 300ms Show
Sleep 1.2s
Type "dmb" Sleep 1.5s

Hide Type@10ms ":Caption dm- deletes the marks on the current line" Enter Sleep 300ms Show
Sleep 1.2s
Type "10G" Sleep 300ms Type "dm-" Sleep 1.5s

Hide Type@10ms ":Caption <Space>ms toggles the signs" Enter Sleep 300ms Show
Sleep 1.2s
Type " ms" Sleep 1s
Type " ms" Sleep 1s

Hide Type@10ms ":Caption dM deletes every letter mark" Enter Sleep 300ms Show
Sleep 1.2s
Type "dM" Sleep 2s

Hide
Type ":qa!"
Enter
