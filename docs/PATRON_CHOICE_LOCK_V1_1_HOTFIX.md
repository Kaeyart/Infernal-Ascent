# Patron Choice + Lock V1.1 Hotfix

Fixes the V1 issue where choosing a second patron could fail to lock the run correctly, especially in the standalone test scene where multiple gates could receive the same E press.

Expected behavior after this patch:

1. Press C to simulate a room clear.
2. Claim the first patron boon.
3. Choose a physical gate for a second patron.
4. The run locks to exactly those two patrons.
5. Future patron gates and rewards can only use those two patrons.
6. Forge / fountain / shop utility gates may still appear.

Changed files:
- scripts/patrons/PatronRunManager.gd
- scripts/iso/IsoPatronFlowController.gd

No art, rooms, player, enemy, or hub files are touched.
