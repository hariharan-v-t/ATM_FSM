`timescale 1ns / 1ps



module ATM_FSM(state_led,transaction_success,validity_card,validity_pin,Balance_avail,balance_out,valid,branch,clk,reset,CARD_NO,P_IN,Amount);
output reg [2:0]state_led;
output reg transaction_success;
output wire validity_card;
output wire validity_pin;
output wire Balance_avail;
output reg [3:0]balance_out;
input valid,branch,clk,reset;
input [3:0]CARD_NO;
input [3:0]P_IN;
input [3:0]Amount;
wire clk_6sec;
Clock_Divider CD1(
    clk,
    reset,
    clk_6sec
);

parameter s0=3'b000,
          s1=3'b001,
          s2=3'b010,
          s3=3'b011,
          s4=3'b100,
          s5=3'b101,
          s6=3'b110;
reg [2:0]state;
reg [2:0]next_state;
reg [3:0]BALANCE;

card_valid x1(validity_card,CARD_NO);
pin_valid x2(validity_pin,P_IN);
balance x3(Balance_avail,BALANCE,Amount);

always @(posedge clk_6sec or posedge reset)
begin
if(reset)
begin
BALANCE<=4'b1111;
state<=s0;
end
else
begin
state<=next_state;
 if(state==s4&&Balance_avail)
BALANCE<=BALANCE-Amount;
end
end

always @(*)
begin
case(state)
s0:
begin
if(validity_card)
next_state=s1;
else
next_state=s0;
end
s1:
begin
if(validity_pin)
next_state=s2;
else
next_state=s0;
end
s2:
case({valid,branch})
2'b00:next_state=s3;
2'b01:next_state=s4;
2'b10:next_state=s0;
2'b11:next_state=s0;
default: next_state = s0;
endcase
s3:
begin
next_state=s0;
end
s4:
begin
if(Balance_avail)
next_state=s6;
else
next_state=s5;
end
s5:
next_state=s0;
s6:
next_state=s0;
default:
next_state=s0;
endcase
end      
always @(*)
begin
state_led=state;
if(state==s6)
transaction_success=1'b1;
else
transaction_success = 1'b0;
if(state==s3)
balance_out=BALANCE;
else
balance_out=4'b0000;

end  

endmodule

module card_valid(o,i);
input [3:0]i;
output o;
parameter valid_number=4'b0010;
 assign o = (valid_number==i);
endmodule

module pin_valid(o,i);
input [3:0]i;
output o;
parameter valid_number=4'b1010;
 assign o = (valid_number==i);
endmodule

module balance(o,balance,amount);
input [3:0]balance;
input [3:0]amount;
output o;

 assign o = (amount <= balance);
endmodule


module Clock_Divider(
    clk_in,
    reset,
    clk_out
);

input clk_in;
input reset;
output reg clk_out;

reg [28:0] counter;

always @(posedge clk_in or posedge reset)
begin

    if(reset)
    begin
        counter <= 29'd0;
        clk_out <= 1'b0;
    end

    else
    begin

        if(counter == 29'd299_999_999)
        begin
            counter <= 29'd0;
            clk_out <= ~clk_out;
        end

        else
        begin
            counter <= counter + 29'd1;
        end

    end

end

endmodule