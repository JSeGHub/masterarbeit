module serdiv_miter import ariane_pkg::*;
  #(parameter WIDTH = 8)
  (
  input clk,
  input rst,

  input  logic [TRANS_ID_BITS-1:0] id_i,
  input  logic [WIDTH-1:0]         op_a_i1, op_a_i2,
  input  logic [WIDTH-1:0]         op_b_i1, op_b_i2,
  input  logic [1:0]               opcode_i,
  input  logic                     in_vld_i,
  input  logic                     flush_i,
  input  logic                     out_rdy_i,
  input  logic                     label_a_i1, label_a_i2,
  input  logic                     label_b_i1, label_b_i2

//  output logic                     in_rdy_o,
//  output logic                     out_vld_o,
//  output logic [TRANS_ID_BITS-1:0] id_o,
//  output logic [WIDTH-1:0]         res_o,
//  output logic                     label_res_o

  );

  serdiv #(.WIDTH(WIDTH)) U1
  (
    .clk_i(clk),
    .rst_ni(rst),
    .id_i(id_i),
    .op_a_i(op_a_i1),
    .op_b_i(op_b_i1),
    .opcode_i(opcode_i),
    .in_vld_i(in_vld_i),
    .flush_i(flush_i),
    .out_rdy_i(out_rdy_i),
    .label_a_i(label_a_i1),
    .label_b_i(label_b_i1),

    .in_rdy_o(),
    .out_vld_o(),
    .id_o(),
    .res_o(),
    .label_res_o()
  );

  serdiv #(.WIDTH(WIDTH)) U2
  (
    .clk_i(clk),
    .rst_ni(rst),
    .id_i(id_i),
    .op_a_i(op_a_i2),
    .op_b_i(op_b_i2),
    .opcode_i(opcode_i),
    .in_vld_i(in_vld_i),
    .flush_i(flush_i),
    .out_rdy_i(out_rdy_i),
    .label_a_i(label_a_i2),
    .label_b_i(label_b_i2),

    .in_rdy_o(),
    .out_vld_o(),
    .id_o(),
    .res_o(),
    .label_res_o()
  );

endmodule;
