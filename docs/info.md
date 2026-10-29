## How it works
 
The Dino VGA game is implemented using Verilog and runs on the Tiny Tapeout board. It generates VGA signals to display the game on a monitor and uses a push button to control the object's jump.
 
1. VGA Signal Generation: The VGA timing generator produces horizontal and vertical synchronization signals (hsync and vsync) and tracks the current pixel position to display the game at the correct screen coordinates.
 
2. Game Object Rendering: The design draws the ball, obstacles, and score by checking the current pixel coordinates. Each pixel is assigned a color based on whether it belongs to a game object or the background.
 
3. Jump Control: When the push button connected to ui_in[0] is pressed or released, the input edge detector detects the change. If the ball is on the ground and not already moving, a jump is initiated.
 
4. Ball Movement and Gravity: The ball moves upward after a jump and then falls due to gravity. The ball controller adjusts the movement timing according to the ball's velocity, and the ball returns to the ground when it reaches the ground position.
 
5. Obstacle Generation and Movement: Obstacles appear on the right side of the screen and move toward the left. A linear feedback shift register (LFSR) generates pseudo-random values to vary the obstacles' positions and cluster sizes.
 
6. Collision Detection: The design checks whether the ball collides with an obstacle. When a collision occurs, the game_over signal is asserted, stopping the ball, obstacle movement, and score updates.
 
7. Score Display: The score increases as obstacles pass the designated scoring position. A binary-coded decimal (BCD) counter converts the score into four decimal digits, which are rendered as seven-segment displays on the VGA screen.
 
8. Reset and Restart: The active-low reset signal (rst_n) initializes the game. After a game-over condition, resetting the design allows the game to start again.
 
9. Hardware Output: The generated VGA synchronization and color signals are sent through the TinyVGA PMOD to a VGA monitor, while the push button provides the jump input.
 
## How to Test
 
1. **Hardware Setup:** Connect the Tiny Tapeout board to the TinyVGA PMOD and connect the PMOD to a VGA monitor. Connect a push button to the jump input (`ui_in[0]`) and provide the required clock and reset signals.
 
2. **Power On and Reset:** Power on the board and apply the active-low reset (`rst_n`) to initialize the game. Verify that the game appears on the VGA monitor with the ball, obstacles, and score display.
 
3. **Test Ball Jump:** Press or release the push button to trigger a jump. Verify that the ball moves upward and falls back to the ground under the effect of gravity.
 
4. **Test Obstacle Movement:** Observe the obstacles moving from the right side of the screen toward the left. Verify that new obstacles appear as previous obstacles move off-screen.
 
5. **Test Score Display:** Allow the ball to avoid obstacles and verify that the score increases as obstacles pass the scoring position. Check that the score is displayed correctly on the screen.
 
6. **Test Collision Detection:** Allow the ball to collide with an obstacle. Verify that the game-over condition is triggered and that the ball, obstacles, and score stop updating.
 
7. **Test Game Restart:** Apply the reset signal again after a collision. Verify that the game returns to its initial state and can be played again.
 
8. **Simulation Testing:** Before hardware testing, simulate the Verilog design using a testbench. Verify VGA timing signals, jump behavior, obstacle movement, score updates, collision detection, and reset functionality using the simulation waveform viewer.
 
9. **Expected Result:** The game should display correctly on the VGA monitor, respond to the jump button, update the score during gameplay, detect collisions, and restart after reset.You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
 
## External hardware
 
## External Hardware I/O
 
| # | Input | Output | Bidirectional |
| :---: | :--- | :--- | :--- |
| 0 | `ui_in[0]` — Jump button input | `uo_out[0]` — VGA blue channel bit 1 | `uio[0]` — Unused |
| 1 | `ui_in[1]` — Unused | `uo_out[1]` — VGA green channel bit 1 | `uio[1]` — Unused |
| 2 | `ui_in[2]` — Unused | `uo_out[2]` — VGA red channel bit 1 | `uio[2]` — Unused |
| 3 | `ui_in[3]` — Unused | `uo_out[3]` — VGA blue channel bit 0 | `uio[3]` — Unused |
| 4 | `ui_in[4]` — Unused | `uo_out[4]` — VGA vertical sync (`vsync`) | `uio[4]` — Unused |
| 5 | `ui_in[5]` — Unused | `uo_out[5]` — VGA red channel bit 0 | `uio[5]` — Unused |
| 6 | `ui_in[6]` — Unused | `uo_out[6]` — VGA green channel bit 0 | `uio[6]` — Unused |
| 7 | `ui_in[7]` — Unused | `uo_out[7]` — VGA horizontal sync (`hsync`) | `uio[7]` — Unused |
 
### Additional Hardware Signals
 
- **`clk`**: System clock for game logic and VGA timing.
- **`rst_n`**: Active-low reset to initialize or restart the game.
- **TinyVGA PMOD**: Connects the board's VGA output signals to the monitor.
- **VGA monitor**: Displays the Dino game.
 
