using Clustering
using DataFrames

include("loadData.jl")


function runKmeans(n_clusters=4, data=loadPatients())
  rois = loadRoiCols()
  kmeans(Matrix(data[rois])', n_clusters)
end


function centersDf(y::KmeansResult)
  rois = loadRoiCols()

  centers = y.centers

  @assert length(rois) == size(centers, 1)

  ret = DataFrame(roi = rois)
  for c in 1:size(centers, 2)
    ret[Symbol("mean_", c)] = centers[:, c]
  end

  ret
end


function assignmentsDf(y::KmeansResult, rids=loadPatients()[:RID])
  assignments = y.assignments

  @assert length(rids) == length(assignments)

  DataFrame(rid=rids, assignment = assignments)
end
