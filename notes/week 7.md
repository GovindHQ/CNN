## Saturday
today i will edit the cnn top to include initiation for layer 3, and i will store the convolution outputs in feature map memories which i can further use in the activation and pooling layers.

both layer ouputs will be stored in fmap_mem_l2 and fmap_mem_l3 which will be outputs.

gonna write relu and pooling blocks between these conv layers by taking these feature maps as input

created relu_pool_unit which takes feature maps, does relu on and does a 2x2 maxpooling, should be passed to the next layer, which i will do later. 

only does the relu and pooling on the l2 output feature map.
