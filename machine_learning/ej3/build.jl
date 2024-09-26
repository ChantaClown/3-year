# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 2 --------------------------------------------
# ----------------------------------------------------------------------------------------------

using Flux;
using Flux.Losses;
using FileIO;
using JLD2;
using Images;
using DelimitedFiles;
using Test;
using Statistics,
include("firmas(1).jl")

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 3 --------------------------------------------
# ----------------------------------------------------------------------------------------------

HopfieldNet = Array{Float32,2}

function trainHopfield(trainingSet::AbstractArray{<:Real,2})

    # Forumula de Hopfield
    w = (1 / size(trainingSet,2)) * (transpose(trainingSet) * trainingSet)
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
    (_, _, height, width) = size(croppedSet)
    # Calcular el número de píxeles que se deben conservar
    numPixelsToKeep = Int(round(width * (1 - ratioCrop)))
    # Crear un indice de la parte derecha a poner a 0
    mask = hcat(ones(Bool, numPixelsToKeep), zeros(Bool, width - numPixelsToKeep))
    # Aplicar la mascara a la parte derecha de cada imagen
    croppedSet .= croppedSet .* reshape(mask, 1, 1, height, width)
    return croppedSet
end;

function randomImages(numImages::Int, resolution::Int)
    #
    # Codigo a desarrollar
    #
end;

function averageMNISTImages(imageArray::AbstractArray{<:Real,4}, labelArray::AbstractArray{Int,1})
    # 
    # Codigo a desarrollar
    # 
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
    train_outputs = stepHopfield(ann, train_images_bool)
    train_predictions = classifyMNISTImages(train_outputs, template_images_bool, template_labels)
    acc_train = mean(train_predictions .== train_labels)
    
    # Calcular precisión en el conjunto de test
    test_outputs = stepHopfield(ann, test_images_bool)
    test_predictions = classifyMNISTImages(test_outputs, template_images_bool, template_labels)
    acc_test = mean(test_predictions .== test_labels)
    
    return (acc_train, acc_test)

end;



croppedSet = copy(datasetNCHW)
# Obtener el tamaño de las imágenes
(_, _, height, width) = size(croppedSet)
# Calcular el número de píxeles que se deben conservar
numPixelsToKeep = Int(round(width * (1 - ratioCrop)))
# Crear un indice de la parte derecha a poner a 0
mask = hcat(ones(Bool, numPixelsToKeep), zeros(Bool, width - numPixelsToKeep))
# Aplicar la mascara a la parte derecha de cada imagen
croppedSet .= croppedSet .* reshape(mask, 1, 1, height, width)
return croppedSet