`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:28:48 09/13/2014 
// Design Name: 
// Module Name:    text_lcd 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module text_lcd(
		input clk,
		input rst,
		input new_data,
		output lcd_rs,
		output lcd_rw,
		output lcd_en,
		output reg [7:0] lcd_data
    );
	 
// Names of the states
localparam [3:0]

	ini_1 = 4'b0000,
	ini_2 = 4'b0001,
	ini_3 = 4'b0010,
	ini_4 = 4'b0011,
	ini_5 = 4'b0100,
	ini_6 = 4'b0101,
	ini_7 = 4'b0110,
	ini_8 = 4'b0111,
	write = 4'b1000,
	idle  = 4'b1001;
	
// Write FSM states
localparam [1:0]

	state_idle       = 2'b00,
	state_pre_delay  = 2'b01,
	state_delay      = 2'b10,
	state_post_delay = 2'b11;
	
	 
// FSM Stuff
reg [3:0] state_reg, state_next;
reg [1:0] write_state_reg, write_state_next = 0;
	 
reg [10:0] slow_reg = 0; // Slows the clock down to 40.96 us, the delay time for a write operation
reg rs_reg = 0;
reg en_reg = 0;
reg start_write = 0;  // Flip it on when you need to write, and we'll flip it off
reg start_write_2 = 0;
reg [7:0] write_data = 0;
reg [255:0] chars = 255'h2173746975637269436c6c6154; // "TallCircuits!"

// Counter registers
// ini_4/5/6/8 don't need counters, they are 40 us delays
reg [10:0] ini_1_reg = 0;
reg [6:0]  ini_2_reg = 0;
reg [1:0]  ini_3_reg = 0;
reg        ini_4_reg = 0;
reg        ini_5_reg = 0;
reg        ini_6_reg = 0;
reg [5:0]  ini_7_reg = 0;
reg        ini_8_reg = 0;

// Counters for the write timing (40, 250, and 10 ns)
reg [1:0] pre_delay = 0;  // 40 ns  (2 cycles)
reg [3:0] delay = 0;      // 230 ns (11.5 cycles)
reg  post_delay = 0;      // 10 ns  (.5 cycles)
 
// Other various registers
reg [7:0] write_counter = 0;
reg did_write = 0;
	 
assign lcd_rs = rs_reg;
assign lcd_rw = 0; // We only need to write
assign lcd_en = en_reg;

// If rst, set this FSM back to zero
always @(posedge clk, posedge rst) begin

	if (rst) begin
		state_reg <= 0;
		write_state_reg = 0;
	end
	else begin
		state_reg <= state_next;
		write_state_reg = write_state_next;
	end

end


// Handles the write timing
always @(posedge clk) begin

		write_state_next = write_state_reg;
		
		if(start_write == 0)
			lcd_data <= 0;
		
		case(write_state_reg)
		
			state_idle:
			
				if(start_write == 1 && start_write_2 == 0) begin
					write_state_next = state_pre_delay;
				end
					
			state_pre_delay:
			
				if(pre_delay == 3)
					write_state_next = state_delay;
				else begin
					pre_delay <= pre_delay + 1;
					lcd_data <= write_data;
				end
			
			state_delay:
			
				if(delay == 15) begin
					write_state_next = state_post_delay;
					en_reg <= 0;
				end
				else begin
					delay <= delay + 1;
					en_reg <= 1;
				end
			
			state_post_delay:
			
				if(post_delay == 1) begin
					
					// Apply beginning conditions
					write_state_next = state_idle;
					pre_delay <= 0;
					delay <= 0;
					post_delay <= 0;
					//lcd_data <= 0;
					
				end
				else begin
				
					post_delay <= 1;
					
				end
				
			default:
			
				write_state_next = idle;
			
		endcase
		
		start_write_2 <= start_write;

end


// Determine state_next, which will be assigned to state on the next clock cycle or reset
always @(posedge clk) begin
	
	// things here happen with a 40.96 us clock period
	if(slow_reg == 0) begin
	
		
		start_write <= 0;  // 40 us have passed so we can reset this flag
		state_next = state_reg; // By default, the next state is the current state, i.e. it stays the same
		
		case (state_reg)
		
			ini_1:
			
				if(ini_1_reg == 2047) begin
					state_next = ini_2;
					did_write = 0;
				end
				else begin
					ini_1_reg <= ini_1_reg + 1;
					rs_reg = 0;
					write_data = 0;
					
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
						
				end
					
			ini_2:
			
				if(ini_2_reg == 127) begin
					state_next = ini_3;
					did_write = 0;
				end
				else begin
					ini_2_reg <= ini_2_reg + 1;
					rs_reg = 0;
					write_data = 8'h38;
					
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
					
				end
			
			ini_3:
			
				if(ini_3_reg == 3) begin
					state_next = ini_4;
					did_write = 0;
				end
				else begin
					ini_3_reg <= ini_3_reg + 1;
					rs_reg = 0;
					write_data = 8'h38;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			ini_4:
			
				if(ini_4_reg == 1) begin
					state_next = ini_5;
					did_write = 0;
				end
				else begin
					ini_4_reg = 1;
					rs_reg = 0;
					write_data = 8'h38;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			ini_5:
			
				if(ini_5_reg == 1) begin
					state_next = ini_6;
					did_write = 0;
				end
				else begin
					ini_5_reg = 1;
					rs_reg = 0;
					write_data = 8'h38;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			ini_6:
			
				if(ini_6_reg == 1) begin
					state_next = ini_7;
					did_write = 0;
				end
				else begin
					ini_6_reg = 1;
					rs_reg = 0;
					write_data = 8'h0f;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			ini_7:
			 
				if(ini_7_reg == 63) begin
					state_next = ini_8;
					did_write = 0;
				end
				else begin
					ini_7_reg <= ini_7_reg + 1;
					rs_reg = 0;
					write_data = 8'h01;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			ini_8:
			
				if(ini_8_reg == 1) begin
					state_next = write;
					did_write = 0;
				end
				else begin
					ini_8_reg = 1;
					rs_reg = 0;
					write_data = 8'h06;
					if(did_write == 0) begin
						start_write <= 1;
						did_write = 1;
					end
				end
			
			write:
			
				if(write_counter == 104) begin
					state_next = idle;
				end
				else begin
					
					// Only write every other loop, we need to give start_write time to reset
					if(did_write == 1) begin
						write_counter <= write_counter + 8;
						rs_reg = 1;
						write_data = chars[write_counter +: 8];
						start_write <= 1;
					end
					
					did_write = !did_write;
					
				end
			
			idle:
			
				if(new_data) begin
					write_counter <= 0;
					state_next = write;
					did_write = 0;
				end
					
			default: state_next = ini_1; // Default to a reset
			
		endcase
	
	end
	
	slow_reg <= slow_reg + 1;
	
end


endmodule
