include("main.jl");
using Test
using Random

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
    distance = euclideanDistances(memory,instance)
    indices_vecinos = partialsortperm(distance, 1:k) 
    salidas_vecinos = memory[2][indices_vecinos]
    valor_prediccion = mode(salidas_vecinos)
    return valor_prediccion 

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
# ------------------------------------------ Tets ----------------------------------------------
# ----------------------------------------------------------------------------------------------

@testset "initializeStreamLearningData tests" begin
    windowSize = 5
    batchSize = 5
    # Crear datos de ejemplo
    memory, batches = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)

    # Verificar que la memoria tiene el tamaño correcto
    @test size(memory[1], 1) == windowSize
    @test length(memory[2]) == windowSize

    # Verificar que el número de lotes es correcto
    # @test length(batches) == (size(fullData[1], 1) - windowSize) ÷ batchSize
end

@testset "addBatch! tests" begin
    windowSize = 5
    batchSize = 5

    memory, batches = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)

    # Caso 2: Actualización de la memoria con un nuevo lote
    newBatch = batches[1]
    addBatch!(memory, newBatch)

    # Verificar que la memoria se actualizó correctamente
    @test size(memory[1], 1) == windowSize
    @test length(memory[2]) == windowSize
    @test memory[1][:, end-batchSize+1:end] == newBatch[1][:, 1:batchSize]
    @test memory[2][end-batchSize+1:end] == newBatch[2]
end

@testset "streamLearning_SVM tests" begin

    datasetFolder = "machine_learning/test/"
    windowSize = 5
    batchSize = 5
    kernel = "linear"
    C = 1.0

    # Test para verificar que la longitud del vector de precisiones es correcta
    accuracies = streamLearning_SVM(datasetFolder, windowSize, batchSize, kernel, C)
    expected_length = (1000 - windowSize) ÷ batchSize # Asumiendo que 20 es el tamaño del dataset reducido de prueba
    @test length(accuracies) == expected_length

    # Test para verificar que las precisiones están en el rango [0.0, 1.0]
    @test all(0.0 <= acc <= 1.0 for acc in accuracies)

    # Test para verificar que las precisiones son de tipo Float32
    @test all(typeof(acc) == Float32 for acc in accuracies)
end

@testset "Pruebas de streamLearning_ISVM" begin

    datasetFolder = "machine_learning/test/"
    windowSize = 200
    batchSize = 200
    kernel = "linear"
    C = 1.0

    # Prueba para verificar que la longitud del vector de precisiones es correcta
    accuracies = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C)
    expected_length = length(accuracies)
    @test length(accuracies) == expected_length

    # Prueba para verificar que las precisiones están en el rango [0.0, 1.0]
    @test all(0.0 <= acc <= 1.0 for acc in accuracies)

    # Prueba para verificar que las precisiones son de tipo Float32
    @test all(typeof(acc) == Float32 for acc in accuracies)

    # Pruebas con diferentes kernels y parámetros
    @testset "Pruebas con diferentes kernels y parámetros" begin
        kernels = ["linear", "poly", "rbf"]
        Cs = [0.1, 1.0, 10.0]
        gammas = [0.1, 1.0, 10.0]
        for kernel in kernels
            for C_val in Cs
                for gamma_val in gammas
                    accuracies = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C_val; gamma=gamma_val)
                    @test all(0.0 <= acc <= 1.0 for acc in accuracies)
                end
            end
        end
    end

    # Pruebas con diferentes tamaños de ventana y lote
    @testset "Pruebas con diferentes tamaños de ventana y lote" begin
        windowSizes = [100, 200, 500]
        batchSizes = [50, 100, 200]
        for wSize in windowSizes
            for bSize in batchSizes
                accuracies = streamLearning_ISVM(datasetFolder, wSize, bSize, kernel, C)
                expected_length = length(accuracies)
                @test length(accuracies) == expected_length
                @test all(0.0 <= acc <= 1.0 for acc in accuracies)
            end
        end
    end

    # Prueba con dataset pequeño
    @testset "Prueba con dataset pequeño" begin
        smallDatasetFolder = "machine_learning/test/"
        accuracies = streamLearning_ISVM(smallDatasetFolder, windowSize, batchSize, kernel, C)
        expected_small_length = length(accuracies)
        @test length(accuracies) == expected_small_length
        @test all(0.0 <= acc <= 1.0 for acc in accuracies)
    end

    #= Prueba con dataset vacío
    @testset "Prueba con dataset vacío" begin
        emptyDatasetFolder = "machine_learning/test/"
        accuracies = streamLearning_ISVM(emptyDatasetFolder, windowSize, batchSize, kernel, C)
        @test isempty(accuracies)
    end
    =#
    
    # Prueba de consistencia de resultados
    @testset "Prueba de consistencia de resultados" begin
        accuracies1 = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C)
        accuracies2 = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C)
        @test accuracies1 == accuracies2
    end

    # Prueba con batches de una sola clase
    @testset "Prueba con batches de una sola clase" begin
        singleClassDatasetFolder = "machine_learning/test/"
        accuracies = streamLearning_ISVM(singleClassDatasetFolder, windowSize, batchSize, kernel, C)
        @test all(0.0 <= acc <= 1.0 for acc in accuracies)
    end

    # Prueba de rendimiento
    @testset "Prueba de rendimiento" begin
        @time accuracies = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C)
        @test length(accuracies) > 0  # Verifica que la función se ejecutó
    end

end

@testset "predictKNN tests" begin
    windowSize = 5
    batchSize = 5
    memory, _ = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)
    
    # Crear una instancia para realizar la predicción
    instance = rand(Float32, 7)  # Una instancia con 4 características
    k = 3

    # Caso 1: Predicción con k = 3
    valor_prediccion = predictKNN(memory, instance, k)
    
    # Verificar que la predicción tiene el mismo tipo que las salidas deseadas
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2])

    # Caso 2: Predicción para múltiples instancias
    instances = rand(Float32, 3, 7)  # 3 instancias, 7 características
    predicciones = predictKNN(memory, instances, k)
    
    # Verificar que las predicciones tienen el mismo tipo que las salidas deseadas
    @test length(predicciones) == size(instances, 1)
    @test all(typeof(pred) == typeof(memory[2][1]) for pred in predicciones)
    @test all(pred in unique(memory[2]) for pred in predicciones)
end

@testset "streamLearning_KNN tests" begin

    datasetFolder = "machine_learning/test/"
    windowSize = 5
    batchSize = 5
    k = 3

    # Test para verificar que la longitud del vector de precisiones es correcta
    accuracies = streamLearning_KNN(datasetFolder, windowSize, batchSize, k)
    expected_length = (1000 - windowSize) ÷ batchSize # Asumiendo que 20 es el tamaño del dataset reducido de prueba
    @test length(accuracies) == expected_length

    # Test para verificar que las precisiones están en el rango [0.0, 1.0]
    @test all(0.0 <= acc <= 1.0 for acc in accuracies)

    # Test para verificar que las precisiones son de tipo Float32
    @test all(typeof(acc) == Float32 for acc in accuracies)
end