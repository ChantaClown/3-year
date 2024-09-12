using FileIO;
using JLD2;
using Images;

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 1 --------------------------------------------
# ----------------------------------------------------------------------------------------------


function fileNamesFolder(folderName::String, extension::String)
    if isdir(folderName)
        extension = uppercase(extension); 
        fileNames = filter(f -> endswith(uppercase(f), ".$extension"), readdir(folderName)) 
        fileNames_no_extension = map(f -> splitext(f)[1], fileNames)
        return(fileNames_no_extension)
    else
        error("The directory doesn't exist")
    end
end;



function loadDataset(datasetName::String, datasetFolder::String;
    datasetType::DataType=Float32)
    #
    # Codigo a desarrollar
    #
end;



function loadImage(imageName::String, datasetFolder::String;
    datasetType::DataType=Float32, resolution::Int=128)
    if !isfile(imageFile)
        return nothing
    end

    image = load(imageFile)
    image = Gray.(image) # Convierte la imagen a escala de grises
    image = imresize(image, (resolution, resolution)) # Cambia la resolución de la imagen
    image = convert(Array{datasetType}, image) # Cambia el tipo de datos de la imagen

    return image
end;


function convertImagesNCHW(imageVector::Vector{<:AbstractArray{<:Real,2}})
    imagesNCHW = Array{eltype(imageVector[1]), 4}(undef, length(imageVector), 1, size(imageVector[1],1), size(imageVector[1],2));
    for numImage in Base.OneTo(length(imageVector))
        imagesNCHW[numImage,1,:,:] .= imageVector[numImage];
    end;
    return imagesNCHW;
end;


function loadImagesNCHW(datasetFolder::String;
    datasetType::DataType=Float32, resolution::Int=128)
    # Obtener los nombres de archivos sin extensión .tif en la carpeta
    imageNames = fileNamesFolder(datasetFolder, ".tif")
    # Cargar todas las imágenes usando broadcast
    images = loadImage.(imageNames, Ref(datasetFolder); datasetType=datasetType, resolution=resolution)

    validImages = filter(x -> x !== nothing, images)
    imagesNCHW = convertImagesNCHW(validImages)

    return imagesNCHW
end;


showImage(image      ::AbstractArray{<:Real,2}                                      ) = display(Gray.(image));
showImage(imagesNCHW ::AbstractArray{<:Real,4}                                      ) = display(Gray.(     hcat([imagesNCHW[ i,1,:,:] for i in 1:size(imagesNCHW ,1)]...)));
showImage(imagesNCHW1::AbstractArray{<:Real,4}, imagesNCHW2::AbstractArray{<:Real,4}) = display(Gray.(vcat(hcat([imagesNCHW1[i,1,:,:] for i in 1:size(imagesNCHW1,1)]...), hcat([imagesNCHW2[i,1,:,:] for i in 1:size(imagesNCHW2,1)]...))));



function loadMNISTDataset(datasetFolder::String; labels::AbstractArray{Int,1}=0:9, datasetType::DataType=Float32)

    dataset = loadDataset("MNIST",datasetFolder)

    train_images = dataset[1]
    train_targets = dataset[2]
    test_images = dataset[3]
    test_targets = dataset[4]

    # Todas las etiquetas restantes marcados como -1
    if -1 in labels
        train_targets[.!in.(train_targets, [setdiff(labels,-1)])] .= -1;
        test_targets[.!in.(test_targets, [setdiff(labels,-1)])] .= -1;
    end;
    # Seleccionamos las imagenes segun los targets
    train_indices = in.(train_targets, [labels])
    test_indices = in.(test_targets, [labels])

    train_images_filtered = train_images[train_indices, :]
    train_targets_filtered = train_targets[train_indices]
    test_images_filtered = test_images[test_indices, :]
    test_targets_filtered = test_targets[test_indices]
    
    # Convertimos las imagenes a NCHW
    train_images_nchw = convertImagesNCHW(train_images_filtered)
    test_images_nchw = convertImagesNCHW(test_images_filtered)

    return train_images_nchw, train_targets_filtered, test_images_nchw, test_targets_filtered
end;


function intervalDiscreteVector(data::AbstractArray{<:Real,1})
    # Ordenar los datos
    uniqueData = sort(unique(data));
    # Obtener diferencias entre elementos consecutivos
    differences = sort(diff(uniqueData));
    # Tomar la diferencia menor
    minDifference = differences[1];
    # Si todas las diferencias son multiplos exactos (valores enteros) de esa diferencia, entonces es un vector de valores discretos
    isInteger(x::Float64, tol::Float64) = abs(round(x)-x) < tol
    return all(isInteger.(differences./minDifference, 1e-3)) ? minDifference : 0.
end;


function cyclicalEncoding(data::AbstractArray{<:Real,1})
    
    m = intervalDiscreteVector(data)
    data_min = minimum(data)
    data_max = maximum(data)
    
    # Obtener los datos normalizados
    # (m != 0 ? m : 1e-6) -> necesario el uso de un valor que evite la division por cero ?
    normalized_data = (data .- data_min) ./ (data_max - data_min + m)
    
    # Calculo de los vectores de sin/cos
    senos =  sin.(2 * pi .* normalized_data)
    cosenos = cos.(2 * pi .* normalized_data)
    return (senos, cosenos)
end;



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