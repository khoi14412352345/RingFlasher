module ring_flasher #(
    parameter integer STEP_DIV = 2
) (
    input clk,
    input rst_n,
    input repeat_en,
    output reg [15:0] led
);

localparam IDLE = 1'b0;
localparam RUN  = 1'b1;

localparam DIR_CW  = 1'b0;
localparam DIR_CCW = 1'b1;

localparam ACT_SET    = 2'b00;
localparam ACT_CLEAR  = 2'b01;
localparam ACT_TOGGLE = 2'b10;

localparam integer DIV_W = (STEP_DIV <= 1) ? 1 : $clog2(STEP_DIV);

reg state;
reg dir;
reg [1:0] action_mode;
reg [3:0] pos;
reg [3:0] steps_left;
reg [3:0] phase_count;
reg [DIV_W-1:0] div_cnt;

reg [15:0] led_next;
reg [3:0] next_phase_count;
reg step_tick;

always @(*) begin
    led_next = led;

    case (action_mode)
        ACT_SET:    led_next[pos] = 1'b1;
        ACT_CLEAR:  led_next[pos] = 1'b0;
        ACT_TOGGLE: led_next[pos] = ~led[pos];
        default:    led_next[pos] = led[pos];
    endcase
end

always @(*) begin
    next_phase_count = phase_count + 1'b1;

    if (STEP_DIV <= 1)
        step_tick = (state == RUN);
    else
        step_tick = (state == RUN) && (div_cnt == STEP_DIV - 1);
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        led         <= 16'b0;
        state       <= IDLE;
        dir         <= DIR_CW;
        action_mode <= ACT_SET;
        pos         <= 4'd0;
        steps_left  <= 4'd0;
        phase_count <= 4'd0;
        div_cnt     <= {DIV_W{1'b0}};
    end else if (state == IDLE) begin
        if (repeat_en) begin
            led         <= 16'b0001;
            state       <= RUN;
            dir         <= DIR_CW;
            action_mode <= ACT_SET;
            pos         <= 4'd1;
            steps_left  <= 4'd7;
            phase_count <= 4'd0;
            div_cnt     <= {DIV_W{1'b0}};
        end else begin
            led         <= 16'b0;
            state       <= IDLE;
            dir         <= DIR_CW;
            action_mode <= ACT_SET;
            pos         <= 4'd0;
            steps_left  <= 4'd0;
            phase_count <= 4'd0;
            div_cnt     <= {DIV_W{1'b0}};
        end
    end else begin
        if (step_tick) begin
            div_cnt <= {DIV_W{1'b0}};

            if (steps_left == 4'd1) begin
                if ((led_next == 16'b0) && (dir == DIR_CCW)) begin
                    if (repeat_en) begin
                        led         <= 16'b0001;
                        state       <= RUN;
                        dir         <= DIR_CW;
                        action_mode <= ACT_SET;
                        pos         <= 4'd1;
                        steps_left  <= 4'd7;
                        phase_count <= 4'd0;
                    end else begin
                        led         <= 16'b0;
                        state       <= IDLE;
                        dir         <= DIR_CW;
                        action_mode <= ACT_SET;
                        pos         <= 4'd0;
                        steps_left  <= 4'd0;
                        phase_count <= 4'd0;
                    end
                end else begin
                    led <= led_next;
                    phase_count <= next_phase_count;

                    if (dir == DIR_CW) begin
                        dir         <= DIR_CCW;
                        steps_left  <= 4'd4;
                        action_mode <= (next_phase_count < 4'd6) ? ACT_CLEAR : ACT_TOGGLE;
                    end else begin
                        dir         <= DIR_CW;
                        steps_left  <= 4'd8;
                        action_mode <= (next_phase_count < 4'd6) ? ACT_SET : ACT_TOGGLE;
                    end
                end
            end else begin
                led        <= led_next;
                steps_left <= steps_left - 1'b1;

                if (dir == DIR_CW)
                    pos <= pos + 1'b1;
                else
                    pos <= pos - 1'b1;
            end
        end else begin
            if (STEP_DIV > 1)
                div_cnt <= div_cnt + 1'b1;
            else
                div_cnt <= {DIV_W{1'b0}};
        end
    end
end

endmodule