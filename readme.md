# ModelicaMAT
A module to read MAT files written by [OpenModelica](https://openmodelica.org/) and related tools.

## Usage
Load a result vector from a file:

```julia
import ModelicaMAT
fbbOM = joinpath(@__DIR__, "FallingBodyBox","FallingBodyBox_om1.19.0.mat")
data = ModelicaMAT.readVariable(fbbOM, "bodyBox.frame_a.r_0[1]")
data["bodyBox.frame_a.r_0[1]"][16] # == 0.002923239,
```

Load a result vectors from a file:
```julia
import ModelicaMAT
fbbOM = joinpath(@__DIR__, "FallingBodyBox","FallingBodyBox_om1.19.0.mat")
data = ModelicaMAT.readVariables(fbbOM, ["bodyBox.frame_a.r_0[1]","bodyBox.frame_a.R.T[1,1]", "world.animateGravity"] )
data["bodyBox.frame_a.r_0[1]"][16] # == 0.002923239
```

## Modelica's MATv4 format 
The OpenModelica MATv4 file takes the basic v4 matrix format and adds some requirements on the contents and ordering of the matrices.
The format is described at [here](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/technical_details.html#the-matv4-result-file-format) and consists of a series of matrices that first describe the data and then store it.

###  Aclass:
   `Aclass(1,:)` is always 'Atrajectory'
   `Aclass(2,:)` is 1.1 in OpenModelica
   `Aclass(3,:)` is empty
   `Aclass(4,:)` is either `binTrans` or `binNormal`, which determines if the data is stored striped (rows of values at a time instance) or transposed (rows being a single variable across time)

### name:
   a NxM matrix giving the names of the N variables as int8 characters

### description:
   a NxM matrix giving the descriptions of the N variables as int8 characters

### dataInfo:
   a Nx4 matrix describing the data of each variable, with
   dataInfo(i,1) locating the data in data_1 or data_2
   dataInfo(i,2) providing the start index within the data_ matrix
   dataInfo(i,3) = 0 to indicate that the variable is interpolated
   dataInfo(i,4) = -1 to indicate that the variable is undefined outside the time range

### data_1:
   is either an Nx1 matrix giving the variable's constant value, or Nx2 giving the start and end values

### data_2:
   holds the values of the continuously-varying variables in rows of [time1, var1(@time1), var2(@time1), ...varN(@time1), time2, var1(@time2)...]


## MIT License
Copyright (c) 2024 Mechanomy LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



