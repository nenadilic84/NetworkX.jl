@testset "NXGraph basic API" begin
    # Empty graph
    g0 = NXGraph(0)
    @test nv(g0) == 0
    @test ne(g0) == 0
    @test collect(vertices(g0)) == Int[]
    @test collect(edges(g0)) == Graphs.SimpleGraphs.SimpleEdge{Int}[]

    # Graph with vertices, no edges
    g = NXGraph(5)
    @test nv(g) == 5
    @test ne(g) == 0
    @test vertices(g) == 1:5

    # has_vertex
    @test has_vertex(g, 1)
    @test has_vertex(g, 5)
    @test !has_vertex(g, 0)
    @test !has_vertex(g, 6)

    # add_edge!
    @test add_edge!(g, Graphs.SimpleEdge(1, 2))
    @test ne(g) == 1
    @test has_edge(g, 1, 2)
    @test has_edge(g, 2, 1)  # undirected

    # duplicate edge
    @test !add_edge!(g, Graphs.SimpleEdge(1, 2))
    @test ne(g) == 1

    # self-loop rejected
    @test !add_edge!(g, Graphs.SimpleEdge(1, 1))

    # edge to non-existent vertex
    @test !add_edge!(g, Graphs.SimpleEdge(1, 10))

    # More edges
    @test add_edge!(g, Graphs.SimpleEdge(2, 3))
    @test add_edge!(g, Graphs.SimpleEdge(3, 4))
    @test add_edge!(g, Graphs.SimpleEdge(4, 5))
    @test ne(g) == 4

    # neighbors
    @test sort(outneighbors(g, 2)) == [1, 3]
    @test sort(inneighbors(g, 2)) == [1, 3]
    @test outneighbors(g, 1) == [2]
    @test outneighbors(g, 5) == [4]

    # edges iterator
    edge_list = collect(edges(g))
    @test length(edge_list) == 4

    # rem_edge!
    @test rem_edge!(g, Graphs.SimpleEdge(2, 3))
    @test ne(g) == 3
    @test !has_edge(g, 2, 3)
    @test !rem_edge!(g, Graphs.SimpleEdge(2, 3))  # already removed

    # add_vertex!
    @test add_vertex!(g)
    @test nv(g) == 6
    @test has_vertex(g, 6)

    # rem_vertex! (last vertex)
    @test rem_vertex!(g, 6)
    @test nv(g) == 5
    @test !has_vertex(g, 6)

    # rem_vertex! (middle vertex — triggers relabeling)
    g2 = NXGraph(4)
    add_edge!(g2, Graphs.SimpleEdge(1, 2))
    add_edge!(g2, Graphs.SimpleEdge(2, 3))
    add_edge!(g2, Graphs.SimpleEdge(3, 4))
    @test rem_vertex!(g2, 2)
    @test nv(g2) == 3
    @test vertices(g2) == 1:3
    # Former vertex 4 is now vertex 2, was connected to 3
    @test has_edge(g2, 2, 3)  # old 4→3 becomes 2→3
    @test !has_edge(g2, 1, 2)  # old 1→2 was removed with vertex 2

    # copy
    g3 = NXGraph(3)
    add_edge!(g3, Graphs.SimpleEdge(1, 2))
    add_edge!(g3, Graphs.SimpleEdge(2, 3))
    g3c = copy(g3)
    @test nv(g3c) == nv(g3)
    @test ne(g3c) == ne(g3)
    add_edge!(g3c, Graphs.SimpleEdge(1, 3))
    @test ne(g3c) == 3
    @test ne(g3) == 2  # original unchanged

    # zero
    gz = zero(NXGraph)
    @test nv(gz) == 0
    @test ne(gz) == 0

    # eltype
    @test eltype(g) == Int

    # edgetype
    @test edgetype(g) == Graphs.SimpleGraphs.SimpleEdge{Int}

    # is_directed
    @test !is_directed(NXGraph)
end
