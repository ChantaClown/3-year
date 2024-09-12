
function loadStreamLearningDataset(datasetFolder::String; datasetType::DataType=Float32)
    #=
    abspath = abspath("file.txt")
    "/Users/username/file.txt"
    
    joinpath = joinpath("path", "to", "file.txt")
    "path/to/file.txt"

    readdlm = numeric_data = readdlm("numeric_data.txt", ',', '\n')
    3×2 Array{Float64,2}:
    1.0   2.0
    3.0   4.0
    5.0   6.0
    =#
    inputs, targets = loadDataset("elec2", datasetFolder)
    # Procesado de targets
    encoded_targets = cyclicalEncoding(targets)

    # Procesado de inputs
    path = joinpath(abspath(inputs))
    matrix_inputs = readdlm(path, ' ')

    # Eliminamos las matrices 1 y 4
    columns = setdiff(1:size(matrix_inputs,2), [1,4]) 

    data_cleaned = matrix_inputs[:, columns]
    # Primera columana de data_cleaned ?
    sin_inputs, cos_inputs = cyclicalEncoding(data_cleaned[:,1])
    concatenated_vectors = hcat(sin_inputs, cos_inputs)
    
    return hcat(concatenated_vectors, data_cleaned), vec(encoded_targets)
end;
