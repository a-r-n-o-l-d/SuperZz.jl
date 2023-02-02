# using SuperZz
using Test

# @testset "SuperZz.jl" begin
#     # Write your tests here.
# end

abstract type Param end

mutable struct BinariseParam <: Param
    bin::Int 
end

function a(a,p::BinariseParam)
    
end

dump(methods(a)[1].sig.parameters[end])
# @testset "pipeline" begin

#     @test 3==5
    
# end