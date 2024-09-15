using FileIO;
using JLD2;
using Images;
using DelimitedFiles;
using Test;

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
    
    # Full path of the file
    filePath = joinpath(abspath(datasetFolder), datasetName * ".tsv")

    # Check if the file exist
    if !isfile(filePath)
        return nothing
    end

    file = readdlm(filePath, '\t', header=true)
    # Data and headers
    rawData, headers = file

    # Search the first header that matches targets
    headers_vec = vec(headers)
    targets_col = findfirst(isequal("target"), headers_vec)
    
    if isnothing(targets_col)
        error("The Dataset doesn't exist.")
    end;
    # Select the cols that aren't targets
    inputs = rawData[:, setdiff(1:size(rawData, 2), targets_col)]
    targets = rawData[:, targets_col]

    # Convert into the correct DataTypes
    if !isnothing(datasetType)
        inputs = convert(Matrix{datasetType}, inputs)
    else
        inputs = convert(Matrix{Float32}, inputs)
    end
    targets = convert(Vector{Bool}, vec(targets))

    return inputs, targets
end;



function loadImage(imageName::String, datasetFolder::String;
    datasetType::DataType=Float32, resolution::Int=128)
    
    filePath = joinpath(abspath(datasetFolder), imageName * ".tif")

    if !isfile(filePath)
        return nothing
    end

    image = load(filePath)
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
    

    if !isdir(datasetFolder)
        return nothing
    end

    # Obtener los nombres de archivos sin extensión .tif en la carpeta
    imageNames = fileNamesFolder(datasetFolder, "tif")
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

    filePath = joinpath(abspath(datasetFolder), "MNIST.jld2")

    # Check if the file exist
    if !isfile(filePath)
        return nothing
    end
    
    dataset = JLD2.load(filePath)
    train_images = dataset["train_imgs"]
    train_targets = dataset["train_labels"]
    test_images = dataset["test_imgs"]
    test_targets = dataset["test_labels"]
    
    # All other tags labeled as -1
    if -1 in labels
        train_targets[.!in.(train_targets, [setdiff(labels,-1)])] .= -1;
        test_targets[.!in.(test_targets, [setdiff(labels,-1)])] .= -1;
    end;
    # Select the indicated targets
    train_indices = in.(train_targets, [labels])
    test_indices = in.(test_targets, [labels])
    
    train_images_filtered = train_images[train_indices, :]
    train_targets_filtered = train_targets[train_indices]
    test_images_filtered = test_images[test_indices, :]
    test_targets_filtered = test_targets[test_indices]
    
    # Convert images to NCHW format
    train_images_nchw = convertImagesNCHW(vec(train_images_filtered))
    test_images_nchw = convertImagesNCHW(vec(test_images_filtered))

    if !isnothing(datasetType)
        train_images_nchw = convert(Array{datasetType}, train_images_nchw)
        test_images_nchw = convert(Array{datasetType}, test_images_nchw)
    else
        train_images_nchw = convert(Array{Float32}, train_images_nchw)
        test_images_nchw = convert(Array{Float32}, test_images_nchw)
    end
    
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
    #=
    Puede fallar si todos los valores son iguales
    =#
    
    m = intervalDiscreteVector(data)
    data_min, data_max = extrema(data)
    # Obtain normalized data
    # (m != 0 ? m : 1e-6) -> necesario el uso de un valor que evite la division por cero ?
    # @. convierte todas las expresiones a .
    normalized_data = (data .- data_min) ./ (data_max - data_min + m)
    # Obtain sin and cos vectors
    senos =  sin.(2 * pi * normalized_data)
    cosenos = cos.(2 * pi * normalized_data)
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
    path = joinpath(abspath(datasetFolder))
    
    inputs = readdlm(path * "/elec2_data.dat", ' ')
    targets = readdlm(path * "/elec2_label.dat", ' ')
    
    encoded_targets = convert.(Bool, vec(targets))
    
    # Removes cols 1 and 4
    columns = setdiff(1:size(inputs,2), [1,4]) 
    
    data_cleaned = inputs[:, columns]
    # Encode inputs into sin and cos
    sin_inputs, cos_inputs = cyclicalEncoding(data_cleaned[:,1])
    final_inputs = hcat(sin_inputs, cos_inputs, data_cleaned[:, 2:end])
    # Convert to the DataType
    final_inputs = convert.(datasetType, final_inputs)

    return final_inputs, encoded_targets
end;


# ----------------------------------------------------------------------------------------------
# ------------------------------------- Test ---------------------------------------------------
# ----------------------------------------------------------------------------------------------

# ------------------------------------- fileNamesFolder ---------------------------------------------------

@testset "fileNamesFolder" begin
    datasetFolder = "machine_learning/ej1/"

    string_vector = fileNamesFolder(datasetFolder,"pdf")
    print(string_vector)
    @test length(string_vector) >= 1
    @test string_vector != ""
    @test string_vector != "build.jl"

    # Test with existing directory and files
    mktempdir() do tmp_dir
        # Create some test files
        touch(joinpath(tmp_dir, "test1.PDF"))
        touch(joinpath(tmp_dir, "test2.pdf"))
        touch(joinpath(tmp_dir, "test3.txt"))
        
        result = fileNamesFolder(tmp_dir, "pdf")
        
        @test issubset(["test1", "test2"], result)
        @test length(result) == 2
        @test !in("test3", result)
    end
    
    # Test with non-existent directory
    @test_throws ErrorException fileNamesFolder("non_existent_dir", "pdf")
    
    # Test with empty directory
    mktempdir() do tmp_dir
        result = fileNamesFolder(tmp_dir, "pdf")
        @test isempty(result)
    end
    
    # Test case insensitivity
    mktempdir() do tmp_dir
        touch(joinpath(tmp_dir, "test.PDF"))
        result = fileNamesFolder(tmp_dir, "pdf")
        @test result == ["test"]
    end
end

# ------------------------------------- loadDataset ---------------------------------------------------

@testset "loadDataset" begin
    # Asumimos que adult.tsv está en el directorio "machine_learning/"
    datasetFolder = "machine_learning/dataset/"
    datasetName = "adult"

    # Test de carga exitosa
    result = loadDataset(datasetName, datasetFolder)
    inputs, targets = result
    @test !isnothing(result) # "El dataset no se pudo cargar"
       
    if !isnothing(result)
        inputs, targets = result

        # Verificar que inputs y targets no están vacíos
        @test !isempty(inputs) # "La matriz de inputs está vacía"
        @test !isempty(targets) # "El vector de targets está vacío"

        # Verificar que el número de filas en inputs y targets coincide
        @test size(inputs, 1) == length(targets) # "El número de filas en inputs y targets no coincide"

        # Verificar el tipo de datos
        @test eltype(inputs) == Float32 # "El tipo de datos de inputs no es Float32"
        @test eltype(targets) == Bool # "El tipo de datos de targets no es Bool"

        # Verificar que targets solo contiene valores booleanos
        @test all(x -> x in [true, false], targets) # "Targets contiene valores que no son booleanos"

        # Imprimir información sobre el dataset para revisión manual
        println("Número de muestras: ", size(inputs, 1))
        println("Número de características: ", size(inputs, 2))
        println("Proporción de targets positivos: ", sum(targets) / length(targets))
    end

    # Test con un archivo que no existe
    @test isnothing(loadDataset("non_existent.tsv", datasetFolder))

    # Test con un directorio que no existe
    @test isnothing(loadDataset(datasetName, "non_existent_folder/"))
end;

# ------------------------------------- loadImage ---------------------------------------------------

@testset "loadImage" begin

    imageName = "cameraman"
    datasetFolder = "machine_learning/dataset/"

    image_matrix = loadImage(imageName, datasetFolder)
    @test !isempty(image_matrix) 
    @test size(image_matrix, 2) == 128 
    @test all(0 .<= image_matrix .<= 1) # Verifica que todos los valores de píxeles están en el rango 0-255    

    image_resulution = loadImage(imageName, datasetFolder, resolution=256)
    @test !isempty(image_resulution) 
    @test size(image_resulution, 2) == 256 
    @test all(0 .<= image_resulution .<= 1) # Verifica que todos los valores de píxeles están en el rango 0-255end
end;

# ------------------------------------- loadImagesNCHW ---------------------------------------------------

@testset "loadImagesNCHW" begin

    datasetFolder = "machine_learning/dataset/"

    image_matrix = loadImagesNCHW(datasetFolder)
    @test !isempty(image_matrix) 
    @test size(image_matrix, 4) == 128 
    @test all(0 .<= image_matrix .<= 1) # Verifica que todos los valores de píxeles están en el rango 0-255    

    image_resulution = loadImagesNCHW(datasetFolder, resolution=256)
    @test !isempty(image_resulution) 
    @test size(image_resulution, 4) == 256 
    @test all(0 .<= image_resulution .<= 1) # Verifica que todos los valores de píxeles están en el rango 0-255end

    @test isnothing(loadImagesNCHW("non_existent_folder/"))
    @test_throws ArgumentError loadImagesNCHW(datasetFolder, resolution=-1)

end;

# ------------------------------------- loadMNISTDataset ---------------------------------------------------
@testset "loadMNISTDataset" begin

    datasetFolder = "machine_learning/dataset/"

    train_images_nchw, train_targets_filtered, test_images_nchw, test_targets_filtered = loadMNISTDataset(datasetFolder)

    @test !isempty(train_images_nchw)
    @test !isempty(test_images_nchw)
    @test length(train_targets_filtered) == size(train_images_nchw, 1)
    @test length(test_targets_filtered) == size(test_images_nchw, 1)
    
    train_images_nchw, train_targets_filtered, test_images_nchw, test_targets_filtered = loadMNISTDataset(datasetFolder, labels=[3,4,9])
    @test !isempty(train_images_nchw)
    @test !isempty(test_images_nchw)
    @test length(train_targets_filtered) == size(train_images_nchw, 1)
    @test length(test_targets_filtered) == size(test_images_nchw, 1)

    train_images_nchw, train_targets_filtered, test_images_nchw, test_targets_filtered = loadMNISTDataset(datasetFolder, labels=[3,4,9,-1])
    @test !isempty(train_images_nchw)
    @test !isempty(test_images_nchw)
    @test length(train_targets_filtered) == size(train_images_nchw, 1)
    @test length(test_targets_filtered) == size(test_images_nchw, 1)

    train_images_nchw, train_targets_filtered, test_images_nchw, test_targets_filtered = loadMNISTDataset(datasetFolder, datasetType=Float64)
    @test typeof(train_images_nchw) == Array{Float64,4}
    @test typeof(test_images_nchw) == Array{Float64,4}
    
end;

# ------------------------------------- cyclicalEncoding ---------------------------------------------------

@testset "cyclicalEncoding" begin
    # Test with non-uniform spacing and values outside [0, 1]
    data_non_uniform = [-1.0, 0.0, 0.3, 1.0, 2.0]
    senos_non_uniform, cosenos_non_uniform = cyclicalEncoding(data_non_uniform)
    # @test isapprox(senos_non_uniform[1], senos_non_uniform[end]) -> comprobar si falla la correccion
    @test isapprox(cosenos_non_uniform[1], cosenos_non_uniform[end])
    @test all(-1 .<= senos_non_uniform .<= 1)
    @test all(-1 .<= cosenos_non_uniform .<= 1)

    # Test division by zero protection (if implemented)
    data_same = [1.0, 0, 1.0]
    senos_same, cosenos_same = cyclicalEncoding(data_same)
    @test !any(isnan, senos_same)
    @test !any(isnan, cosenos_same)
end

# ------------------------------------- loadStreamLearningDataset ---------------------------------------------------

@testset "loadStreamLearningDataset" begin

    # Asume que tienes una carpeta de datos de prueba
    test_folder = "/home/chantaclown/3-year/machine_learning/dataset/"
    
    # Test 1: Verificar que la función se ejecuta sin errores
    @test_nowarn loadStreamLearningDataset(test_folder)
    
    # Cargar los datos para los siguientes tests
    inputs, targets = loadStreamLearningDataset(test_folder)
    
    # Test 2: Verificar las dimensiones de la salida
    @test size(inputs, 2) == 7  # Debe haber 7 columnas en inputs
    @test size(inputs, 1) == length(targets)  # El número de filas debe coincidir con el número de targets
    
    # Test 3: Verificar el tipo de datos
    @test eltype(inputs) == Float32  # Por defecto debe ser Float32
    @test eltype(targets) == Bool
    
    # Test 4: Verificar que los valores de seno y coseno están en el rango correcto
    @test all(-1 .<= inputs[:, 1] .<= 1)  # Columna de seno
    @test all(-1 .<= inputs[:, 2] .<= 1)  # Columna de coseno
    
    # Test 5: Verificar que los targets son booleanos
    @test all(x -> x isa Bool, targets)
    
    # Test 6: Probar con un tipo de dato diferente
    inputs_float64, _ = loadStreamLearningDataset(test_folder, datasetType=Float64)
    @test eltype(inputs_float64) == Float64
    
    # Test 7: Verificar que no hay valores faltantes (NaN) en los inputs
    @test !any(isnan, inputs)
    
    # Test 8: Verificar que las columnas de seno y coseno son ortogonales (su producto punto debe ser cercano a cero)
    @test abs(dot(inputs[:, 1], inputs[:, 2])) < 1e-6
end