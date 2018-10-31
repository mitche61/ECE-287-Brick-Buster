module PP2VerilogDrawingController(xPixel,yPixel,VGAr,VGAg,VGAb,mouseX,mouseY);

input [9:0]xPixel;
input[8:0]yPixel;
input [10:0]mouseX;
input [10:0]mouseY;
output [7:0]VGAr;
output [7:0]VGAg;
output [7:0]VGAb;
reg [7:0]VGAr;
reg [7:0]VGAg;
reg [7:0]VGAb;

always @(*)
begin

	//Writing backgound color
	VGAr = 8'b11111111;
	VGAg = 8'b11111111; 
	VGAb = 8'b11111111; 

	//Drawing Solid shape "UNNAMED"
	if(xPixel>18 && xPixel<68 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>87 && xPixel<137 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>187 && xPixel<237 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>36 && xPixel<86 && yPixel>46 && yPixel<70)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>137 && xPixel<187 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>572 && xPixel<622 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>521 && xPixel<571 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>470 && xPixel<520 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>420 && xPixel<470 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>369 && xPixel<419 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>319 && xPixel<369 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>269 && xPixel<319 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>218 && xPixel<268 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>168 && xPixel<218 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>118 && xPixel<168 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>68 && xPixel<118 && yPixel>21 && yPixel<45)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>236 && xPixel<286 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>288 && xPixel<338 && yPixel>46 && yPixel<70)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>339 && xPixel<389 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>390 && xPixel<440 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>440 && xPixel<490 && yPixel>46 && yPixel<70)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>491 && xPixel<541 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>542 && xPixel<592 && yPixel>45 && yPixel<69)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>119 && xPixel<169 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>68 && xPixel<118 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>170 && xPixel<220 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>221 && xPixel<271 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>273 && xPixel<323 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>323 && xPixel<373 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>373 && xPixel<423 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>423 && xPixel<473 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>474 && xPixel<524 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>525 && xPixel<575 && yPixel>70 && yPixel<94)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>221 && xPixel<457 && yPixel>436 && yPixel<447)
	begin
		VGAr = 8'b00000000;
		VGAg = 8'b00000000;
		VGAb = 8'b00000000;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>503 && xPixel<553 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>401 && xPixel<451 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>452 && xPixel<502 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>299 && xPixel<349 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>350 && xPixel<400 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>147 && xPixel<197 && yPixel>95 && yPixel<119)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>97 && xPixel<147 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>197 && xPixel<247 && yPixel>94 && yPixel<118)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>248 && xPixel<298 && yPixel>95 && yPixel<119)
	begin
		VGAr = 8'b01000100;
		VGAg = 8'b01110010;
		VGAb = 8'b11000100;
	end

	//Drawing Solid shape "UNNAMED"
	if(xPixel>304 && xPixel<344 && yPixel>391 && yPixel<431)
	begin
		VGAr = 8'b10000011;
		VGAg = 8'b11011011;
		VGAb = 8'b11101101;
	end

end

endmodule
