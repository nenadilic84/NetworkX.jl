@testset "Conversion between NXGraph and SimpleGraph" begin
    # SimpleGraph → NXGraph → SimpleGraph round-trip
    sg = Graphs.path_graph(5)
    nxg = NXGraph(sg)
    @test nv(nxg) == 5
    @test ne(nxg) == 4

    sg2 = Graphs.SimpleGraphs.SimpleGraph(nxg)
    @test nv(sg2) == 5
    @test ne(sg2) == 4
    @test Set(collect(edges(sg))) == Set(collect(edges(sg2)))

    # Cycle graph round-trip
    sg3 = Graphs.cycle_graph(6)
    nxg3 = NXGraph(sg3)
    sg4 = Graphs.SimpleGraphs.SimpleGraph(nxg3)
    @test nv(sg4) == 6
    @test ne(sg4) == 6
    @test Set(collect(edges(sg3))) == Set(collect(edges(sg4)))
end

@testset "Conversion between NXDiGraph and SimpleDiGraph" begin
    sdg = Graphs.SimpleDiGraph(3)
    Graphs.add_edge!(sdg, 1, 2)
    Graphs.add_edge!(sdg, 2, 3)

    nxdg = NXDiGraph(sdg)
    @test nv(nxdg) == 3
    @test ne(nxdg) == 2

    sdg2 = Graphs.SimpleGraphs.SimpleDiGraph(nxdg)
    @test nv(sdg2) == 3
    @test ne(sdg2) == 2
    @test Set(collect(edges(sdg))) == Set(collect(edges(sdg2)))
end
