module Phase_2(clk, rst, key, start_game, DAC_clk, VGA_R, VGA_G, VGA_B, VGA_Hsync,VGA_Vsync, blank_n, KB_clk, data,begin_game, score, 
	start_angle45, start_angle90, start_angle135, as,bs,cs,ds,es,fs,gs,al,bl,cl,dl,el,fl,gl,aS,bS,cS,dS,eS,fS,gS,dL,eL,fL);
					
input clk, rst;
input KB_clk, data;
input [1:0]key;
input start_game;
input start_angle45, start_angle90, start_angle135; //user decides at which angle the ball starts (diagonally left (135, SW17) straight up (90, SW16) diagonally right (45, SW15) 
input begin_game;

output VGA_Hsync;
output VGA_Vsync;
output DAC_clk;
output blank_n;
output as,bs,cs,ds,es,fs,gs,al,bl,cl,dl,el,fl,gl,aS,bS,cS,dS,eS,fS,gS,dL,eL,fL;
output [3:0]score;

output reg [7:0]VGA_R;
output reg [7:0]VGA_G;
output reg [7:0]VGA_B;

reg R;
reg G;
reg B;
reg trigger;
reg [1:0]level;
reg border;
reg game_over;
reg win_game;
reg lastDirection;
reg status_lose,status_win;
reg [3:0]score;
reg [10:0]x_pad, y_pad; //the top left point of the paddle
reg [10:0]x_ball,y_ball; //the top right of the ball
reg [10:0]x_block1,x_block2,x_block3,x_block4,x_block5,x_block6,x_block7,x_block8,x_block9,x_block10,x_block11; //top right corner of block
reg [10:0]y_block1,y_block2,y_block3,y_block4,y_block5,y_block6,y_block7,y_block8,y_block9,y_block10,y_block11;
reg [10:0]x_left_border, y_left_border;
reg [10:0]x_screen_border, y_screen_border;

wire update;
wire updatePad;
wire VGA_clk;
wire displayArea;
wire paddle;
wire ball;
wire block1,block2,block3,block4,block5,block6,block7,block8,block9,block10,block11;
wire screen_border;
wire [10:0]xCounter;
wire [10:0]yCounter;
wire [2:0]direction;

//instantiate modules
kbInput keyboard(KB_clk, key, direction); //the "keyboard", aka the buttons
updateCLK clk_updateCLK(clk, update); // ball clock
updatePaddleCLK clk_updatePaddleCLK(clk, updatePad); // paddle clock'
clk_reduce reduce(clk, VGA_clk);
VGA_generator generator(VGA_clk, VGA_Hsync, VGA_Vsync, DisplayArea, xCounter, yCounter, blank_n);
display score_display(score,as,bs,cs,ds,es,fs,gs); // Score # Display
display scoreS_display(4'd5,aS,bS,cS,dS,eS,fS,gS); // Score # Display
display level_Display(level,al,bl,cl,dl,el,fl,gl); // Level # Display

assign dL = 1'd0;
assign eL = 1'd0;
assign fL = 1'd0;

assign DAC_clk = VGA_clk; //DON'T DELETE. this allows the clock on the board to sync with the vga (allowing things to shop up on the monitor)

assign paddle = (xCounter >= x_pad && xCounter <= x_pad + 11'd80 && yCounter >= y_pad && yCounter <= y_pad + 11'd15); // sets the size of the paddle
assign ball   = (xCounter >= x_ball && xCounter <= x_ball + 11'd20 && yCounter >= y_ball && yCounter <= y_ball + 11'd20); // sets the size of the ball
assign screen_border = (xCounter >= x_screen_border && xCounter <= x_screen_border + 11'd600 && yCounter >= y_screen_border && yCounter <= y_screen_border + 11'd440);

// Create nine blocks
assign block1 = (xCounter >= x_block1 && xCounter <= x_block1 + 11'd80 && yCounter >= y_block1 && yCounter <= y_block1 + 11'd30);
assign block2 = (xCounter >= x_block2 && xCounter <= x_block2 + 11'd80 && yCounter >= y_block2 && yCounter <= y_block2 + 11'd30);
assign block3 = (xCounter >= x_block3 && xCounter <= x_block3 + 11'd80 && yCounter >= y_block3 && yCounter <= y_block3 + 11'd30);
assign block4 = (xCounter >= x_block4 && xCounter <= x_block4 + 11'd80 && yCounter >= y_block4 && yCounter <= y_block4 + 11'd30);
assign block5 = (xCounter >= x_block5 && xCounter <= x_block5 + 11'd80 && yCounter >= y_block5 && yCounter <= y_block5 + 11'd30);
assign block6 = (xCounter >= x_block6 && xCounter <= x_block6 + 11'd80 && yCounter >= y_block6 && yCounter <= y_block6 + 11'd30);
assign block7 = (xCounter >= x_block7 && xCounter <= x_block7 + 11'd80 && yCounter >= y_block7 && yCounter <= y_block7 + 11'd30);
assign block8 = (xCounter >= x_block8 && xCounter <= x_block8 + 11'd80 && yCounter >= y_block8 && yCounter <= y_block8 + 11'd30);
assign block9 = (xCounter >= x_block9 && xCounter <= x_block9 + 11'd80 && yCounter >= y_block9 && yCounter <= y_block9 + 11'd30);

// Create the level two blocks
assign block10 = (xCounter >= x_block10 && xCounter <= x_block10 + 11'd80 && yCounter >= y_block10 && yCounter <= y_block10 + 11'd15);
assign block11 = (xCounter >= x_block11 && xCounter <= x_block11 + 11'd80 && yCounter >= y_block11 && yCounter <= y_block11 + 11'd15);

///////////////////////////////////////////////////////////////////////////////FSM for collisions
reg [10:0]S;
reg [10:0]NS;
parameter before1 = 11'd0, start = 11'd1, ball_move_up = 11'd2, collision = 11'd3, ball_move_down = 11'd4, end_game = 11'd5, 
			 ball_move_45 = 11'd6, ball_move_135 = 11'd7, ball_move_225 = 11'd8, ball_move_315 = 11'd9, before2 = 11'd10, ball_move_up2 = 11'd11, 
			 ball_move_down2 = 11'd12, end_game2 = 11'd13, ball_move_452 = 11'd14, ball_move_1352 = 11'd15, ball_move_2252 = 11'd16, ball_move_3152 = 11'd17, 
			 ball_move_180 = 11'd18, ball_move_1802 = 11'd19, ball_move_0 = 11'd20, ball_move_02 = 11'd21, before3 = 11'd22, ball_move_up3 = 11'd23, 
			 ball_move_down3 = 11'd24, end_game3 = 11'd25, ball_move_453 = 11'd26, ball_move_1353 = 11'd27, ball_move_2253 = 11'd28, ball_move_3153 = 11'd29;

// Check if the ball hits a brick from the top or bottom
wire hit_block1;
assign hit_block1 = (((y_block1 + 11'd30 == y_ball) || (y_block1 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block1) && (x_ball <= x_block1 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block2;
assign hit_block2 = (((y_block2 + 11'd30 == y_ball) || (y_block2 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block2) && (x_ball <= x_block2 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block3;
assign hit_block3 = (((y_block3 + 11'd30 == y_ball) || (y_block3 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block3) && (x_ball <= x_block3 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block4;
assign hit_block4 = (((y_block4 + 11'd30 == y_ball) || (y_block4 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block4) && (x_ball <= x_block4 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block5;
assign hit_block5 = (((y_block5 + 11'd30 == y_ball) || (y_block5 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block5) && (x_ball <= x_block5 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block6;
assign hit_block6 = (((y_block6 + 11'd30 == y_ball) || (y_block6 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block6) && (x_ball <= x_block6 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block7;
assign hit_block7 = (((y_block7 + 11'd30 == y_ball) || (y_block7 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block7) && (x_ball <= x_block7 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block8;
assign hit_block8 = (((y_block8 + 11'd30 == y_ball) || (y_block8 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block8) && (x_ball <= x_block8 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block9;
assign hit_block9 = (((y_block9 + 11'd30 == y_ball) || (y_block9 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block9) && (x_ball <= x_block9 + 11'd80))) ? 1'b1 : 1'b0;

// Check if the ball hits a level two brick from the top or bottom
wire hit_block10;
assign hit_block10 = (((y_block10 + 11'd15 == y_ball) || (y_block10 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block10) && (x_ball <= x_block10 + 11'd80))) ? 1'b1 : 1'b0;
wire hit_block11;
assign hit_block11 = (((y_block11 + 11'd15 == y_ball) || (y_block11 == y_ball + 11'd20)) && ((x_ball + 11'd20 >= x_block11) && (x_ball <= x_block11 + 11'd80))) ? 1'b1 : 1'b0;

// Check if the ball hits a brick from the left or the right
wire hit_side_block1;
assign hit_side_block1 = (((x_block1 == x_ball + 11'd20) || (x_ball == x_block1 + 11'd80)) && ((y_ball + 11'd20 > y_block1) && (y_ball < y_block1 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block2;
assign hit_side_block2 = (((x_block2 == x_ball + 11'd20) || (x_ball == x_block2 + 11'd80)) && ((y_ball + 11'd20 > y_block2) && (y_ball < y_block2 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block3;
assign hit_side_block3 = (((x_block3 == x_ball + 11'd20) || (x_ball == x_block3 + 11'd80)) && ((y_ball + 11'd20 > y_block3) && (y_ball < y_block3 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block4;
assign hit_side_block4 = (((x_block4 == x_ball + 11'd20) || (x_ball == x_block4 + 11'd80)) && ((y_ball + 11'd20 > y_block4) && (y_ball < y_block4 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block5;
assign hit_side_block5 = (((x_block5 == x_ball + 11'd20) || (x_ball == x_block5 + 11'd80)) && ((y_ball + 11'd20 > y_block5) && (y_ball < y_block5 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block6;
assign hit_side_block6 = (((x_block6 == x_ball + 11'd20) || (x_ball == x_block6 + 11'd80)) && ((y_ball + 11'd20 > y_block6) && (y_ball < y_block6 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block7;
assign hit_side_block7 = (((x_block7 == x_ball + 11'd20) || (x_ball == x_block7 + 11'd80)) && ((y_ball + 11'd20 > y_block7) && (y_ball < y_block7 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block8; 
assign hit_side_block8 = (((x_block8 == x_ball + 11'd20) || (x_ball == x_block8 + 11'd80)) && ((y_ball + 11'd20 > y_block8) && (y_ball < y_block8 + 11'd30))) ? 1'b1 : 1'b0;
wire hit_side_block9;
assign hit_side_block9 = (((x_block9 == x_ball + 11'd20) || (x_ball == x_block9 + 11'd80)) && ((y_ball + 11'd20 > y_block9) && (y_ball < y_block9 + 11'd30))) ? 1'b1 : 1'b0;

// Check if the ball hits a level two brick from the left or right
wire hit_side_block10;
assign hit_side_block10 = (((x_block10 == x_ball + 11'd20) || (x_ball == x_block10 + 11'd80)) && ((y_ball + 11'd20 >= y_block10) && (y_ball <= y_block10 + 11'd15))) ? 1'b1 : 1'b0;
wire hit_side_block11;
assign hit_side_block11 = (((x_block11 == x_ball + 11'd20) || (x_ball == x_block11 + 11'd80)) && ((y_ball + 11'd20 >= y_block11) && (y_ball <= y_block11 + 11'd15))) ? 1'b1 : 1'b0;

// Paddle hits
wire paddle_hit; // checks any pixel of the ball overlaps with the top of the paddle
assign paddle_hit = (((y_ball + 11'd20) == y_pad) && ((x_ball + 11'd20 > x_pad) && (x_ball + 11'd20 < x_pad + 11'd99)))  ? 1'b1 : 1'b0;
wire paddle_hit_left_corner; // check if the bottom right corner of the ball directly hits the top left corner of the paddle
assign paddle_hit_left_corner = ((y_ball + 11'd20 == y_pad) && (x_ball + 11'd20 == x_pad)) ? 1'd1 : 1'd0; 
wire paddle_hit_right_corner; // check if the bottom left corner of the ball directly hits the top right corner of the paddle
assign paddle_hit_right_corner = ((y_ball + 11'd20 == y_pad) && (x_ball == x_pad + 11'd80)) ? 1'd1 : 1'd0; 

wire hit_me; // checks if the ball has hit the top of the screen
assign hit_me = (y_ball == y_screen_border) ? 1'b1 : 1'b0;
wire hit_me_low; // checks if a ball flew off the bottom of the screen
assign hit_me_low = (y_ball == y_screen_border + 11'd420) ? 1'b1 : 1'b0;

// Check if the ball hits a wall or the sides of the paddle
wire hit_side_left;
assign hit_side_left = ((x_ball == x_screen_border) || ((x_ball == x_pad + 11'd80) && (y_ball + 11'd20 > y_pad))) ? 1'b1 : 1'b0;
wire hit_side_right;
assign hit_side_right = ((x_ball == x_screen_border + 11'd580) || ((x_ball + 11'd20 == x_pad) && (y_ball + 11'd20 > y_pad))) ? 1'b1 : 1'b0;

//////////////////////////////////////////reset
always @(posedge update or negedge rst)
begin
	if(rst == 1'd0)
		S <= before1;
	else
		S <= NS;
end

////////////////////////////////////////state transitions
always @(*)
begin
	case (S)
	
		//////////////////////////////////////// Level 1
		
		before1:
		begin
			if(start_game == 1'b1 && rst == 1'd1 && begin_game == 1'd1) ///makes the ball move
			begin
				if(start_angle45 == 1'd1)
					NS = ball_move_45;
				else if (start_angle90 == 1'd1)
					NS = ball_move_up;
				else
					NS = ball_move_135;
			 end	
			else
				NS = before1;
		end	

		ball_move_up:
		begin
			// If the ball hits one of the blocks, move down. Otherwise, continue to move up
			if((hit_block1 == 1'd1 || hit_block2 == 1'd1 || hit_block3 == 1'd1 || hit_block4 == 1'd1 || hit_block5 == 1'd1 || 
				hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1) || hit_me == 1'd1)
				NS = ball_move_down;
			else
				NS = ball_move_up;
		end
			
		ball_move_down:
		begin	
			if(hit_me_low == 1'b1)
				NS = end_game;
			else if(paddle_hit == 1'd1)
			begin
				if((x_ball > x_pad + 11'd60) || (paddle_hit_right_corner == 1'd1)) // Ball hits the right edge of the paddle
					NS = ball_move_45;
				else if((x_ball < x_pad) || (paddle_hit_left_corner == 1'd1)) // Ball hits the left edge of the paddle
					NS = ball_move_135;
				else if((x_ball >= x_pad) && (x_ball + 20 <= x_pad + 11'd80)) // Ball hits the center of the paddle
					NS = ball_move_up;
				else
					NS = ball_move_down;
			end
			else
				NS = ball_move_down;
		end
		
		ball_move_45:
		begin
			if(score == 4'd9)
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
			if(score == 4'd9)
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
			if(hit_me_low == 1'b1 || score == 4'd9)
				NS = end_game;
			else if(paddle_hit_right_corner == 1'd1)
				NS = ball_move_45;
			else if(hit_side_left == 1'b1)
				NS = ball_move_315;
			else if(paddle_hit == 1'b1)
				NS = ball_move_135;
			else if(hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_135;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_315;
			else
				NS = ball_move_225;
		end
		
		ball_move_315:
		begin
			if(hit_me_low == 1'b1 || score == 4'd9)
				NS = end_game;
			else if(paddle_hit_left_corner == 1'd1)
				NS = ball_move_135;
			else if(hit_side_right == 1'b1)
				NS = ball_move_225;
			else if(paddle_hit == 1'b1)
				NS = ball_move_45;
			else if(hit_block6 == 1'd1 || hit_block7 == 1'd1 || hit_block8 == 1'd1 || hit_block9 == 1'd1)
				NS = ball_move_45;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'd1 || hit_side_block3 == 1'd1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1)
				NS = ball_move_225;
			else 
				NS = ball_move_315;
		end
		
		end_game: 
		begin
			if(status_win == 1'd1 && start_game == 1'd0 && begin_game == 1'd1)
				NS = before2;	
			else if(status_lose == 1'd1 && start_game == 1'd0 && begin_game == 1'd1)
				NS = before1;
			else
				NS = end_game;
		end
			
		//////////////////////////////////////// Level 2
		
		before2:
		begin
			if(start_game == 1'b1) ///makes the ball move
			begin
				if(start_angle45 == 1'd1)
					NS = ball_move_452;
				else if(start_angle90 == 1'd1)
					NS = ball_move_up2;
				else
					NS = ball_move_1352;
			end	
			else
				NS = before2;
		end	

		ball_move_up2:
		begin
			if(hit_me == 1'd1)
				NS = ball_move_down2;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'b1 || hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1 || hit_block11 == 1'd1)
				NS = ball_move_down2;
			else
				NS = ball_move_up2;
		end
			
		ball_move_down2:
		begin	
			if(hit_me_low == 1'b1)
				NS = end_game2;
			else if(paddle_hit == 1'b1)
			begin
				if((x_ball > x_pad + 11'd60) || (paddle_hit_right_corner == 1'd1)) // Ball hits the right edge of the paddle
					NS = ball_move_452;
				else if((x_ball < x_pad) || (paddle_hit_left_corner == 1'd1)) // Ball hits the left edge of the paddle
					NS = ball_move_1352;
				else if((x_ball >= x_pad) && (x_ball + 11'd20 <= x_pad + 11'd80)) // Ball hits the center of the paddle
					NS = ball_move_up2;
				else
					NS = ball_move_down2;
			end
			else
				NS = ball_move_down2;
		end
		
		ball_move_452:
		begin
			if(score == 4'd8)
				NS = end_game2;
			else if(hit_me == 1'd1)
				NS = ball_move_3152;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'd1 
				|| hit_block8 == 1'd1 || hit_block9 == 1'd1 || hit_block10 == 1'd1 || hit_block11 == 1'd1)
				NS = ball_move_3152;
			else if(hit_side_right == 1'b1)
				NS = ball_move_1352;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || 
				hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1 || hit_side_block10 == 1'd1 || hit_side_block11 == 1'd1)
				NS = ball_move_1352;	
			else
				NS = ball_move_452;
		end
		
		ball_move_1352:
		begin
			if(score == 4'd8)
				NS = end_game2;
			else if(hit_side_left == 1'b1)
				NS = ball_move_452;
			else if(hit_me == 1'd1)
				NS = ball_move_2252;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'b1 || 
				hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1 || hit_block11 == 1'd1)
				NS = ball_move_2252;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1 || hit_side_block11 == 1'd1)
				NS = ball_move_452;
			else
				NS = ball_move_1352;
		end
		
		ball_move_2252:
		begin
			if(hit_me_low == 1'b1 || score == 4'd8)
				NS = end_game2;
			else if(paddle_hit_right_corner == 1'b1)
				NS = ball_move_452;
			else if(paddle_hit == 1'b1)
				NS = ball_move_1352;
			else if(hit_block6 == 1'b1 || hit_block7 == 1'b1 || hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1 || hit_block11 == 1'd1)
				NS = ball_move_1352;
			else if(hit_side_left == 1'b1)
				NS = ball_move_3152;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1 || hit_side_block11 == 1'd1)
				NS = ball_move_3152;
			else
				NS = ball_move_2252;
		end
		
		ball_move_3152:
		begin
			if(hit_me_low == 1'b1 || score == 4'd8)
				NS = end_game2;
			else if(paddle_hit_left_corner == 1'b1)
				NS = ball_move_1352;
			else if(hit_side_right == 1'b1)
				NS = ball_move_2252;
			else if(paddle_hit == 1'b1)
				NS = ball_move_452;
			else if(hit_block6 == 1'b1 || hit_block7 == 1'b1 || hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1 || hit_block11 == 1'd1)
				NS = ball_move_452;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1 || hit_side_block11 == 1'd1)
				NS = ball_move_2252;
			else 
				NS = ball_move_3152;
		end
		
		end_game2: 
		begin	
			if(status_win == 1'd1 && start_game == 1'd0 && begin_game == 1'd1)
				NS = before3;	
			else if(status_lose == 1'd1 && start_game == 1'd0 && begin_game == 1'd1)
				NS = before1;
			else
				NS = end_game2;
		end
		
		//////////////////////////////////////// Level 3
		
		before3:
		begin
			if(start_game == 1'b1) ///makes the ball move
			begin
				if(start_angle45 == 1'd1)
					NS = ball_move_453;
				else if(start_angle90 == 1'd1)
					NS = ball_move_up3;
				else
					NS = ball_move_1353;
			end	
			else
				NS = before3;
		end	

		ball_move_up3:
		begin
			if(hit_me == 1'd1)
				NS = ball_move_down3;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'b1 
				|| hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1)
				NS = ball_move_down3;
			else if(hit_side_block10)
			begin
				if(x_block10 + 11'd80 == x_ball)
				begin
					NS = ball_move_453;
				end
				else
				begin
					NS = ball_move_1353;
				end
			end
			else
				NS = ball_move_up3;
		end
			
		ball_move_down3:
		begin	
			if(hit_me_low == 1'b1)
				NS = end_game3;
			else if(hit_side_block10)
			begin
				if(x_block10 + 11'd80 == x_ball)
				begin
					NS = ball_move_3153;
				end
				else
				begin
					NS = ball_move_2253;
				end
			end
			else if(paddle_hit == 1'b1)
			begin
				if((x_ball > x_pad + 11'd60) || (paddle_hit_right_corner == 1'd1)) // Ball hits the right edge of the paddle
					NS = ball_move_453;
				else if((x_ball < x_pad) || (paddle_hit_left_corner == 1'd1)) // Ball hits the left edge of the paddle
					NS = ball_move_1353;
				else if((x_ball >= x_pad) && (x_ball + 11'd20 <= x_pad + 11'd80)) // Ball hits the center of the paddle
					NS = ball_move_up3;
				else
					NS = ball_move_down3;
			end
			else
				NS = ball_move_down3;
		end
		
		ball_move_453:
		begin
			if(score == 4'd8)
				NS = end_game3;
			else if(hit_me == 1'd1)
				NS = ball_move_3153;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'd1 
				|| hit_block8 == 1'd1 || hit_block9 == 1'd1 || hit_block10 == 1'd1)
				NS = ball_move_3153;
			else if(hit_side_right == 1'b1)
				NS = ball_move_1353;
			else if(hit_side_block1 == 1'd1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'd1 || hit_side_block5 == 1'd1 || 
				hit_side_block6 == 1'd1 || hit_side_block7 == 1'd1 || hit_side_block8 == 1'd1 || hit_side_block9 == 1'd1 || hit_side_block10 == 1'd1)
				NS = ball_move_1353; 
			else
				NS = ball_move_453;
		end
		
		ball_move_1353:
		begin
			if(score == 4'd8)
				NS = end_game3;
			else if(hit_side_left == 1'b1)
				NS = ball_move_453;
			else if(hit_me == 1'd1)
				NS = ball_move_2253;
			else if(hit_block1 == 1'b1 || hit_block2 == 1'b1 || hit_block3 == 1'b1 || hit_block4 == 1'b1 || hit_block5 == 1'b1 || hit_block6 == 1'b1 || hit_block7 == 1'b1 || 
				hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1)
				NS = ball_move_2253;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1)
				NS = ball_move_453;
			else
				NS = ball_move_1353;
		end
		
		ball_move_2253:
		begin
			if(hit_me_low == 1'b1 || score == 4'd8)
				NS = end_game3;
			else if(paddle_hit_right_corner == 1'b1)
				NS = ball_move_453;
			else if(paddle_hit == 1'b1)
				NS = ball_move_1353;
			else if(hit_block6 == 1'b1 || hit_block7 == 1'b1 || hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1)
				NS = ball_move_1353;
			else if(hit_side_left == 1'b1)
				NS = ball_move_3153;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1)
				NS = ball_move_3153;
			else
				NS = ball_move_2253;
		end
		
		ball_move_3153:
		begin
			if(hit_me_low == 1'b1 || score == 4'd8)
				NS = end_game3;
			else if(paddle_hit_left_corner == 1'b1)
				NS = ball_move_1353;
			else if(hit_side_right == 1'b1)
				NS = ball_move_2253;
			else if(paddle_hit == 1'b1)
				NS = ball_move_453;
			else if(hit_block6 == 1'b1 || hit_block7 == 1'b1 || hit_block8 == 1'b1 || hit_block9 == 1'b1 || hit_block10 == 1'd1)
				NS = ball_move_453;
			else if(hit_side_block1 == 1'b1 || hit_side_block2 == 1'b1 || hit_side_block3 == 1'b1 || hit_side_block4 == 1'b1 || hit_side_block5 == 1'b1 || 
				hit_side_block6 == 1'b1 || hit_side_block7 == 1'b1 || hit_side_block8 == 1'b1 || hit_side_block9 == 1'b1 || hit_side_block10 == 1'd1)
				NS = ball_move_2253;
			else 
				NS = ball_move_3153;
		end
		
		end_game3: 
		begin
			if(start_game == 1'd0 && begin_game == 1'd1)
				NS = before1;	
			else
				NS = end_game3;
		end
		
		default: NS = before1;
	endcase	
end

////////////////////////////////////////////state definitions
always @(posedge update or negedge rst)
begin
	if(rst == 1'd0)
	begin
		score = 4'd0;
	end
	else
	begin
		case(S)
			before1:
			begin
				// Set the game status controls
				status_lose <= 1'd0;
				status_win <= 1'd0;
				
				trigger <= 1'd0;
				score = 4'd0;
				level <= 2'd0;
				
				// Position the ball on the screen
				x_ball <= x_pad + 11'd30;
				y_ball <= 11'd424;
				
				// Position the blocks on the screen
				x_block1 <= 11'd116;
				y_block1 <= 11'd20;
				x_block2 <= 11'd198;
				y_block2 <= 11'd20;
				x_block3 <= 11'd280;
				y_block3 <= 11'd20;
				x_block4 <= 11'd362;
				y_block4 <= 11'd20;
				x_block5 <= 11'd444;
				y_block5 <= 11'd20;
				x_block6 <= 11'd157;
				y_block6 <= 11'd52;
				x_block7 <= 11'd239;
				y_block7 <= 11'd52;
				x_block8 <= 11'd321;
				y_block8 <= 11'd52;
				x_block9 <= 11'd403;
				y_block9 <= 11'd52;
				
				// Position the special level two blocks on the screen
				x_block10 <= 11'd50;
				y_block10 <= 11'd500;
				x_block11 <= 11'd550;
				y_block11 <= 11'd500;
				
				x_screen_border <= 11'd20;
				y_screen_border <= 11'd20;
			end
			
			ball_move_up:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball - 11'd1;
			end
			
			ball_move_down:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball + 11'd1;
			end
			
			ball_move_45:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball - 11'd1;
				x_ball <= x_ball + 11'd1;
			end
			
			ball_move_135:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball - 11'd1;
				x_ball <= x_ball - 11'd1;
			end
			
			ball_move_225:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball + 11'd1;
				x_ball <= x_ball - 11'd1;
			end
			
			ball_move_315:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				y_ball <= y_ball + 11'd1;
				x_ball <= x_ball + 11'd1;
			end				
			
			end_game: // wut ahh final reveal
			begin
				if(score == 4'd9)
				begin
					status_win <= 1'd1;
					level <= 2'd1;
				end
				else
					status_lose <= 1'd1;	
				trigger <= 1'd1;	
			end
			
			// Level 2
			
			before2:
			begin
				// Set the game status controls
				status_lose <= 1'd0;
				status_win <= 1'd0;
				
				trigger <= 1'd0;
				score <= 4'd0;
				level <= 2'd1;
				
				// Position the ball on the screen
				x_ball <= x_pad + 11'd30;
				y_ball <= 11'd424;
				
				// Position the blocks on the screen
				x_block1 <= 11'd116;
				y_block1 <= 11'd20;
				x_block2 <= 11'd198;
				y_block2 <= 11'd20;
				x_block3 <= 11'd280;
				y_block3 <= 11'd20;
				x_block4 <= 11'd362;
				y_block4 <= 11'd20;
				x_block5 <= 11'd444;
				y_block5 <= 11'd20;
				x_block6 <= 11'd157;
				y_block6 <= 11'd52;
				x_block7 <= 11'd239;
				y_block7 <= 11'd52;
				x_block8 <= 11'd321;
				y_block8 <= 11'd52;
				x_block9 <= 11'd403;
				y_block9 <= 11'd52;
				
				// Position the special level two block on the screen
				x_block10 <= 11'd120;
				y_block10 <= 11'd200;
				x_block11 <= 11'd420;
				y_block11 <= 11'd200;
				
				x_screen_border <= 11'd20;
				y_screen_border <= 11'd20;
			end
			
			ball_move_up2:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				else if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
				end
			end
			
			ball_move_down2:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				else if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
				end
				else 
				begin
					y_ball <= y_ball + 11'd1;
				end
			end
			
			ball_move_452:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
					x_ball <= x_ball + 11'd1;
				end
				else if(hit_side_block10 || hit_side_block11) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball - 11'd1;
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball + 11'd1;
				end
			end
			
			ball_move_1352:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
					x_ball <= x_ball - 11'd1;
				end
				else if(hit_side_block10 || hit_side_block11) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball + 11'd1;
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball - 11'd1;
				end
			end
			
			ball_move_2252:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball = y_ball - 11'd1;
					x_ball = x_ball - 11'd1;
				end
				else if(hit_side_block10 || hit_side_block11) // Scoot
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball + 11'd1;
				end
				else 
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball - 11'd1;
				end
			end
			
			ball_move_3152:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10 || hit_block11) // Scoot
				begin
					y_ball = y_ball - 11'd1;
					x_ball = x_ball + 11'd1;
				end
				else if(hit_side_block10 || hit_side_block11)
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball - 11'd1;
				end
				else 
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball + 11'd1;
				end
			end				
			
			end_game2: // wut ahh final reveal
			begin
				if(score == 4'd8)
				begin
					status_win <= 1'd1;
					level <= 2'd2;
				end
				else
					status_lose <= 1'd1;
				trigger <= 1'd1;
			end
			
			// Level 3
			
			before3:
			begin
				// Set the game status controls
				status_lose <= 1'd0;
				status_win <= 1'd0;
				
				trigger <= 1'd0;
				score <= 4'd0;
				level <= 2'd2;
				lastDirection = 1'd0;
				
				// Position the ball on the screen
				x_ball <= x_pad + 11'd30;
				y_ball <= 11'd424;
				
				// Position the blocks on the screen
				x_block1 <= 11'd116;
				y_block1 <= 11'd20;
				x_block2 <= 11'd198;
				y_block2 <= 11'd20;
				x_block3 <= 11'd280;
				y_block3 <= 11'd20;
				x_block4 <= 11'd362;
				y_block4 <= 11'd20;
				x_block5 <= 11'd444;
				y_block5 <= 11'd20;
				x_block6 <= 11'd157;
				y_block6 <= 11'd52;
				x_block7 <= 11'd239;
				y_block7 <= 11'd52;
				x_block8 <= 11'd321;
				y_block8 <= 11'd52;
				x_block9 <= 11'd403;
				y_block9 <= 11'd52;
				
				// Position the special level two block on the screen
				x_block10 <= 11'd120;
				y_block10 <= 11'd200;
				x_block11 <= 11'd440;
				y_block11 <= 11'd500;
				
				x_screen_border <= 11'd20;
				y_screen_border <= 11'd20;
			end
			
			ball_move_up3:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				else if(hit_block10) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
				end
				else if(hit_side_block10)
				begin
					if(x_block10 + 11'd80 == x_ball)
					begin
						x_ball = x_ball + 1'd4;
						y_ball = y_ball - 1'd4;
					end
					else
					begin
						x_ball = x_ball - 1'd4;
						y_ball = y_ball - 1'd4;
					end
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border)
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end
			
			ball_move_down3:
			begin
				// Check if the ball hit a brick, then delete that brick
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				else if(hit_block10) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
				end
				else if(hit_side_block10)
				begin
					if(x_block10 + 11'd80 == x_ball)
					begin
						x_ball <= x_ball + 1'd4;
						y_ball <= y_ball + 1'd4;
					end
					else
					begin
						x_ball <= x_ball - 1'd4;
						y_ball <= y_ball + 1'd4;
					end
				end
				else 
				begin
					y_ball <= y_ball + 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border) // Move to the left
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end
			
			ball_move_453:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
					x_ball <= x_ball + 11'd1;
				end
				else if(hit_side_block10) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball - 11'd1;
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball + 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border) // Move to the left
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end
			
			ball_move_1353:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10) // Scoot
				begin
					y_ball <= y_ball + 11'd1;
					x_ball <= x_ball - 11'd1;
				end
				else if(hit_side_block10) // Scoot
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball + 11'd1;
				end
				else 
				begin
					y_ball <= y_ball - 11'd1;
					x_ball <= x_ball - 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border) // Move to the left
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end
			
			ball_move_2253:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10) // Scoot
				begin
					y_ball = y_ball - 11'd1;
					x_ball = x_ball - 11'd1;
				end
				else if(hit_side_block10) // Scoot
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball + 11'd1;
				end
				else 
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball - 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border) // Move to the left
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end
			
			ball_move_3153:
			begin
				if(hit_block1 || hit_side_block1) // Delete block 1
				begin
					x_block1 = 11'd700;
					y_block1 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block2 || hit_side_block2) // Delete block 2
				begin
					x_block2 = 11'd700;
					y_block2 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block3 || hit_side_block3) // Delete block 3
				begin
					x_block3 = 11'd700;
					y_block3 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block4 || hit_side_block4) // Delete block 4
				begin
					x_block4 = 11'd700;
					y_block4 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block5 || hit_side_block5) // Delete block 5
				begin
					x_block5 = 11'd700;
					y_block5 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block6 || hit_side_block6) // Delete block 6
				begin
					x_block6 = 11'd700;
					y_block6 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block7 || hit_side_block7) // Delete block 7
				begin
					x_block7 = 11'd700;
					y_block7 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block8 || hit_side_block8) // Delete block 8
				begin
					x_block8 = 11'd700;
					y_block8 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block9 || hit_side_block9) // Delete block 9
				begin
					x_block9 = 11'd700;
					y_block9 = 11'd500;
					score = score + 4'd1;
				end
				if(hit_block10) // Scoot
				begin
					y_ball = y_ball - 11'd1;
					x_ball = x_ball + 11'd1;
				end
				else if(hit_side_block10)
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball - 11'd1;
				end
				else 
				begin
					y_ball = y_ball + 11'd1;
					x_ball = x_ball + 11'd1;
				end
				if(lastDirection == 1'd1) // Move to the right
					x_block10 = x_block10 + 11'd1;
				else
					x_block10 = x_block10 - 11'd1;
				if(x_block10 == x_screen_border) // Move to the left
					lastDirection = 1'd1;
				if(x_block10 + 11'd80 == x_screen_border + 11'd600)
					lastDirection = 1'd0;
			end				
			
			end_game3: // wut ahh final reveal
			begin
				if(score >= 4'd8)
					status_win <= 1'd1;
				else
					status_lose <= 1'd1;
				trigger <= 1'd1;
			end
		endcase	
	end
end

// Position the paddle
always @(posedge updatePad or negedge rst)
begin
	if(rst == 1'd0) // If the reset is pressed place the paddle in the center of the screen
	begin
		x_pad <= 11'd280; 
		y_pad <= 11'd445;
	end
	else if(trigger == 1'd1) // If the user wins or loses and decides to replay the game, the trigger resets the paddle position
	begin
		x_pad <= 11'd280; 
		y_pad <= 11'd445;
	end
	else
	begin
		case(direction) // Push Buttons Key[1] and KEY[0] control the direction that the paddle will move
			3'd1: 
				if(x_pad <= 11'd540)
					x_pad <= x_pad + 11'd1; // Paddle increments right at a speed of "1"			
				else
					x_pad <= 11'd540;
			3'd2: 
				if(x_pad >= 11'd20)
					x_pad <= x_pad - 11'd1; // Paddle increments left at a speed of "1"
				else
					x_pad <= 11'd20;
			default: x_pad <= x_pad;
		endcase
	end
end

always @(posedge VGA_clk) //border and color
begin
	border <= (((xCounter >= 11'd0) && (xCounter < 11'd11) || (xCounter >= 11'd630) && (xCounter < 11'd641)) 
		|| ((yCounter >= 11'd0) && (yCounter < 11'd11) || (yCounter >= 11'd470) && (yCounter < 11'd481)));
	VGA_R = {8{R}};
	VGA_G = {8{G}};
	VGA_B = {8{B}};
end

///////////////////////////////////////////////////////////////////////// Screen decision
reg [3:0]NS_Screen,S_Screen;
parameter SS = 4'd0,RSNR = 4'd1,RSR = 4'd2,L = 4'd3,W = 4'd4,SS2 = 4'd5,RSNR2 = 4'd6,RSR2 = 4'd7,SS3 = 4'd8,RSNR3 = 4'd9,RSR3 = 4'd10;

always @(posedge clk or negedge rst)
begin
	// If the game is reset, stay on teh start screen, otherwise, go to the next decided screen state
	if(rst == 1'd0)
		S_Screen <= SS;
	else
		S_Screen <= NS_Screen;
end

always @(*)
begin
	case(S_Screen)
		SS: // "START GAME"
			if(begin_game == 1'd1 && rst == 1'd1)
				NS_Screen = RSNR;
			else
				NS_Screen = SS;
				
		RSNR: // Run Screen No Run
			if(start_game == 1'd1)
				NS_Screen = RSR;
			else
				NS_Screen = RSNR;
				
		RSR: // Run Screen Run
			if(status_win == 1'd1)
				NS_Screen = SS2;
			else if(status_lose == 1'd1)
				NS_Screen = L;
			else
				NS_Screen = RSR;
				
		SS2: // "LEVEL UP"
			if(begin_game == 1'd1 && start_game == 1'd0)
				NS_Screen = RSNR2;
			else 
				NS_Screen = SS2;
		
		RSNR2: // Level 2 Run Screen No Run
			if(start_game == 1'd1)
				NS_Screen = RSR2;
			else
				NS_Screen = RSNR2;
		
		RSR2: // Level 2 Run Screen Run
			if(status_win == 1'd1)
				NS_Screen = SS3;
			else if(status_lose == 1'd1)
				NS_Screen = L;
			else
				NS_Screen = RSR2;
				
		SS3: // "LEVEL UP"
			if(begin_game == 1'd1 && start_game == 1'd0)
				NS_Screen = RSNR3;
			else 
				NS_Screen = SS3;
		
		RSNR3: // Level 3 Run Screen No Run
			if(start_game == 1'd1)
				NS_Screen = RSR3;
			else
				NS_Screen = RSNR3;
		
		RSR3: // Level 3 Run Screen Run
			if(status_win == 1'd1)
				NS_Screen = W;
			else if(status_lose == 1'd1)
				NS_Screen = L;
			else
				NS_Screen = RSR3;
		
		L: // "LOSER!"
			if(begin_game == 1'd1 && start_game == 1'b0)
				NS_Screen = SS;
			else
				NS_Screen = L;
				
		W: // "WINNER!"
			if(begin_game == 1'd1 && start_game == 1'b0)
				NS_Screen = SS;
			else
				NS_Screen = W;
				
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
		
		SS2:
		begin
			R <= 1'd0;
			B <= 1'd1 && ~row_level0[0] && ~row_level0[1] && ~row_level0[2] && ~row_level0[3] && ~row_level0[4] && ~row_level0[5] && ~row_level0[6] && ~row_level1[0] 
				&& ~row_level1[1] && ~row_level1[2] && ~row_level1[3] && ~row_level1[4] && ~row_level1[5] && ~row_level1[6] && ~row_level2[0] && ~row_level2[1] && 
				~row_level2[2] && ~row_level2[3] && ~row_level2[4] && ~row_level2[5] && ~row_level2[6] && ~row_level3[0] && ~row_level3[1] && ~row_level3[2] && 
				~row_level3[3] && ~row_level3[4] && ~row_level3[5] && ~row_level3[6] && ~row_level4[0] && ~row_level4[1] && ~row_level4[2] && ~row_level4[3] && 
				~row_level4[4] && ~row_level4[5] && ~row_level4[6];
			G <= 1'd0;
		end
		
		RSNR2:
		begin
			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
			B <= screen_border && ~paddle && ~block10 && ~block11 && 1'b1;
			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~block10 && ~block11 && 1'b1;
		end
		
		RSR2:
		begin
			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
			B <= screen_border && ~paddle && ~block10 && ~block11 && 1'b1;
			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~block10 && ~block11 && 1'b1;
		end
		
		SS3:
		begin
			R <= 1'd0;
			B <= 1'd1 && ~row_level0[0] && ~row_level0[1] && ~row_level0[2] && ~row_level0[3] && ~row_level0[4] && ~row_level0[5] && ~row_level0[6] && ~row_level1[0] 
				&& ~row_level1[1] && ~row_level1[2] && ~row_level1[3] && ~row_level1[4] && ~row_level1[5] && ~row_level1[6] && ~row_level2[0] && ~row_level2[1] && 
				~row_level2[2] && ~row_level2[3] && ~row_level2[4] && ~row_level2[5] && ~row_level2[6] && ~row_level3[0] && ~row_level3[1] && ~row_level3[2] && 
				~row_level3[3] && ~row_level3[4] && ~row_level3[5] && ~row_level3[6] && ~row_level4[0] && ~row_level4[1] && ~row_level4[2] && ~row_level4[3] && 
				~row_level4[4] && ~row_level4[5] && ~row_level4[6];
			G <= 1'd0;
		end
		
		RSNR3:
		begin
			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
			B <= screen_border && ~paddle && ~block10 && 1'b1;
			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~block10 && 1'b1;
		end
		
		RSR3:
		begin
			R <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~ball && 1'b1;
			B <= screen_border && ~paddle && ~block10 && 1'b1;
			G <= screen_border && ~paddle && ~block1 && ~block2 && ~block3 && ~block4 && ~block5 && ~block6 && ~block7 && ~block8 && ~block9 && ~block10 && 1'b1;
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
//assign row_Lose3[5] = 1'd0;
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
// Level Up Screen
wire [6:0]row_level0,row_level1,row_level2,row_level3,row_level4;
// Row 0
assign row_level0[0] = (xCounter >= 11'd200 && xCounter <= 11'd209) && (yCounter >= 11'd220 && yCounter <= 11'd229);// L
assign row_level0[1] = (xCounter >= 11'd232 && xCounter <= 11'd259) && (yCounter >= 11'd220 && yCounter <= 11'd229);// E
assign row_level0[2] = ((xCounter >= 11'd264 && xCounter <= 11'd273) || (xCounter >= 11'd300 && xCounter <= 11'd309)) && (yCounter >= 11'd220 && yCounter <= 11'd229);// V
assign row_level0[3] = (xCounter >= 11'd314 && xCounter <= 11'd341) && (yCounter >= 11'd220 && yCounter <= 11'd229);// E
assign row_level0[4] = (xCounter >= 11'd346 && xCounter <= 11'd355) && (yCounter >= 11'd220 && yCounter <= 11'd229);// L
assign row_level0[5] = ((xCounter >= 11'd383 && xCounter <= 11'd392) || (xCounter >= 11'd401 && xCounter <= 11'd410)) && (yCounter >= 11'd220 && yCounter <= 11'd229);// U
assign row_level0[6] = (xCounter >= 11'd415 && xCounter <= 11'd442) && (yCounter >= 11'd220 && yCounter <= 11'd229);// P
// Row 1
assign row_level1[0] = (xCounter >= 11'd200 && xCounter <= 11'd209) && (yCounter >= 11'd229 && yCounter <= 11'd238);// L
assign row_level1[1] = (xCounter >= 11'd232 && xCounter <= 11'd241) && (yCounter >= 11'd229 && yCounter <= 11'd238);// E
assign row_level1[2] = ((xCounter >= 11'd264 && xCounter <= 11'd273) || (xCounter >= 11'd300 && xCounter <= 11'd309)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// V
assign row_level1[3] = (xCounter >= 11'd314 && xCounter <= 11'd323) && (yCounter >= 11'd229 && yCounter <= 11'd238);// E
assign row_level1[4] = (xCounter >= 11'd346 && xCounter <= 11'd355) && (yCounter >= 11'd229 && yCounter <= 11'd238);// L
assign row_level1[5] = ((xCounter >= 11'd383 && xCounter <= 11'd392) || (xCounter >= 11'd401 && xCounter <= 11'd410)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// U
assign row_level1[6] = ((xCounter >= 11'd415 && xCounter <= 11'd424) || (xCounter >= 11'd433 && xCounter <= 11'd442)) && (yCounter >= 11'd229 && yCounter <= 11'd238);// P
// Row 2
assign row_level2[0] = (xCounter >= 11'd200 && xCounter <= 11'd209) && (yCounter >= 11'd238 && yCounter <= 11'd247);// L
assign row_level2[1] = (xCounter >= 11'd232 && xCounter <= 11'd250) && (yCounter >= 11'd238 && yCounter <= 11'd247);// E
assign row_level2[2] = ((xCounter >= 11'd264 && xCounter <= 11'd282) || (xCounter >= 11'd291 && xCounter <= 11'd309)) && (yCounter >= 11'd238 && yCounter <= 11'd247);// V
assign row_level2[3] = (xCounter >= 11'd314 && xCounter <= 11'd332) && (yCounter >= 11'd238 && yCounter <= 11'd247);// E
assign row_level2[4] = (xCounter >= 11'd346 && xCounter <= 11'd355) && (yCounter >= 11'd238 && yCounter <= 11'd247);// L
assign row_level2[5] = ((xCounter >= 11'd383 && xCounter <= 11'd392) || (xCounter >= 11'd401 && xCounter <= 11'd410)) && (yCounter >= 11'd238 && yCounter <= 11'd247);// U
assign row_level2[6] = (xCounter >= 11'd415 && xCounter <= 11'd442) && (yCounter >= 11'd238 && yCounter <= 11'd247);// P
// Row 3
assign row_level3[0] = (xCounter >= 11'd200 && xCounter <= 11'd209) && (yCounter >= 11'd247 && yCounter <= 11'd256);// L
assign row_level3[1] = (xCounter >= 11'd232 && xCounter <= 11'd241) && (yCounter >= 11'd247 && yCounter <= 11'd256);// E
assign row_level3[2] = ((xCounter >= 11'd273 && xCounter <= 11'd282) || (xCounter >= 11'd291 && xCounter <= 11'd300)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// V
assign row_level3[3] = (xCounter >= 11'd314 && xCounter <= 11'd323) && (yCounter >= 11'd247 && yCounter <= 11'd256);// E
assign row_level3[4] = (xCounter >= 11'd346 && xCounter <= 11'd355) && (yCounter >= 11'd247 && yCounter <= 11'd256);// L
assign row_level3[5] = ((xCounter >= 11'd383 && xCounter <= 11'd392) || (xCounter >= 11'd401 && xCounter <= 11'd410)) && (yCounter >= 11'd247 && yCounter <= 11'd256);// U
assign row_level3[6] = (xCounter >= 11'd415 && xCounter <= 11'd424) && (yCounter >= 11'd247 && yCounter <= 11'd256);// P
// Row 4
assign row_level4[0] = (xCounter >= 11'd200 && xCounter <= 11'd227) && (yCounter >= 11'd256 && yCounter <= 11'd265);// L
assign row_level4[1] = (xCounter >= 11'd232 && xCounter <= 11'd259) && (yCounter >= 11'd256 && yCounter <= 11'd265);// E
assign row_level4[2] = (xCounter >= 11'd273 && xCounter <= 11'd300) && (yCounter >= 11'd256 && yCounter <= 11'd265);// V
assign row_level4[3] = (xCounter >= 11'd314 && xCounter <= 11'd341) && (yCounter >= 11'd256 && yCounter <= 11'd265);// E
assign row_level4[4] = (xCounter >= 11'd346 && xCounter <= 11'd373) && (yCounter >= 11'd256 && yCounter <= 11'd265);// L
assign row_level4[5] = (xCounter >= 11'd383 && xCounter <= 11'd410) && (yCounter >= 11'd256 && yCounter <= 11'd265);// U
assign row_level4[6] = (xCounter >= 11'd415 && xCounter <= 11'd424) && (yCounter >= 11'd256 && yCounter <= 11'd265);// P
endmodule

/////////////////////////////////////////////////////////////////// VGA_generator to display using VGA
module VGA_generator(VGA_clk, VGA_Hsync, VGA_Vsync, DisplayArea, xCounter, yCounter, blank_n);

input VGA_clk;
output VGA_Hsync, VGA_Vsync, blank_n;
output reg DisplayArea;
output reg [9:0]xCounter;
output reg [9:0]yCounter;

reg HSync;
reg VSync;

// Horizontal Integer Assignments (x values)
integer HFront = 10'd640;
integer hSync = 10'd655;
integer HBack = 10'd747;
integer maxH = 10'd793;

// Vertical Integer Assignments (y values)
integer VFront = 10'd480;
integer vSync = 10'd490;
integer VBack = 10'd492;
integer maxV = 10'd525;

// Collect information on the positioning of pixels on the screen
always @(posedge VGA_clk)
begin		
	if(xCounter == maxH)
	begin
		xCounter <= 10'd0;
		if(yCounter === maxV)
			yCounter <= 10'd0;
		else
			yCounter <= yCounter + 10'd1;
	end
	else
	begin
		xCounter <= xCounter + 10'd1;
	end
	DisplayArea <= ((xCounter < HFront) && (yCounter < VFront));
	HSync <= ((xCounter >= hSync) && (xCounter < HBack));
	VSync <= ((yCounter >= vSync) && (yCounter < VBack));
end

// Assign values to the VGA output
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
	count <= count + 22'd1;
	if(count == 22'd150000)
	begin
		update <= ~update;
		count <= 22'd0;
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
	count <= count + 22'd1;
	if(count == 22'd100000)
	begin
		updatePad <= ~updatePad;
		count <= 22'd0;
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

////////////////////////////////////////////////////////////////// Hex Display
module display(val,a,b,c,d,e,f,g);

	input [3:0]val;
	wire [3:0]in;
	output a,b,c,d,e,f,g;
	
	assign in[0] = val[3];
	assign in[1] = val[2];
	assign in[2] = val[1];
	assign in[3] = val[0];
					
	// a
	assign a = ~((!in[1]&!in[3])|(in[0]&!in[1]&!in[2])|(in[0]&!in[3])|(!in[0]&in[1]&in[3])|(in[1]&in[2])|(!in[0]&in[2]));
	
	// b
	assign b = ~((!in[1]&!in[3])|(!in[0]&!in[2]&!in[3])|(!in[0]&!in[1])|(in[0]&!in[2]&in[3])|(!in[0]&in[2]&in[3]));
	
	// c
	assign c = ~((in[0]&!in[1])|(!in[2]&in[3])|(!in[0]&in[1])|(!in[0]&!in[2])|(!in[0]&in[3]));
	
	// d
	assign d = ~((in[0]&!in[2]&!in[3])|(in[1]&!in[2]&in[3])|(!in[0]&!in[1]&!in[3])|(in[1]&in[2]&!in[3])|(!in[1]&in[2]&in[3]));
	
	// e
	assign e = ~((!in[1]&!in[3])|(in[0]&in[1])|(in[2]&!in[3])|(in[0]&in[2]));
	
	// f
	assign f = ~((!in[2]&!in[3])|(in[0]&!in[1])|(!in[0]&in[1]&!in[2])|(in[1]&!in[3])|(in[0]&in[2]));
	
	// g
	assign g = ~((!in[0]&in[1]&!in[2])|(!in[0]&!in[1]&in[2])|(in[2]&!in[3])|(in[0]&!in[1])|(in[0]&in[3]));
	
endmodule