
`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

`ifdef BSV_ASYNC_RESET
 `define BSV_ARESET_EDGE_META or `BSV_RESET_EDGE RST
`else
 `define BSV_ARESET_EDGE_META
`endif

// Corrected SizedFIFO with Data Ports[cite: 15, 25]
module SizedFIFO(CLK, RST, ENQ, D_IN, FULL_N, DEQ, D_OUT, EMPTY_N, CLR);
   parameter p1width = 8;        // Added: Width of the pixel data
   parameter p2depth = 3;        // Added: Number of stages in the FIFO
   parameter p3cntr_width = 2;   // Counter bit-width
   parameter guarded = 1;

   input     CLK;
   input     RST;
   input     CLR;
   input     ENQ;
   input     DEQ;
   input  [p1width-1 : 0] D_IN;  // Added: Input data port
   output    FULL_N;
   output    EMPTY_N;
   output [p1width-1 : 0] D_OUT; // Added: Output data port[cite: 25]

   reg [p1width-1 : 0] arr [0:p2depth-1]; // Added: Memory to store pixels[cite: 25]
   reg [p3cntr_width-1 : 0] head;
   reg [p3cntr_width-1 : 0] tail;
   reg [p3cntr_width-1 : 0] count;

   assign EMPTY_N = (count != 0);
   assign FULL_N  = (count != p2depth);
   assign D_OUT   = arr[head];

   always @(posedge CLK) begin
      if (RST == 0 || CLR) begin
         head  <= `BSV_ASSIGNMENT_DELAY 0;
         tail  <= `BSV_ASSIGNMENT_DELAY 0;
         count <= `BSV_ASSIGNMENT_DELAY 0;
      end else begin
         if (ENQ && FULL_N && (!DEQ || guarded)) begin
            arr[tail] <= `BSV_ASSIGNMENT_DELAY D_IN;
            tail      <= `BSV_ASSIGNMENT_DELAY (tail == p2depth-1) ? 0 : tail + 1;
         end
         if (DEQ && EMPTY_N) begin
            head      <= `BSV_ASSIGNMENT_DELAY (head == p2depth-1) ? 0 : head + 1;
         end
         
         // Update count based on simultaneous Enq/Deq
         if (ENQ && !DEQ && FULL_N)
            count <= `BSV_ASSIGNMENT_DELAY count + 1;
         else if (DEQ && !ENQ && EMPTY_N)
            count <= `BSV_ASSIGNMENT_DELAY count - 1;
      end
   end
endmodule