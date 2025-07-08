## Saturday
today i will edit the cnn top to include initiation for layer 3, and i will store the convolution outputs in feature map memories which i can further use in the activation and pooling layers.

both layer ouputs will be stored in fmap_mem_l2 and fmap_mem_l3 which will be outputs.

gonna write relu and pooling blocks between these conv layers by taking these feature maps as input

created relu_pool_unit which takes feature maps, does relu on and does a 2x2 maxpooling, should be passed to the next layer, which i will do later. 

only does the relu and pooling on the l2 output feature map.

now i will connect input to relu from fmap_mem_l2 and ouput of relu ill connect to layer 3 input.

so i just realized that my fcnn takes 28x28 as input, so i dont need to maxpool . only relu and i can pass the layer 3 output to the fcnn. since layer 3 accumulates over channels its output is 28x28. i need to flatten the output maybe by using another flattener module and send it to fcnn.