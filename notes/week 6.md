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