@testset "NXAlgorithm dispatch" begin
    @testset "is_connected" begin
        g = Graphs.cycle_graph(5)
        @test Graphs.is_connected(g, NXAlgorithm()) == true
        @test Graphs.is_connected(g, NXAlgorithm()) == Graphs.is_connected(g)

        g2 = Graphs.Graph(4)
        Graphs.add_edge!(g2, 1, 2)
        Graphs.add_edge!(g2, 3, 4)
        @test Graphs.is_connected(g2, NXAlgorithm()) == false
        @test Graphs.is_connected(g2, NXAlgorithm()) == Graphs.is_connected(g2)
    end

    @testset "connected_components" begin
        g = Graphs.cycle_graph(5)
        cc = Graphs.connected_components(g, NXAlgorithm())
        @test length(cc) == 1
        @test sort(cc[1]) == [1, 2, 3, 4, 5]

        g2 = Graphs.Graph(5)
        Graphs.add_edge!(g2, 1, 2)
        Graphs.add_edge!(g2, 2, 3)
        Graphs.add_edge!(g2, 4, 5)
        cc2 = Graphs.connected_components(g2, NXAlgorithm())
        @test length(cc2) == 2
        cc_ref = Graphs.connected_components(g2)
        @test Set(Set.(cc2)) == Set(Set.(cc_ref))
    end

    @testset "diameter" begin
        g = Graphs.path_graph(5)
        @test Graphs.diameter(g, NXAlgorithm()) == 4
        @test Graphs.diameter(g, NXAlgorithm()) == Graphs.diameter(g)
    end

    @testset "density" begin
        g = Graphs.complete_graph(4)
        d = Graphs.density(g, NXAlgorithm())
        @test d ≈ 1.0
    end

    @testset "pagerank" begin
        g = Graphs.cycle_graph(4)
        pr = Graphs.pagerank(g, NXAlgorithm())
        @test length(pr) == 4
        # For a cycle, all nodes should have approximately equal PageRank
        vals = collect(values(pr))
        @test all(v -> isapprox(v, 0.25; atol=0.01), vals)
    end

    @testset "betweenness_centrality" begin
        g = Graphs.path_graph(5)
        bc = Graphs.betweenness_centrality(g, NXAlgorithm())
        @test length(bc) == 5
        # Middle vertex (3) should have highest betweenness
        @test bc[3] > bc[1]
        @test bc[3] > bc[5]
    end
end
