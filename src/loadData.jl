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


function loadNormalizedData(normalize_fn::Function)
  data = loadData()

  rois = loadRoiCols()

  normalized_data = copy(data)

  for r in rois
    normalized_data[r] = normalize_fn(r, data[r], data[:BL_ICV])
  end

  normalized_data
end


loadLogNormalizedData() = loadNormalizedData((x, r, b) -> log(r) - log(b))
loadDivNormalizedData() = loadNormalizedData((x, r, b) -> r ./ b)
load1000NormalizedData() = loadNormalizedData((x, r, b) -> r ./ (1e-3 * b))


function loadPatients(fn::Function = loadData)
  data = fn()
  data[data[:BL_DX_coded] .== 1, :]
end


function loadControls(fn::Function = loadData)
  data = fn()
  data[data[:BL_DX_coded] .== 0, :]
end


loadDivPatients() = loadPatients(loadDivNormalizedData)
loadLogPatients() = loadPatients(loadLogNormalizedData)
load1000Patients() = loadPatients(load1000NormalizedData)

loadDivControls() = loadControls(loadDivNormalizedData)
loadLogControls() = loadControls(loadLogNormalizedData)

function loadZscorePatients()
  data_controls = loadDivControls()
  rois = loadRoiCols()

  data_patients = loadDivPatients()
  data_patients_z = copy(data_patients)

  for r in rois
    mn, standard = mean_and_std(data_controls[r])
    data_patients_z[r] = (data_patients_z[r] .- mn) ./ standard
  end

  data_patients_z
end
