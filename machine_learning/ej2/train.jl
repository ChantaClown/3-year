using Flux;
using Flux.Losses;
using FileIO;
using JLD2;
using Images;
using DelimitedFiles;
using Test;
using Statistics
using LinearAlgebra;
include("35634619Y_48111913F_32740686W.jl")

indexOutputLayer(ann::Chain) = length(ann) - (ann[end]==softmax);


# ----------------------------------------------------------------------------------------------
# ------------------------------------- Test ---------------------------------------------------
# ----------------------------------------------------------------------------------------------

# ------------------------------------- trainClassANN! -----------------------------------


@testset "trainClassANN!" begin
    # Crear el dataset de ejemplo
    inputs = rand(Float32, 5, 10)  # 5 atributos, 10 instancias trans
    targets = rand(Bool, 1, 10)    # 19 col, 10 instancias (booleanas) trans

    # Red neuronal
    ann = Chain(Dense(5, 3, sigmoid), Dense(3, 1, sigmoid))

    # Test 1: Verificar que la función se ejecuta sin errores
    result = trainClassANN!(ann, (inputs, targets), false, maxEpochs=50)
    @test length(result) > 0  # Debe devolver el histórico de pérdidas
    @test length(result) == 51
    # Test 2: Verificar que la pérdida disminuye con el entrenamiento
    losses = result
    @test all(diff(losses) .<= 0)  # Las pérdidas deben disminuir o ser constantes

    # Test 3: Verificar el comportamiento con trainOnly2LastLayers=true
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result = trainClassANN!(ann, (inputs, targets), true)  # Solo entrenar las dos últimas capas
    @test length(result) > 0

    # Test 4: Verificar que diferentes tasas de aprendizaje afectan el entrenamiento
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result_fast = trainClassANN!(ann, (inputs, targets), true, learningRate=0.1)
    result_slow = trainClassANN!(ann, (inputs, targets), true, learningRate=0.0001)
    @test result_fast[end] > result_slow[end]  # La tasa rápida debería entrenar más rápido

    # Test 5: Verificar que el entrenamiento se detiene temprano por poca variación en la pérdida
    ann = Chain(Dense(5, 3, relu), Dense(3, 1, sigmoid))  # Nueva red
    result_early = trainClassANN!(ann, (inputs, targets), true, minLossChange=1e-2, lossChangeWindowSize=3)
    @test length(result_early) < 1000  # El entrenamiento debería haber parado antes de 1000 épocas
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

# Crear el dataset de ejemplo
inputs = rand(Float32, 10, 5)  # 5 atributos, 10 instancias
targets = rand(Bool, 10, 1)    # 1 fila, 10 instancias (booleanas)
ann = newClassCascadeNetwork(size(inputs,1),size(targets,1))

transferFunction::Function=σ

ann = newClassCascadeNetwork(size(inputs, 2), size(targets, 2))
println("Red original: ", ann)
ann = addClassCascadeNeuron(ann; transferFunction=transferFunction)
println("Red con una neurona añadida: ", ann)



# Datos de ejemplo
X = rand(Float32, 4, 10)  # 4 atributos, 10 instancias
Y = rand(Bool, 2, 10)     # 2 clases, 10 instancias

# Entrena la RNA en cascada
maxNumNeurons = 3
_, losses = trainClassCascadeANN(maxNumNeurons, (X', Y'); maxEpochs=100, learningRate=0.01)

println("Pérdidas durante el entrenamiento en cascada: ", losses)


function test_trainClassANN_and_trainClassCascadeANN()

    # Datos de ejemplo para pruebas
    X = rand(Float32, 10, 4)  # 4 atributos, 10 instancias
    Y = hcat([true, false, true, false, true, true, false, true, false, true]...)  # 2 clases, 10 instancias
    Y = Y'
    println("==== Test 1: Dimension mismatch ====")
    try
        X_wrong = rand(Float32, 10, 4)
        Y_wrong = rand(Bool, 10, 3)  # Error intencionado: 3 clases, 10 instancias
        trainClassCascadeANN(2, (X_wrong, Y_wrong))
    catch e
        println("Error atrapado correctamente: ", e)
    end

    println("==== Test 2: Convergencia del loss ====")
    ann, losses = trainClassCascadeANN(2, (X, Y))
    println("Pérdidas durante el entrenamiento: ", losses)

    println("==== Test 3: Parada temprana ====")
    ann_early, losses_early = trainClassCascadeANN(2, (X, Y); minLossChange=1e-3, lossChangeWindowSize=3)
    println("Pérdidas con parada temprana: ", losses_early)

    println("==== Test 4: Concatenación de vectores de pérdidas ====")
    println("Número total de valores de pérdidas: ", length(losses))

    println("==== Test 5: Adición de neuronas en cascada ====")
    ann = newClassCascadeNetwork(4, 2)
    println("Red inicial: ", ann)
    ann = addClassCascadeNeuron(ann, transferFunction=σ)
    println("Red con una neurona añadida: ", ann)

    println("==== Test 6: Optimización de tasa de aprendizaje ====")
    ann_lr_01, losses_lr_01 = trainClassCascadeANN(2, (X, Y); learningRate=0.01)
    println("Pérdidas con tasa de aprendizaje 0.01: ", losses_lr_01)

    ann_lr_1, losses_lr_1 = trainClassCascadeANN(2, (X, Y); learningRate=0.1)
    println("Pérdidas con tasa de aprendizaje 0.1: ", losses_lr_1)

    println("==== Test 7: Verificación de maxNumNeurons ====")
    ann_neurons, losses_neurons = trainClassCascadeANN(5, (X, Y))
    println("Número de capas en la red tras añadir 5 neuronas: ", length(ann_neurons.layers))

end

# Llamar a la función de pruebas
test_trainClassANN_and_trainClassCascadeANN()
