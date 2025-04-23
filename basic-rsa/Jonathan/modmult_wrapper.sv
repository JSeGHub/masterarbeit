// Auto-generated SystemVerilog Wrapper for modmult
`timescale 1ns/1ps

module modmult_wrapper #(
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

  logic ds_q, ds_d;
  logic ready_q, ready_d;

  logic [MPWID-1:0] timer_q, timer_d;

 
  // Timing array
  logic [MPWID-1:0] t_array [3][0];
 

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
    .mpand_label(mpand_label),
    .mplier_label(mplier_label),
    .modulus_label(modulus_label),
    .product(product_q),
    .product_label(product_label_q) 
  );

  

  // Combinatorial logic - Timing behavior
 
  always_comb begin
    // Default values
    t_array[0] = 0;
    t_array[1] = 9;
    t_array[2] = 0;

    // Timing decision based on MSB

        case (mplier[MPWID-1:MPWID-3])
          3'b000: t_array[1] = 6;
          3'b001: t_array[1] = 7;
          3'b010: t_array[1] = 8;
          3'b011: t_array[1] = 8;
          3'b100: t_array[1] = 9;
          3'b101: t_array[1] = 9;
          3'b110: t_array[1] = 9;
          3'b111: t_array[1] = 9;
          default: t_array[1] = 9;
        endcase

  end


  // FSM combinatorial logic
  always_comb begin
    state_d = state_q;
    timer_d = timer_q;
    product_label_d = product_label_q;
    ready_d = ready_q;
    product_d = product_q;

    case (state_q)
      IDLE: begin
        if (ds_q) begin
          state_d = RUN;
          timer_d = 0;
          for (int i = 0; i < 3; i++) begin
            if (t_array[i] > timer_d) timer_d = t_array[i];
          end
          ready_d = 0;
          product_label_d =  mplier_label;
        end
      end
      RUN: begin
        if (timer_q > 0)
          timer_d = timer_q - 1;
        else
          state_d = DONE;
      end
      DONE: begin
        product_d = product_q;
        product_label_d = product_label_q;
        ready_d = 1;
        state_d = IDLE;
      end
    endcase

  end



  // FSM sequential logic
  always_ff @(posedge clk or posedge reset) begin
    if (!reset) begin
      state_q <= IDLE;
      timer_q <= 9;
      ready_q <= 0;
      product_q <= 0;
      product_label_q <= 1;
    end else begin
      state_q <= state_d;
      timer_q <= timer_d;
      ready_q <= ready_d;
      product_q <= product_d;
      product_label_q <= product_label_d;
    end
  end

  // Assignments
  assign ds_q = (state_q == IDLE) ? ds : 0;
  assign ready_q = ready_d;
  assign product = product_q;
  assign product_label = product_label_q;


endmodule
