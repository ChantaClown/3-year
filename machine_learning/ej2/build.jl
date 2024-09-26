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
include("tester.jl");

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
    # @assert(size(inputs,2)==size(targets,2));

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
    while (numEpoch<maxEpochs) && (trainingLoss>minLoss) 

        # Train cycle (0 if its the first one)
        Flux.train!(loss, ann, [(inputs, targets)], opt_state);

        numEpoch += 1;
        # Calculamos las metricas en este ciclo
        trainingLoss = loss(ann, inputs, targets);
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
    
    # @assert size(inputs, 2) == size(targets, 2) "Dimension mismatch: number of examples in inputs and targets must match."


    # Create a ANN without hidden layers
    ann = newClassCascadeNetwork(size(inputs,1),size(targets,1))

    # Train the first ANN
    ann, trainingLosses = trainClassANN!(ann, (inputs, targets), false,
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Comprobar la condicion de este bucle
    for neuronIdx in 1:maxNumNeurons

        ann = addClassCascadeNeuron(ann, transferFunction=transferFunction)

        if neuronIdx > 1
            # Train freezing all layers except the last two
            ann, lossVector = trainClassANN!(ann, (inputs, targets), true,
                maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
                minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
            # Concatenate loss vectors, skipping the first value
            trainingLosses = vcat(trainingLosses, lossVector[2:end])
        end
    
        # Train the entire ANN
        ann, lossVectorFull = trainClassANN!(ann, (inputs, targets), false,
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
# ------------------------------------- Test ---------------------------------------------------
# ----------------------------------------------------------------------------------------------

# ------------------------------------- newClassCascadeNetwork -----------------------------------

@testset "newClassCascadeNetwork" begin
    # Test binary classification network
    ann_binary = newClassCascadeNetwork(5, 1)
    @test length(ann_binary) == 1
    @test ann_binary[1] isa Dense
    @test size(ann_binary[1].weight) == (1, 5)
    @test ann_binary[1].σ == σ

    # Test multi-class classification network
    ann_multi = newClassCascadeNetwork(5, 3)
    @test length(ann_multi) == 2
    @test ann_multi[1] isa Dense
    @test ann_multi[2] == softmax
    @test size(ann_multi[1].weight) == (3, 5)
    @test ann_multi[1].σ == identity
end

# ------------------------------------- addClassCascadeNeuron -----------------------------------

@testset "addClassCascadeNeuron" begin
    input  = rand32(5)
    # Red neuronal de prueba para clasificación binaria
    ann_binary = Chain(Dense(5, 1, σ))
    new_ann_binary = addClassCascadeNeuron(ann_binary)
    @test isequal(ann_binary(input), new_ann_binary(input))
    @test size(new_ann_binary[end].weight, 2) == size(ann_binary[end].weight, 2) + 1

    # Red neuronal de prueba para clasificación multiclase
    ann_multi = Chain(Dense(5, 3, identity), softmax)
    new_ann_multi = addClassCascadeNeuron(ann_multi)
    @test isequal(ann_multi(input), new_ann_multi(input))
    @test size(new_ann_multi[end-1].weight, 2) == size(ann_multi[end-1].weight, 2) + 1
end

# ------------------------------------- trainClassANN! -----------------------------------

@testset "trainClassANN! tests" begin

    # Crear el dataset de ejemplo
    inputs = rand(Float32, 5, 10)  # 5 atributos, 10 instancias trans
    targets = rand(Bool, 1, 10)    # 19 col, 10 instancias (booleanas) trans

    # Red neuronal
    ann = Chain(Dense(5, 3, sigmoid), Dense(3, 1, sigmoid))

    # Test 1: Verificar que la función se ejecuta sin errores
    result = trainClassANN!(ann, (inputs, targets), true)
    @test length(result[2]) > 0  # Debe devolver el histórico de pérdidas

    # Test 2: Verificar que la pérdida disminuye con el entrenamiento
    losses = result[2]
    @test all(diff(losses) .<= 0)  # Las pérdidas deben disminuir o ser constantes

    # Test 3: Verificar el comportamiento con trainOnly2LastLayers=true
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result = trainClassANN!(ann, (inputs, targets), true)  # Solo entrenar las dos últimas capas
    @test length(result[2]) > 0

    # Test 4: Verificar que diferentes tasas de aprendizaje afectan el entrenamiento
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result_fast = trainClassANN!(ann, (inputs, targets), true, learningRate=0.1)
    result_slow = trainClassANN!(ann, (inputs, targets), true, learningRate=0.0001)
    @test result_fast[2][end] > result_slow[2][end]  # La tasa rápida debería entrenar más rápido

    # Test 5: Verificar que el entrenamiento se detiene temprano por poca variación en la pérdida
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result_early = trainClassANN!(ann, (inputs, targets), true, minLossChange=1e-2, lossChangeWindowSize=3)
    @test length(result_early[2]) < 1000  # El entrenamiento debería haber parado antes de 1000 épocas
end


# ------------------------------------- trainClassCascadeANN -----------------------------------
@testset "trainClassCascadeANN tests" begin

    # Crear el dataset de ejemplo
    inputs = rand(Float32, 10, 5)  # 5 atributos, 10 instancias
    targets = rand(Bool, 10, 1)    # 1 fila, 10 instancias (booleanas)

    # Test 1: Verificar que la función se ejecuta sin errores con maxNumNeurons=1
    maxNumNeurons = 1
    ann, trainingLosses = trainClassCascadeANN(maxNumNeurons, (inputs, targets))
    @test length(trainingLosses) > 0  # Debe devolver el histórico de pérdidas

    # Test 2: Verificar que la pérdida disminuye con el entrenamiento
    @test all(diff(trainingLosses) .<= 0)  # Las pérdidas deben disminuir o ser constantes

    # Test 3: Verificar el comportamiento con maxNumNeurons>1
    maxNumNeurons = 3
    ann, trainingLosses = trainClassCascadeANN(maxNumNeurons, (inputs, targets))
    @test length(trainingLosses) > 0

    # Test 4: Verificar que el entrenamiento se detiene temprano con una tasa de cambio de pérdida pequeña
    maxNumNeurons = 2
    ann, trainingLossesEarlyStop = trainClassCascadeANN(maxNumNeurons, (inputs, targets), 
        maxEpochs=1000, minLossChange=1e-2, lossChangeWindowSize=3)
    @test length(trainingLossesEarlyStop) < 1000  # Debe detenerse antes de alcanzar 1000 épocas

    # Test 5: Probar con targets unidimensionales (usando la sobrecarga)
    targets1D = rand(Bool, 10)  # 10 instancias de targets booleanos (1D)
    ann, trainingLosses1D = trainClassCascadeANN(maxNumNeurons, (inputs, targets1D))
    @test length(trainingLosses1D) > 0  # Debe devolver el histórico de pérdidas correctamente

    # Test 6: Verificar que diferentes tasas de aprendizaje afectan el entrenamiento
    maxNumNeurons = 1
    ann_fast, trainingLossesFast = trainClassCascadeANN(maxNumNeurons, (inputs, targets), learningRate=0.1)
    ann_slow, trainingLossesSlow = trainClassCascadeANN(maxNumNeurons, (inputs, targets), learningRate=0.0001)
    @test trainingLossesFast[end] < trainingLossesSlow[end]  # El entrenamiento con tasa rápida debería alcanzar una pérdida menor
end


@testset "Real Datasets" begin
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

    # Cargar los datos sin modificar loadDataset
    dataset = loadDataset("adult", "/home/clown/3-year/machine_learning/dataset")

    # Si el dataset es `nothing`, entonces el archivo no existe o no se cargó correctamente
    if dataset === nothing
        error("El dataset no fue encontrado o no se pudo cargar.")
    end

    # Asegúrate de que el dataset tenga la estructura adecuada: (inputs, targets)
    inputs, targets = dataset

    # Convertir targets a una matriz de 2 dimensiones
    targets = reshape(targets, :, 1)

    # Verifica los tipos de los datos después de la transformación
    println("Tipos de datos: Inputs - ", typeof(inputs), ", Targets - ", typeof(targets))

    # Define la red neuronal ANN
    ann = Chain(Dense(size(inputs, 2), 3, sigmoid), Dense(3, 1, sigmoid))

    # Entrenar la red neuronal usando las funciones de entrenamiento
    println("Using trainClassANN - 2layer = false: ")
    trainClassANN!(ann, (inputs', targets'), false)
    println("Using trainClassANN - 2layer = true: ")
    trainClassANN!(ann, (inputs', targets'), true)
    println("Using trainClassCascadeANN: ")
    trainClassCascadeANN(3, (inputs, targets))
    println("Using trainClassCascadeANN Overload: ")
    inputs, targets = dataset
    trainClassCascadeANN(5, (inputs, targets))
end