using Clustering
using DataFrames

include("loadData.jl")


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
