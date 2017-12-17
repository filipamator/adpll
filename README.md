# adpll

All digital PLL

This project is a kind of exercises with PLLs and VHDL. The goal is to develop a working all digial (or all software) phase locked loop inside FPGA able to track external signal sampled by ADC. Filtered signal from loop filter will provide demodulated FM signal. The next step will be use such a  FM demodulator to build all software radio receiver (with some external components like mixer and band pass filter).


Here are the results from the simulation in the Modelsim. 
Reference oscillator frequency: 5_000_100 Hz
VCO center frequency: 5_000_000 Hz
Loop bandwidth: 50 kHz (Active PI filter)

PLL transfer function:

![Simulation](https://raw.githubusercontent.com/filipamator/adpll/master/pll_transfer_function.png)


Signals from top:
- Sinewave from the reference oscillator (14 bit) (sample rate = 50 MHz, STD_LOGIC_VECTOR)
- Sinewave from the VCO (14 bit)
- Output from the mixer/phase detector (28 bit); this is an error signal used to lock VCO
- Output from the mixer/phase detector (truncated to 16 bit)
- Output from the low pass filter with fc = 3 MHz
- Decimated error signal (sample rate = 781250 Hz)
- Output of the loop filter - used to steer VCO frequency
- Calculated frequency of the VCO (type 'real')

![Simulation](https://raw.githubusercontent.com/filipamator/adpll/master/Simulation.png)

As you see after 100us PLL is locked at the reference frequency. 






