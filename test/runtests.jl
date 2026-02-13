using NetworkX
using Graphs
using Test

@testset "NetworkX.jl" begin
    include("test_graph_api.jl")
    include("test_digraph_api.jl")
    include("test_conversion.jl")
    include("test_algorithms.jl")
end
