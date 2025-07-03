A layer: 32x32x3 image and a 5x5x3 filter. the filters are weights. we slide the filter over the image spacialy and compute dot products. filters always have the same depth(3) of the input volume.
resulting 1 number : the result of taking a dot product between the filter and a small 5x5x3 chunk of the image. 5* 5* 3 = 75 multiplications (number of elements of the filter) - turning the whole vector into one dimentional(both filter and input spacial location) and then multiplying each element and adding up.

we center our filter on top of every pixel in this input volume.
and construct a matrix from the result of each convolution.
called the activation map which will be a 28x28x1 matrix - which is the value of that filter at every spacial location. 


we can work with multiple layers, each will try to get different infos from the input layer. each will give a different activation map but of the same size. if we have 6 of these filters, we can stack up the activation maps to get a "new image" of size 28x28x6. 

A Convnet is a sequence of convolution layer, interspersed with activation functions. each layer will have multiple filters, each producing an activation map. where the filters at the earlier layers represent low level features that you are looking for. like edges  

we can also have strides where we slide the filter over the input image at different rates. with stride one, we move the filter right by one unit and etc

output size: (N-F)/stride +1 - where N and F are input and filter length or width. 

in practice it is common to zero pad the border. if the input is 7x7 and 3x3 filter is applied with stride one, with 1 pixel pad border then the ouput is also 7x7 (use he formula) 

you can also mirror the values at the edges to the padding.

btw a 1x1 convolution layer also makes sense. eg 1x1xdepth filters, performs a depth-dimentional dot product.

pooling layer: makes the representations smaller and more manageable. operates over each activation map independently. 
doesnt do anything to the depth. 
max pooling - pooling layers also have a filter, in max pooling we slide this filter and take the max value of inside this filter, like 2x2 filter, we will slide with stride two take max in each box. commonly the stride is choosen so that it doesnt overlap. 

we connect the outputs of  the convolution layer(entire one) to the FCNN. 