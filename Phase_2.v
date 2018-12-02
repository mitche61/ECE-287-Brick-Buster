module Phase_2(clk, rst, key, start_game, DAC_clk, VGA_R, VGA_G, VGA_B, VGA_Hsync, 
					VGA_Vsync, blank_n, KB_clk, data);
					
input clk, rst;
input KB_clk, data;
input [1:0]key;
input start_game;

wire [2:0]direction;
wire reset;

output reg [7:0]VGA_R;
output reg [7:0]VGA_G;
output reg [7:0]VGA_B;

output VGA_Hsync;
output VGA_Vsync;
output DAC_clk;
output blank_n;

wire [10:0]xCounter;
wire [10:0]yCounter;

wire R;
wire G;
wire B;

wire update;
wire VGA_clk;
wire displayArea;

wire paddle;
wire ball;
wire block1, block2;
wire top_border, bottom_border_block, right_border, left_border;
wire top_border_ball;

reg border;
reg game_over;
reg win_game;
reg [10:0]x_pad, y_pad; //the top left point of the paddle

reg [10:0]x_ball,y_ball; //the top right of the ball

reg [10:0] x_block1, y_block1; //top right corner of block
reg [10:0] x_block2, y_block2;

reg [10:0] x_top_border, y_top_border;
reg [10:0] x_bottom_border, y_bottom_border;
reg [10:0] x_right_border, y_right_border;
reg [10:0] x_left_border, y_left_border;

reg [10:0] x_top_border_ball, y_top_border_ball;

//instantiate modules
kbInput keyboard(KB_clk, key, direction, reset); //the "keyboard", aka the buttons
updateCLK clk_updateCLK(clk, update);
clk_reduce reduce(clk, VGA_clk);
VGA_generator generator(VGA_clk, VGA_Hsync, VGA_Vsync, DisplayArea, xCounter, yCounter, blank_n);

assign DAC_clk = VGA_clk; //DON'T DELETE. this allows the clock on the board to sync with the vga (allowing things to shop up on the monitor)

assign paddle = (xCounter >= x_pad && xCounter <= x_pad + 80 && yCounter >= y_pad && yCounter <= y_pad + 15); // sets the size of the paddle
assign ball   = (xCounter >= x_ball && xCounter <= x_ball + 20 && yCounter >= y_ball && yCounter <= y_ball + 20); // sets the size of the ball
assign block1 = (xCounter >= x_block1 && xCounter <= x_block1 + 80 && yCounter >= y_block1 && yCounter <= y_block1 + 30);
assign block2 = (xCounter >= x_block2 && xCounter <= x_block2 + 80 && yCounter >= y_block2 && yCounter <= y_block2 + 30);

assign bottom_border_block = (xCounter >= x_bottom_border && xCounter <= x_bottom_border + 80 && yCounter >= y_bottom_border && yCounter <= y_bottom_border + 5);


assign top_border_ball = (xCounter >= x_top_border_ball && xCounter <= x_top_border_ball + 20 && yCounter >= y_top_border_ball && yCounter <= y_top_border_ball + 1);

///////////////////////////////////////////////////////////////////////////////FSM
reg [10:0]S;
reg [10:0]NS;
parameter before = 11'd0, start = 11'd1, ball_move_up = 11'd2, collision = 11'd3, ball_move_down = 11'd4;

wire collide;
assign collide = (y_ball==y_block1-11'd30) ? 1'b1 : 1'b0; ////checks if ball (all blue) == block (red and blue) 

wire paddle_hit;
assign paddle_hit = (~R == ~B && ~G && ~R); /// checks if ball (all blue) == paddle (green and blue)

//////////////////////////////////////////reset
always @ (posedge update or negedge rst)
begin
if (rst == 1'd0)
	S <= 11'd0;
else
	S <= NS;
end

////////////////////////////////////////state transitions
always @ (posedge update or negedge rst)
case (S)
before: 
	begin
	if (rst == 1'd0)
		NS = before;
	else
		NS = start;
	end

start:
	begin
	if (start_game == 1'd0)
		NS = start;
	else
		NS = ball_move_up;
	end		

ball_move_up:
	begin
	if (collide == 1'd0)
		NS = ball_move_up;
	else 
		NS = collision;
	end

collision:
	begin
	if (collide == 1'd1)
		NS = collision;
	else
		NS = ball_move_down;
	end

ball_move_down:
	begin
	if (paddle_hit == 1'd1)
		NS = ball_move_up;
	else
		NS = ball_move_down;
	end

default:
	NS = before;
endcase	

////////////////////////////////////////////state definitions
always @ (posedge update or negedge rst)
if (rst==1'd0)
	begin	
		x_pad = 11'd290; 
		y_pad = 11'd465;
	
		x_ball = 11'd315;
		y_ball = 11'd444;
		
		x_block1 = 11'd315;
		y_block1 = 11'd0;
		
		x_bottom_border = 11'd315;
		y_bottom_border = 11'd30;
		
		x_top_border_ball = 11'd315;
		y_top_border_ball = 11'd435;
	end
else
	case (S)
	ball_move_up:
	begin
	y_ball = y_ball - 11'd20;
	y_top_border_ball = y_top_border_ball - 11'd20;
	end
	
	collision:
	begin
	x_block1 = 11'd700;
	y_block1 = 11'd500;
	
	x_bottom_border = 11'd700;
	y_bottom_border = 11'd500;
	end
	
	ball_move_down:
	begin
	y_ball = y_ball + 11'd20;
	y_top_border_ball = y_top_border_ball + 11'd20;
	end
	
	endcase	
//////////////////////////////////////////////////////////////////////////////////////FSM

//always @(posedge update)
//begin
//	if(rst == 0)
//	begin	
//		x_pad <= 11'd290; 
//		y_pad <= 11'd465;
//		x_ball <= 11'd315;
//		y_ball <= 11'd444;		
//		x_block <= 11'd315;
//		y_block <= 11'd0;
//	end
//	else
//	begin
//		case(start_game) //start button
//			1'd0: y_ball <= y_ball;
//			1'd1: begin 
//			y_ball <= y_ball - 11'd20;
//			if (x_block == x_ball && y_block == y_ball)
//			begin 
//			x_block <= 11'd700;
//			y_block <= 11'd500;
//			end
//			else
//			begin
//			x_block <= 11'd315;
//			y_block <= 11'd0;
//			end
//			end
//		endcase
//		case(direction) //push buttons
//			3'd1: x_pad <= x_pad + 11'd10; //left at a speed of "10"
//			3'd2: x_pad <= x_pad - 11'd10; //right at a speed of "10"
//			default: 
//			begin
//				x_pad <= x_pad; //stationary
//			end
//		endcase	
//		end
//		end


//check colored pixcels (blue ball check against black paddle, purple blocks, black border)?


always @(posedge VGA_clk) //border and color
begin
	border <= (((xCounter >= 0) && (xCounter < 11) || (xCounter >= 630) && (xCounter < 641)) 
				|| ((yCounter >= 0) && (yCounter < 11) || (yCounter >= 470) && (yCounter < 481)));
	VGA_R = {8{R}};
	VGA_G = {8{G}};
	VGA_B = {8{B}};
end

//assigning colors to objects
assign R = 1'b1 && ~paddle && ~ball && ~bottom_border_block && ~top_border_ball;
assign B = 1'b1 && ~paddle && ~bottom_border_block;
assign G = 1'b1 && ~block1 && ~block2 && ~ball && ~bottom_border_block;

	
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

/////////////////////////////////////////////////////////////////// update clk to lower snake speed
module updateCLK(clk, update);
input clk;
output reg update;
reg[21:0]count;

always @(posedge clk)
begin
	count <= count + 1;
	if(count == 2500000)
	begin
		update <= ~update;
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

module kbInput(KB_clk, key, direction, reset);
input KB_clk;
input [1:0]key;
output reg [2:0]direction;
output reg reset = 0; 

always @(KB_clk)
begin
	if(key[1] == 1'b1 & key[0] == 1'b0)
		direction = 3'd1;//left
	else if(key[0] == 1'b1 & key[1] == 1'b0)
		direction = 3'd2;//right
	else
		direction = 3'd0;//stationary
end
endmodule















