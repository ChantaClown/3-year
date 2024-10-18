include("main.jl");
using Test
using Random

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 5 --------------------------------------------
# ----------------------------------------------------------------------------------------------


function streamLearning_SVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)

    # Inicializar memoria y batches
    memory, batches = initializeStreamLearningData(datasetFolder, windowSize, batchSize)
    # Primer SVM
    model, _, _ = trainSVM(memory, kernel, C; degree=degree, gamma=gamma, coef0=coef0)

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
        model, _, _ = trainSVM(memory, kernel, C; degree, gamma, coef0)
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
    accuracies = Float32[]

    for idx in 2:num_batches
        # Test del modelo actual
        X_batch, y_batch = batchInputs(batches[idx]), batchTargets(batches[idx])
        y_pred = predict(model, X_batch)
        push!(accuracies, mean(y_pred .== y_batch))

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
        # FALLO EN EL INDICES SUP
        newSupportVectorsBatch = selectInstances(batches[idx], indicesSupportVectorsBatch)
        supportVectors = joinBatches(newSupportVectorsOld, newSupportVectorsBatch)
        
        # Actualizar vector de edades de los nuevos vectores de soporte
        vectorAgeOld = vectorAge[indicesSupportVectorsOld]
        batch_age_vector = collect(batchSize:-1:1)
        vectorAgeBatch = batch_age_vector[indicesSupportVectorsBatch]
        vectorAge = vcat(vectorAgeOld, vectorAgeBatch)
    end
    # @assert length(accuracies) == length(batches)
    return accuracies
end;


# ----------------------------------------------------------------------------------------------
# ------------------------------------------ Tets ----------------------------------------------
# ----------------------------------------------------------------------------------------------

using Test

# Definir los parámetros de entrada
datasetFolder = "machine_learning/dataset"  # Ruta al dataset
windowSize = 100     # Tamaño de la memoria inicial
batchSize = 100      # Tamaño de cada lote
kernel = "linear"    # Kernel a usar en el SVM
C = 1.0              # Parámetro de regularización

memory, batches = initializeStreamLearningData(datasetFolder, windowSize, batchSize)
size(memory[1])
# Llamar a la función
accuracies = streamLearning_SVM(datasetFolder, windowSize, batchSize, kernel, C)
accuracies2 = streamLearning_KNN(datasetFolder, windowSize, batchSize, 3)

@test typeof(accuracies) == typeof(accuracies2)

# Test: Verificar que la longitud del vector accuracies es la esperada
@test length(accuracies) == (45312 - windowSize) ÷ batchSize + 1

# Test: Verificar que todos los valores de accuracies están entre 0 y 1 (ya que son precisiones)
@test all(accuracies .>= 0) && all(accuracies .<= 1)

# Test: Verificar que hay variabilidad en las precisiones (opcional, dependiendo del comportamiento esperado)
@test std(accuracies) > 0

println("Todos los tests han pasado.")




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

@testset "streamLearning_SVM tests" begin
    windowSize = 5
    batchSize = 5

    # Inicializar datos de prueba
    datasetFolder = "machine_learning/test/"
    kernel = "linear"
    C = 1.0

    accuracies = streamLearning_SVM(datasetFolder, windowSize, batchSize, kernel, C)
    println(accuracies)
    # Verificar que la longitud de accuracies sea correcta
    @test length(accuracies) == length(initializeStreamLearningData(datasetFolder, windowSize, batchSize)[2])

    # Verificar que los valores de accuracies estén en el rango [0, 1]
    @test all(0.0 .<= accuracies .<= 1.0)
end

@testset "streamLearning_ISVM tests" begin
    windowSize = 200
    batchSize = 200

    # Inicializar datos de prueba
    datasetFolder = "machine_learning/dataset/"
    kernel = "linear"
    C = 1.0

    accuracies = streamLearning_ISVM(datasetFolder, windowSize, batchSize, kernel, C)

    # Verificar que la longitud de accuracies sea correcta
    @test length(accuracies) == length(initializeStreamLearningData(datasetFolder, windowSize, batchSize)[2]) - 1

    # Verificar que los valores de accuracies estén en el rango [0, 1]
    @test all(0.0 .<= accuracies .<= 1.0)
end