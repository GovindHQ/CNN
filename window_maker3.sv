module window_maker3 #(
    parameter WIDTH = 28,
    parameter DATA_WIDTH = 18,
    parameter CHANNELS = 16
)(

    input logic clk,
    input logic rst,
    input logic start, //start signal for burst mode operation
    input logic [DATA_WIDTH-1:0] fmap_in [0:WIDTH-1][0:WIDTH-1][0:CHANNELS-1], //relu 3d map input

    output logic [(9*DATA_WIDTH)-1:0] ifmap_chunk [0:CHANNELS-1], //going to layer 3 mac array
    output logic o_valid,
    output logic done

);

    typedef enum logic [1:0] {
        IDLE, PROCESS, DONE
    } state_t;

    state_t state, next_state;

    logic [5:0] x,y;

    //FSM
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            x <= 0;
            y <= 0;

        end else begin
            state <= next_state;
            if(state == PROCESS) begin
                if(x < WIDTH - 3)
                    x <= x + 1;
                else
                    x <= 0;
                if(y< HEIGHT - 3)
                    y <= y + 1;
                else
                    y <= 0; // completed whole fmap
            end
        end
    end

    //next state logic
    always_comb begin
        case(state)
            IDLE: next_state = (start) ? PROCESS : IDLE;
            PROCESS: next_state = ((x = WIDTH - 3) && (y == HEIGHT - 3)) ? DONE : PROCESS;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    //Extract and flatten the 3x3 window for all 16 channels

    always_comb begin
        for(int c = 0; c < 16; c++) begin
            ifmap_chunk[c] = {
                fmap_in[y+0][x+0][c], fmap_in[y+0][x+1][c], fmap_in[y+0][x+2][c],
                fmap_in[y+1][x+0][c], fmap_in[y+1][x+1][c], fmap_in[y+1][x+2][c],
                fmap_in[y+2][x+0][c], fmap_in[y+2][x+1][c], fmap_in[y+2][x+2][c]
            };
        end
    end

    assign o_valid = (state == PROCESS); //the process is combinational, under a cycle it will be completed
    assign done = (state == DONE);

    endmodule






































