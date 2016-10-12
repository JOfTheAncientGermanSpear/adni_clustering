using Clustering
using DataFrames

include("loadData.jl")


function runKmeans(n_clusters=4)
  rois = loadRoiCols()
  data = loadNormalizedData()
  kmeans(Matrix(data[rois])', n_clusters)
end


function centersDf(y::KmeansResult)
  rois = loadRoiCols()

  centers = y.centers

  @assert length(rois) == size(centers, 1)

  ret = DataFrame(roi = rois)
  for c in 1:size(centers, 2)
    ret[Symbol("dim_", c)] = centers[:, c]
  end

  ret
end


function assignmentsDf(y::KmeansResult)
  assignments = y.assignments

  rids = loadNormalizedData()[:RID]

  @assert length(rids) == length(assignments)

  DataFrame(rid=rids, assignment = assignments)
end
