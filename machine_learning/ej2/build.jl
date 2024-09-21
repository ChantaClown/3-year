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
    println("Epoch ", numEpoch, ": loss: ", trainingLoss);

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
        println("Epoch ", numEpoch, ": loss: ", trainingLoss);
        
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

    inputs = convert(Matrix{Float32}, inputs)
    targets = targets
    @assert size(inputs, 2) == size(targets, 2) "Dimension mismatch: number of examples in inputs and targets must match."

    # Check if the inputs and targets are of the same sizes
    # @assert(size(inputs,1)==size(targets,1));

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
    return trainClassCascadeANN(maxNumNeurons, (inputs, reshaped_targets');
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
    inputs = rand(Float32, 100, 5)  # 5 atributos, 10 instancias
    targets = rand(Bool, 100, 1)    # 1 fila, 10 instancias (booleanas)

    # Red neuronal
    ann = Chain(Dense(5,3,sigmoid), Dense(3, 1, sigmoid))

    # Test 1: Verificar que la función se ejecuta sin errores
    result = trainClassANN!(ann, (inputs, targets), false)
    @test length(result[2]) > 0  # Debe devolver el histórico de pérdidas

    # Test 2: Verificar que la pérdida disminuye con el entrenamiento
    losses = result[2]
    @test all(diff(losses) .<= 0)  # Las pérdidas deben disminuir o ser constantes

    # Test 3: Verificar el comportamiento con trainOnly2LastLayers=true
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result = trainClassANN!(ann, (inputs, targets), true)  # Solo entrenar las dos últimas capas
    @test length(result[2]) > 0
end

# ------------------------------------- trainClassCascadeANN -----------------------------------

@testset "trainClassCascadeANN 1 - Compile Test" begin
    function generateSampleData(numSamples::Int, inputSize::Int, outputSize::Int)
        # Generate random input data
        inputs = rand(Float32, numSamples, inputSize)
        # Generate random target data (Boolean values)
        targets = rand(Bool, numSamples, outputSize)
        return (inputs, targets)
    end

    # Generate sample training data
    numSamples = 100  # Number of training samples
    inputSize = 4     # Number of input features
    outputSize = 2    # Number of output classes
    trainingData = generateSampleData(numSamples, inputSize, outputSize)

    # Set parameters for the training
    maxNumNeurons = 9  # Maximum number of neurons to add in the cascade
    transferFunction = σ
    maxEpochs = 1000
    learningRate = 0.01

    # Call the trainClassCascadeANN function with the sample data
    trainedANN, trainingLosses = trainClassCascadeANN(
        maxNumNeurons,
        trainingData;
        transferFunction=transferFunction,
        maxEpochs=maxEpochs,
        learningRate=learningRate
    )

    # Output the results
    println("Trained ANN structure: ", trainedANN)
    println("Training losses: ", trainingLosses)
end

@testset "trainClassCascadeANN 1 - Hard Test" begin
    # Datos de prueba
    inputs = rand(Float32, 5, 10)  # 10 muestras con 5 características cada una
    targets_binary = rand(Bool, 1, 10)  # Objetivo binario para clasificación binaria
    targets_multi = rand(Bool, 3, 10)   # Objetivo multiclase para clasificación multiclase

    # Parámetros del entrenamiento
    maxNumNeurons = 3
    maxEpochs = 100
    minLoss = 0.01
    learningRate = 0.01
    minLossChange = 1e-6
    lossChangeWindowSize = 5

    # Entrenamiento para clasificación binaria
    ann_binary, losses_binary = trainClassCascadeANN(maxNumNeurons, (inputs, targets_binary),
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
    
    # Tests para la red binaria
    @test length(losses_binary) > 0  # Asegura que haya pérdidas registradas
    @test size(ann_binary[end].weight, 2) == size(inputs, 1) + maxNumNeurons  # Verifica el número correcto de neuronas en la capa de salida

    # Entrenamiento para clasificación multiclase
    ann_multi, losses_multi = trainClassCascadeANN(maxNumNeurons, (inputs, targets_multi),
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Tests para la red multiclase
    @test length(losses_multi) > 0  # Asegura que haya pérdidas registradas
    @test size(ann_multi[end-1].weight, 2) == size(inputs, 1) + maxNumNeurons  # Verifica el número correcto de neuronas en la capa de salida

    # Verificación de que las pérdidas disminuyen con el entrenamiento
    @test losses_binary[end] < losses_binary[1]  # Las pérdidas deben disminuir en clasificación binaria
    @test losses_multi[end] < losses_multi[1]    # Las pérdidas deben disminuir en clasificación multiclase
end     

    inputs = rand(Float32, 5, 10)  # 10 muestras con 5 características cada una
    targets_binary = rand(Bool, 10)  # Vector de 10 valores booleanos para clasificación binaria

    # Parámetros del entrenamiento
    maxNumNeurons = 3
    maxEpochs = 100
    minLoss = 0.01
    learningRate = 0.01
    minLossChange = 1e-6
    lossChangeWindowSize = 5

    reshaped_targets = reshape(targets_binary, length(targets_binary), 1)

    # Llamar a la función original con las salidas convertidas
    return trainClassCascadeANN(maxNumNeurons, (inputs, reshaped_targets'); maxEpochs=maxEpochs, minLoss=minLoss, 
                                learningRate=learningRate, minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)


    # Entrenamiento para clasificación binaria
    ann_binary, losses_binary = trainClassCascadeANN(maxNumNeurons, (inputs, targets_binary),
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Verificar que el entrenamiento generó pérdidas
    @test length(losses_binary) > 0  # Debe haber algún valor de pérdida
    @test losses_binary[end] < losses_binary[1]  # Las pérdidas deben disminuir durante el entrenamiento

    inputs = rand(Float32, 5, 15)  # 15 muestras con 5 características cada una
    targets_multi = rand(Bool, 15)  # Vector de 15 valores booleanos para clasificación multiclase

    # Parámetros del entrenamiento
    maxNumNeurons = 2
    maxEpochs = 50
    minLoss = 0.01
    learningRate = 0.005
    minLossChange = 1e-5
    lossChangeWindowSize = 3

    # Entrenamiento para clasificación multiclase simulada
    ann_multi, losses_multi = trainClassCascadeANN(maxNumNeurons, (inputs, targets_multi),
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Verificar que el entrenamiento se realizó correctamente
    @test length(losses_multi) > 0  # Debe haber algún valor de pérdida
    @test losses_multi[end] < losses_multi[1]  # Las pérdidas deben disminuir durante el entrenamiento
end
