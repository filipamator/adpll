/*****************************************************************************
 *                                                                           *
 * Module:       Altera_UP_Clock_Edge                                        *
 * Description:                                                              *
 *      This module finds clock edges of one clock at the frquency of        *
 *   another clock.                                                          *
 *                                                                           *
 *****************************************************************************/

module Altera_UP_Clock_Edge (
	// Inputs
	clk,
	reset,
	
	test_clk,
	
	// Bidirectionals

	// Outputs
	rising_edge,
	falling_edge
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input				clk;
input				reset;
	
input				test_clk;

// Bidirectionals

// Outputs
output				rising_edge;
output				falling_edge;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire				found_edge;

// Internal Registers
reg					cur_test_clk;
reg					last_test_clk;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

always @(posedge clk)
	cur_test_clk	<= test_clk;

always @(posedge clk)
	last_test_clk	<= cur_test_clk;

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

// Output Assignments
assign rising_edge	= found_edge & cur_test_clk;
assign falling_edge	= found_edge & last_test_clk;

// Internal Assignments
assign found_edge	= last_test_clk ^ cur_test_clk;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

endmodule

