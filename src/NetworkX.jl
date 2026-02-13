module NetworkX

export NXGraph, NXDiGraph, NXAlgorithm, local_clustering_coefficient

import Graphs
using PythonCall

const nx = PythonCall.pynew()

function __init__()
    PythonCall.pycopy!(nx, pyimport("networkx"))
end

# ---------------------------------------------------------------------------
# NXGraph — wraps a networkx.Graph (undirected) as a Graphs.jl AbstractSimpleGraph
# ---------------------------------------------------------------------------

"""
    NXGraph <: Graphs.SimpleGraphs.AbstractSimpleGraph{Int}

Thin wrapper around a Python `networkx.Graph` object.
Nodes are stored as 1-based `Int` values to satisfy the Graphs.jl API contract
(`vertices(g) == 1:nv(g)`).
"""
mutable struct NXGraph <: Graphs.SimpleGraphs.AbstractSimpleGraph{Int}
    pyg::Py
end

"""
    NXGraph(n::Integer)

Create an undirected graph with `n` vertices (labeled 1 through `n`) and no edges.
"""
function NXGraph(n::Integer)
    pyg = nx.Graph()
    if n > 0
        pyg.add_nodes_from(pylist(1:n))
    end
    NXGraph(pyg)
end

# --- Graphs.jl required interface ---

Base.eltype(::NXGraph) = Int
Base.zero(::Type{NXGraph}) = NXGraph(0)

Graphs.is_directed(::Type{NXGraph}) = false
Graphs.edgetype(::NXGraph) = Graphs.SimpleGraphs.SimpleEdge{Int}

Graphs.nv(g::NXGraph) = pyconvert(Int, nx.number_of_nodes(g.pyg))
Graphs.ne(g::NXGraph) = pyconvert(Int, nx.number_of_edges(g.pyg))

Graphs.vertices(g::NXGraph) = 1:Graphs.nv(g)

Graphs.has_vertex(g::NXGraph, v::Integer) = pyconvert(Bool, g.pyg.has_node(v))
Graphs.has_edge(g::NXGraph, s::Integer, d::Integer) = pyconvert(Bool, g.pyg.has_edge(s, d))

function Graphs.outneighbors(g::NXGraph, v::Integer)
    Graphs.has_vertex(g, v) || return Int[]
    nbrs = pyconvert(Vector{Int}, pybuiltins.sorted(g.pyg.neighbors(v)))
    return nbrs
end

Graphs.inneighbors(g::NXGraph, v::Integer) = Graphs.outneighbors(g, v)

# --- Edge iterator ---

struct NXGraphEdgeIterator
    graph::NXGraph
end

Base.length(it::NXGraphEdgeIterator) = Graphs.ne(it.graph)
Base.eltype(::Type{NXGraphEdgeIterator}) = Graphs.SimpleGraphs.SimpleEdge{Int}

function Base.iterate(it::NXGraphEdgeIterator, state=nothing)
    if state === nothing
        pyiter = pybuiltins.iter(it.graph.pyg.edges())
        return _next_edge(pyiter)
    end
    return _next_edge(state)
end

function _next_edge(pyiter::Py)
    try
        edge = pybuiltins.next(pyiter)
        s = pyconvert(Int, edge[0])
        d = pyconvert(Int, edge[1])
        if s > d
            s, d = d, s
        end
        return (Graphs.SimpleGraphs.SimpleEdge{Int}(s, d), pyiter)
    catch e
        if e isa PyException
            return nothing
        end
        rethrow()
    end
end

Graphs.edges(g::NXGraph) = NXGraphEdgeIterator(g)

# --- Mutation ---

function Graphs.add_edge!(g::NXGraph, e::Graphs.SimpleGraphs.SimpleEdge)
    s, d = Graphs.src(e), Graphs.dst(e)
    if !Graphs.has_vertex(g, s) || !Graphs.has_vertex(g, d) || s == d
        return false
    end
    if Graphs.has_edge(g, s, d)
        return false
    end
    g.pyg.add_edge(s, d)
    return true
end

function Graphs.rem_edge!(g::NXGraph, e::Graphs.SimpleGraphs.SimpleEdge)
    s, d = Graphs.src(e), Graphs.dst(e)
    if !Graphs.has_edge(g, s, d)
        return false
    end
    g.pyg.remove_edge(s, d)
    return true
end

function Graphs.add_vertex!(g::NXGraph)
    n = Graphs.nv(g)
    g.pyg.add_node(n + 1)
    return true
end

function Graphs.rem_vertex!(g::NXGraph, v::Integer)
    n = Graphs.nv(g)
    if !Graphs.has_vertex(g, v)
        return false
    end
    if v < n
        # Relabel node n → v to maintain contiguous 1:n-1 vertices.
        # First, collect edges of node n.
        n_nbrs = pyconvert(Vector{Int}, pybuiltins.list(g.pyg.neighbors(n)))
        # Remove node v (and its edges)
        g.pyg.remove_node(v)
        # Remove node n (and its edges)
        g.pyg.remove_node(n)
        # Add node v back
        g.pyg.add_node(v)
        # Re-add edges of former node n under the label v
        for nbr in n_nbrs
            if nbr != v  # skip self-loops (shouldn't exist in simple graph)
                g.pyg.add_edge(v, nbr)
            end
        end
    else
        # Removing the last vertex — just remove it
        g.pyg.remove_node(v)
    end
    return true
end

function Base.copy(g::NXGraph)
    return NXGraph(g.pyg.copy())
end

# --- Conversion to/from Graphs.jl SimpleGraph ---

function Graphs.SimpleGraphs.SimpleGraph(g::NXGraph)
    n = Graphs.nv(g)
    sg = Graphs.SimpleGraphs.SimpleGraph{Int}(n)
    for e in Graphs.edges(g)
        Graphs.add_edge!(sg, e)
    end
    return sg
end

function NXGraph(g::Graphs.AbstractSimpleGraph)
    n = Graphs.nv(g)
    nxg = NXGraph(n)
    for e in Graphs.edges(g)
        nxg.pyg.add_edge(Graphs.src(e), Graphs.dst(e))
    end
    return nxg
end

# ---------------------------------------------------------------------------
# NXDiGraph — wraps a networkx.DiGraph (directed)
# ---------------------------------------------------------------------------

"""
    NXDiGraph <: Graphs.SimpleGraphs.AbstractSimpleDiGraph{Int}

Thin wrapper around a Python `networkx.DiGraph` object.
"""
mutable struct NXDiGraph <: Graphs.SimpleGraphs.AbstractSimpleGraph{Int}
    pyg::Py
end

function NXDiGraph(n::Integer)
    pyg = nx.DiGraph()
    if n > 0
        pyg.add_nodes_from(pylist(1:n))
    end
    NXDiGraph(pyg)
end

Base.eltype(::NXDiGraph) = Int
Base.zero(::Type{NXDiGraph}) = NXDiGraph(0)

Graphs.is_directed(::Type{NXDiGraph}) = true
Graphs.edgetype(::NXDiGraph) = Graphs.SimpleGraphs.SimpleEdge{Int}

Graphs.nv(g::NXDiGraph) = pyconvert(Int, nx.number_of_nodes(g.pyg))
Graphs.ne(g::NXDiGraph) = pyconvert(Int, nx.number_of_edges(g.pyg))

Graphs.vertices(g::NXDiGraph) = 1:Graphs.nv(g)

Graphs.has_vertex(g::NXDiGraph, v::Integer) = pyconvert(Bool, g.pyg.has_node(v))
Graphs.has_edge(g::NXDiGraph, s::Integer, d::Integer) = pyconvert(Bool, g.pyg.has_edge(s, d))

function Graphs.outneighbors(g::NXDiGraph, v::Integer)
    Graphs.has_vertex(g, v) || return Int[]
    return pyconvert(Vector{Int}, pybuiltins.sorted(g.pyg.successors(v)))
end

function Graphs.inneighbors(g::NXDiGraph, v::Integer)
    Graphs.has_vertex(g, v) || return Int[]
    return pyconvert(Vector{Int}, pybuiltins.sorted(g.pyg.predecessors(v)))
end

# --- Edge iterator for DiGraph ---

struct NXDiGraphEdgeIterator
    graph::NXDiGraph
end

Base.length(it::NXDiGraphEdgeIterator) = Graphs.ne(it.graph)
Base.eltype(::Type{NXDiGraphEdgeIterator}) = Graphs.SimpleGraphs.SimpleEdge{Int}

function Base.iterate(it::NXDiGraphEdgeIterator, state=nothing)
    if state === nothing
        pyiter = pybuiltins.iter(it.graph.pyg.edges())
        return _next_edge_di(pyiter)
    end
    return _next_edge_di(state)
end

function _next_edge_di(pyiter::Py)
    try
        edge = pybuiltins.next(pyiter)
        s = pyconvert(Int, edge[0])
        d = pyconvert(Int, edge[1])
        return (Graphs.SimpleGraphs.SimpleEdge{Int}(s, d), pyiter)
    catch e
        if e isa PyException
            return nothing
        end
        rethrow()
    end
end

Graphs.edges(g::NXDiGraph) = NXDiGraphEdgeIterator(g)

# --- Mutation for DiGraph ---

function Graphs.add_edge!(g::NXDiGraph, e::Graphs.SimpleGraphs.SimpleEdge)
    s, d = Graphs.src(e), Graphs.dst(e)
    if !Graphs.has_vertex(g, s) || !Graphs.has_vertex(g, d) || s == d
        return false
    end
    if Graphs.has_edge(g, s, d)
        return false
    end
    g.pyg.add_edge(s, d)
    return true
end

function Graphs.rem_edge!(g::NXDiGraph, e::Graphs.SimpleGraphs.SimpleEdge)
    s, d = Graphs.src(e), Graphs.dst(e)
    if !Graphs.has_edge(g, s, d)
        return false
    end
    g.pyg.remove_edge(s, d)
    return true
end

function Graphs.add_vertex!(g::NXDiGraph)
    n = Graphs.nv(g)
    g.pyg.add_node(n + 1)
    return true
end

function Graphs.rem_vertex!(g::NXDiGraph, v::Integer)
    n = Graphs.nv(g)
    if !Graphs.has_vertex(g, v)
        return false
    end
    if v < n
        out_nbrs = pyconvert(Vector{Int}, pybuiltins.list(g.pyg.successors(n)))
        in_nbrs = pyconvert(Vector{Int}, pybuiltins.list(g.pyg.predecessors(n)))
        g.pyg.remove_node(v)
        g.pyg.remove_node(n)
        g.pyg.add_node(v)
        for nbr in out_nbrs
            target = nbr == v ? v : nbr
            if target != v  # no self-loops
                g.pyg.add_edge(v, target)
            end
        end
        for nbr in in_nbrs
            source = nbr == v ? v : nbr
            if source != v  # no self-loops
                g.pyg.add_edge(source, v)
            end
        end
    else
        g.pyg.remove_node(v)
    end
    return true
end

function Base.copy(g::NXDiGraph)
    return NXDiGraph(g.pyg.copy())
end

function Graphs.SimpleGraphs.SimpleDiGraph(g::NXDiGraph)
    n = Graphs.nv(g)
    sg = Graphs.SimpleGraphs.SimpleDiGraph{Int}(n)
    for e in Graphs.edges(g)
        Graphs.add_edge!(sg, e)
    end
    return sg
end

function NXDiGraph(g::Graphs.AbstractSimpleGraph)
    n = Graphs.nv(g)
    nxg = NXDiGraph(n)
    for e in Graphs.edges(g)
        nxg.pyg.add_edge(Graphs.src(e), Graphs.dst(e))
    end
    return nxg
end

# ---------------------------------------------------------------------------
# NXAlgorithm — dispatch type for networkx algorithm implementations
# ---------------------------------------------------------------------------

"""
    NXAlgorithm

Algorithm dispatch type for NetworkX Python library implementations.
Pass `NXAlgorithm()` as a second argument to dispatch graph algorithms
to the networkx Python implementation. Non-NXGraph inputs are automatically
converted.

# Example
```julia
g = Graphs.path_graph(5)
Graphs.is_connected(g, NXAlgorithm())
Graphs.connected_components(g, NXAlgorithm())
```
"""
struct NXAlgorithm end

_to_nxgraph(g::NXGraph) = g
_to_nxgraph(g::Graphs.AbstractSimpleGraph) = NXGraph(g)

_to_nxdigraph(g::NXDiGraph) = g
_to_nxdigraph(g::Graphs.AbstractSimpleGraph) = NXDiGraph(g)

_to_nx(g::NXGraph) = g
_to_nx(g::NXDiGraph) = g
_to_nx(g::Graphs.AbstractSimpleGraph) = Graphs.is_directed(g) ? NXDiGraph(g) : NXGraph(g)

"""
    Graphs.is_connected(g::AbstractGraph, ::NXAlgorithm)

Test whether `g` is connected using networkx.
For directed graphs, tests weak connectivity.
"""
function Graphs.is_connected(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    if Graphs.is_directed(nxg)
        return pyconvert(Bool, nx.is_weakly_connected(nxg.pyg))
    else
        return pyconvert(Bool, nx.is_connected(nxg.pyg))
    end
end

"""
    Graphs.connected_components(g::AbstractGraph, ::NXAlgorithm)

Return the connected components of `g` using networkx.
"""
function Graphs.connected_components(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    if Graphs.is_directed(nxg)
        py_comps = nx.weakly_connected_components(nxg.pyg)
    else
        py_comps = nx.connected_components(nxg.pyg)
    end
    components = Vector{Int}[]
    for comp in py_comps
        push!(components, sort(pyconvert(Vector{Int}, pybuiltins.list(comp))))
    end
    return components
end

"""
    Graphs.degree(g::AbstractGraph, v::Integer, ::NXAlgorithm)

Return the degree of vertex `v` using networkx.
"""
function Graphs.degree(g::Graphs.AbstractGraph, v::Integer, ::NXAlgorithm)
    nxg = _to_nx(g)
    return pyconvert(Int, nxg.pyg.degree(v))
end

"""
    Graphs.diameter(g::AbstractGraph, ::NXAlgorithm)

Compute the diameter of `g` using networkx.
"""
function Graphs.diameter(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    return pyconvert(Int, nx.diameter(nxg.pyg))
end

"""
    Graphs.radius(g::AbstractGraph, ::NXAlgorithm)

Compute the radius of `g` using networkx.
"""
function Graphs.radius(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    return pyconvert(Int, nx.radius(nxg.pyg))
end

"""
    Graphs.density(g::AbstractGraph, ::NXAlgorithm)

Compute the density of `g` using networkx.
"""
function Graphs.density(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    return pyconvert(Float64, nx.density(nxg.pyg))
end

"""
    local_clustering_coefficient(g::AbstractGraph, v::Integer, ::NXAlgorithm)

Compute the local clustering coefficient of vertex `v` using networkx.
This function is not yet available in Graphs.jl — it is declared here
as a proof-of-concept for extending the Graphs.jl ecosystem with
algorithms only available in networkx.

!!! note
    Requires NetworkX.jl to be loaded. A future Graphs.jl release may
    add `local_clustering_coefficient` directly.
"""
function local_clustering_coefficient(g::Graphs.AbstractGraph, v::Integer, ::NXAlgorithm)
    nxg = _to_nx(g)
    return pyconvert(Float64, nx.clustering(nxg.pyg, v))
end

"""
    local_clustering_coefficient(g::AbstractGraph, v::Integer)

Compute the local clustering coefficient of vertex `v`.
Requires NetworkX.jl — raises an error hinting at the dependency.
"""
function local_clustering_coefficient(g::Graphs.AbstractGraph, v::Integer)
    error("local_clustering_coefficient requires NetworkX.jl. Use `local_clustering_coefficient(g, v, NXAlgorithm())` after `using NetworkX`.")
end

"""
    Graphs.pagerank(g::AbstractGraph{U}, ::NXAlgorithm; alpha=0.85) where U<:Integer

Compute PageRank of `g` using networkx. Returns a Dict{Int,Float64}.
"""
function Graphs.pagerank(g::Graphs.AbstractGraph{U}, ::NXAlgorithm; alpha=0.85) where U<:Integer
    nxg = _to_nx(g)
    pr = nx.pagerank(nxg.pyg; alpha=alpha)
    return pyconvert(Dict{Int,Float64}, pr)
end

"""
    Graphs.betweenness_centrality(g::AbstractGraph, ::NXAlgorithm; normalized=true)

Compute betweenness centrality of `g` using networkx. Returns a Dict{Int,Float64}.
"""
function Graphs.betweenness_centrality(g::Graphs.AbstractGraph, ::NXAlgorithm; normalized=true)
    nxg = _to_nx(g)
    bc = nx.betweenness_centrality(nxg.pyg; normalized=normalized)
    return pyconvert(Dict{Int,Float64}, bc)
end

"""
    Graphs.closeness_centrality(g::AbstractGraph, ::NXAlgorithm)

Compute closeness centrality of all vertices using networkx.
Returns a Dict{Int,Float64}.
"""
function Graphs.closeness_centrality(g::Graphs.AbstractGraph, ::NXAlgorithm)
    nxg = _to_nx(g)
    cc = nx.closeness_centrality(nxg.pyg)
    return pyconvert(Dict{Int,Float64}, cc)
end

end
