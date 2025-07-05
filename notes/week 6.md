designing the mac_array.sv
The CNN architecture used is a 7-layer network, as shown below. Our input MNIST image is 30x30. The original dimensions of MNIST sample images are 28x28, but we used 30x30 so that every convolutional kernel in the network can be restricted to a 3x3 size. All original MNIST images have been padded on the edges with the color black (pixel value of 0x00). A 3x3 convolutional kernel transforms the input layer of 30x30 pixels into **16 feature maps of 28x28 pixels**. Then, the rectified linear unit (ReLu) activation function is applied (nonlinear transformation). The next 3 layers follow a similar pattern. The last two fully connected layers generate a 64x1 vector in the penultimate layer and the final 10x1 vector in the final layer. The max() function is then applied to the 10x1 vector to get the classification.

if generating layer 2, the mac array gives 16 outputs(16 feature maps)

- The module needs to **delay the `valid_i`** signal to align with the latency of MACs.
    
- If computing **layer 2 outputs**, output is ready after **3 cycles**.

## Full flow
### **Input (Layer 1):**

- Shape: `30×30×1` (after zero-padding original `28×28`)
    
- Single channel

### **Layer 2(First Conv Layer):**

- **Operation**: 3×3 convolution
    
- **Output**: `28×28×16` (i.e., 16 feature maps)
    
- **Each filter** is applied to the single input channel → no accumulation across channel
In hardware:

- You can use 16 parallel `mac` units — each takes **1 channel** of the 3×3 input and **its own 3×3 kernel** → outputs a **single feature map**.
    

This is what `RCV_L2 = 1` means:

- Just output the raw MAC results without any channel-wise accumulation.
### **Layer 3(Second Conv Layer):**

- **Input**: 16 channels (`28×28×16`)
    
- **Output**: e.g., `14×14×16` after pooling/stride
    
- Now, **each filter spans _all_ 16 input channels**.
his is the key difference.

✅ In hardware:

- For each output feature map, you now need to:
    
    - Apply a different 3×3 kernel to **each of the 16 input channels**
        
    - **Sum the results across channels**
        

This is where `RCV_L2 = 0`:

- MAC units still compute individual channel convolutions,
    
- But their **outputs must be summed (accumulated)** → hence, only `accum_o[0]` is used.

- For each 3×3 region, you use 16 MACs (one per channel),
    
- Then **accumulate** those 16 outputs → single pixel of one fmap.
    
- This matches the `mac_array` module's **accum tree**.

i made a line buffer module, which is a two row bram, stores the two most recent rows of 28 pixels passes . which is layer to be manipulated into 3x3 windows as shift register window.

// Access pixel at row r, column c
logic [15:0] p = image_data[r * 28 + c];

thought of a three line buffer since without that, the window maker would need to wait each pixel of the next row. so that we can directly read any pixel in all three rows at ones to make the window.

once initialized (after first two rows) you get, 1 valid 3x3 winndow every clock.

each clock, one window will be formed so 28 windows, and one pixel each clock loaded into next line buffer row. so three rows are always ready when new row is needed for the window.


writing the window_maker, which takes the three rows as input and forms the windows. and slides it. 

making the conv_wt_mem - - `wt_mem0` holds the 9 weights for filter 0 → used by **MAC 0**
    
- `wt_mem1` holds the 9 weights for filter 1 → used by **MAC 1**
    
- ...
    
- `wt_mem15` → **MAC 15**

once lineBuffer and windowMaker are warmed up
 

|Cycle|Action|
|---|---|
|1–9|Read 9 weights from each `wt_memX` (addr 0–8), 1 per cycle|
||Store 9 pixel values from current window|
|10|Flatten `ifmap_chunk[x]` and `wt[x]`, send to `mac_array`|
|11+|Output `accum_o[x]`, valid_o toggles|

instantiate 16 copies of wt_mem with MEM_ID from 0 to 8 in cnn_top

the weight sender gets weights from the wt_memX, flattens them and sends to mac array

writing the cnn_top module that integrates and initiates the lineBuffer, windowmaker, 16 wt_mem, weight sender, mac array
each mac has its own weights from filterX.txt
ouputs 16 parallel convolution results.

im writing for one layer

it takes input pixel and sends it to line buffer too. i need to connect the result to a feature map memory module.

i used win_trigger = win_valid cause start on weight_sender must be a 1 cycle pulse where a window is valid. its often unsafe to directly connect a valid signals to modules expecting a 1 cycle start events, because valid signals might remain high multiple cycles. win_trigger serves as a clear handshake trigger between windowMaker and weight_sender.


