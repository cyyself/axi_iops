module my_LFSR #(
    parameter LEN_BITS = 16, // range [3,36]
    parameter SEED = 0
) (
    input                   clock,
    input                   reset,
    output [LEN_BITS-1:0]   out
);

logic xnor_result;
logic [LEN_BITS:1] lfsr;

// https://docs.xilinx.com/v/u/en-US/xapp052
always_comb begin : xnor_result_gen
    case (LEN_BITS)
         3: xnor_result = lfsr[ 3] ^~ lfsr[ 2];
         4: xnor_result = lfsr[ 4] ^~ lfsr[ 3];
         5: xnor_result = lfsr[ 5] ^~ lfsr[ 3];
         6: xnor_result = lfsr[ 6] ^~ lfsr[ 5];
         7: xnor_result = lfsr[ 7] ^~ lfsr[ 6];
         8: xnor_result = lfsr[ 8] ^~ lfsr[ 6] ^~ lfsr[ 5] ^~ lfsr[ 4];
         9: xnor_result = lfsr[ 9] ^~ lfsr[ 5];
        10: xnor_result = lfsr[10] ^~ lfsr[ 7];
        11: xnor_result = lfsr[11] ^~ lfsr[ 9];
        12: xnor_result = lfsr[12] ^~ lfsr[ 6] ^~ lfsr[ 4] ^~ lfsr[ 1];
        13: xnor_result = lfsr[13] ^~ lfsr[ 4] ^~ lfsr[ 3] ^~ lfsr[ 1];
        14: xnor_result = lfsr[14] ^~ lfsr[ 5] ^~ lfsr[ 3] ^~ lfsr[ 1];
        15: xnor_result = lfsr[15] ^~ lfsr[14];
        16: xnor_result = lfsr[16] ^~ lfsr[15] ^~ lfsr[13] ^~ lfsr[ 4];
        17: xnor_result = lfsr[17] ^~ lfsr[14];
        18: xnor_result = lfsr[18] ^~ lfsr[11];
        19: xnor_result = lfsr[19] ^~ lfsr[ 6] ^~ lfsr[ 2] ^~ lfsr[ 1];
        20: xnor_result = lfsr[20] ^~ lfsr[17];
        21: xnor_result = lfsr[21] ^~ lfsr[19];
        22: xnor_result = lfsr[22] ^~ lfsr[21];
        23: xnor_result = lfsr[23] ^~ lfsr[18];
        24: xnor_result = lfsr[24] ^~ lfsr[23] ^~ lfsr[22] ^~ lfsr[17];
        25: xnor_result = lfsr[25] ^~ lfsr[22];
        26: xnor_result = lfsr[26] ^~ lfsr[ 6] ^~ lfsr[ 2] ^~ lfsr[ 1];
        27: xnor_result = lfsr[27] ^~ lfsr[ 5] ^~ lfsr[ 2] ^~ lfsr[ 1];
        28: xnor_result = lfsr[28] ^~ lfsr[25];
        29: xnor_result = lfsr[29] ^~ lfsr[27];
        30: xnor_result = lfsr[30] ^~ lfsr[ 6] ^~ lfsr[ 4] ^~ lfsr[ 1];
        31: xnor_result = lfsr[31] ^~ lfsr[28];
        32: xnor_result = lfsr[32] ^~ lfsr[22] ^~ lfsr[ 2] ^~ lfsr[ 1];
        33: xnor_result = lfsr[33] ^~ lfsr[20];
        34: xnor_result = lfsr[34] ^~ lfsr[27] ^~ lfsr[ 2] ^~ lfsr[ 1];
        35: xnor_result = lfsr[35] ^~ lfsr[33];
        36: xnor_result = lfsr[36] ^~ lfsr[25];
        default: $error("invalid LEN_BITS in LFSR");
    endcase
end

always_ff @(posedge clock) begin
    if (reset) lfsr <= SEED;
    else lfsr <= {lfsr[LEN_BITS-1:1],xnor_result};
end

assign out = lfsr;

endmodule

module axi_iops #(
    parameter LFSR_INIT = 0,
    parameter ADDR_LEN  = 32,
    parameter DATA_LEN  = 64,
    parameter ID_LEN    = 6,
    parameter LEN_SIZE  = 4 // 4 for AXI3, 8 for AXI4, Xilinx HBM IP only provides AXI3 interface
) (
    input                   clock,
    input                   reset,
    output [ID_LEN-1:0]     axi_awid,
    output [ADDR_LEN-1:0]   axi_awaddr,
    output [LEN_SIZE-1:0]   axi_awlen,
    output [2:0]            axi_awsize,
    output [1:0]            axi_awburst,
    output                  axi_awvalid,
    input                   axi_awready,
    output [DATA_LEN-1:0]   axi_wdata,
    output [DATA_LEN/8-1:0] axi_wstrb,
    output                  axi_wlast,
    output                  axi_wvalid,
    input                   axi_wready,
    input  [ID_LEN-1:0]     axi_bid,
    input  [1:0]            axi_bresp,
    input                   axi_bvalid,
    output                  axi_bready,
    output [ID_LEN-1:0]     axi_arid,
    output [ADDR_LEN-1:0]   axi_araddr,
    output [LEN_SIZE-1:0]   axi_arlen,
    output [2:0]            axi_arsize,
    output [1:0]            axi_arburst,
    output                  axi_arvalid,
    input                   axi_arready,
    input  [ID_LEN-1:0]     axi_rid,
    input  [DATA_LEN-1:0]   axi_rdata,
    input  [1:0]            axi_rresp,
    input                   axi_rlast,
    input                   axi_rvalid,
    output                  axi_rready,
    output [31:0]           iocount_period,
    input  [2:0]            debug_arsize,
    input  [LEN_SIZE-1:0]   debug_arlen,
    input                   debug_pause
);

reg [31:0] timestamp;
reg [31:0] io_count;
reg [31:0] io_count_out;

assign iocount_period = io_count_out;

always_ff @(posedge clock) begin : counting
    if (reset) begin
        timestamp <= 0;
        io_count <= 0;
        io_count_out <= 0;
    end
    else begin
        timestamp <= timestamp + 1;
        if (timestamp == 0) begin
            io_count_out <= io_count;
            io_count <= 0;
        end
        if (axi_rvalid && axi_rlast) begin
            io_count <= timestamp == 0 ? 1 : (io_count + 1);
        end
    end
end

logic [ADDR_LEN-1:0] lfsr_out;

my_LFSR #(
    .SEED(LFSR_INIT),
    .LEN_BITS(ADDR_LEN)
) lfsr_inst (
    .clock(clock),
    .reset(reset),
    .out(lfsr_out)
);

reg [ID_LEN-1:0] arid;
reg [ADDR_LEN-1:0] araddr;
reg [LEN_SIZE-1:0] arlen;
reg [2:0] arsize;
reg arvalid;

assign axi_arid = arid;
assign axi_araddr = araddr;
assign axi_arlen = arlen;
assign axi_arsize = arsize;
assign axi_arburst = 2'b01; // INCR
assign axi_arvalid = arvalid;

always_ff @(posedge clock) begin
    if (reset) begin
        arid <= 0;
        araddr <= 0;
        arlen <= 0;
        arsize <= 0;
        arvalid <= 0;
    end
    else begin
        if (!axi_arvalid && !debug_pause) begin
            // generate new
            arid <= arid + 1;
            araddr <= lfsr_out & ~((1<<debug_arsize)-1);
            arlen <= debug_arlen;
            arsize <= debug_arsize;
            arvalid <= 1'b1;
        end
        else begin
            if (axi_arready) begin
                if (debug_pause) arvalid <= 0;
                else begin
                    // generate new
                    arid <= arid + 1;
                    araddr <= lfsr_out & ~((1<<debug_arsize)-1);
                    arlen <= debug_arlen;
                    arsize <= debug_arsize;
                    arvalid <= 1'b1;
                end
            end
        end
    end
end

// don't care aw, w
assign axi_awid = 0;
assign axi_awaddr = 0;
assign axi_awlen = 0;
assign axi_awsize = 0;
assign axi_awburst = 0;
assign axi_awvalid = 0;
assign axi_wdata = 0;
assign axi_wstrb = 0;
assign axi_wlast = 0;
assign axi_wvalid = 0;
// always ack b
assign axi_bready = !reset;
// always ack r
assign axi_rready = !reset;

endmodule
