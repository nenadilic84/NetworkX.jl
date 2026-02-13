# NetworkX.jl

[![CI](https://github.com/nenadilic84/NetworkX.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/nenadilic84/NetworkX.jl/actions/workflows/ci.yml)

A Julia wrapper around Python's [NetworkX](https://networkx.org/) graph library, providing seamless interop with the [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) ecosystem.

## Features

- **`NXGraph`** and **`NXDiGraph`** types that implement the full `Graphs.jl` `AbstractGraph` interface
- Automatic Python environment management via [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) and [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl)
- Zero-copy conversion between Graphs.jl `SimpleGraph`/`SimpleDiGraph` and NetworkX types
- **`NXAlgorithm`** dispatch type to run NetworkX algorithm implementations on any Graphs.jl graph
- New functions like `local_clustering_coefficient` that expose NetworkX-only algorithms to Julia

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/nenadilic84/NetworkX.jl")
```

## Quick Start

```julia
using NetworkX, Graphs

# Create an undirected graph with 5 vertices
g = NXGraph(5)
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 5)

nv(g)  # 5
ne(g)  # 4

# Use NetworkX algorithms on any Graphs.jl graph
g2 = path_graph(10)
Graphs.is_connected(g2, NXAlgorithm())        # true
Graphs.diameter(g2, NXAlgorithm())             # 9
Graphs.pagerank(g2, NXAlgorithm())             # Dict{Int,Float64}
Graphs.betweenness_centrality(g2, NXAlgorithm())

# Algorithms only available in NetworkX
local_clustering_coefficient(g2, 3, NXAlgorithm())  # Float64

# Convert between Graphs.jl and NetworkX types
sg = SimpleGraph(g)          # NXGraph -> SimpleGraph
nxg = NXGraph(sg)            # SimpleGraph -> NXGraph
```

## Supported Algorithm Dispatches

Pass `NXAlgorithm()` as a second argument to use NetworkX implementations:

| Function | Description |
|----------|-------------|
| `Graphs.is_connected(g, NXAlgorithm())` | Test connectivity (weak for digraphs) |
| `Graphs.connected_components(g, NXAlgorithm())` | Connected components |
| `Graphs.degree(g, v, NXAlgorithm())` | Vertex degree |
| `Graphs.diameter(g, NXAlgorithm())` | Graph diameter |
| `Graphs.radius(g, NXAlgorithm())` | Graph radius |
| `Graphs.density(g, NXAlgorithm())` | Graph density |
| `Graphs.pagerank(g, NXAlgorithm())` | PageRank centrality |
| `Graphs.betweenness_centrality(g, NXAlgorithm())` | Betweenness centrality |
| `Graphs.closeness_centrality(g, NXAlgorithm())` | Closeness centrality |
| `local_clustering_coefficient(g, v, NXAlgorithm())` | Local clustering coefficient |

## Related Packages

Part of the [JuliaGraphs](https://github.com/JuliaGraphs) ecosystem:
- [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) - Core graph types and algorithms
- [IGraphs.jl](https://github.com/JuliaGraphs/IGraphs.jl) - igraph C library wrapper
- [VNGraphs.jl](https://github.com/JuliaGraphs/VNGraphs.jl) - nauty/Traces wrapper

## License

MIT
