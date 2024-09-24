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
include("firmas.jl")
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
    inputs, targets  = trainingData
    inputs = convert(Matrix{Float32}, inputs')
    targets = targets'
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
    inputs = rand(Float32, 10, 5)  # 10 muestras con 5 características cada una
    targets_binary = rand(Bool, 10, 1)  # Objetivo binario para clasificación binaria
    targets_multi = rand(Bool, 10, 3)   # Objetivo multiclase para clasificación multiclase

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
    @test size(ann_binary[end].weight, 1) == 1  # Verifica que la salida es binaria (1 salida)
    @test size(ann_binary[end].weight, 2) == size(inputs, 2) + maxNumNeurons  # Verifica el número correcto de conexiones en la capa de salida

    # Entrenamiento para clasificación multiclase
    ann_multi, losses_multi = trainClassCascadeANN(maxNumNeurons, (inputs, targets_multi),
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)

    # Tests para la red multiclase -> Mirar estos
    @test length(losses_multi) > 0  # Asegura que haya pérdidas registradas
    @test size(ann_multi[end - 1].weight, 1) == size(targets_multi, 2)  # Verifica que la salida tiene el tamaño correcto de clases
    @test size(ann_multi[end - 1].weight, 2) == size(inputs, 2) + maxNumNeurons  # Verifica el número correcto de conexiones en la capa de salida

    # Verificación de que las pérdidas disminuyen con el entrenamiento
    @test losses_binary[end] < losses_binary[1]  # Las pérdidas deben disminuir en clasificación binaria
    @test losses_multi[end] < losses_multi[1]    # Las pérdidas deben disminuir en clasificación multiclase
end

@testset "trainClassCascadeANN 2 - Tests" begin
    # Datos de prueba
    inputs = rand(Float32, 10, 5)  # 10 muestras con 5 características cada una
    targets_vector = rand(Bool, 10)  # Objetivos en forma de vector (una única clase binaria)

    # Parámetros del entrenamiento
    maxNumNeurons = 3
    maxEpochs = 50
    minLoss = 0.01
    learningRate = 0.01
    minLossChange = 1e-6
    lossChangeWindowSize = 5

    # Prueba: Verificar que reshaped_targets se maneja correctamente
    ann, losses = trainClassCascadeANN(maxNumNeurons, (inputs, targets_vector);
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
    
    # Test 1: Verificar que la red neuronal ha sido entrenada correctamente
    @test length(losses) > 0  # Asegurar que se registran las pérdidas
    @test losses[end] < losses[1]  # Las pérdidas deben disminuir con el entrenamiento

    # Test 2: Verificar el formato de los objetivos después del reshape
    reshaped_targets = reshape(targets_vector, length(targets_vector), 1)
    @test size(reshaped_targets, 2) == 1  # La salida debe ser una matriz de Nx1

    # Test 3: Verificar que la red final tiene la salida binaria adecuada
    @test size(ann[end].weight, 1) == 1  # La capa de salida debe tener 1 neurona (clasificación binaria)

    # Prueba con diferentes parámetros
    targets_vector_2 = rand(Bool, 15)  # Nuevos objetivos de mayor longitud
    inputs_2 = rand(Float32, 15, 5)    # Nuevas entradas con el mismo número de características
    
    # Test 4: Entrenamiento con nuevos datos
    ann_2, losses_2 = trainClassCascadeANN(maxNumNeurons, (inputs_2, targets_vector_2);
        maxEpochs=maxEpochs, minLoss=minLoss, learningRate=learningRate,
        minLossChange=minLossChange, lossChangeWindowSize=lossChangeWindowSize)
    
    @test length(losses_2) > 0  # Verificar que se registran pérdidas en el segundo conjunto de datos
    @test losses_2[end] < losses_2[1]  # Las pérdidas deben disminuir con el entrenamiento en los nuevos datos
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
    dataset = loadDataset("adult", "C:\\Users\\Pablo\\OneDrive\\3year\\machine_learning\\dataset")

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
    trainClassANN!(ann, (inputs, targets), false)
    println("Using trainClassANN - 2layer = true: ")
    trainClassANN!(ann, (inputs, targets), true)
    println("Using trainClassCascadeANN: ")
    trainClassCascadeANN(3, (inputs, targets))
    println("Using trainClassCascadeANN Overload: ")
    inputs, targets = dataset
    trainClassCascadeANN(5, (inputs, targets))
end