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
    input  logic [MPWID-1:0] modulus,
    input  logic [MPWID-1:0] mplier,
    input  logic mpand_label,
    input  logic modulus_label,
    input  logic mplier_label,
    output logic [MPWID-1:0] product,
    output logic product_label 
);

  // Internal signals
  logic [MPWID-1:0] product_internal,
  logic product_label_internal;
  logic [MPWID-1:0] product_internal;
  logic ready_internal;
  logic running;
  logic [MPWID-1:0] timer = 0;

  // Instantiate the DUT
  modmult #(
    .MPWID(MPWID)
  ) dut (
    .clk(clk),
    .reset(reset),
    .ds(ds_internal),
    .ready(ready_internal),
    .mpand(mpand),
    .modulus(modulus),
    .mplier(mplier),
    .product(product)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (!reset) begin
      running <= 0;
      ready <= 0;
      product <= 0;
      product_label <= 0;
      timer = 9;
    end else begin
      if (ds && !running) begin
        timer = 0;
        t_array[0] = 0;
        t_array[1] = 0;
        t_array[2] = 0;
        product_label_internal <= 1;

        // MUX for mplier
        case (mplier[MPWID-1:MPWID-3])
          3'b000: t_array[2] = 6;
          3'b001: t_array[2] = 7;
          3'b010: t_array[2] = 8;
          3'b011: t_array[2] = 8;
          3'b100: t_array[2] = 9;
          3'b101: t_array[2] = 9;
          3'b110: t_array[2] = 9;
          3'b111: t_array[2] = 9;
          default: t_array[2] = 9;
        endcase

        for (int i = 0; i < 3; i++) begin
          if (t_array[i] > timer)
             timer = t_array[i];
        end

        running <= 1;
        ready <= 0;
      end else if (running) begin
        if (timer > 0) begin
          timer = timer - 1;
        end else begin
          ready <= ready_internal;
          running <= 0;
          product <= product_internal;
          product_label <= product_label_internal;
        end
      end else begin
        ready <= 0;
      end
    end
  end

endmodule
