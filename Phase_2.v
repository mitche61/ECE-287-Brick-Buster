// Task list: score counter, multiple levels (level tracker)

//Potential additions: LASERS, 
//ball move slower/faster if hits "slow" or "fast" block (defined by different colors)
// Multiple balls
//time based score?
//Make the paddle different colors to show where to hit to make it go what angle


module Phase_2(clk, rst, key, start_game, DAC_clk, VGA_R, VGA_G, VGA_B, VGA_Hsync, 
					VGA_Vsync, blank_n, KB_clk, data,begin_game, score, start_angle45, start_angle90, start_angle135, cheat_win);
					
input clk, rst;
input KB_clk, data;
input [1:0]key;
input start_game;
input start_angle45, start_angle90, start_angle135; //user decides at which angle the ball starts (diagonally left (135, SW17) straight up (90, SW16) diagonally right (45, SW15) 
input cheat_win;

output [10:0] score;

wire [2:0]direction;

output reg [7:0]VGA_R;
output reg [7:0]VGA_G;
output reg [7:0]VGA_B;

output VGA_Hsync;
output VGA_Vsync;
output DAC_clk;
output blank_n;

wire [10:0]xCounter;
wire [10:0]yCounter;

reg R;
reg G;
reg B;

wire update;
wire updatePad;
wire VGA_clk;
wire displayArea;

wire paddle;
wire ball;
wire block1,block2,block3,block4,block5,block6,block7,block8,block9;
wire movingblock1, movingblock2;
wire top_border, right_border, left_border;
wire screen_border;

reg border;
reg game_over;
reg win_game;
reg [10:0] score;

reg [10:0]x_pad, y_pad; //the top left point of the paddle
reg [10:0]x_ball,y_ball; //the top right of the ball

reg [10:0] x_block1,x_block2,x_block3,x_block4,x_block5,x_block6,x_block7,x_block8,x_block9; //top right corner of block
reg [10:0] y_block1,y_block2,y_block3,y_block4,y_block5,y_block6,y_block7,y_block8,y_block9;

reg [10:0] x_movingblock1, x_movingblock2;
reg [10:0] y_movingblock1, y_movingblock2;

reg [10:0] x_right_border, y_right_border;
reg [10:0] x_left_border, y_left_border;
reg [10:0] x_screen_border, y_screen_border;

//instantiate modules
kbInput keyboard(KB_clk, key, direction); //the "keyboard", aka the buttons
updateCLK clk_updateCLK(clk, update); // ball clock
updatePaddleCLK clk_updatePaddleCLK(clk, updatePad); // paddle clock
clk_reduce reduce(clk, VGA_clk);
VGA_generator generator(VGA_clk, VGA_Hsync, VGA_Vsync, DisplayArea, xCounter, yCounter, blank_n);

assign DAC_clk = VGA_clk; //DON'T DELETE. this allows the clock on the board to sync with the vga (allowing things to shop up on the monitor)

assign paddle = (xCounter >= x_pad && xCounter <= x_pad + 8'd80 && yCounter >= y_pad && yCounter <= y_pad + 8'd15); // sets the size of the paddle
assign ball   = (xCounter >= x_ball && xCounter <= x_ball + 8'd20 && yCounter >= y_ball && yCounter <= y_ball + 8'd20); // sets the size of the ball
assign screen_border = (xCounter >= x_screen_border && xCounter <= x_screen_border + 11'd600 && yCounter >= y_screen_border && yCounter <= y_screen_border + 11'd440);

// Create nine blocks
assign block1 = (xCounter >= x_block1 && xCounter <= x_block1 + 8'd80 && yCounter >= y_block1 && yCounter <= y_block1 + 8'd30);
assign block2 = (xCounter >= x_block2 && xCounter <= x_block2 + 8'd80 && yCounter >= y_block2 && yCounter <= y_block2 + 8'd30);
assign block3 = (xCounter >= x_block3 && xCounter <= x_block3 + 8'd80 && yCounter >= y_block3 && yCounter <= y_block3 + 8'd30);
assign block4 = (xCounter >= x_block4 && xCounter <= x_block4 + 8'd80 && yCounter >= y_block4 && yCounter <= y_block4 + 8'd30);
assign block5 = (xCounter >= x_block5 && xCounter <= x_block5 + 8'd80 && yCounter >= y_block5 && yCounter <= y_block5 + 8'd30);
assign block6 = (xCounter >= x_block6 && xCounter <= x_block6 + 8'd80 && yCounter >= y_block6 && yCounter <= y_block6 + 8'd30);
assign block7 = (xCounter >= x_block7 && xCounter <= x_block7 + 8'd80 && yCounter >= y_block7 && yCounter <= y_block7 + 8'd30);
assign block8 = (xCounter >= x_block8 && xCounter <= x_block8 + 8'd80 && yCounter >= y_block8 && yCounter <= y_block8 + 8'd30);
assign block9 = (xCounter >= x_block9 && xCounter <= x_block9 + 8'd80 && yCounter >= y_block9 && yCounter <= y_block9 + 8'd30);

assign movingblock1 = (xCounter >= x_movingblock1 && xCounter <= x_movingblock1 + 8'd80 && yCounter >= y_movingblock1 && yCounter <= y_movingblock1 + 8'd30);
assign movingblock2 = (xCounter >= x_movingblock2 && xCounter <= x_movingblock2 + 8'd80 && yCounter >= y_movingblock2 && yCounter <= y_movingblock2 + 8'd30);
///////////////////////////////////////////////////////////////////////////////FSM for collisions
reg [10:0]S;
reg [10:0]NS;
parameter before = 11'd0, start = 11'd1, ball_move_up = 11'd2, collision = 11'd3, ball_move_down = 11'd4, end_game = 11'd5,
			 ball_move_45 = 11'd6, ball_move_135 = 11'd7, ball_move_225 = 11'd8, ball_move_315 = 11'd9, ball_move_180 = 11'd10, ball_move_0 = 11'd11;

parameter beforeL2 = 11'd12, startL2 = 11'd13, ball_move_upL2 = 11'd14, collisionL2 = 11'd15, ball_move_downL2 = 11'd16, end_gameL2 = 11'd17,
			 ball_move_45L2 = 11'd18, ball_move_135L2 = 11'd19, ball_move_225L2 = 11'd20, ball_move_315L2 = 11'd21;

// Check if the ball hits a brick from the top or bottom (bottom)
wire hit_block1;
assign hit_block1 = ((((y_block1+5'd30)==y_ball) && (x_ball > (x_block1-5'd20)) && (x_ball < (x_block1 + 8'd80))) || ((y_block1==(y_ball+5'd20)) && (x_ball > (x_block1-5'd20)) && (x_ball < (x_block1 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block2;
assign hit_block2 = ((((y_block2+5'd30)==y_ball) && (x_ball > (x_block2-5'd20)) && (x_ball < (x_block2 + 8'd80))) || ((y_block2==(y_ball+5'd20)) && (x_ball > (x_block2-5'd20)) && (x_ball < (x_block2 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block3;
assign hit_block3 = ((((y_block3+5'd30)==y_ball) && (x_ball > (x_block3-5'd20)) && (x_ball < (x_block3 + 8'd80))) || ((y_block3==(y_ball+5'd20)) && (x_ball > (x_block3-5'd20)) && (x_ball < (x_block3 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block4;
assign hit_block4 = ((((y_block4+5'd30)==y_ball) && (x_ball > (x_block4-5'd20)) && (x_ball < (x_block4 + 8'd80))) || ((y_block4==(y_ball+5'd20)) && (x_ball > (x_block4-5'd20)) && (x_ball < (x_block4 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block5;
assign hit_block5 = ((((y_block5+5'd30)==y_ball) && (x_ball > (x_block5-5'd20)) && (x_ball < (x_block5 + 8'd80))) || ((y_block5==(y_ball+5'd20)) && (x_ball > (x_block5-5'd20)) && (x_ball < (x_block5 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block6;
assign hit_block6 = ((((y_block6+5'd30)==y_ball) && (x_ball > (x_block6-5'd20)) && (x_ball < (x_block6 + 8'd80))) || ((y_block6==(y_ball+5'd20)) && (x_ball > (x_block6-5'd20)) && (x_ball < (x_block6 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block7;
assign hit_block7 = ((((y_block7+5'd30)==y_ball) && (x_ball > (x_block7-5'd20)) && (x_ball < (x_block7 + 8'd80))) || ((y_block7==(y_ball+5'd20)) && (x_ball > (x_block7-5'd20)) && (x_ball < (x_block7 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block8;
assign hit_block8 = ((((y_block8+5'd30)==y_ball) && (x_ball > (x_block8-5'd20)) && (x_ball < (x_block8 + 8'd80))) || ((y_block8==(y_ball+5'd20)) && (x_ball > (x_block8-5'd20)) && (x_ball < (x_block8 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_block9;
assign hit_block9 = ((((y_block9+5'd30)==y_ball) && (x_ball > (x_block9-5'd20)) && (x_ball < (x_block9 + 8'd80))) || ((y_block9==(y_ball+5'd20)) && (x_ball > (x_block9-5'd20)) && (x_ball < (x_block9 + 8'd80)))) ? 1'b1 : 1'b0;

wire hit_movingblock1;
assign hit_movingblock1 = ((((y_movingblock1+5'd30)==y_ball) && (x_ball > (x_movingblock1-5'd20)) && (x_ball < (x_movingblock1 + 8'd80))) || ((y_movingblock1==(y_ball+5'd20)) && (x_ball > (x_movingblock1-5'd20)) && (x_ball < (x_movingblock1 + 8'd80)))) ? 1'b1 : 1'b0;
wire hit_movingblock2;
assign hit_movingblock2 = ((((y_movingblock2+5'd30)==y_ball) && (x_ball > (x_movingblock2-5'd20)) && (x_ball < (x_movingblock2 + 8'd80))) || ((y_movingblock2==(y_ball+5'd20)) && (x_ball > (x_movingblock2-5'd20)) && (x_ball < (x_movingblock2 + 8'd80)))) ? 1'b1 : 1'b0;

// Check if the ball hits a brick from the left or the right (left)
wire hit_side_block1;
assign hit_side_block1 = (((x_block1==(x_ball+5'd20)) && (y_ball > y_block1-5'd20) && (y_ball < (y_block1 + 8'd30))) || (((x_block1 + 11'd80)==x_ball) && (y_ball > (y_block1-5'd20)) && (y_ball < (y_block1 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block2;
assign hit_side_block2 = (((x_block2==(x_ball+5'd20)) && (y_ball > y_block2-5'd20) && (y_ball < (y_block2 + 8'd30))) || (((x_block2 + 11'd80)==x_ball) && (y_ball > (y_block2-5'd20)) && (y_ball < (y_block2 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block3;
assign hit_side_block3 = (((x_block3==(x_ball+5'd20)) && (y_ball > y_block3-5'd20) && (y_ball < (y_block3 + 8'd30))) || (((x_block3 + 11'd80)==x_ball) && (y_ball > (y_block3-5'd20)) && (y_ball < (y_block3 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block4;
assign hit_side_block4 = (((x_block4==(x_ball+5'd20)) && (y_ball > y_block4-5'd20) && (y_ball < (y_block4 + 8'd30))) || (((x_block4 + 11'd80)==x_ball) && (y_ball > (y_block4-5'd20)) && (y_ball < (y_block4 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block5;
assign hit_side_block5 = (((x_block5==(x_ball+5'd20)) && (y_ball > y_block5-5'd20) && (y_ball < (y_block5 + 8'd30))) || (((x_block5 + 11'd80)==x_ball) && (y_ball > (y_block5-5'd20)) && (y_ball < (y_block5 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block6;
assign hit_side_block6 = (((x_block6==(x_ball+5'd20)) && (y_ball > y_block6-5'd20) && (y_ball < (y_block6 + 8'd30))) || (((x_block6 + 11'd80)==x_ball) && (y_ball > (y_block6-5'd20)) && (y_ball < (y_block6 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block7;
assign hit_side_block7 = (((x_block7==(x_ball+5'd20)) && (y_ball > y_block7-5'd20) && (y_ball < (y_block7 + 8'd30))) || (((x_block7 + 11'd80)==x_ball) && (y_ball > (y_block7-5'd20)) && (y_ball < (y_block7 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block8;
assign hit_side_block8 = (((x_block8==(x_ball+5'd20)) && (y_ball > y_block8-5'd20) && (y_ball < (y_block8 + 8'd30))) || (((x_block8 + 11'd80)==x_ball) && (y_ball > (y_block8-5'd20)) && (y_ball < (y_block8 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_block9;
assign hit_side_block9 = (((x_block9==(x_ball+5'd20)) && (y_ball > y_block9-5'd20) && (y_ball < (y_block9 + 8'd30))) || (((x_block9 + 11'd80)==x_ball) && (y_ball > (y_block9-5'd20)) && (y_ball < (y_block9 + 8'd30)))) ? 1'b1 : 1'b0;

wire hit_side_movingblock1;
assign hit_side_movingblock1 = (((x_movingblock1==(x_ball+5'd20)) && (y_ball > y_movingblock1-5'd20) && (y_ball < (y_movingblock1 + 8'd30))) || (((x_movingblock1 + 11'd80)==x_ball) && (y_ball > (y_movingblock1-5'd20)) && (y_ball < (y_movingblock1 + 8'd30)))) ? 1'b1 : 1'b0;
wire hit_side_movingblock2;
assign hit_side_movingblock2 = (((x_movingblock2==(x_ball+5'd20)) && (y_ball > y_movingblock2-5'd20) && (y_ball < (y_movingblock2 + 8'd30))) || (((x_movingblock2 + 11'd80)==x_ball) && (y_ball > (y_movingblock2-5'd20)) && (y_ball < (y_movingblock2 + 8'd30)))) ? 1'b1 : 1'b0;

wire paddle_hit; // checks any pixel of the ball overlaps with the top of the paddle or the side of the paddle
assign paddle_hit = ((((y_ball + 5'd20) >= y_pad) && (y_ball + 5'd20 < y_pad + 5'd15) && (x_ball > x_pad - 8'd20) && (x_ball < (x_pad + 8'd100))))  ? 1'b1 : 1'b0;

wire hit_me; // checks if the ball has hit the top of the screen
assign hit_me = (y_ball == y_screen_border) ? 1'b1 : 1'b0;
wire hit_me_low; // checks if a ball flew off the bottom of the screen
assign hit_me_low = (y_ball == (y_screen_border + 11'd480)) ? 1'b1 : 1'b0;

// Check if the ball hits a wall
wire hit_side_left;
assign hit_side_left = (x_ball == x_screen_border) ? 1'b1 : 1'b0;
wire hit_side_right;
assign hit_side_right = ((x_ball + 5'd20) == (x_screen_border + 11'd600)) ? 1'b1 : 1'b0;

//////////////////////////////////////////reset
always @ (posedge update or negedge rst)
begin
	if(rst == 1'd0)
		S <= before;
	else if (cheat_win == 1'd1)
		S <= end_game;
	else
		S <= NS;
end

////////////////////////////////////////state transitions
always @(*)
begin
	case (S)
		before:
			begin
				if(rst_game == 1'd0) ///resets the game
					NS = before;
				else if(start_game == 1'b1) ///makes the ball move
					begin
						if (start_angle45 == 1'd1)
							NS = ball_move_45;
						else if (start_angle90 == 1'd1)
							NS = ball_move_up;
						else
							NS = ball_move_135;
					 end	
				else
					NS = before;
			end	

		ball_move_up:
		begin
			if((hit_block1 == 1'd0 && hit_block2 == 1'd0 && hit_block3 == 1'd0 && hit_block4 == 1'd0 && hit_block5 == 1'd0 && hit_block6 == 1'd0 && 
					hit_block7 == 1'd0 && hit_block8 == 1'd0 && hit_block9 == 1'd0) && hit_me == 1'd0)
				NS = ball_move_up;
			else if((hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1) || hit_me == 1'd1)
				NS = ball_move_down;
		end
			
		ball_move_down:
		begin	
			if(hit_me_low == 1'b1)  ///you suck
				NS = end_game;
			else if (paddle_hit == 1'd0)
				NS = ball_move_down;
			else if (paddle_hit == 1'd1)
				begin
					if ((x_ball + 5'd20 >= x_pad) && (x_ball + 5'd20 < x_pad + 5'd5)) ///left edge
						NS = ball_move_180;
					else if ((x_ball + 5'd20 >= x_pad + 11'd5) && (x_ball + 5'd20 < x_pad + 5'd10)) ///left side but not edge
						NS = ball_move_135;
					if ((x_ball + 5'd20 >= x_pad + 11'd75) && (x_ball + 5'd20 < x_pad + 11'd80))       ///right edge
						NS = ball_move_0;						
					else if (x_ball > x_pad + 11'd60) ///right side but not edge
						NS = ball_move_45;
					else ///center of paddle
						NS = ball_move_up;
			
				end
		end
		
		ball_move_45:
		begin
			if(score == 11'd9) //////////////score tracker
				NS = end_game;
			else if(hit_side_right == 1'b1)
				NS = ball_move_135;
			else if(hit_me == 1'b1)
				NS = ball_move_315;
			else if(hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_315;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_135; 
			else
				NS = ball_move_45;
		end
		
		ball_move_135:
		begin
			if (score == 11'd9) //////////////score tracker
				NS = end_game;
			else if(hit_side_left == 1'b1)
				NS = ball_move_45;
			else if(hit_me == 1'b1)
				NS = ball_move_225;
			else if(hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_225;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_45;
			else
				NS = ball_move_135;
		end
		
		ball_move_225:
		begin
			if(score == 11'd9) //////////////score tracker
				NS = end_game;
			else if(hit_me_low == 1'b1)  //you suck
				NS = end_game;
			else if(hit_side_left == 1'b1)
				NS = ball_move_315;
			else if(paddle_hit == 1'b1)
				NS = ball_move_135;
			else if(hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_135;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_315;
			else
				NS = ball_move_225;
		end
		
		ball_move_315:
		begin
			if(score == 11'd9) //////////////score tracker
				NS = end_game;
			else if(hit_me_low == 1'b1) ///you suck
				NS = end_game;
			else if(hit_side_right == 1'b1)
				NS = ball_move_225;
			else if(paddle_hit == 1'b1)
				NS = ball_move_45;
			else if(hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_45;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_225;		
			else 
				NS = ball_move_315;
		end
		
		ball_move_180:
		begin
			if(hit_side_left == 1'b1)
				NS = ball_move_0;
			else
				NS = ball_move_180;
			if (paddle_hit == 1'd1)
				NS = ball_move_45;
		end
		
		ball_move_0:
		begin
			if(hit_side_right == 1'd1)
				NS = ball_move_180;
			else
				NS = ball_move_0;
			if (paddle_hit == 1'd1)
				NS = ball_move_135;
		end
		
		end_game:
			if(score == 11'd9 || cheat_win == 1'd1)
				NS = beforeL2;
			else
				NS = end_game;
				
		beforeL2:
			begin
				if(rst_game == 1'd0) ///resets the game
					NS = beforeL2;
				else if(start_game == 1'b1 && begin_game == 1'd1) ///makes the ball move
					begin
						if (start_angle45 == 1'd1)
							NS = ball_move_45L2;
						else if (start_angle90 == 1'd1)
							NS = ball_move_upL2;
						else
							NS = ball_move_135L2;
					 end	
			end	

		ball_move_upL2:
		begin
			if((hit_movingblock1 == 1'd0 && hit_movingblock2 == 1'd0 && hit_block1 == 1'd0 && hit_block2 == 1'd0 && hit_block3 == 1'd0 && hit_block4 == 1'd0 && hit_block5 == 1'd0 && hit_block6 == 1'd0 && hit_block7 == 1'd0 && hit_block8 == 1'd0 && hit_block9 == 1'd0) && hit_me == 1'd0)
				NS = ball_move_upL2;
			else if((hit_movingblock1 == 1'd1 || hit_movingblock2 == 1'd1 || hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1) || hit_me == 1'd1)
				NS = ball_move_downL2;
		end
			
		ball_move_downL2:
		begin	
			if(hit_me_low == 1'b1)  ///you suck
				NS = end_gameL2;
			else if (paddle_hit == 1'd0)
				NS = ball_move_downL2;
			else if (paddle_hit == 1'd1)
				begin
					if ((x_ball + 5'd20 >= x_pad + 11'd5) && (x_ball + 5'd20 < x_pad + 5'd10)) ///left side but not edge
						NS = ball_move_135L2;						
					else if (x_ball > x_pad + 11'd60) ///right side but not edge
						NS = ball_move_45L2;
					else ///center of paddle
						NS = ball_move_upL2;
			
				end
		end
		
		ball_move_45L2:
		begin
			if (score == 11'd9) //////////////score tracker
				NS = end_gameL2;
			else if(hit_side_right == 1'b1)
				NS = ball_move_135L2;
			else if(hit_me == 1'b1)
				NS = ball_move_315L2;
			else if(hit_movingblock1 == 1'd1 || hit_movingblock2 == 1'd1 || hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_315L2;
			else if(hit_side_movingblock1 == 1'd1 || hit_side_movingblock2 == 1'd1 || hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_135L2; 
			else
				NS = ball_move_45L2;
		end
		
		ball_move_135L2:
		begin
			if (score == 11'd9) //////////////score tracker
				NS = end_gameL2;
			else if(hit_side_left == 1'b1)
				NS = ball_move_45L2;
			else if(hit_me == 1'b1)
				NS = ball_move_225L2;
			else if(hit_movingblock1 == 1'd1 || hit_movingblock2 == 1'd1 || hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_225L2;
			else if(hit_side_movingblock1 == 1'd1 || hit_side_movingblock2 == 1'd1 || hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_45L2;
			else
				NS = ball_move_135L2;
		end
		
		ball_move_225L2:
		begin
			if (score == 11'd9) //////////////score tracker
				NS = end_gameL2;
			else if(hit_me_low == 1'b1)  //you suck
				NS = end_gameL2;
			else if(hit_side_left == 1'b1)
				NS = ball_move_315L2;
			else if(paddle_hit == 1'b1)
				NS = ball_move_135L2;
			else if(hit_movingblock1 == 1'd1 || hit_movingblock2 == 1'd1 || hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_135L2;
			else if(hit_side_movingblock1 == 1'd1 || hit_side_movingblock2 == 1'd1 || hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_315L2;
			else
				NS = ball_move_225L2;
		end
		
		ball_move_315L2:
		begin
			if (score == 11'd9) //////////////score tracker
				NS = end_gameL2;
			else if(hit_me_low == 1'b1) ///you suck
				NS = end_gameL2;
			else if(hit_side_right == 1'b1)
				NS = ball_move_225L2;
			else if(paddle_hit == 1'b1)
				NS = ball_move_45L2;
			else if(hit_movingblock1 == 1'd1 || hit_movingblock2 == 1'd1 || hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_45L2;
			else if(hit_side_movingblock1 == 1'd1 || hit_side_movingblock2 == 1'd1 || hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_225L2;		
			else 
				NS = ball_move_315L2;
		end
		
		end_gameL2: 
			if(start_game == 1'd0)
				NS = before;	
			else
				NS = end_gameL2;
		
		default: NS = before;
	endcase	
end

////////////////////////////////////////////state definitions
always @(posedge update or negedge rst)
begin
	if(rst == 1'd0)
		rst_game = 1'd0;
	else
		case(S)
			before:
			begin
				// Set the game status controls
				status_lose <= 1'd0;
				status_win <= 1'd0;
				
				// Reset score
				score <= 11'd0;
				
				// Position the ball on the screen
				x_ball = x_pad + 11'd30;
				y_ball = 11'd424;
				
				// Position the blocks on the screen
				x_block1 = 11'd116;
				y_block1 = 11'd20;
				x_block2 = 11'd198;
				y_block2 = 11'd20;
				x_block3 = 11'd280;
				y_block3 = 11'd20;
				x_block4 = 11'd362;
				y_block4 = 11'd20;
				x_block5 = 11'd444;
				y_block5 = 11'd20;
				x_block6 = 11'd157;
				y_block6 = 11'd52;
				x_block7 = 11'd239;
				y_block7 = 11'd52;
				x_block8 = 11'd321;
				y_block8 = 11'd52;
				x_block9 = 11'd403;
				y_block9 = 11'd52;
				
				x_movingblock1 = 11'd500;
				y_movingblock1 = 11'd700;
				
				x_movingblock2 = 11'd500;
				y_movingblock2 = 11'd700;
				
				x_screen_border = 11'd20;
				y_screen_border = 11'd20;
				
				if(rst_game == 1'd0)
					rst_game =1'd1;
			end
			
			ball_move_up:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
			end
			
			ball_move_down:
			begin
				y_ball = y_ball + 11'd1;
			end
			
			ball_move_45:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
				x_ball = x_ball + 11'd1;
			end
			
			ball_move_135:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
				x_ball = x_ball - 11'd1;
			end
			
			ball_move_225:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball + 11'd1;
				x_ball = x_ball - 11'd1;
			end
			
			ball_move_315:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end										//continued motion
				y_ball = y_ball + 11'd1;
				x_ball = x_ball + 11'd1;
			end
			
			ball_move_180:
				x_ball = x_ball - 11'd1;
				
			ball_move_0:
				x_ball = x_ball + 11'd1;
				
			
			end_game: // wut ahh final reveal	
			begin
				if (score != 11'd9)
				begin
					status_lose <= 1'd1;
				end	
				rst_game = 1'd0;
			end
			
		beforeL2:
			begin
				// Set the game status controls
				status_lose <= 1'd0;
				status_win <= 1'd0;
				
				// Reset score
				score <= 11'd0;
				
				// Position the ball on the screen
				x_ball = x_pad + 11'd30;
				y_ball = 11'd424;
				
				// Position the blocks on the screen
				x_block1 = 11'd116;
				y_block1 = 11'd20;
				x_block2 = 11'd198;
				y_block2 = 11'd20;
				x_block3 = 11'd280;
				y_block3 = 11'd20;
				x_block4 = 11'd362;
				y_block4 = 11'd20;
				x_block5 = 11'd444;
				y_block5 = 11'd20;
				x_block6 = 11'd157;
				y_block6 = 11'd52;
				x_block7 = 11'd239;
				y_block7 = 11'd52;
				x_block8 = 11'd321;
				y_block8 = 11'd52;
				x_block9 = 11'd403;
				y_block9 = 11'd52;
				
				x_movingblock1 = 11'd116;
				y_movingblock1 = 11'd200;
				
				x_movingblock2 = 11'd400;
				y_movingblock2 = 11'd200;
				
				x_screen_border = 11'd20;
				y_screen_border = 11'd20;
				
				if(rst_game == 1'd0)
					rst_game =1'd1;
			end
			
			ball_move_upL2:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
			end
			
			ball_move_downL2:
			begin
				y_ball = y_ball + 11'd1;
			end
			
			ball_move_45L2:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
				x_ball = x_ball + 11'd1;
			end
			
			ball_move_135L2:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball - 11'd1;
				x_ball = x_ball - 11'd1;
			end
			
			ball_move_225L2:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end
				y_ball = y_ball + 11'd1;
				x_ball = x_ball - 11'd1;
			end
			
			ball_move_315L2:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score <= score + 11'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score <= score + 11'd1;
				end										//continued motion
				y_ball = y_ball + 11'd1;
				x_ball = x_ball + 11'd1;
			end
				
			
			end_gameL2: // wut ahh final reveal	
				begin
				if (score == 11'd9)
				begin
					status_win <= 1'd1;
				end
				else if (score != 11'd9)
				begin
					status_lose <= 1'd1;
				end	
				rst_game = 1'd0;
				end
				
		endcase	
	end

// Position the paddle

always @(posedge updatePad or negedge rst)
begin
	if(rst == 1'd0)
	begin	
		x_pad <= 11'd280; 
		y_pad <= 11'd445;
	end
	else
	begin
		case(direction) //push buttons
			3'd1: 
				if(x_pad <= 11'd540)
					x_pad <= x_pad + 11'd1; //right at a speed of "1"				
				else
					x_pad <= 11'd540;
			3'd2: 
				if(x_pad >= 11'd20)
					x_pad <= x_pad - 11'd1; //left at a speed of "1"
				else
					x_pad <= 11'd20;
			default: x_pad <= x_pad;
		endcase
	end
end


always @(posedge VGA_clk) //border and color
begin
	border <= (((xCounter >= 0) && (xCounter < 11) || (xCounter >= 630) && (xCounter < 641)) 
				|| ((yCounter >= 0) && (yCounter < 11) || (yCounter >= 470) && (yCounter < 481)));
	VGA_R = {8{R}};
	VGA_G = {8{G}};
	VGA_B = {8{B}};
end

///////////////////////////////////////////////////////////////////////// Screen decision

reg [2:0]NS_Screen,S_Screen;

parameter SS = 5'd0,RSNR = 5'd1,RSR = 5'd2,L = 5'd3,W = 5'd4, SS2 = 5'd5, RSNR2 = 5'd6, RSR2 = 5'd7, L2 = 5'd8, W2 = 5'd9;

input begin_game;

reg status_lose,status_win;

reg rst_game;



always @(posedge clk or negedge rst)

begin
	if(rst == 1'b0)
		S_Screen <= SS;
	else
		S_Screen <= NS_Screen;
end



always @(*)
begin
	case(S_Screen)
		SS:
			if(rst_game == 1'd0 || begin_game == 1'd0)
				NS_Screen = SS;
			else if(begin_game == 1'd1)
				NS_Screen = RSNR;

		RSNR:
			if(start_game == 1'd0)
				NS_Screen = RSNR;
			else
				NS_Screen = RSR;

		RSR:
			if(status_win == 1'd1 || cheat_win == 1'd1)
				NS_Screen = W;
			else if(status_lose == 1'd1)
				NS_Screen = L;
			else if(status_win == 1'd0 && status_lose == 1'd0)
				NS_Screen = RSR;
				
		W:
			if(begin_game == 1'd0 || start_game == 1'b0)
				NS_Screen = RSNR2;
			else
				NS_Screen = W;

		L:

			if(begin_game == 1'd1 && start_game == 1'b1)
				NS_Screen = L;
			else if(begin_game == 1'd0 || start_game == 1'b0)
				NS_Screen = SS;				

		RSNR2:
			if(start_game == 1'd0)
				NS_Screen = RSNR2;
			else if (start_game == 1'd1)
				NS_Screen = RSR2;
		
		RSR2:
			if(status_win == 1'd1)
				NS_Screen = W2;
			else if(status_lose == 1'd1)
				NS_Screen = L2;
			else if(status_win == 1'd0 && status_lose == 1'd0)
				NS_Screen = RSR2;

		L2:
			if(begin_game == 1'd1 || start_game == 1'b1)
				NS_Screen = L2;
			else if(begin_game == 1'd0 && start_game == 1'b0)
				NS_Screen = SS;

		W2:
			if(begin_game == 1'd1 || start_game == 1'b1)
				NS_Screen = W2;
			else if(begin_game == 1'd0 && start_game == 1'b0)
				NS_Screen = SS;

		default: NS_Screen = SS;

	endcase

end



always @(posedge clk or negedge rst)

begin

	case(S_Screen)

		SS:

		begin

			R <= 1'd0;

			B <= 1'd1 && ~row0[0] && ~row0[1] && ~row0[2] && ~row0[3] && ~row0[4] && ~row0[5] && ~row0[6] && ~row0[7] && ~row0[8] && ~row1[0] 

				&& ~row1[1] && ~row1[2] && ~row1[3] && ~row1[4] && ~row1[5] && ~row1[6] && ~row1[7] && ~row1[8]&& ~row2[0] && ~row2[1] &&

				~row2[2] && ~row2[3] && ~row2[4] && ~row2[5] && ~row2[6] && ~row2[7] && ~row2[8] && ~row3[0] && ~row3[1] && ~row3[2] && ~row3[3] 

				&& ~row3[4] && ~row3[5] && ~row3[6] && ~row3[7] && ~row3[8] && ~row4[0] && ~row4[1] && ~row4[2] && ~row4[3] && ~row4[4] && 

				~row4[5] && ~row4[6] && ~row4[7] && ~row4[8];

			G <= 1'd0;

		end

		RSNR:

		begin

			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;

			B <= screen_border && ~paddle && 1'b1;

			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && 1'b1;

		end

		RSR:

		begin

			// Set screen colors

			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;

			B <= screen_border && ~paddle && 1'b1;

			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && 1'b1;

		end

		L:

		begin

			R <= 1'd1 && ~row_Lose0[0] && ~row_Lose0[1] && ~row_Lose0[2] && ~row_Lose0[3] && ~row_Lose0[4] && ~row_Lose0[5] && ~row_Lose1[0] && 

				~row_Lose1[1] && ~row_Lose1[2] && ~row_Lose1[3] && ~row_Lose1[4] && ~row_Lose1[5] && ~row_Lose1[0] && ~row_Lose1[1] && ~row_Lose1[2] 

				&& ~row_Lose1[3] && ~row_Lose1[4] && ~row_Lose1[5] && ~row_Lose2[0] && ~row_Lose2[1] && ~row_Lose2[2] && ~row_Lose2[3] && 

				~row_Lose2[4] && ~row_Lose2[5] && ~row_Lose3[0] && ~row_Lose3[1] && ~row_Lose3[2] && ~row_Lose3[3] && ~row_Lose3[4] 

				&& ~row_Lose3[5] && ~row_Lose4[0] && ~row_Lose4[1] && ~row_Lose4[2] && ~row_Lose4[3] && ~row_Lose4[4] && ~row_Lose4[5];

			B <= 1'd0;

			G <= 1'd0;

		end

		W:

		begin

			R <= 1'd0;

			B <= 1'd0;

			G <= 1'd1 && ~row_Win0[0] && ~row_Win0[1] && ~row_Win0[2] && ~row_Win0[3] && ~row_Win0[4] && ~row_Win0[5] && ~row_Win0[6] && 

				~row_Win1[0] && ~row_Win1[1] && ~row_Win1[2] && ~row_Win1[3] && ~row_Win1[4] && ~row_Win1[5] && ~row_Win1[6] && ~row_Win2[0] 

				&& ~row_Win2[1] && ~row_Win2[2] && ~row_Win2[3] && ~row_Win2[4] && ~row_Win2[5] && ~row_Win2[6] && ~row_Win3[0] && ~row_Win3[1]

				&& ~row_Win3[2] && ~row_Win3[3] && ~row_Win3[4] && ~row_Win3[5] && ~row_Win4[0] && ~row_Win4[1] && ~row_Win4[2] && ~row_Win4[3]

				&& ~row_Win4[4] && ~row_Win4[5] && ~row_Win4[6];
		end	

		RSNR2:
		begin
		R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
		B <= screen_border && ~paddle && 1'b1;
		G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~movingblock1 && ~movingblock2 && 1'b1;
		end
		
		RSR2:
		begin
		R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
		B <= screen_border && ~paddle && 1'b1;
		G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~movingblock1 && ~movingblock2 && 1'b1;
		end
		
		L2:
		begin
			R <= 1'd1 && ~row_Lose0[0] && ~row_Lose0[1] && ~row_Lose0[2] && ~row_Lose0[3] && ~row_Lose0[4] && ~row_Lose0[5] && ~row_Lose1[0] && 

				~row_Lose1[1] && ~row_Lose1[2] && ~row_Lose1[3] && ~row_Lose1[4] && ~row_Lose1[5] && ~row_Lose1[0] && ~row_Lose1[1] && ~row_Lose1[2] 

				&& ~row_Lose1[3] && ~row_Lose1[4] && ~row_Lose1[5] && ~row_Lose2[0] && ~row_Lose2[1] && ~row_Lose2[2] && ~row_Lose2[3] && 

				~row_Lose2[4] && ~row_Lose2[5] && ~row_Lose3[0] && ~row_Lose3[1] && ~row_Lose3[2] && ~row_Lose3[3] && ~row_Lose3[4] 

				&& ~row_Lose3[5] && ~row_Lose4[0] && ~row_Lose4[1] && ~row_Lose4[2] && ~row_Lose4[3] && ~row_Lose4[4] && ~row_Lose4[5];

			B <= 1'd0;

			G <= 1'd0;

		end

		W2:
		begin
			R <= 1'd0;

			B <= 1'd0;

			G <= 1'd1 && ~row_Win0[0] && ~row_Win0[1] && ~row_Win0[2] && ~row_Win0[3] && ~row_Win0[4] && ~row_Win0[5] && ~row_Win0[6] && 

				~row_Win1[0] && ~row_Win1[1] && ~row_Win1[2] && ~row_Win1[3] && ~row_Win1[4] && ~row_Win1[5] && ~row_Win1[6] && ~row_Win2[0] 

				&& ~row_Win2[1] && ~row_Win2[2] && ~row_Win2[3] && ~row_Win2[4] && ~row_Win2[5] && ~row_Win2[6] && ~row_Win3[0] && ~row_Win3[1]

				&& ~row_Win3[2] && ~row_Win3[3] && ~row_Win3[4] && ~row_Win3[5] && ~row_Win4[0] && ~row_Win4[1] && ~row_Win4[2] && ~row_Win4[3]

				&& ~row_Win4[4] && ~row_Win4[5] && ~row_Win4[6];
		end
		

	endcase

end	



/////////////////////////////////////////////////////////////////// Text controls

// Start Screen

wire [8:0]row0,row1,row2,row3,row4;

// Row 0

assign row0[0] = (xCounter >= 11'd187 -11'd20 && xCounter <= 11'd214 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//S

assign row0[1] = (xCounter >= 11'd219 -11'd20 && xCounter <= 11'd246 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//T

assign row0[2] = (xCounter >= 11'd251 -11'd20 && xCounter <= 11'd278 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//A

assign row0[3] = (xCounter >= 11'd283 -11'd20 && xCounter <= 11'd310 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//R

assign row0[4] = (xCounter >= 11'd315 -11'd20 && xCounter <= 11'd342 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//T

assign row0[5] = (xCounter >= 11'd352 -11'd20 && xCounter <= 11'd379 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//G

assign row0[6] = (xCounter >= 11'd384 -11'd20 && xCounter <= 11'd411 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//A

assign row0[7] = (xCounter >= 11'd416 -11'd20 && xCounter <= 11'd425 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229) || (xCounter >= 11'd452 -11'd20 && xCounter <= 11'd461 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//M

assign row0[8] = (xCounter >= 11'd466 -11'd20 && xCounter <= 11'd493 -11'd20 && yCounter >= 11'd220 && yCounter <= 11'd229);//E

// Row 1

assign row1[0] = (xCounter >= 11'd187 -11'd20 && xCounter <= 11'd196 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//S

assign row1[1] = (xCounter >= 11'd228 -11'd20 && xCounter <= 11'd237 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//T

assign row1[2] = (xCounter >= 11'd269 -11'd20 && xCounter <= 11'd278 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238) || (xCounter >= 11'd251 -11'd20 && xCounter <= 11'd260 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//A

assign row1[3] = (xCounter >= 11'd283 -11'd20 && xCounter <= 11'd292 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238) || (xCounter >= 11'd301 -11'd20 && xCounter <= 11'd310 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//R

assign row1[4] = (xCounter >= 11'd324 -11'd20 && xCounter <= 11'd333 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//T

assign row1[5] = (xCounter >= 11'd352 -11'd20 && xCounter <= 11'd361 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//G

assign row1[6] = (xCounter >= 11'd384 -11'd20 && xCounter <= 11'd393 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238) || (xCounter >= 11'd402 -11'd20 && xCounter <= 11'd411 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//A

assign row1[7] = (yCounter >= 11'd229 && yCounter <= 11'd238) && ((xCounter >= 11'd416 -11'd20 && xCounter <= 11'd434 -11'd20) || (xCounter >= 11'd443 -11'd20 && xCounter <= 11'd461 -11'd20));//M

assign row1[8] = (xCounter >= 11'd466 -11'd20 && xCounter <= 11'd475 -11'd20 && yCounter >= 11'd229 && yCounter <= 11'd238);//E

// Row 2

assign row2[0] = (xCounter >= 11'd187 -11'd20 && xCounter <= 11'd214 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//S

assign row2[1] = (xCounter >= 11'd228 -11'd20 && xCounter <= 11'd237 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//T

assign row2[2] = (xCounter >= 11'd251 -11'd20 && xCounter <= 11'd278 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//A

assign row2[3] = (xCounter >= 11'd283 -11'd20 && xCounter <= 11'd310 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//R

assign row2[4] = (xCounter >= 11'd324 -11'd20 && xCounter <= 11'd333 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//T

assign row2[5] = (xCounter >= 11'd352 -11'd20 && xCounter <= 11'd361 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//G

assign row2[6] = (xCounter >= 11'd384 -11'd20 && xCounter <= 11'd411 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//A

assign row2[7] = (yCounter >= 11'd238 && yCounter <= 11'd247) && ((xCounter >= 11'd416 -11'd20 && xCounter <= 11'd425 -11'd20) || (xCounter >= 11'd452 -11'd20 && xCounter <= 11'd461 -11'd20) || (xCounter >= 11'd434 -11'd20 && xCounter <= 11'd443 -11'd20));//M

assign row2[8] = (xCounter >= 11'd466 -11'd20 && xCounter <= 11'd484 -11'd20 && yCounter >= 11'd238 && yCounter <= 11'd247);//E

// Row 3

assign row3[0] = (xCounter >= 11'd136 + 11'd49 && xCounter <= 11'd145 + 11'd49 && yCounter >= 11'd247 && yCounter <= 11'd256);//S

assign row3[1] = (xCounter >= 11'd159 + 11'd49  && xCounter <= 11'd168 + 11'd49 && yCounter >= 11'd247 && yCounter <= 11'd256);//T

assign row3[2] = (xCounter >= 11'd200 + 11'd49  && xCounter <= 11'd209 + 11'd49 && yCounter >= 11'd247 && yCounter <= 11'd256) || (xCounter >= 11'd182 + 11'd49 && xCounter <= 11'd191 + 11'd49 && yCounter >= 11'd247 && yCounter <= 11'd256);//A

assign row3[3] = (xCounter >= 11'd214 + 11'd49  && xCounter <= 11'd232 + 11'd49 && yCounter >= 11'd247 && yCounter <= 11'd256);//R

assign row3[4] = (xCounter >= 11'd255 + 11'd49  && xCounter <= 11'd264 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256);//T

assign row3[5] = (xCounter >= 11'd283 + 11'd49  && xCounter <= 11'd292 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256) || (xCounter >= 11'd301 + 11'd49  && xCounter <= 11'd310 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256);//G

assign row3[6] = (xCounter >= 11'd315 + 11'd49  && xCounter <= 11'd324 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256) || (xCounter >= 11'd333 + 11'd49  && xCounter <= 11'd342 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256);//A

assign row3[7] = (yCounter >= 11'd247 && yCounter <= 11'd256) && ((xCounter >= 11'd347 + 11'd49  && xCounter <= 11'd356 + 11'd49 ) || (xCounter >= 11'd383 + 11'd49  && xCounter <= 11'd392 + 11'd49 ));//M

assign row3[8] = (xCounter >= 11'd397 + 11'd49  && xCounter <= 11'd406 + 11'd49  && yCounter >= 11'd247 && yCounter <= 11'd256);//E

// Row 0

assign row4[0] = (xCounter >= 11'd118 + 11'd49  && xCounter <= 11'd145 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//S

assign row4[1] = (xCounter >= 11'd159 + 11'd49  && xCounter <= 11'd168 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//T

assign row4[2] = (xCounter >= 11'd200 + 11'd49  && xCounter <= 11'd209 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265) || (xCounter >= 11'd182 + 11'd49  && xCounter <= 11'd191 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//A

assign row4[3] = (xCounter >= 11'd214 + 11'd49  && xCounter <= 11'd223 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265) || (xCounter >= 11'd232 + 11'd49  && xCounter <= 11'd241 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//R

assign row4[4] = (xCounter >= 11'd255 + 11'd49  && xCounter <= 11'd264 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//T

assign row4[5] = (xCounter >= 11'd283 + 11'd49  && xCounter <= 11'd310 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//G

assign row4[6] = (xCounter >= 11'd315 + 11'd49  && xCounter <= 11'd324 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265) || (xCounter >= 11'd333 + 11'd49  && xCounter <= 11'd342 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//A

assign row4[7] = (yCounter >= 11'd256 && yCounter <= 11'd265) && ((xCounter >= 11'd347 + 11'd49  && xCounter <= 11'd356 + 11'd49 ) || (xCounter >= 11'd383 + 11'd49  && xCounter <= 11'd392 + 11'd49 ));//M

assign row4[8] = (xCounter >= 11'd397 + 11'd49  && xCounter <= 11'd424 + 11'd49  && yCounter >= 11'd256 && yCounter <= 11'd265);//E

// Lose Screen

wire [5:0]row_Lose0,row_Lose1,row_Lose2,row_Lose3,row_Lose4;

// Row 0

assign row_Lose0[0] = (xCounter >= 11'd225 && xCounter <= 11'd234) && (yCounter >= 11'd220 && yCounter <= 11'd229);// L

assign row_Lose0[1] = (xCounter >= 11'd257 && xCounter <= 11'd284) && (yCounter >= 11'd220 && yCounter <= 11'd229);// O

assign row_Lose0[2] = (xCounter >= 11'd289 && xCounter <= 11'd316) && (yCounter >= 11'd220 && yCounter <= 11'd229);// S

assign row_Lose0[3] = (xCounter >= 11'd321 && xCounter <= 11'd348) && (yCounter >= 11'd220 && yCounter <= 11'd229);// E

assign row_Lose0[4] = (xCounter >= 11'd353 && xCounter <= 11'd380) && (yCounter >= 11'd220 && yCounter <= 11'd229);// R

assign row_Lose0[5] = (xCounter >= 11'd385 && xCounter <= 11'd394) && (yCounter >= 11'd220 && yCounter <= 11'd229);// !

// Row 1

assign row_Lose1[0] = (xCounter >= 11'd225 && xCounter <= 11'd234) && (yCounter >= 11'd229 && yCounter <= 11'd238);// L

assign row_Lose1[1] = ((xCounter >= 11'd257 && xCounter <= 11'd266) || (xCounter >= 11'd275 && xCounter <= 11'd284)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// O

assign row_Lose1[2] = (xCounter >= 11'd289 && xCounter <= 11'd298) && (yCounter >= 11'd229 && yCounter <= 11'd238);// S

assign row_Lose1[3] = (xCounter >= 11'd321 && xCounter <= 11'd330) && (yCounter >= 11'd229 && yCounter <= 11'd238);// E

assign row_Lose1[4] = ((xCounter >= 11'd353 && xCounter <= 11'd362) || (xCounter >= 11'd371 && xCounter <= 11'd380)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// R

assign row_Lose1[5] = (xCounter >= 11'd385 && xCounter <= 11'd394) && (yCounter >= 11'd229 && yCounter <= 11'd238);// !

// Row 2

assign row_Lose2[0] = (xCounter >= 11'd225 && xCounter <= 11'd234) && (yCounter >= 11'd238 && yCounter <= 11'd247);// L

assign row_Lose2[1] = ((xCounter >= 11'd257 && xCounter <= 11'd266) || (xCounter >= 11'd275 && xCounter <= 11'd284)) && (yCounter >= 11'd238 && yCounter <= 11'd247);// O

assign row_Lose2[2] = (xCounter >= 11'd289 && xCounter <= 11'd316) && (yCounter >= 11'd238 && yCounter <= 11'd247);// S

assign row_Lose2[3] = (xCounter >= 11'd321 && xCounter <= 11'd339) && (yCounter >= 11'd238 && yCounter <= 11'd247);// E

assign row_Lose2[4] = (xCounter >= 11'd353 && xCounter <= 11'd380) && (yCounter >= 11'd238 && yCounter <= 11'd247);// R

assign row_Lose2[5] = (xCounter >= 11'd385 && xCounter <= 11'd394) && (yCounter >= 11'd238 && yCounter <= 11'd247);// !

// Row 3

assign row_Lose3[0] = (xCounter >= 11'd225 && xCounter <= 11'd234) && (yCounter >= 11'd247 && yCounter <= 11'd256);// L

assign row_Lose3[1] = ((xCounter >= 11'd257 && xCounter <= 11'd266) || (xCounter >= 11'd275 && xCounter <= 11'd284)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// O

assign row_Lose3[2] = (xCounter >= 11'd307 && xCounter <= 11'd316) && (yCounter >= 11'd247 && yCounter <= 11'd256);// S

assign row_Lose3[3] = (xCounter >= 11'd321 && xCounter <= 11'd330) && (yCounter >= 11'd247 && yCounter <= 11'd256);// E

assign row_Lose3[4] = (xCounter >= 11'd353 && xCounter <= 11'd371) && (yCounter >= 11'd247 && yCounter <= 11'd256);// R

// Row 4

assign row_Lose4[0] = (xCounter >= 11'd225 && xCounter <= 11'd252) && (yCounter >= 11'd256 && yCounter <= 11'd265);// L

assign row_Lose4[1] = (xCounter >= 11'd257 && xCounter <= 11'd284) && (yCounter >= 11'd256 && yCounter <= 11'd265);// O

assign row_Lose4[2] = (xCounter >= 11'd289 && xCounter <= 11'd316) && (yCounter >= 11'd256 && yCounter <= 11'd265);// S

assign row_Lose4[3] = (xCounter >= 11'd321 && xCounter <= 11'd348) && (yCounter >= 11'd256 && yCounter <= 11'd265);// E

assign row_Lose4[4] = ((xCounter >= 11'd353 && xCounter <= 11'd362) || (xCounter >= 11'd371 && xCounter <= 11'd380)) && (yCounter >= 11'd256 && yCounter <= 11'd265);// R

assign row_Lose4[5] = (xCounter >= 11'd385 && xCounter <= 11'd394) && (yCounter >= 11'd256 && yCounter <= 11'd265);// !

// Win Screen

wire [6:0]row_Win0,row_Win1,row_Win2,row_Win3,row_Win4;

// Row 0

assign row_Win0[0] = ((xCounter >= 11'd200 && xCounter <= 11'd209) || (xCounter >= 11'd236 && xCounter <= 11'd245)) && (yCounter >= 11'd220 && yCounter <= 11'd229);// W

assign row_Win0[1] = (xCounter >= 11'd250 && xCounter <= 11'd277) && (yCounter >= 11'd220 && yCounter <= 11'd229);// I

assign row_Win0[2] = ((xCounter >= 11'd282 && xCounter <= 11'd291) || (xCounter >= 11'd309 && xCounter <= 11'd318)) && (yCounter >= 11'd220 && yCounter <= 11'd229);// N

assign row_Win0[3] = ((xCounter >= 11'd323 && xCounter <= 11'd332) || (xCounter >= 11'd350 && xCounter <= 11'd359)) && (yCounter >= 11'd220 && yCounter <= 11'd229);// N

assign row_Win0[4] = (xCounter >= 11'd364 && xCounter <= 11'd391) && (yCounter >= 11'd220 && yCounter <= 11'd229);// E

assign row_Win0[5] = (xCounter >= 11'd396 && xCounter <= 11'd423) && (yCounter >= 11'd220 && yCounter <= 11'd229);// R

assign row_Win0[6] = (xCounter >= 11'd428 && xCounter <= 11'd437) && (yCounter >= 11'd220 && yCounter <= 11'd229);// !

// Row 1

assign row_Win1[0] = ((xCounter >= 11'd200 && xCounter <= 11'd209) || (xCounter >= 11'd236 && xCounter <= 11'd245)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// W

assign row_Win1[1] = (xCounter >= 11'd259 && xCounter <= 11'd268) && (yCounter >= 11'd229 && yCounter <= 11'd238);// I

assign row_Win1[2] = ((xCounter >= 11'd282 && xCounter <= 11'd300) || (xCounter >= 11'd309 && xCounter <= 11'd318)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// N

assign row_Win1[3] = ((xCounter >= 11'd323 && xCounter <= 11'd341)|| (xCounter >= 11'd350 && xCounter <= 11'd359)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// N

assign row_Win1[4] = (xCounter >= 11'd364 && xCounter <= 11'd373) && (yCounter >= 11'd229 && yCounter <= 11'd238);// E

assign row_Win1[5] = ((xCounter >= 11'd396 && xCounter <= 11'd405) || (xCounter >= 11'd414 && xCounter <= 11'd423)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// R

assign row_Win1[6] = (xCounter >= 11'd428 && xCounter <= 11'd437) && (yCounter >= 11'd229 && yCounter <= 11'd238);// !

// Row 2

assign row_Win2[0] = ((xCounter >= 11'd200 && xCounter <= 11'd209) || (xCounter >= 11'd236 && xCounter <= 11'd245) || (xCounter >= 11'd218 && xCounter <= 11'd227)) && (yCounter >= 11'd238 && yCounter <= 11'd247);// W

assign row_Win2[1] = (xCounter >= 11'd259 && xCounter <= 11'd268) && (yCounter >= 11'd238 && yCounter <= 11'd247);// I

assign row_Win2[2] = (xCounter >= 11'd282 && xCounter <= 11'd318) && (yCounter >= 11'd238 && yCounter <= 11'd247);// N

assign row_Win2[3] = (xCounter >= 11'd323 && xCounter <= 11'd359) && (yCounter >= 11'd238 && yCounter <= 11'd247);// N

assign row_Win2[4] = (xCounter >= 11'd364 && xCounter <= 11'd382) && (yCounter >= 11'd238 && yCounter <= 11'd247);// E

assign row_Win2[5] = (xCounter >= 11'd396 && xCounter <= 11'd423) && (yCounter >= 11'd238 && yCounter <= 11'd247);// R

assign row_Win2[6] = (xCounter >= 11'd428 && xCounter <= 11'd437) && (yCounter >= 11'd238 && yCounter <= 11'd247);// !

// Row 3

assign row_Win3[0] = ((xCounter >= 11'd200 && xCounter <= 11'd218) || (xCounter >= 11'd227 && xCounter <= 11'd245)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// W

assign row_Win3[1] = (xCounter >= 11'd259 && xCounter <= 11'd268) && (yCounter >= 11'd247 && yCounter <= 11'd256);// I

assign row_Win3[2] = ((xCounter >= 11'd282 && xCounter <= 11'd291) || (xCounter >= 11'd300 && xCounter <= 11'd318)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// N

assign row_Win3[3] = ((xCounter >= 11'd323 && xCounter <= 11'd332) || (xCounter >= 11'd341 && xCounter <= 11'd359)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// N

assign row_Win3[4] = (xCounter >= 11'd364 && xCounter <= 11'd373) && (yCounter >= 11'd247 && yCounter <= 11'd256);// E

assign row_Win3[5] = (xCounter >= 11'd396 && xCounter <= 11'd414) && (yCounter >= 11'd247 && yCounter <= 11'd256);// R

// Row 4

assign row_Win4[0] = ((xCounter >= 11'd200 && xCounter <= 11'd209) || (xCounter >= 11'd236 && xCounter <= 11'd245)) && (yCounter >= 11'd256 && yCounter <= 11'd265);// w

assign row_Win4[1] = (xCounter >= 11'd250 && xCounter <= 11'd277) && (yCounter >= 11'd256 && yCounter <= 11'd265);// I

assign row_Win4[2] = ((xCounter >= 11'd282 && xCounter <= 11'd291) || (xCounter >= 11'd309 && xCounter <= 11'd318)) && (yCounter >= 11'd256 && yCounter <= 11'd265);// N

assign row_Win4[3] = ((xCounter >= 11'd323 && xCounter <= 11'd332) || (xCounter >= 11'd350 && xCounter <= 11'd359)) && (yCounter >= 11'd256 && yCounter <= 11'd265);// N

assign row_Win4[4] = (xCounter >= 11'd364 && xCounter <= 11'd391) && (yCounter >= 11'd256 && yCounter <= 11'd265);// E

assign row_Win4[5] = ((xCounter >= 11'd396 && xCounter <= 11'd405) || (xCounter >= 11'd414 && xCounter <= 11'd423)) && (yCounter >= 11'd256 && yCounter <= 11'd265);// R

assign row_Win4[6] = (xCounter >= 11'd428 && xCounter <= 11'd437) && (yCounter >= 11'd256 && yCounter <= 11'd265);// !

endmodule



/////////////////////////////////////////////////////////////////// VGA_generator to display using VGA

module VGA_generator(VGA_clk, VGA_Hsync, VGA_Vsync, DisplayArea, xCounter, yCounter, blank_n);

input VGA_clk;

output VGA_Hsync, VGA_Vsync, blank_n;

output reg DisplayArea;

output reg [9:0] xCounter;

output reg [9:0] yCounter;



reg HSync;

reg VSync;



integer HFront = 640;//640

integer hSync = 655;//655

integer HBack = 747;//747

integer maxH = 793;//793



integer VFront = 480;//480

integer vSync = 490;//490

integer VBack = 492;//492

integer maxV = 525;//525



always @(posedge VGA_clk)

begin		

	if(xCounter == maxH)

	begin

		xCounter <= 0;

		if(yCounter === maxV)

			yCounter <= 0;

		else

			yCounter <= yCounter +1;

	end

	else

	begin

		xCounter <= xCounter + 1;

	end

	DisplayArea <= ((xCounter < HFront) && (yCounter < VFront));

	HSync <= ((xCounter >= hSync) && (xCounter < HBack));

	VSync <= ((yCounter >= vSync) && (yCounter < VBack));

end



assign VGA_Vsync = ~VSync;

assign VGA_Hsync = ~HSync;

assign blank_n = DisplayArea;



endmodule



/////////////////////////////////////////////////////////////////// ball speed

module updateCLK(clk, update);

input clk;

output reg update;

reg[21:0]count;



always @(posedge clk)

begin

	count <= count + 1;

	if(count == 150000)

	begin

		update <= ~update;

		count <= 0;

	end

end

endmodule



/////////////////////////////////////////////////////////////////// paddle speed

module updatePaddleCLK(clk, updatePad);

input clk;

output reg updatePad;

reg[21:0]count;



always @(posedge clk)

begin

	count <= count + 1;

	if(count == 100000)

	begin

		updatePad <= ~updatePad;

		count <= 0;

	end

end

endmodule

/////////////////////////////////////////////////////////////////// reduce clk from 50MHz to 25MHz
module clk_reduce(clk, VGA_clk);

	input clk;
	output reg VGA_clk;
	reg a;

	always @(posedge clk)
	begin
		a <= ~a; 
		VGA_clk <= a;
	end
endmodule

////////////////////////////////////////////////////////////////// decide which direction the paddle will move based off of user input
module kbInput(KB_clk,key,direction);
	input KB_clk;
	input [1:0]key;
	output reg [2:0]direction;

	always @(KB_clk)
	begin	
		if(key[1] == 1'b1 && key[0] == 1'b0)
			direction = 3'd1;//right
		else if(key[0] == 1'b1 & key[1] == 1'b0)
			direction = 3'd2;//left
		else
			direction = 3'd0;//stationary
	end
endmodule