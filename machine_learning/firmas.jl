using FileIO;
using JLD2;
using Images;
using DelimitedFiles;

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
    # @assert(size(inputs,1)==size(targets,1));

    # Loss function
    loss(model,x,y) = (size(y,1) == 1) ? Losses.binarycrossentropy(model(x),y) : Losses.crossentropy(model(x),y);

    trainingLosses = Float32[];
    numEpoch = 0;

    # Get the loss for the cycle 0 (no training yet)
    trainingLoss = loss(ann, inputs', targets');
    push!(trainingLosses, trainingLoss);
    # println("Epoch ", numEpoch, ": loss: ", trainingLoss);

    opt_state = Flux.setup(Adam(learningRate), ann);

    if trainOnly2LastLayers
        # Freeze all the layers except the last 2
        Flux.freeze!(opt_state.layers[1:(indexOutputLayer(ann)-2)]); 
    end

    # Train until a stop condition is reached
    while (numEpoch<maxEpochs) && (trainingLoss>minLoss) 

        # Train cycle (0 if its the first one)
        Flux.train!(loss, ann, [(inputs', targets')], opt_state);

        numEpoch += 1;
        # Calculamos las metricas en este ciclo
        trainingLoss = loss(ann, inputs', targets');
        push!(trainingLosses, trainingLoss);
        # println("Epoch ", numEpoch, ": loss: ", trainingLoss);
        
        # Calculate loss in the window for early stopping
        if numEpoch >= lossChangeWindowSize
            lossWindow = trainingLosses[end-lossChangeWindowSize+1:end];
            minLossValue, maxLossValue = extrema(lossWindow);

            if ((maxLossValue - minLossValue) / minLossValue) <= minLossChange
                println("Stopping early at epoch $numEpoch due to minimal change in loss.");
                break;
            end
        end
    
    end;

    return (ann, trainingLosses);
end;


function trainClassCascadeANN(maxNumNeurons::Int,
    trainingDataset::Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,2}};
    transferFunction::Function=σ,
    maxEpochs::Int=1000, minLoss::Real=0.0, learningRate::Real=0.001, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)

    # Comprobar las transposiciones de las matrices

    (inputs, targets) = trainingDataset

    inputs = convert(Matrix{Float32}, inputs')
    targets = targets'
    
    @assert size(inputs, 2) == size(targets, 2) "Dimension mismatch: number of examples in inputs and targets must match."


    # Create a ANN without hidden layers
    ann = newClassCascadeNetwork(size(inputs,1),size(targets,1))

    # Train the first ANN
    ann, trainingLosses = trainClassANN!(ann, (inputs', targets'), false,
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Comprobar la condicion de este bucle
    for neuronIdx in 1:maxNumNeurons

        ann = addClassCascadeNeuron(ann, transferFunction=transferFunction)

        if neuronIdx > 1
            # Train freezing all layers except the last two
            ann, lossVector = trainClassANN!(ann, (inputs', targets'), true,
                maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
                minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
            # Concatenate loss vectors, skipping the first value
            trainingLosses = vcat(trainingLosses, lossVector[2:end])
        end
    
        # Tra   in the entire ANN
        ann, lossVectorFull = trainClassANN!(ann, (inputs', targets'), false,
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
end;
    

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 3 --------------------------------------------
# ----------------------------------------------------------------------------------------------

HopfieldNet = Array{Float32,2}

function trainHopfield(trainingSet::AbstractArray{<:Real,2})
    #
    # Codigo a desarrollar
    #
end;
function trainHopfield(trainingSet::AbstractArray{<:Bool,2})
    #
    # Codigo a desarrollar
    #
end;
function trainHopfield(trainingSetNCHW::AbstractArray{<:Bool,4})
    #
    # Codigo a desarrollar
    #
end;

function stepHopfield(ann::HopfieldNet, S::AbstractArray{<:Real,1})
    #
    # Codigo a desarrollar
    #
end;
function stepHopfield(ann::HopfieldNet, S::AbstractArray{<:Bool,1})
    #
    # Codigo a desarrollar
    #
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





function addNoise(datasetNCHW::AbstractArray{<:Bool,4}, ratioNoise::Real)
    #
    # Codigo a desarrollar
    #
end;

function cropImages(datasetNCHW::AbstractArray{<:Bool,4}, ratioCrop::Real)
    #
    # Codigo a desarrollar
    #
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
    # Codigo a desarrollar
    #
end;

function calculateMNISTAccuracies(datasetFolder::String, labels::AbstractArray{Int,1}, threshold::Real)
    #
    # Codigo a desarrollar
    #
end;



# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 4 --------------------------------------------
# ----------------------------------------------------------------------------------------------


using ScikitLearn: @sk_import, fit!, predict
@sk_import svm: SVC

Batch = Tuple{AbstractArray{<:Real,2}, AbstractArray{<:Any,1}}


function batchInputs(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function batchTargets(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function batchLength(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function selectInstances(batch::Batch, indices::Any)
    #
    # Codigo a desarrollar
    #
end;

function joinBatches(batch1::Batch, batch2::Batch)
    #
    # Codigo a desarrollar
    #
end;


function divideBatches(dataset::Batch, batchSize::Int; shuffleRows::Bool=false)
    #
    # Codigo a desarrollar
    #
end;

function trainSVM(dataset::Batch, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.,
    supportVectors::Batch=( Array{eltype(dataset[1]),2}(undef,0,size(dataset[1],2)) , Array{eltype(dataset[2]),1}(undef,0) ) )
    #
    # Codigo a desarrollar
    #
end;

function trainSVM(batches::AbstractArray{<:Batch,1}, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;





# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 5 --------------------------------------------
# ----------------------------------------------------------------------------------------------


function initializeStreamLearningData(datasetFolder::String, windowSize::Int, batchSize::Int)
    #
    # Codigo a desarrollar
    #
end;

function addBatch!(memory::Batch, newBatch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_SVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_ISVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

function euclideanDistances(memory::Batch, instance::AbstractArray{<:Real,1})
    #
    # Codigo a desarrollar
    #
end;

function predictKNN(memory::Batch, instance::AbstractArray{<:Real,1}, k::Int)
    #
    # Codigo a desarrollar
    #
end;

function predictKNN(memory::Batch, instances::AbstractArray{<:Real,2}, k::Int)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_KNN(datasetFolder::String, windowSize::Int, batchSize::Int, k::Int)
    #
    # Codigo a desarrollar
    #
end;




# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 6 --------------------------------------------
# ----------------------------------------------------------------------------------------------


function predictKNN_SVM(dataset::Batch, instance::AbstractArray{<:Real,1}, k::Int, C::Real)
    #
    # Codigo a desarrollar
    #
end;

function predictKNN_SVM(dataset::Batch, instances::AbstractArray{<:Real,2}, k::Int, C::Real)
    #
    # Codigo a desarrollar
    #
end;