using DataFrames
using Lazy

include("loadData.jl")


function calculateCentroids(write_to_file=false)
  roi_cols = loadRoiCols()

  df = begin
    clus_result = readtable("../data/output/ward_cluster_result.csv")
    pat_z = readtable("../data/patients_z.csv")
    join(clus_result, pat_z, on=:RID)[[:group; roi_cols]]
  end

  groups = unique(df[:group])

  df_mean = reduce(DataFrame(), roi_cols) do acc, r
    curr = DataFrame(roi=r, mingroup=-1)

    min_g = Inf
    for g in groups
      mn = df[df[:group] .== g, r] |> mean
      curr[Symbol(:mean, "_", g)] = mn

      if mn < min_g
        min_g = mn
        curr[:mingroup] = g
      end
    end

    isempty(acc) ? curr : vcat(acc, curr)
  end

  if write_to_file
    writetable("../data/output/ward_cluster_means.csv", df_mean)
  end

  df_mean
end
