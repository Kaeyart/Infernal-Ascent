# V10.1 Player Health Bar Parser Hotfix

Fixes the parser error:

`Function "_draw_player_health_bar()" not found in base self.`

Cause: the player `_draw()` function calls `_draw_player_health_bar()`, but the helper function was missing from `IsoPhysicsTestPlayer.gd`.

This patch adds the missing helper only. It does not touch V10 run-choice logic, room gates, rewards, or sprite assets.
