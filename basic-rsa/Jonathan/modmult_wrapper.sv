// Auto-generated SystemVerilog Wrapper for modmult
`timescale 1ns/1ps

module modmult_wrapper import ariane_pkg::*; #(
    parameter int MPWID = 8
) (
    input  logic clk,
    input  logic reset,

    input  logic ds,
    output logic ready,

    input  logic [MPWID-1:0] mpand,
    input  logic [MPWID-1:0] mplier,
    input  logic modulus,
    input  logic mpand_label,
    input  logic mplier_label,
    input  logic modulus_label,

    output logic [MPWID-1:0] product,
    output logic product_label 
);

  // FSM - Typedef
  typedef enum logic [1:0] {
    IDLE, RUN, DONE
  } state_t;
  state_t state_q, state_d;

  // Internal signals
  logic [MPWID-1:0] product_q, product_d;
  logic product_label_q, product_label_d;

  logic ds_q;
  logic ready_q, ready_d;

  logic [MPWID-1:0] timer_q, timer_d;

 
  // Timing array
  logic [MPWID-1:0] t_array [3];
 

  // Instantiate the DUT
  modmult #(
    .MPWID(MPWID)

  ) dut (
    .clk(clk),
    .reset(reset),
    .ds(ds_q),
    .ready(ready_q),
    .mpand(mpand),
    .mplier(mplier),
    .modulus(modulus),
    .product(product_q) 
  );

  

  // Combinatorial logic - Timing behavior
 
  always_comb begin

    // Timing decision based on MSB

      if (mplier_label == 0) begin
        case (mplier[MPWID-1:MPWID-9])
          8'b1xxxxxxx: t_array[1] = 9;
          8'b01xxxxxx: t_array[1] = 8;
          8'b001xxxxx: t_array[1] = 7;
          8'b0001xxxx: t_array[1] = 6;
          8'b00001xxx: t_array[1] = 5;
          8'b000001xx: t_array[1] = 4;
          8'b0000001x: t_array[1] = 3;
          8'b00000001: t_array[1] = 2;
          default: t_array[1] = 9;
        endcase
      end else t_array[1] = 0;

end


  // FSM combinatorial logic
  always_comb begin
    state_d = state_q;
    timer_d = timer_q;
    ready_d = ready_q;

    case (state_q)
      IDLE: begin
        if (ds_q) begin
          state_d = RUN;
          timer_d = 0;
          if ((mpand_label == 1) && (mplier_label == 1) && (modulus_label == 1)) begin
            timer_d = 9;
          end else if ((mpand_label == 0) && (mplier_label == 0) && (modulus_label == 0)) begin
            timer_d = 0;
          end else begin
            for (int i = 0; i < 3; i++) begin
              if (t_array[i] > timer_d) timer_d = t_array[i];
            end
          end
          ready_d = 1'b0;
        end
      end
      RUN: begin
        if (timer_q > 0)
          timer_d = timer_q - 1;
        else if (ready_q) begin
          state_d = DONE;
        end
      end
      DONE: begin
        product_d = product_q;
        ready_d = 1'b1;
        state_d = IDLE;
      end
    endcase

  end



  // FSM sequential logic
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state_q <= IDLE;
      timer_q <= 9;
    end else begin
      state_q <= state_d;
      timer_q <= timer_d;
      ready_q <= ready_d;
    end
  end

  // Secure handling of output label - always prioritize labels
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      product_label_q <= 1'b0;
    end else if (state_q == IDLE && ds) begin
      product_label_q <= mpand_label | mplier_label | modulus_label;
    end
  end

  // Assignments
  assign ds_q = ((state_q == IDLE) ? ds : 1'b0);
  assign ready = ready_d;
  assign product = product_d;
  assign product_label = product_label_q;

endmodule
