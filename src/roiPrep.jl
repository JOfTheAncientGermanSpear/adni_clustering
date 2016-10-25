using DataFrames
using Lazy

include("loadData.jl")

function createDkPolished(write_f=true)
  dk = readtable("../data/rois/dk_coords.csv")
  dk[:name] = [lowercase(n[2:end]) for n in dk[:name]]
  dk[:name_full] = map(dk[:name_full]) do n
    @> n[3:end] begin
      lowercase
      replace(" cortex", "")
      replace(" gyrus", "")
      replace(" lobule", "")
      replace(" ", "")
      replace("bankofthesuperiortemporalsulcus", "bankssts")
    end
  end

  rename!(dk, Dict(:name_full=>:roi, :name=>:roi_dk))

  if(write_f)
    writetable("../data/rois/dk_polished.csv", dk)
  end

  dk
end


dkPolished() = readtable("../data/rois/dk_polished.csv")


getRoi(select_roi) = @> r"^(BL_)([L|R])?(.*?)(_)?(G)?(Vol)?$" begin
  match(select_roi)
  getindex(3)
  lowercase
end

function getHemi(select_roi)
  m = match(r"^BL_([L|R]).*", select_roi)
  isa(m, Void) ? "NA" : m[1]
end

function createSelectRoisPolished(write_f=true)
  rois = readcsv("../data/rois/select_rois.csv")[:];
  rois_pol = [getRoi(r) for r in rois]
  hemis = [getHemi(r) for r in rois]

  ret = DataFrame(roi=rois_pol, select_roi=rois, hemi=hemis)

  if(write_f)
    writetable("../data/rois/rois_polished.csv", ret)
  end

  ret
end


roisPolished() = readtable("../data/rois/rois_polished.csv")


function createNodeTables(write_f=true)
  dk = dkPolished()
  rois = roisPolished()

  all_data = @> "../data/output/centers.csv" begin
    readtable
    rename!(:roi, :select_roi)
    join(rois, on=:select_roi)
    join(dk, on=[:roi, :hemi])
  end

  map(1:4) do mn
    mn_col = Symbol("mean_", mn)
    DataFrame(x = all_data[:x_mni],
              y = all_data[:y_mni],
              z = all_data[:z_mni],
              color = all_data[mn_col],
              size = all_data[mn_col],
              label = all_data[:roi_dk]
    )
  end
end
