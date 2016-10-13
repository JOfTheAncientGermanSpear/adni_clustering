using DataFrames

loadRoiCols() = [Symbol(r) for r in readcsv("../data/select_rois.csv")[:] if r != "BL_ICV"]

function loadRawData(raw_f)
  data = readtable(raw_f)

  roi_cols = loadRoiCols()

  data[[:RID; :BL_DX_coded; :BL_ICV; roi_cols]]
end



function loadData()
  data = readtable("../data/input_data_nas.csv")

  num_rows = size(data, 1)
  na_rows = reduce(zeros(Bool, num_rows), names(data)) do acc, r
    acc = acc | isna(data[r])
  end

  (sum(na_rows) > 0) && warn("na rows at $(find(na_rows))")

  data[!na_rows, :]
end


function loadNormalizedData()
  data = loadData()

  rois = loadRoiCols()

  normalized_data = copy(data)

  for r in rois
    normalized_data[r] = data[r] ./ data[:BL_ICV]
  end

  normalized_data
end


function loadPatients()
  data = loadNormalizedData()
  data[data[:BL_DX_coded] .== 1, :]
end
