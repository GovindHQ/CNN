## Saturday
today i will edit the cnn top to include initiation for layer 3, and i will store the convolution outputs in feature map memories which i can further use in the activation and pooling layers.

both layer ouputs will be stored in fmap_mem_l2 and fmap_mem_l3 which will be outputs.

gonna write relu and pooling blocks between these conv layers by taking these feature maps as input

created relu_pool_unit which takes feature maps, does relu on and does a 2x2 maxpooling, should be passed to the next layer, which i will do later. 

only does the relu and pooling on the l2 output feature map.

now i will connect input to relu from fmap_mem_l2 and ouput of relu ill connect to layer 3 input.

so i just realized that my fcnn takes 28x28 as input, so i dont need to maxpool . only relu and i can pass the layer 3 output to the fcnn. since layer 3 accumulates over channels its output is 28x28. i need to flatten the output maybe by using another flattener module and send it to fcnn.

found a bug, i was assigning to an input port which is illegal in verilog in the relu pool unit. 

wrote an another valid signal that is triggered when the layer 2 feature map is fully written so that the relu pool unit is properly triggered only after the map is ready.

so the relu unit produces a 3D map while the mac array for layer 3 only accepts flattened 3x3 for all 16 macs. so we write a windowmaker3 module for producing such flattened output from the relu 3d input.

also i noticed im sending the same weights wt_flat to both the mac array layers.

- `window_maker3.ifmap_chunk` is computed in a **combinational** `always_comb` block (flattening).
    
- `o_valid` is asserted in the **same cycle** that `ifmap_chunk` is valid.
    
- `mac_array` samples its inputs on the **rising edge** when `valid_i` is high, so you’re safe: data is already stable.

ou’ll have roughly **1 cycle** from `start→first ifmap_chunk/o_valid` (because `window_maker3` registers its `state` but uses combinational flatten)

- `mac_array` then takes **3 cycles** of MAC multiplies + **2 cycles** of adder‐tree (if `RCV_L2=0`), and finally asserts `valid_o` on cycle _5_ after seeing `valid_i`.
    
- Make sure downstream logic (e.g. writing to `fmap_mem_l3`) uses `mac_array.valid_o`, not an earlier signal.

window_maker3 will stream out windows until its own done pulse.
dont re assert start until you've consumed all those windows. 
valid signal fires every cycle with the window.

ok so what if the mac array is not ready for new windows. i need a ready signal for that or else i will lose window data. i wrote the previous code assuming mac array is always ready for a valid input signal

have to implement valid ready handshake between windowmaker and macarray.

the delay chain in mac_array simply echoes valid_i through the same number of cycles it takes to compute. but doesnt prevent mac_array from receiving a new valid_i before its done with the last one.

so we need handshaking - both sides only hand data over when valid && ready are both true.



