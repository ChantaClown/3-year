using Flux;
using Flux.Losses;
using FileIO;
using JLD2;
using Images;
using DelimitedFiles;
using Test;
using Statistics;
include("tester.jl");

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 3 --------------------------------------------
# ----------------------------------------------------------------------------------------------

HopfieldNet = Array{Float32,2}

function trainHopfield(trainingSet::AbstractArray{<:Real,2})

    # Forumula de Hopfield
    w = (1 / size(trainingSet,1)) * (transpose(trainingSet) * trainingSet)
    # Diagonal a 0
    w[diagind(w)] .= 0
    w = convert(Matrix{Float32}, w)
    @assert typeof(w) == Matrix{Float32}
    return w

end;

function trainHopfield(trainingSet::AbstractArray{<:Bool,2})
    # Convertir los 0 a -1
    trainingSet = (2. .*trainingSet) .- 1
    return trainHopfield(trainingSet)
end;

function trainHopfield(trainingSetNCHW::AbstractArray{<:Bool,4})
    trainingSet = reshape(trainingSetNCHW, size(trainingSetNCHW,1), size(trainingSetNCHW,3)*size(trainingSetNCHW,4))
    return trainHopfield(trainingSet)
end;

function stepHopfield(ann::HopfieldNet, S::AbstractArray{<:Real,1})
    S = convert(Vector{Float32}, S)
    # Matriz de Pesos X Vector de salidas
    res = ann * S
    # Usar sign para crear el umbral
    return convert(Vector{Float32}, sign.(res))

end;
function stepHopfield(ann::HopfieldNet, S::AbstractArray{<:Bool,1})
    # Transformar a 0, 1
    S = (2. .* S) .- 1
    res = stepHopfield(ann, S)
    # Convertir a binario
    res .>= 0
   
    return convert(Vector{Bool}, res .>= 0f0)
end;


function runHopfield(ann::HopfieldNet, S::AbstractArray{<:Real,1})
    prev_S = nothing;
    prev_prev_S = nothing;
    while S!=prev_S && S!=prev_prev_S
        prev_prev_S = prev_S;
        prev_S = S;
        S = stepHopfield(ann, S);
    end;
    return S
end;
function runHopfield(ann::HopfieldNet, dataset::AbstractArray{<:Real,2})
    outputs = copy(dataset);
    for i in 1:size(dataset,1)
        outputs[i,:] .= runHopfield(ann, view(dataset, i, :));
    end;
    return outputs;
end;
function runHopfield(ann::HopfieldNet, datasetNCHW::AbstractArray{<:Real,4})
    outputs = runHopfield(ann, reshape(datasetNCHW, size(datasetNCHW,1), size(datasetNCHW,3)*size(datasetNCHW,4)));
    return reshape(outputs, size(datasetNCHW,1), 1, size(datasetNCHW,3), size(datasetNCHW,4));
end;


function addNoise(datasetNCHW::AbstractArray{<:Bool, 4}, ratioNoise::Real)
    noiseSet = copy(datasetNCHW)
    # Numero total de pixeles
    total_pixels = length(noiseSet)
    # Calculo de los índices de los píxeles a modificar
    pixels_to_change = Int(round(total_pixels * ratioNoise))
    indices = shuffle(1:total_pixels)[1:pixels_to_change]
    # Modificar los píxeles en los índices seleccionados (invertir su valor)
    noiseSet[indices] .= .!noiseSet[indices]
    return noiseSet
end;

function cropImages(datasetNCHW::AbstractArray{<:Bool,4}, ratioCrop::Real)
    croppedSet = copy(datasetNCHW)
    # Obtener el tamaño de las imágenes
    (_, _, _, width) = size(croppedSet)
    # Calcular el número de píxeles que se deben conservar
    pixels_to_keep = Int(round(width * (1 - ratioCrop)))
    # Comprobar el + 1
    croppedSet[:,:,:,pixels_to_keep+1:end] .= 0
    return croppedSet
end;

function randomImages(numImages::Int, resolution::Int)
    matrix = randn(numImages, 1, resolution, resolution)
    result = matrix .> 0 
    return result
end;

function averageMNISTImages(imageArray::AbstractArray{<:Real,4}, labelArray::AbstractArray{Int,1})
    # 
    labels = unique(labelArray)
    N = length(labels)
    
    # Crear la matriz de salida en formato NCHW, donde N es el número de dígitos únicos
    C, H, W = size(imageArray)[2:4]  # Obtener las dimensiones de las imágenes
    template_images = Array{eltype(imageArray)}(undef, N, C, H, W)
    
    # Promediar las imágenes por dígito
    for i in 1:N
        digit = labels[i]
        template_images[i, 1, :, :] = dropdims(mean(imageArray[labelArray .== digit, 1, :, :], dims=1), dims=1)
    end
    
    # Retornar las plantillas promedio y las etiquetas
    return template_images, labels
end; 

function classifyMNISTImages(imageArray::AbstractArray{<:Real,4}, templateInputs::AbstractArray{<:Real,4}, templateLabels::AbstractArray{Int,1})
    #
    outputs = fill(-1, size(imageArray, 1))

    for idx in 1:size(templateInputs, 1)
        template = templateInputs[[idx], :, :, :]; 
        label = templateLabels[idx]; 
        indicesCoincidence = vec(all(imageArray .== template, dims=[3,4])); 
        outputs[indicesCoincidence] .= label
    end;

    return outputs
end;

function calculateMNISTAccuracies(datasetFolder::String, labels::AbstractArray{Int,1}, threshold::Real)

    # Cargar el dataset MNIST
    train_images, train_labels, test_images, test_labels = loadMNISTDataset(datasetFolder; labels=labels, datasetType=Float32)
    
    # Obtener plantillas promedio
    template_images, template_labels = averageMNISTImages(train_images, train_labels)
    
    # Umbralizar las imágenes
    train_images_bool = train_images .>= threshold
    test_images_bool = test_images .>= threshold
    template_images_bool = template_images .>= threshold
    
    # Entrenar la red de Hopfield con las plantillas
    ann = trainHopfield(template_images_bool)
    
    # Calcular precisión en el conjunto de entrenamiento
    train_outputs = runHopfield(ann, train_images_bool)
    train_predictions = classifyMNISTImages(train_outputs, template_images_bool, template_labels)
    acc_train = mean(train_predictions .== train_labels)
    
    # Calcular precisión en el conjunto de test
    test_outputs = runHopfield(ann, test_images_bool)
    test_predictions = classifyMNISTImages(test_outputs, template_images_bool, template_labels)
    acc_test = mean(test_predictions .== test_labels)
    
    return (acc_train, acc_test)

end;


# ----------------------------------------------------------------------------------------------
# ------------------------------------- Test ---------------------------------------------------
# ----------------------------------------------------------------------------------------------


using Random

@testset "trainHopfield tests" begin
    # Crear un conjunto de entrenamiento pequeño (valores reales)
    trainingSetReal = randn(Float32, 5, 5)  # 5 patrones, 5 neuronas
    w_real = trainHopfield(trainingSetReal)
    @test typeof(w_real) == Matrix{Float32}
    @test size(w_real) == (5, 5)
    
    # Verificar que la diagonal sea cero
    @test all(diag(w_real) .== 0)
    
    # Probar la función con un conjunto booleano
    trainingSetBool = rand(Bool, 5, 5)  # 5 patrones, 5 neuronas
    w_bool = trainHopfield(trainingSetBool)
    @test typeof(w_bool) == Matrix{Float32}
    @test size(w_bool) == (5, 5)
    @test all(diag(w_bool) .== 0)
    
    # Probar la función con un conjunto NCHW booleano
    trainingSetNCHW = rand(Bool, 5, 1, 3, 3)  # 5 imágenes de 3x3
    w_nchw = trainHopfield(trainingSetNCHW)
    @test typeof(w_nchw) == Matrix{Float32}
    @test size(w_nchw) == (9, 9)  # 5 patrones, cada uno con 3x3 píxeles
end

@testset "stepHopfield tests" begin
    # Crear una matriz de pesos aleatoria y un vector de entrada
    ann = rand(Float32, 5, 5)
    inputReal = rand(Float32, 5)
    resultReal = stepHopfield(ann, inputReal)
    @test typeof(resultReal) == Vector{Float32}
    @test length(resultReal) == 5
    
    # Probar con un conjunto booleano
    inputBool = rand(Bool, 5)
    resultBool = stepHopfield(ann, inputBool)
    @test typeof(resultBool) == Vector{Bool}
    @test length(resultBool) == 5
end


@testset "addNoise tests" begin
    datasetNCHW = rand(Bool, 5, 1, 3, 3)
    noisyDataset = addNoise(datasetNCHW, 0.1)
    @test size(noisyDataset) == size(datasetNCHW)
end

@testset "cropImages tests" begin
    
    # Función para cargar una imagen y convertirla a booleano
    function loadImageAsBool(imagePath::String, resolution::Int=128)
        img = load(imagePath)                  # Cargar imagen
        img_resized = imresize(Float32.(img), (resolution, resolution))  # Redimensionar si es necesario
        binary_image = img_resized .> 0.5      # Convertir a formato booleano usando un umbral
        return binary_image
    end
    # Convertir la imagen a formato NCHW
    function convertToNCHW(image::AbstractArray{Bool})
        return reshape(image, 1, 1, size(image)...)  # Agregar las dimensiones de canal y batch: NCHW
    end

    imagePath = "/home/clown/3-year/machine_learning/dataset/cameraman.tif"
    binary_image = loadImageAsBool(imagePath)         # Cargar la imagen como binaria
    datasetNCHW = convertToNCHW(binary_image)         # Convertirla a formato NCHW
    
    # Aplicar el recorte
    croppedSet = cropImages(datasetNCHW, 0.5)
    
    # Mostrar la imagen recortada (opcional)
    using Images
    showImage(croppedSet)  # Mostrar la imagen como un array 2D
    
    # Test para comprobar si las últimas columnas son cero
    @test all(croppedSet[:, :, :, end-4:end] .== 0)  # Las últimas 5 columnas deben ser 0
    
end

@testset "randomImages tests" begin
    numImages = 5
    resolution = 10
    randomSet = randomImages(numImages, resolution)
    @test size(randomSet) == (5, 1, 10, 10)
    @test all(eltype(randomSet) == Bool)  # Las imágenes deben ser booleanas
    randomSet = randomImages(1, 128)
    showImage(randomSet)
end

@testset "MNIST tests" begin
    # Simular un dataset de MNIST (imágenes y etiquetas)
    images = rand(Float32, 100, 1, 28, 28)  # 100 imágenes de 28x28
    labels = rand(0:9, 100)  # 100 etiquetas aleatorias

    # Probar la función de promediar
    template_images, template_labels = averageMNISTImages(images, labels)
    @test size(template_images) == (10, 1, 28, 28)
    @test length(template_labels) == 10

    # Probar la función de clasificación
    classified_labels = classifyMNISTImages(images, template_images, template_labels)
    @test length(classified_labels) == 100
end

@testset "calculateMNISTAccuracies tests" begin
    # Simular etiquetas y configuraciones
    datasetFolder = "/home/clown/3-year/machine_learning/"

    # Test 1: Precisión con threshold bajo (0.5)
    @testset "Precisión con threshold bajo (0.5)" begin
        acc_train, acc_test = calculateMNISTAccuracies(datasetFolder, [7, 8, 9], 0.5)
        @test acc_train == 0
        @test acc_test == 0
    end

    
    # Test 3: Un solo dígito en las etiquetas
    @testset "Un solo dígito en las etiquetas" begin
        acc_train, acc_test = calculateMNISTAccuracies(datasetFolder, [7], 0.5)
        @test acc_train == 1.0
        @test acc_test == 1.0
    end
    
    
    # Test 5: Dataset vacío
    @testset "Dataset vacío" begin
        function loadMNISTDataset(datasetFolder; labels, datasetType=Float32)
            return zeros(Float32, 0, 1, 3, 3), Int[], zeros(Float32, 0, 1, 3, 3), Int[]
        end
    
        acc_train, acc_test = calculateMNISTAccuracies(datasetFolder, [7, 8, 9], 0.5)
        @test acc_train == 0.0  # No hay datos, precisión debe ser 0
        @test acc_test == 0.0
    end
end;
