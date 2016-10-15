using Clustering
using DataFrames
using Lazy
using Plots

include("loadData.jl")


function tryDifferentClusters(data, dists=calcDists(data); max_n=10)
  num_subjs = size(data, 2)

  clusters = zeros(Int64, num_subjs * (max_n - 1))
  distances = zeros(Float64, num_subjs * (max_n - 1) )

  for i in 2:max_n
    ys = map(j -> kmeans(data, i), 1:10)

    best_y = reduce(ys) do acc, y
      y.totalcost < acc.totalcost ? y : acc
    end

    ixs = begin
      offset = (i - 2) * num_subjs
      start = offset + 1
      stop = offset + num_subjs
      start:stop
    end
    clusters[ixs] = i
    distances[ixs] = silhouettes(best_y, dists)
  end

  DataFrame(cluster=clusters, distance=distances)
end


function compareDifferentClusters(data, dists=calcDists(data);
  max_n=10, compare_fn=varinfo)

  kmeans_per_cluster = 10
  compares_per_cluster = sum([i-1 for i in 2:kmeans_per_cluster])
  clusters = zeros(Int64, compares_per_cluster * (max_n - 1))
  compares = zeros(Float64, compares_per_cluster * (max_n - 1))

  for n in 2:max_n
    ys = map(j -> kmeans(data, n), 1:10)
    ixs = begin
      offset = (n - 2) * compares_per_cluster
      start = offset + 1
      stop = offset + compares_per_cluster
      start:stop
    end
    compares[ixs] = [
      compare_fn(ys[i], ys[j]) for i in 1:length(ys) for j in (i+1):length(ys)
    ]

    clusters[ixs] = n
  end

  DataFrame(cluster=clusters, compare=compares)
end


function visualizeCluster(df;
  x_axis=:cluster, y_axis=setdiff(names(df), [x_axis])[1])

  violin(df, x_axis, y_axis, marker=(0.2, :blue, stroke(0)))
  boxplot!(df, x_axis, y_axis, marker=(0.3, :orange, stroke(2)))
end


function runKmeans(;n_clusters=4, data=loadLogPatients())
  rois = loadRoiCols()
  kmeans(Matrix(data[rois])', n_clusters, display=:final)
end


function centersDf(y::KmeansResult)
  rois = loadRoiCols()

  centers = y.centers

  @assert length(rois) == size(centers, 1)

  ret = DataFrame(roi = rois)

  is_min = centers .== minimum(centers, 2) + 0.
  for c in 1:size(centers, 2)
    ret[Symbol("mean_", c)] = centers[:, c]
    ret[Symbol("is_min_", c)] = is_min[:, c]
  end

  ret
end


function assignmentsDf(y::KmeansResult=runKmeans(), rids=loadLogPatients()[:RID])
  assignments = y.assignments

  @assert length(rids) == length(assignments)

  DataFrame(rid=rids, assignment = assignments)
end


function calcDists(data)
  num_subjs = size(data, 2)

  dists = zeros(Float64, num_subjs, num_subjs)
  for i in 1:num_subjs
    for j in (i + 1):num_subjs
      dist = norm(data[:, i] .- data[:, j])
      dists[i, j] = dists[j, i] = dist
    end
  end

  dists
end
