@testset "NXDiGraph basic API" begin
    g = NXDiGraph(4)
    @test nv(g) == 4
    @test ne(g) == 0
    @test is_directed(NXDiGraph)

    # add directed edges
    @test add_edge!(g, Graphs.SimpleEdge(1, 2))
    @test add_edge!(g, Graphs.SimpleEdge(2, 3))
    @test add_edge!(g, Graphs.SimpleEdge(3, 1))
    @test ne(g) == 3

    # directed: 1→2 exists but 2→1 does not
    @test has_edge(g, 1, 2)
    @test !has_edge(g, 2, 1)

    # outneighbors vs inneighbors
    @test outneighbors(g, 1) == [2]
    @test inneighbors(g, 1) == [3]
    @test outneighbors(g, 2) == [3]
    @test inneighbors(g, 2) == [1]

    # rem_edge! directed
    @test rem_edge!(g, Graphs.SimpleEdge(1, 2))
    @test !has_edge(g, 1, 2)
    @test ne(g) == 2

    # add_vertex! and rem_vertex!
    @test add_vertex!(g)
    @test nv(g) == 5
    @test rem_vertex!(g, 5)
    @test nv(g) == 4

    # copy
    gc = copy(g)
    @test nv(gc) == nv(g)
    @test ne(gc) == ne(g)
    add_edge!(gc, Graphs.SimpleEdge(1, 4))
    @test ne(gc) == 3
    @test ne(g) == 2

    # edges iterator
    g2 = NXDiGraph(3)
    add_edge!(g2, Graphs.SimpleEdge(1, 2))
    add_edge!(g2, Graphs.SimpleEdge(2, 3))
    edge_list = collect(edges(g2))
    @test length(edge_list) == 2
end
