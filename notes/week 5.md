learned about the axi lite interface. its for the processor to read write to the neural network. we assign certain addresses to which the processor can read and write which is mapped to registers in our network. 
designed and commented the axi_lite_wrapper.
//AXI4-Lite protocol
//it contains 8 32bit memory mapped registers accessed via AXI
/*
Registers are addressed based on the AXI address. 
Using axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] 
(i.e., 3-bit register index):
| Address (Offset) | Register      | Read/Write | Description                             |
| ---------------- | ------------- | ---------- | --------------------------------------- |
| 0x00             | `weightReg`   | W          | Write weight value (32-bit)             |
| 0x04             | `biasReg`     | W          | Write bias value                        |
| 0x08             | `outputReg`   | R          | Final output from the neuron            |
| 0x0C             | `layerReg`    | W          | Specify the layer number of this neuron |
| 0x10             | `neuronReg`   | W          | Specify the neuron ID                   |
| 0x14             | `axi_rd_data` | R          | Data from external source (AXI read)    |
| 0x18             | `statReg`     | R          | Status register (set when output valid) |
| 0x1C             | `controlReg`  | W/R        | Control bits (e.g., soft reset = bit 0) |
*/


also connected the final output of the neural network to a register. 


### Verification of tut4
all the memory intialization files are ready, 4 layers coded, axi wrapped, hardmax finder. the whole hardware designed.

created project name tut4-verification. for zynq-7000 series.

mnist data set 28x28 input pixels. each pixel is greyscale so it ranges from 0 to 255. 

added top_sim.v testbench. reads one particular test image and injects it into the neural network. through our axi stream interface. 

all 10k images in 10k txt files, 784 values of pixel in 16 bit binary values. 785th line is the binary representation of the digit in the file for verification comparison. 
testbench will take one image from here and inject it, wait for the interrupt from the neural network, check the output and if it matches. accuracy calculation is also there. maxtestsamples is defined as 100 in the top of the testbench module. 
the readmb expected a string literal. so im changing it to system verilog. and doing some changes for dynamic string allocation. 

i kept getting errors that the files couldnt be found. i had some bugs fixed with the string format in the top_sim module and moved all mifs and txt files into top_sim_behav directory.

the files configured perfectly. all 100 files were injected and we got a 91 percent accurate prediction.


## Researching convolution layers

chatgpt plan: 
![[Implementing a CNN (MNIST) on FPGA_ Plan, Design, and Feasibility.pdf]]

Designing the MAC array: 
The MAC_ARRAY is central to the two-dimensional convolutions that are needed for CNN inferences. Many FPGAs provides optimized hardware primitives such as DSP tiles. The interface between the designer and these DSP tiles would simply be the designated multiplication operator in the HDL or high-level synthesis tool. we choose to use a relatively tiny MAC array that consists of 144 multipliers and 128 adders. 16 bit resolution. 