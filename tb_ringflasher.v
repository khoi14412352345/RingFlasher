`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/26/2025 10:00:00 AM
// Module Name: tb_ringflasher
// Description:
//  Testbench for ring_flasher module with parameterized delays.
// Revision:
// Revision 0.01 - File Created
// Revision 1.00 - Adapted to current ring_flasher interface
//////////////////////////////////////////////////////////////////////////////////

module tb_ringflasher;

    //------------------------------------------
    // Parameters
    //------------------------------------------
    localparam CLK_HALF_PERIOD = 5;
    localparam RST_DELAY       = 20;
    localparam TEST_DELAY      = 1000;
    localparam START_PULSE     = 10;
    localparam FINAL_DELAY     = 4000;

    //------------------------------------------
    // Signals
    //------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         repeat_en;
    wire [15:0] led;

    //------------------------------------------
    // Instantiate DUT
    //------------------------------------------
    ring_flasher uut (
        .clk       (clk),
        .rst_n     (rst_n),
        .repeat_en (repeat_en),
        .led       (led)
    );

    //------------------------------------------
    // Waveform Dump
    //------------------------------------------
    initial begin
        $dumpfile("sim_build/ringflasher.vcd");
        $dumpvars(0, tb_ringflasher);
    end

    //------------------------------------------
    // Clock Generation
    //------------------------------------------
    always #CLK_HALF_PERIOD clk = ~clk;

    //------------------------------------------
    // Test Sequence
    //------------------------------------------
    initial begin
        clk       = 1'b0;
        rst_n     = 1'b0;
        repeat_en = 1'b0;

        // Release reset
        #RST_DELAY rst_n = 1'b1;

        // First start pulse
        #TEST_DELAY repeat_en = 1'b1;
        #START_PULSE repeat_en = 1'b0;

        // Restart test with another pulse
        #TEST_DELAY repeat_en = 1'b1;
        #START_PULSE repeat_en = 1'b0;

        // Third start pulse after another idle interval
        #TEST_DELAY repeat_en = 1'b1;
        #START_PULSE repeat_en = 1'b0;

        // Finish simulation
        #FINAL_DELAY $finish;
    end

    //------------------------------------------
    // Monitoring
    //------------------------------------------
    initial begin
        $monitor("Time: %0t | LED State: %b | repeat_en = %b | state = %b | dir = %b | phase = %0d",
                 $time, led, repeat_en, uut.state, uut.dir, uut.phase_count);
    end

endmodule