@testset "GraphsInterfaceChecker" begin
    using GraphsInterfaceChecker

    @testset "NXGraph interface" begin
        g = NXGraph(5)
        add_edge!(g, Graphs.SimpleEdge(1, 2))
        add_edge!(g, Graphs.SimpleEdge(2, 3))
        add_edge!(g, Graphs.SimpleEdge(3, 4))
        add_edge!(g, Graphs.SimpleEdge(4, 5))

        @test GraphsInterfaceChecker.is_valid_graph_type(NXGraph)
        @test GraphsInterfaceChecker.check_interface(g)
    end

    @testset "NXDiGraph interface" begin
        g = NXDiGraph(4)
        add_edge!(g, Graphs.SimpleEdge(1, 2))
        add_edge!(g, Graphs.SimpleEdge(2, 3))
        add_edge!(g, Graphs.SimpleEdge(3, 4))

        @test GraphsInterfaceChecker.is_valid_graph_type(NXDiGraph)
        @test GraphsInterfaceChecker.check_interface(g)
    end
end
