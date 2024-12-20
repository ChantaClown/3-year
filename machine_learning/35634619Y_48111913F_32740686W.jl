using Flux;
using Flux.Losses;
using FileIO;
using JLD2;
using Images;
using DelimitedFiles;
using Test;
using Statistics
using LinearAlgebra;
using Base.Iterators
using StatsBase;

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
    inputs = convert(Matrix{datasetType}, inputs)
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

    train_images_nchw = convert(Array{datasetType}, train_images_nchw)
    test_images_nchw = convert(Array{datasetType}, test_images_nchw)
    
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
# ------------------------------------- Ejercicio 2 --------------------------------------------
# ----------------------------------------------------------------------------------------------

using Flux

indexOutputLayer(ann::Chain) = length(ann) - (ann[end]==softmax);

function newClassCascadeNetwork(numInputs::Int, numOutputs::Int)
    ann=Chain();
    if (numOutputs == 1)
        ann = Chain(ann..., Dense(numInputs, numOutputs, σ));
    
    else
        ann = Chain(ann..., Dense(numInputs, numOutputs, identity))
        ann = Chain(ann..., softmax);
    end;
    
    return ann;
end;

function addClassCascadeNeuron(previousANN::Chain; transferFunction::Function=σ)
    outputLayer    = previousANN[   indexOutputLayer(previousANN)   ]; 
    previousLayers = previousANN[1:(indexOutputLayer(previousANN)-1)]; 
    
    numInputsOutputLayer  = size(outputLayer.weight, 2); 
    numOutputsOutputLayer = size(outputLayer.weight, 1); 
    
    if numOutputsOutputLayer == 1
        # Binary case
        new_output_layers = [Dense(numInputsOutputLayer + 1, numOutputsOutputLayer, transferFunction)]
    else
        # Multi case
        new_output_layers = [
            Dense(numInputsOutputLayer + 1, numOutputsOutputLayer, identity),
            softmax
        ]
    end

    # New neuron layer
    ann=Chain();
    ann = Chain(
            previousLayers...,  
            SkipConnection(Dense(numInputsOutputLayer, 1, transferFunction), (mx, x) -> vcat(x, mx)),
            new_output_layers...
        )
    
    # Previous layer + new output + soft
    newOutputLayer = ann[length(previousLayers) + 2]  
    
    newOutputLayer.weight[:, end] .= 0                       # Last col is all 0
    newOutputLayer.weight[:, 1:end-1] .= outputLayer.weight  # Copy previous weights
    newOutputLayer.bias .= outputLayer.bias                  # Copy bias

    return ann
end;

function trainClassANN!(ann::Chain, trainingDataset::Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,2}}, trainOnly2LastLayers::Bool;
    maxEpochs::Int=1000, minLoss::Real=0.0, learningRate::Real=0.001, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)

    # Si da fallo de size(inputs) == size(inputs), transponer estas matrices
    (inputs, targets) = trainingDataset;
    
    # Check if the inputs and targets are of the same sizes

    # Loss function
    loss(model,x,y) = (size(y,1) == 1) ? Losses.binarycrossentropy(model(x),y) : Losses.crossentropy(model(x),y);

    trainingLosses = Float32[];
    numEpoch = 0;

    # Get the loss for the cycle 0 (no training yet)
    trainingLoss = loss(ann, inputs, targets);
    push!(trainingLosses, trainingLoss);
    # println("Epoch ", numEpoch, ": loss: ", trainingLoss);

    opt_state = Flux.setup(Adam(learningRate), ann);

    if trainOnly2LastLayers
        # Freeze all the layers except the last 2
        Flux.freeze!(opt_state.layers[1:(indexOutputLayer(ann)-2)]); 
    end

    # Train until a stop condition is reached
    while (numEpoch < maxEpochs) && (trainingLoss > minLoss) 

        numEpoch += 1;

        # Train cycle (0 if its the first one)
        Flux.train!(loss, ann, [(inputs, targets)], opt_state);

        # Calculamos las metricas en este ciclo
        trainingLoss = loss(ann, inputs, targets);
        push!(trainingLosses, trainingLoss);
        # println("Epoch ", numEpoch, ": loss: ", trainingLoss);
        
        # Calculate loss in the window for early stopping
        if numEpoch > lossChangeWindowSize
            lossWindow = trainingLosses[end - lossChangeWindowSize + 1: end];
            minLossValue, maxLossValue = extrema(lossWindow);

            if ((maxLossValue - minLossValue) / minLossValue) <= minLossChange
                println("Stopping early at epoch $numEpoch due to minimal change in loss.");
                break;
            end
        end
    
    end;

    return trainingLosses;
end;



function trainClassCascadeANN(maxNumNeurons::Int,
    trainingDataset::Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,2}};
    transferFunction::Function=σ,
    maxEpochs::Int=1000, minLoss::Real=0.0, learningRate::Real=0.001, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)

    # Comprobar las transposiciones de las matrices

    (inputs, targets) = trainingDataset

    inputs = convert(Matrix{Float32}, inputs')
    targets = targets'
    
    # @assert size(inputs, 2) == size(targets, 2) "Dimension mismatch: number of examples in inputs and targets must match."


    # Create a ANN without hidden layers
    ann = newClassCascadeNetwork(size(inputs,1),size(targets,1))

    # Train the first ANN
    trainingLosses = trainClassANN!(ann, (inputs, targets), false,
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Comprobar la condicion de este bucle
    for neuronIdx in 1:maxNumNeurons

        ann = addClassCascadeNeuron(ann, transferFunction=transferFunction)

        if neuronIdx > 1
            # Train freezing all layers except the last two
            lossVector = trainClassANN!(ann, (inputs, targets), true,
                maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
                minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
            # Concatenate loss vectors, skipping the first value
            trainingLosses = vcat(trainingLosses, lossVector[2:end])
        end
    
        # Train the entire ANN
        lossVectorFull = trainClassANN!(ann, (inputs, targets), false,
            maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
            minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
        # Concatenate loss vectors, skipping the first value
        trainingLosses = vcat(trainingLosses, lossVectorFull[2:end])
    end;

    # trainingLosses = convert(Vector{Float32}, trainingLosses), los vectores deberian ser Float32
    return ann, trainingLosses
end;

function trainClassCascadeANN(maxNumNeurons::Int,
    trainingDataset::  Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,1}};
    transferFunction::Function=σ,
    maxEpochs::Int=100, minLoss::Real=0.0, learningRate::Real=0.01, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)
    
    inputs, targets = trainingDataset
    reshaped_targets = reshape(targets, length(targets), 1)

    # Llamar a la función original con las salidas convertidas
    return trainClassCascadeANN(maxNumNeurons, (inputs, reshaped_targets);
                                transferFunction=transferFunction, maxEpochs=maxEpochs, minLoss=minLoss, 
                                learningRate=learningRate, minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
end
    

    

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
# ------------------------------------- Ejercicio 4 --------------------------------------------
# ----------------------------------------------------------------------------------------------


using ScikitLearn: @sk_import, fit!, predict
@sk_import svm: SVC

Batch = Tuple{AbstractArray{<:Real,2}, AbstractArray{<:Any,1}}

function batchInputs(batch::Batch) 
    inputs = batch[1]

    return inputs
end;


function batchTargets(batch::Batch) 
    targets = batch[2]
    return targets
end;


function batchLength(batch::Batch) 
    inputs = batchInputs(batch)
    lenghtInputs = size(inputs, 1)

    targets = batchTargets(batch)
    lenghtTargets = length(targets)
                
    return lenghtInputs == lenghtTargets ? lenghtInputs : error("Las salidas y entradas no coiciden en tamaño")
end;

function selectInstances(batch::Batch, indices::Any) 
    # Extraer entradas y salidas del batch
    inputs = batchInputs(batch)
    targets = batchTargets(batch)

    # Seleccionar las instancias correspondientes
    selected_inputs = inputs[indices, :]
    selected_targets = targets[indices]

    # Devolver un nuevo batch con las instancias seleccionadas
    return (selected_inputs, selected_targets)
end


function joinBatches(batch1::Batch, batch2::Batch)
    new_inputs = vcat(batchInputs(batch1), batchInputs(batch2))
    new_targets = vcat(batchTargets(batch1), batchTargets(batch2))
    return (new_inputs, new_targets)
end;

function divideBatches(dataset::Batch, batchSize::Int; shuffleRows::Bool=false)
    inputs = batchInputs(dataset)
    targets = batchTargets(dataset)
    rows = size(inputs, 1)
    
    # Si shuffleRows es verdadero, desordenamos las filas
    if shuffleRows
        indices = shuffle(1:rows)
        inputs = inputs[indices, :]
        targets = targets[indices]
    end

    # Dividir el conjunto de datos en particiones (lotes)
    #=
    * partition(1:size(inputs, 1), batchSize)] -> devuelve un batch de tamaño x con los indices de cada fila
    * partition(1:10, 3)
    * Primer lote: [1, 2, 3]
    * Segundo lote: [4, 5, 6]
    * Tercer lote: [7, 8, 9]
    =#
    # Usar partition para dividir el conjunto de datos en lotes de tamaño batchSize
    partitions = partition(1:rows, batchSize)
    
    # Crear los lotes
    batches = [selectInstances((inputs, targets), collect(p)) for p in partitions]
    
    #= Manejar el último lote si no es divisible por batchSize
    remaining = rows % batchSize
    if remaining > 0
        # Selecionamos la ultima instancia 
        last_batch_indices = (rows - remaining + 1):rows
        push!(batches, selectInstances((inputs, targets), collect(last_batch_indices)))
    end
    =#
    
    return batches
end;

function trainSVM(dataset::Batch, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.,
    supportVectors::Batch=( Array{eltype(dataset[1]),2}(undef,0,size(dataset[1],2)) , Array{eltype(dataset[2]),1}(undef,0) ) )

    # Concatenar los vectores de soporte con el dataset original si se han pasado
    trainingData = isnothing(supportVectors) ? dataset : joinBatches(supportVectors, dataset)

    inputs = batchInputs(trainingData)
    targets = batchTargets(trainingData)

    # Entrenar el modelo
    model = SVC(kernel=kernel, C=C, gamma=gamma, coef0=coef0, degree=degree, random_state=1)
    fit!(model, inputs, targets)

    indicesNewSupportVectors = sort(model.support_.+1); 

    # Número de vectores de soporte previos
    numOldSupportVectors = isnothing(supportVectors) ? 0 : batchLength(supportVectors)

    # Separar los índices en: vectores de soporte antiguos y los nuevos
    oldSupportIndices = indicesNewSupportVectors[indicesNewSupportVectors .<= numOldSupportVectors]
    newSupportIndices = indicesNewSupportVectors[indicesNewSupportVectors .> numOldSupportVectors] .- numOldSupportVectors
    
    # Crear los lotes de vectores de soporte
    oldSupportVectorsBatch = isnothing(supportVectors) ? nothing : selectInstances(supportVectors, oldSupportIndices)
    newSupportVectorsBatch = selectInstances(dataset, newSupportIndices)
    
    # Concatenar los lotes de vectores de soporte
    finalSupportVectorsBatch = isnothing(oldSupportVectorsBatch) ? newSupportVectorsBatch : joinBatches(oldSupportVectorsBatch, newSupportVectorsBatch)
    
    # Devolver el modelo, los vectores de soporte y el tuple con los índices
    return model, finalSupportVectorsBatch, (oldSupportIndices, newSupportIndices)
end;


function trainSVM(batches::AbstractArray{<:Batch,1}, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    
    supportVectors = nothing
    model = nothing
    for batch in batches
        if isnothing(supportVectors)
            # Si no hay vectores de soporte aún, entrenar el modelo sin ellos
            model, supportVectors, _ = trainSVM(batch, kernel, C; degree=degree, gamma=gamma, coef0=coef0)
        else
            # Si ya hay vectores de soporte, usarlos en el entrenamiento
            model, supportVectors, _ = trainSVM(batch, kernel, C; degree=degree, gamma=gamma, coef0=coef0, supportVectors=supportVectors)
        end
    end

    return model
end;




# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 5 --------------------------------------------
# ----------------------------------------------------------------------------------------------

function initializeStreamLearningData(datasetFolder::String, windowSize::Int, batchSize::Int)

    fullData = loadStreamLearningDataset(datasetFolder)
    # Crear la memoria inicial
    memory = selectInstances(fullData, 1:windowSize)
    # Dividir el resto de los datos en batches con tamaño batchSize, sin desordenar (shuffleRows=false)
    remainingData = selectInstances(fullData, (windowSize+1):size(fullData[1], 1))
    batches = divideBatches(remainingData, batchSize; shuffleRows=false)
    
    return memory, batches
end;

#=
 = SI FALLA USAR EL BROADCAST AL FINAL
 =#
function addBatch!(memory::Batch, newBatch::Batch)
  
    # Desempaquetar la memoria actual y el nuevo lote de datos
    memoryInputs, memoryOutputs = memory
    newInputs, newOutputs = newBatch
    # Número de instancias del nuevo lote
    batchSize = size(newInputs, 1)
    # Desplazar la memoria hacia adelante, eliminando los datos más antiguos
    memoryInputs[:, 1:end-batchSize] = memoryInputs[:, batchSize+1:end]
    memoryOutputs[1:end-batchSize] = memoryOutputs[batchSize+1:end]
    
    # Añadir los nuevos datos al final de la memoria
    memoryInputs[:, end-batchSize+1:end] = newInputs[:, 1:batchSize]
    memoryOutputs[end-batchSize+1:end] = newOutputs[1:batchSize]
end;

function streamLearning_SVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)

    # Inicializar memoria y batches
    memory, batches = initializeStreamLearningData(datasetFolder, windowSize, batchSize)
    # Primer SVM
    model, supportVectors, _ = trainSVM(memory, kernel, C; degree, gamma, coef0)

    num_batches = length(batches)
    accuracies = Vector{Float32}(undef, num_batches)

    for idx in 1:num_batches
        # Test del modelo actual
        X_batch, y_batch = batchInputs(batches[idx]), batchTargets(batches[idx])
        y_pred = predict(model, X_batch)
        accuracies[idx] = mean(y_pred .== y_batch)
        # Actualizar memoria con i-esimo batch
        addBatch!(memory, batches[idx])
        # Entrenar de nuevo el modelo usando los vectores de soporte
        model, supportVectors, _ = trainSVM(memory, kernel, C; degree, gamma, coef0, supportVectors=supportVectors)
    end

    @assert length(accuracies) == length(batches)
    return accuracies
end;

function streamLearning_ISVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)

    # Inicializar memoria y batches
    memory, batches = initializeStreamLearningData(datasetFolder, batchSize, batchSize)
    # Primer SVM
    model, supportVectors, indicesSupportVectorsInFirstBatch = trainSVM(memory, kernel, C; degree, gamma, coef0)

    num_batches = length(batches)
    # batchSize = el  más  antiguo,  1  = el  más  reciente.
    age_vector = collect(batchSize:-1:1)
    vectorAge = age_vector[indicesSupportVectorsInFirstBatch[2]]
    accuracies = Vector{Float32}(undef, num_batches)

    for idx in 2:num_batches
        # Test del modelo actual
        X_batch, y_batch = batchInputs(batches[idx]), batchTargets(batches[idx])
        y_pred = predict(model, X_batch)
        accuracies[idx] = mean(y_pred .== y_batch)

        # Actualizar la edad de los vectores
        vectorAge .+= batchSize
        indices = findall(x -> x <= windowSize, vectorAge)
        supportVectors = selectInstances(supportVectors, indices)
        vectorAge = vectorAge[indices]
        
        
        # Entrenar de nuevo el modelo usando los vectores de soporte
        model, supportVectors, (indicesSupportVectorsOld, indicesSupportVectorsBatch) = trainSVM(
            batches[idx], kernel, C; degree=degree, gamma=gamma, coef0=coef0, supportVectors=supportVectors)
            
        # Crear nuevo lote de datos con los nuevos vectores de soporte
        newSupportVectorsOld = selectInstances(supportVectors, indicesSupportVectorsOld)
        newSupportVectorsBatch = selectInstances(batches[idx], indicesSupportVectorsBatch)
        supportVectors = joinBatches(newSupportVectorsOld, newSupportVectorsBatch)
        
        # Actualizar vector de edades de los nuevos vectores de soporte
        vectorAgeOld = vectorAge[indicesSupportVectorsOld]
        vectorAgeBatch = batchSize .- indicesSupportVectorsBatch .+ 1
        vectorAge = vcat(vectorAgeOld, vectorAgeBatch)
    end

    # COMO TRATAR CON EL SALTO DEL PRIMER BATCH
    accuracies[1] = accuracies[2]
    # @assert length(accuracies) == length(batches)
    return accuracies

end;

function euclideanDistances(memory::Batch, instance::AbstractArray{<:Real,1})
    matriz_entradas = batchInputs(memory)  
    instance_transpuesta = instance'        
    diferencia = matriz_entradas .- instance_transpuesta  
    diferencia_cuadrado = diferencia .^ 2   
    suma_filas = sum(diferencia_cuadrado, dims=2)  
    distancias = sqrt.(suma_filas)          
    distancias_vector = vec(distancias)      

    return distancias_vector
end;

function predictKNN(memory::Batch, instance::AbstractArray{<:Real,1}, k::Int)
    _ , memoryOutputs = memory
    distance = euclideanDistances(memory, instance)

    # Obtener los índices de los k vecinos más cercanos
    indices_vecinos = partialsortperm(distance, k)
    salidas_vecinos = memoryOutputs[indices_vecinos]

    # Calcular el valor de predicción utilizando la moda
    valor_prediccion = mode(salidas_vecinos)

    return convert(eltype(memoryOutputs), valor_prediccion)
end;

function predictKNN(memory::Batch, instances::AbstractArray{<:Real,2}, k::Int)
    
    predicciones = [predictKNN(memory, instance, k) for instance in eachrow(instances)]  
    return predicciones 
end;

function streamLearning_KNN(datasetFolder::String, windowSize::Int, batchSize::Int, k::Int)

    # Inicializar memoria y batches
    memory, batches = initializeStreamLearningData(datasetFolder, windowSize, batchSize)

    num_batches = length(batches)
    accuracies = Vector{Float32}(undef, num_batches)

    for idx in 1:num_batches
        # Test del modelo actual
        X_batch, y_batch = batchInputs(batches[idx]), batchTargets(batches[idx])
        y_pred = predictKNN(memory, X_batch, k)
        accuracies[idx] = mean(y_pred .== y_batch)

        # Actualizar memoria con i-esimo batch
        addBatch!(memory, batches[idx])
    end

    @assert length(accuracies) == length(batches)
    return accuracies
end;



# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 6 --------------------------------------------
# ----------------------------------------------------------------------------------------------


function predictKNN_SVM(dataset::Batch, instance::AbstractArray{<:Real,1}, k::Int, C::Real)

    memory, labels = dataset
    distance = euclideanDistances(dataset, instance)
    minDistances = partialsortperm(distance, k)

    # Todas son de la misma clase
    if length(unique(labels[minDistances])) == 1
        return labels[minDistances[1]]
    end

    # Creacion y entrenamiento del modelo
    model = SVC(kernel="linear", C=C, random_state=1)
    inputs = memory[minDistances, :]
    targets = labels[minDistances]
    fit!(model, inputs, targets)

    # Prediccion de la instancia
    pred = predict(model, reshape(instance, 1, :))
    return convert(eltype(labels), pred[1])
end;

function predictKNN_SVM(dataset::Batch, instances::AbstractArray{<:Real,2}, k::Int, C::Real)
    predictions = [predictKNN_SVM(dataset, instance, k, C) for instance in eachrow(instances)]  
    return predictions
end;
