// Auto-generated SystemVerilog Wrapper for serdiv
`timescale 1ns/1ps

module serdiv_wrapper import ariane_pkg::*; #(
    parameter int WIDTH = 8
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic flush_i,

    input  logic in_vld_i,
    output logic out_vld_o,
    input  logic out_rdy_i,
    output logic in_rdy_o,

    input  logic [WIDTH-1:0] op_a_i,
    input  logic [WIDTH-1:0] op_b_i,
    input  logic op_a_i_label,
    input  logic op_b_i_label,

    input  logic [1:0] opcode_i,
    input  logic [TRANS_ID_BITS-1:0] id_i,
    output logic [TRANS_ID_BITS-1:0] id_o,
    output logic [WIDTH-1:0] res_o,
    output logic res_o_label 
);

  // FSM - Typedef
  typedef enum logic [1:0] {
    IDLE, RUN, DONE
  } state_t;
  state_t state_q, state_d;

  // Internal signals
  logic [WIDTH-1:0] res_o_q, res_o_d;
  logic res_o_label_q, res_o_label_d;

  logic in_vld_i_q, in_vld_i_d;
  logic out_rdy_i_q, out_rdy_i_d;
  logic out_vld_o_q, out_vld_o_d;
  logic in_rdy_o_q, in_rdy_o_d;

  logic [WIDTH-1:0] timer_q, timer_d;

 
  // Timing array
  logic [WIDTH-1:0] t_array [2];
 

  // Instantiate the DUT
  serdiv #(
    .WIDTH(WIDTH)

  ) dut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .flush_i(flush_i),
    .in_vld_i(in_vld_i_q),
    .out_vld_o(out_vld_o_q),
    .out_rdy_i(out_rdy_i_q),
    .in_rdy_o(in_rdy_o_q),
    .opcode_i(opcode_i),
    .id_i(id_i),
    .op_a_i(op_a_i),
    .op_b_i(op_b_i),
    .id_o(id_o),
    .res_o(res_o_q) 
  );

  

  // Combinatorial logic - Timing behavior
 
  always_comb begin

    // Timing decision based on MSB

      if (op_a_i_label == 0) begin
        case (op_a_i[WIDTH-1:WIDTH-3])
          3'b000: t_array[0] = 6;
          3'b001: t_array[0] = 7;
          3'b010: t_array[0] = 8;
          3'b011: t_array[0] = 8;
          3'b100: t_array[0] = 9;
          3'b101: t_array[0] = 9;
          3'b110: t_array[0] = 9;
          3'b111: t_array[0] = 9;
          default: t_array[0] = 9;
        endcase
      end else t_array[0] = 0;

      if (op_b_i_label == 0) begin
        case (op_b_i[WIDTH-1:WIDTH-3])
          3'b000: t_array[1] = 9;
          3'b001: t_array[1] = 4;
          3'b010: t_array[1] = 3;
          3'b011: t_array[1] = 3;
          3'b100: t_array[1] = 3;
          3'b101: t_array[1] = 3;
          3'b110: t_array[1] = 4;
          3'b111: t_array[1] = 9;
          default: t_array[1] = 9;
        endcase
      end else t_array[1] = 0;

end


  // FSM combinatorial logic
  always_comb begin
    state_d = state_q;
    timer_d = timer_q;
    res_o_label_d = res_o_label_q;

    case (state_q)
      IDLE: begin
        if (in_vld_i_q) begin
          state_d = RUN;
          timer_d = 0;
          if ((op_a_i_label == 1) && (op_b_i_label == 1)) begin
            timer_d = 9;
          end else if ((op_a_i_label == 0) && (op_b_i_label == 0)) begin
            timer_d = 0;
          end else begin
            for (int i = 0; i < 2; i++) begin
              if (t_array[i] > timer_d) timer_d = t_array[i];
            end
        end
          out_vld_o_d = 1'b0;
          in_rdy_o_d = 1'b0;
          res_o_label_d = op_a_i_label | op_b_i_label;
        end
      end
      RUN: begin
        if (timer_q > 0)
          timer_d = timer_q - 1;
        else
          state_d = DONE;
      end
      DONE: begin
        res_o_d = res_o_q;
        res_o_label_d = res_o_label_q;
        out_vld_o_d = 1'b1;
        in_rdy_o_d = 1'b1;
        state_d = IDLE;
      end
    endcase

  end



  // FSM sequential logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      timer_q <= 9;
      res_o_label_q <= 1'b1;
    end else begin
      state_q <= state_d;
      timer_q <= timer_d;
      in_rdy_o_q <= in_rdy_o_d;
      out_vld_o_q <= out_vld_o_d;
      res_o_label_q <= res_o_label_d;
    end
  end

  // Assignments
  assign in_vld_i_q = (state_q == IDLE) ? in_vld_i : 1'b0;
  assign out_rdy_i_q = (state_q == IDLE) ? out_rdy_i : 1'b0;
  assign out_vld_o = out_vld_o_d;
  assign in_rdy_o = in_rdy_o_q;
  assign res_o = res_o_d;
  assign res_o_label = res_o_label_q;

endmodule
