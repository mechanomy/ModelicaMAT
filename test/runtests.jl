# MIT License
# Copyright (c) 2024 Mechanomy LLC
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Test origins:
#  test/BouncingBall/BouncingBall_res.mat - simulated with OpenModelica v1.19.0
#  test/BouncingBall/BouncingBall_dymola2021.mat - simulated with Dymola v2021
#  test/FallingbodyBox/FallingBodyBox_res.mat - simulated with OpenModelica v1.19.0
#  test/FallingbodyBox/FallingBodyBox_dymola2021.mat - simulated with Dymola v2021 (Number of intervals = 100, Stop Time = 0.2)
# These exercise every function in ModelicaMAT.jl...but often use hand-observed values or otherwise require knowledge of the mat's contents

#OpenModelica v1.19.0
bbOM = joinpath(@__DIR__, "BouncingBall","BouncingBall_om1.19.0.mat")
fbbOM = joinpath(@__DIR__, "FallingBodyBox","FallingBodyBox_om1.19.0.mat")

#OpenModelica v1.21.0
wcOM = joinpath(@__DIR__, "WebCutter","WebCutter_om1.21.0.mat")

#Dymola v2021
bbDy = joinpath(@__DIR__, "BouncingBall","BouncingBall_dymola2021.mat")
fbbDy = joinpath(@__DIR__, "FallingBodyBox","FallingBodyBox_dymola2021.mat")

using Test
using ModelicaMAT

@testset "isLittleEndian" begin
  @test ModelicaMAT.isLittleEndian(0) == true
  @test ModelicaMAT.isLittleEndian(1000) == false
  @test ModelicaMAT.isLittleEndian(2000) == false
  @test ModelicaMAT.isLittleEndian(3000) == false
end

@testset "dataFormat" begin
  @test ModelicaMAT.dataFormat(0000) <: Float64
  @test ModelicaMAT.dataFormat(0020) <: Int32
  @test ModelicaMAT.dataFormat(0030) <: Int16
  @test ModelicaMAT.dataFormat(0040) <: UInt16
  @test ModelicaMAT.dataFormat(0050) <: UInt8
end

@testset "typeBytes" begin
  @test ModelicaMAT.typeBytes(Int32) == 4
end

@testset "isModelicaFormat" begin
  @test ModelicaMAT.isMatV4Modelica( bbOM );
  @test ModelicaMAT.isMatV4Modelica( fbbOM );
  @test ModelicaMAT.isMatV4Modelica( bbDy );

  #cursorily check negative coverage
  @test_throws SystemError ModelicaMAT.isMatV4Modelica( joinpath( @__DIR__, "v6", "array.mat") )
  @test_throws SystemError ModelicaMAT.isMatV4Modelica( joinpath( @__DIR__, "v7", "array.mat") )
  @test_throws SystemError ModelicaMAT.isMatV4Modelica( joinpath( @__DIR__, "v7.3", "array.mat") )
end

@testset "Aclass" begin
  ac = ModelicaMAT.readAclass(bbOM)
  @test ac.positionStart == 0
  @test ac.positionEnd == 71
end

@testset "readVariableNames" begin
  ac = ModelicaMAT.readAclass(bbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  # @show vn
  @test length(vn.names) == 11
  @test vn.names[1] == "time"
  @test vn.names[3] == "vel"
  @test vn.names[11] == "grav"
  @test vn.positionStart == 71
  @test vn.positionEnd == 228
end

@testset "getVariableIndex" begin
  ac = ModelicaMAT.readAclass(bbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  @test ModelicaMAT.getVariableIndex(vn, vn.names[3]) == 3
  @test ModelicaMAT.getVariableIndex(vn, vn.names[10]) == 10
end

@testset "readVariableDescriptions" begin
  ac = ModelicaMAT.readAclass(bbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  @test length(vd.descriptions) == 11  
  @test vd.descriptions[1] == "Simulation time [s]"
  @test vd.descriptions[3] == "velocity of ball"
  @test vd.descriptions[11] == "gravity acceleration"
end

@testset "readDataInfo" begin
  ac = ModelicaMAT.readAclass(bbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  di = ModelicaMAT.readDataInfo(ac,vd)
  # @show di.info[3]
  @test di.info[1]["isWithinTimeRange"] == -1
  @test di.info[3]["locatedInData"] == 2 
  @test di.info[4]["isInterpolated"] == 0
  @test di.info[11]["isWithinTimeRange"] == 0
end

@testset "readVariable: BouncingBall OpenModelica" begin
  ac = ModelicaMAT.readAclass(bbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  di = ModelicaMAT.readDataInfo(ac,vd)

  eff = ModelicaMAT.readVariable(ac, vn, vd, di, "eff") #data1
  @test length(eff) == 2
  @test eff[1] ≈ 0.77
  @test eff[2] ≈ 0.77

  grav = ModelicaMAT.readVariable(ac, vn, vd, di, "grav") #data1
  @test length(grav) == 2
  @test grav[1] ≈ 9.81
  @test grav[2] ≈ 9.81

  time = ModelicaMAT.readVariable(ac, vn, vd, di, "time") # data0
  @test all(isapprox.(time, [0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1], rtol=1e-3))

  height = ModelicaMAT.readVariable(ac, vn, vd, di, "height") #data2
  @test isapprox(height[1], 111, rtol=1e-3)
  @test isapprox(height[2], 110.9509, rtol=1e-3)

  vel = ModelicaMAT.readVariable(ac, vn, vd, di, "vel") #data2
  @test isapprox(vel[2], -0.981, rtol=1e-3)
end

@testset "all-in-one readVariable" begin
  data = ModelicaMAT.readVariable(fbbOM, "bodyBox.frame_a.r_0[1]")
  @test isapprox(data["bodyBox.frame_a.r_0[1]"][16], 0.002923239, rtol=1e-3)
  @test_throws ArgumentError ModelicaMAT.readVariable(fbbOM, "nullVariable")
end

@testset "all-in-one readVariables" begin
  data = ModelicaMAT.readVariables(fbbOM, ["bodyBox.frame_a.r_0[1]","bodyBox.frame_a.r_0[2]","bodyBox.frame_a.r_0[3]","bodyBox.frame_a.R.T[1,1]", "world.animateGravity"] )
  @test isapprox(data["bodyBox.frame_a.r_0[1]"][16], 0.002923239, rtol=1e-3)
  @test isapprox(data["bodyBox.frame_a.r_0[2]"][16], -0.00432883, rtol=1e-3)
  @test isapprox(data["bodyBox.frame_a.r_0[3]"][16], -6.2115e-5, rtol=1e-3)
  @test isapprox(data["bodyBox.frame_a.R.T[1,1]"][26], 0.983794001, rtol=1e-3)
  @test isapprox(data["world.animateGravity"][1], 1.0, rtol=1e-3) #this constant of length 2 is filled across dataframe's time
end

@testset "readVariable: BouncingBall Dymola" begin
  ac = ModelicaMAT.readAclass(bbDy)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  di = ModelicaMAT.readDataInfo(ac,vd)

  eff = ModelicaMAT.readVariable(ac, vn, vd, di, "eff") #data1
  @test length(eff) == 2
  @test eff[1] ≈ 0.77
  @test eff[2] ≈ 0.77

  grav = ModelicaMAT.readVariable(ac, vn, vd, di, "grav") #data1
  @test length(grav) == 2
  @test grav[1] ≈ 9.81
  @test grav[2] ≈ 9.81

  Time = ModelicaMAT.readVariable(ac, vn, vd, di, "Time") # data0
  @test all(isapprox.(Time, [0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1], rtol=1e-3))

  height = ModelicaMAT.readVariable(ac, vn, vd, di, "height") #data2
  @test isapprox(height[1], 111, rtol=1e-3)
  @test isapprox(height[2], 110.9509, rtol=1e-3)

  vel = ModelicaMAT.readVariable(ac, vn, vd, di, "vel") #data2
  @test isapprox(vel[2], -0.981, rtol=1e-3)
end

@testset "readVariable: FallingBodyBox OpenModelica" begin
  ac = ModelicaMAT.readAclass(fbbOM)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  di = ModelicaMAT.readDataInfo(ac,vd)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "time") 
  # display(var)
  ret = true
  for i = 2:length(var)-1 #last time is duplicated
    ret &= isapprox(var[i]-var[i-1], 0.002, rtol=1e-4)
  end
  @test ret == true

  #point-check values read from FallingBodyBox_res.csv
  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.r_0[1]") 
  @test isapprox(var[16], 0.002923239, rtol=1e-3)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.R.T[1,1]") 
  @test isapprox(var[26], 0.983794001, rtol=1e-3)

  @test_throws ArgumentError ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.v_0[1]")  # there is no frame_A.v_0

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.v_0[2]") 
  @test isapprox(var[33], -0.58818129, rtol=1e-3)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_b.r_0[1]") 
  @test isapprox(var[72], 0.935886479, rtol=1e-3)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "world.animateGravity") 
  @test isapprox(var[1], 1.0, rtol=1e-3)
end

@testset "readVariable: FallingBodyBox Dymola" begin
  ac = ModelicaMAT.readAclass(fbbDy)
  vn = ModelicaMAT.readVariableNames(ac)
  vd = ModelicaMAT.readVariableDescriptions(ac,vn)
  di = ModelicaMAT.readDataInfo(ac,vd)
  var = ModelicaMAT.readVariable(ac, vn, vd, di, "Time") 

  # display(var)
  ret = true
  for i = 2:length(var)-1 #last time is duplicated
    ret &= isapprox(var[i]-var[i-1], 0.002, rtol=1e-4)
  end
  @test ret == true

  #point-check values read from FallingBodyBox_res.csv
  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.r_0[1]") 
  @test isapprox(var[16], 0.002923239, rtol=1e-2)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.R.T[1, 1]") 
  @test isapprox(var[26], 0.983794001, rtol=1e-2)

  @test_throws ArgumentError ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_a.v_0[1]")  # there is no frame_A.v_0

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.v_0[2]") 
  @test isapprox(var[33], -0.58818129, rtol=1e-3)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "bodyBox.frame_b.r_0[1]") 
  @test isapprox(var[72], 0.935886479, rtol=1e-3)

  var = ModelicaMAT.readVariable(ac, vn, vd, di, "world.animateGravity") 
  @test isapprox(var[1], 1.0, rtol=1e-3)
end

@testset "readVariable: WebCutter OpenModelica" begin
  # check negative indexInData, this does not occur in BouncingBall or FallingBodyBox
  # for instance, "webModel.frame_a.f[1] has dataInfo: 3339;webModel.frame_a.f[1];-342;0;0;2;Cut-force resolved in connector frame [N]
  # ModelicaMAT.dumpDataInfoToCSV(wcOM, "test/WebCutter/WebCutter_dataInfo.csv")

  # use the step change at t=4.36s for point-checks:
  webModel = ModelicaMAT.readVariables(wcOM, ["webModel.frame_a.f[1]", "webModel.frame_a.f[2]","webModel.frame_a.f[3]"] ) 
  # for (i,t) in enumerate(webModel["time"])
  #   println("$i: $t ", webModel["webModel.frame_a.f[1]"][i], webModel["webModel.frame_a.f[2]"][i], webModel["webModel.frame_a.f[3]"][i])
  # end
  @test isapprox(webModel["webModel.frame_a.f[1]"][219], 0.17762, rtol=1e-3)
  @test isapprox(webModel["webModel.frame_a.f[2]"][219], 0.27589, rtol=1e-3)
  @test isapprox(webModel["webModel.frame_a.f[3]"][219], 0.0, rtol=1e-3)
end