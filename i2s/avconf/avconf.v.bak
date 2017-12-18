module avconf (	//	Host Side
						CLOCK_50,
						reset,
						//	I2C Side
						I2C_SCLK,
						I2C_SDAT	);
//	Host Side
input		CLOCK_50;
input		reset;
//	I2C Side
output		I2C_SCLK;
inout		I2C_SDAT;
//	Internal Registers/Wires
reg	[15:0]	mI2C_CLK_DIV;
reg	[23:0]	mI2C_DATA;
reg			mI2C_CTRL_CLK;
reg			mI2C_GO;
wire		mI2C_END;
wire		mI2C_ACK;
wire		iRST_N = !reset;
reg	[15:0]	LUT_DATA;
reg	[5:0]	LUT_INDEX;
reg	[3:0]	mSetup_ST;

parameter USE_MIC_INPUT		= 1'b0;

parameter AUD_LINE_IN_LC	= 9'd24;
parameter AUD_LINE_IN_RC	= 9'd24;
parameter AUD_LINE_OUT_LC	= 9'd119;
parameter AUD_LINE_OUT_RC	= 9'd119;
parameter AUD_ADC_PATH		= 9'd17;
parameter AUD_DAC_PATH		= 9'd6;
parameter AUD_POWER			= 9'h000;
parameter AUD_DATA_FORMAT	= 9'd77;
parameter AUD_SAMPLE_CTRL	= 9'd0;
parameter AUD_SET_ACTIVE	= 9'h001;

//	Clock Setting
parameter	CLK_Freq	=	50000000;	//	50	MHz
parameter	I2C_Freq	=	20000;		//	20	KHz
//	LUT Data Number
parameter	LUT_SIZE	=	50;
//	Audio Data Index
parameter	SET_LIN_L	=	0;
parameter	SET_LIN_R	=	1;
parameter	SET_HEAD_L	=	2;
parameter	SET_HEAD_R	=	3;
parameter	A_PATH_CTRL	=	4;
parameter	D_PATH_CTRL	=	5;
parameter	POWER_ON	=	6;
parameter	SET_FORMAT	=	7;
parameter	SAMPLE_CTRL	=	8;
parameter	SET_ACTIVE	=	9;
//	Video Data Index
parameter	SET_VIDEO	=	10;

/////////////////////	I2C Control Clock	////////////////////////
always@(posedge CLOCK_50 or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		mI2C_CTRL_CLK	<=	0;
		mI2C_CLK_DIV	<=	0;
	end
	else
	begin
		if( mI2C_CLK_DIV	< (CLK_Freq/I2C_Freq) )
		mI2C_CLK_DIV	<=	mI2C_CLK_DIV+1;
		else
		begin
			mI2C_CLK_DIV	<=	0;
			mI2C_CTRL_CLK	<=	~mI2C_CTRL_CLK;
		end
	end
end
////////////////////////////////////////////////////////////////////
I2C_Controller 	u0	(	.CLOCK(mI2C_CTRL_CLK),		//	Controller Work Clock
						.I2C_SCLK(I2C_SCLK),		//	I2C CLOCK
 	 	 	 	 	 	.I2C_SDAT(I2C_SDAT),		//	I2C DATA
						.I2C_DATA(mI2C_DATA),		//	DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
						.GO(mI2C_GO),      			//	GO transfor
						.END(mI2C_END),				//	END transfor 
						.ACK(mI2C_ACK),				//	ACK
						.RESET(iRST_N)	);
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mSetup_ST	<=	0;
		mI2C_GO		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mSetup_ST)
			0:	begin
					if(LUT_INDEX<SET_VIDEO)
					mI2C_DATA	<=	{8'h34,LUT_DATA};
					else
					mI2C_DATA	<=	{8'h40,LUT_DATA};
					mI2C_GO		<=	1;
					mSetup_ST	<=	1;
				end
			1:	begin
					if(mI2C_END)
					begin
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;							
						mI2C_GO		<=	0;
					end
				end
			2:	begin
					LUT_INDEX	<=	LUT_INDEX+1;
					mSetup_ST	<=	0;
				end
			endcase
		end
	end
end
////////////////////////////////////////////////////////////////////
/////////////////////	Config Data LUT	  //////////////////////////	
always
begin
	case(LUT_INDEX)
	//	Audio Config Data
	SET_LIN_L	:	LUT_DATA	<=	{7'h0, AUD_LINE_IN_LC};
	SET_LIN_R	:	LUT_DATA	<=	{7'h1, AUD_LINE_IN_RC};
	SET_HEAD_L	:	LUT_DATA	<=	{7'h2, AUD_LINE_OUT_LC};
	SET_HEAD_R	:	LUT_DATA	<=	{7'h3, AUD_LINE_OUT_RC};
	A_PATH_CTRL	:	LUT_DATA	<=	{7'h4, AUD_ADC_PATH} + (16'h0004 * USE_MIC_INPUT);
	D_PATH_CTRL	:	LUT_DATA	<=	{7'h5, AUD_DAC_PATH};
	POWER_ON	:	LUT_DATA	<=	{7'h6, AUD_POWER};
	SET_FORMAT	:	LUT_DATA	<=	{7'h7, AUD_DATA_FORMAT};
	SAMPLE_CTRL	:	LUT_DATA	<=	{7'h8, AUD_SAMPLE_CTRL};
	SET_ACTIVE	:	LUT_DATA	<=	{7'h9, AUD_SET_ACTIVE};
	//	Video Config Data
	SET_VIDEO+0	:	LUT_DATA	<=	16'h1500;
	SET_VIDEO+1	:	LUT_DATA	<=	16'h1741;
	SET_VIDEO+2	:	LUT_DATA	<=	16'h3a16;
	SET_VIDEO+3	:	LUT_DATA	<=  16'h503f; // 16'h5004;
	SET_VIDEO+4	:	LUT_DATA	<=	16'hc305;
	SET_VIDEO+5	:	LUT_DATA	<=	16'hc480;
	SET_VIDEO+6	:	LUT_DATA	<=	16'h0e80;
	SET_VIDEO+7	:	LUT_DATA	<=	16'h503f; // 16'h5020;
	SET_VIDEO+8	:	LUT_DATA	<=	16'h5218;
	SET_VIDEO+9	:	LUT_DATA	<=	16'h58ed;
	SET_VIDEO+10:	LUT_DATA	<=	16'h77c5;
	SET_VIDEO+11:	LUT_DATA	<=	16'h7c93;
	SET_VIDEO+12:	LUT_DATA	<=	16'h7d00;
	SET_VIDEO+13:	LUT_DATA	<=	16'hd048;
	SET_VIDEO+14:	LUT_DATA	<=	16'hd5a0;
	SET_VIDEO+15:	LUT_DATA	<=	16'hd7ea;
	SET_VIDEO+16:	LUT_DATA	<=	16'he43e;
	SET_VIDEO+17:	LUT_DATA	<=	16'hea0f;
	SET_VIDEO+18:	LUT_DATA	<=	16'h3112;
	SET_VIDEO+19:	LUT_DATA	<=	16'h3281;
	SET_VIDEO+20:	LUT_DATA	<=	16'h3384;
	SET_VIDEO+21:	LUT_DATA	<=	16'h37A0;
	SET_VIDEO+22:	LUT_DATA	<=	16'he580;
	SET_VIDEO+23:	LUT_DATA	<=	16'he603;
	SET_VIDEO+24:	LUT_DATA	<=	16'he785;
	SET_VIDEO+25:	LUT_DATA	<=	16'h2778; // 16'h503f; // 16'h5000;
	SET_VIDEO+26:	LUT_DATA	<=	16'h5100;
	SET_VIDEO+27:	LUT_DATA	<=	16'h0050;
	SET_VIDEO+28:	LUT_DATA	<=	16'h1000;
	SET_VIDEO+29:	LUT_DATA	<=	16'h0402;
	SET_VIDEO+30:	LUT_DATA	<=	16'h0860;
	SET_VIDEO+31:	LUT_DATA	<=	16'h0a18;
	SET_VIDEO+32:	LUT_DATA	<=	16'h1100;
	SET_VIDEO+33:	LUT_DATA	<=	16'h2b00;
	SET_VIDEO+34:	LUT_DATA	<=	16'h2c8c;
	SET_VIDEO+35:	LUT_DATA	<=	16'h2df8;
	SET_VIDEO+36:	LUT_DATA	<=	16'h2eee;
	SET_VIDEO+37:	LUT_DATA	<=	16'h2ff4;
	SET_VIDEO+38:	LUT_DATA	<=	16'h30d2;
	SET_VIDEO+39:	LUT_DATA	<=	16'h0e05;
	endcase
end
////////////////////////////////////////////////////////////////////
endmodule
