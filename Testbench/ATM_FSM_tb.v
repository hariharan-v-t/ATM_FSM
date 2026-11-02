
`timescale 1ns / 1ps

module ATM_FSM_tb;

reg clk;
reg reset;
reg valid;
reg branch;
reg [3:0] CARD_NO;
reg [3:0] P_IN;
reg [3:0] Amount;

wire [2:0] state_led;
wire transaction_success;
wire validity_card;
wire validity_pin;
wire Balance_avail;
wire [3:0] balance_out;

ATM_FSM DUT (
    .state_led(state_led),
    .transaction_success(transaction_success),
    .validity_card(validity_card),
    .validity_pin(validity_pin),
    .Balance_avail(Balance_avail),
    .balance_out(balance_out),
    .valid(valid),
    .branch(branch),
    .clk(clk),
    .reset(reset),
    .CARD_NO(CARD_NO),
    .P_IN(P_IN),
    .Amount(Amount)
);

always #5 clk = ~clk;

initial begin
    force DUT.clk_6sec = clk;
end

initial begin
    $monitor("TIME=%0t | STATE=%b | CARD_VALID=%b | PIN_VALID=%b | AMOUNT=%d | BALANCE_AVAIL=%b | BALANCE=%d | SUCCESS=%b",
    $time, state_led, validity_card, validity_pin,
    Amount, Balance_avail, balance_out, transaction_success);
end

task valid_login;
begin
    wait(state_led == 3'b000);

    @(negedge clk);
    CARD_NO = 4'b0010;
    P_IN = 4'b1010;

    @(posedge clk);
    #1;

    @(posedge clk);
    #1;

    if(state_led == 3'b010)
        $display("PASS: VALID CARD AND PIN ACCEPTED");
    else
        $display("FAIL: LOGIN ERROR");
end
endtask

initial begin

    clk = 0;
    reset = 1;
    valid = 0;
    branch = 0;
    CARD_NO = 0;
    P_IN = 0;
    Amount = 0;

    #20;
    reset = 0;

    $display("\nTEST 1: INVALID CARD");

    @(negedge clk);
    CARD_NO = 4'b0001;
    P_IN = 4'b1010;

    @(posedge clk);
    #1;

    if(state_led == 3'b000)
        $display("PASS: INVALID CARD REJECTED");
    else
        $display("FAIL: INVALID CARD ACCEPTED");


    $display("\nTEST 2: INVALID PIN");

    @(negedge clk);
    CARD_NO = 4'b0010;
    P_IN = 4'b0001;

    @(posedge clk);
    #1;

    @(posedge clk);
    #1;

    if(state_led == 3'b000)
        $display("PASS: INVALID PIN REJECTED");
    else
        $display("FAIL: INVALID PIN ACCEPTED");


    $display("\nTEST 3: INITIAL BALANCE ENQUIRY");

    valid_login;

    valid = 0;
    branch = 0;

    @(posedge clk);
    #1;

    if(state_led == 3'b011) begin
        $display("INITIAL BALANCE = %d", balance_out);

        if(balance_out == 4'd15)
            $display("PASS: INITIAL BALANCE IS 15");
        else
            $display("FAIL: INCORRECT INITIAL BALANCE");
    end

    @(posedge clk);
    #1;


    $display("\nTEST 4: WITHDRAWAL OF 12");

    valid_login;

    Amount = 4'd12;
    valid = 0;
    branch = 1;

    @(posedge clk);
    #1;

    @(posedge clk);
    #1;

    if(state_led == 3'b110 && transaction_success) begin
        $display("TRANSACTION SUCCESSFUL");
        $display("INITIAL BALANCE = 15");
        $display("WITHDRAWAL AMOUNT = 12");
        $display("REMAINING BALANCE = %d", DUT.BALANCE);

        if(DUT.BALANCE == 4'd3)
            $display("PASS: BALANCE DEDUCTION CORRECT");
        else
            $display("FAIL: BALANCE DEDUCTION ERROR");
    end
    else begin
        $display("FAIL: TRANSACTION UNSUCCESSFUL");
    end

    @(posedge clk);
    #1;


    $display("\nTEST 5: BALANCE AFTER WITHDRAWAL");

    Amount = 0;
    valid_login;

    valid = 0;
    branch = 0;

    @(posedge clk);
    #1;

    if(state_led == 3'b011) begin
        $display("CURRENT BALANCE = %d", balance_out);

        if(balance_out == 4'd3)
            $display("PASS: REMAINING BALANCE IS 3");
        else
            $display("FAIL: BALANCE IS NOT 3");
    end

    @(posedge clk);
    #1;


    $display("\nTEST 6: INSUFFICIENT BALANCE");

    valid_login;

    Amount = 4'd5;
    valid = 0;
    branch = 1;

    @(posedge clk);
    #1;

    @(posedge clk);
    #1;

    if(state_led == 3'b101) begin
        $display("INSUFFICIENT BALANCE");
        $display("REQUESTED AMOUNT = 5");
        $display("AVAILABLE BALANCE = %d", DUT.BALANCE);

        if(DUT.BALANCE == 4'd3)
            $display("PASS: WITHDRAWAL REJECTED");
        else
            $display("FAIL: BALANCE CHANGED INCORRECTLY");
    end

    @(posedge clk);
    #1;


    $display("\nTEST 7: BALANCE AFTER REJECTED WITHDRAWAL");

    Amount = 0;
    valid_login;

    valid = 0;
    branch = 0;

    @(posedge clk);
    #1;

    $display("CURRENT BALANCE = %d", balance_out);

    if(balance_out == 4'd3)
        $display("PASS: BALANCE REMAINS 3");
    else
        $display("FAIL: BALANCE MISMATCH");

    @(posedge clk);
    #1;


    $display("\nTEST 8: VALID=1, BRANCH=0");

    valid_login;

    valid = 1;
    branch = 0;

    @(posedge clk);
    #1;

    if(state_led == 3'b000)
        $display("PASS: INVALID TRANSACTION REJECTED");
    else
        $display("FAIL: INVALID TRANSACTION");


    $display("\nTEST 9: VALID=1, BRANCH=1");

    valid_login;

    valid = 1;
    branch = 1;

    @(posedge clk);
    #1;

    if(state_led == 3'b000)
        $display("PASS: INVALID TRANSACTION REJECTED");
    else
        $display("FAIL: INVALID TRANSACTION");


    $display("\nALL TEST CASES COMPLETED");
    $display("FINAL BALANCE = %d", DUT.BALANCE);

    $finish;

end

endmodule
