include("main.jl");
using Test
using Random

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

@testset "predictKNN_SVM test" begin
    windowSize = 5
    batchSize = 5
    memory, _ = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)
    # Crear una instancia para realizar la predicción
    instance = rand(Float32, 7)  # Crear una instancia con el mismo número de características que las entradas del dataset
    k = 3
    C = 1.0

    # Caso 1: Predicción con k = 3
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)
    
    # Verificar que la predicción tiene el mismo tipo que las salidas deseadas
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2][1])

    # Caso 2: Predicción para múltiples instancias
    instan = rand(Float32, 3, size(memory, 1))  # 3 instancias, con el mismo número de características que las entradas del dataset
    predicciones = predictKNN_SVM(dataset, instan, k, C)
    
    # Verificar que las predicciones tienen el mismo tipo que las salidas deseadas
    @test length(predicciones) == size(instan, 1)
    @test all(pred in unique(memory[2]) for pred in predicciones)
end

@testset "predictKNN_SVM test2" begin
    windowSize = 5
    batchSize = 5
    memory, _ = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)
    
    # Create an instance for prediction with the same number of features
    instance = rand(Float32, size(memory[1], 2))
    k = 3
    C = 1.0

    # Caso 1: Prediction with k = 1
    k = 1
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)
    
    # Verify that the prediction has the same type as the desired outputs
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2][1])

    # Caso 2: Prediction with k equal to the size of the dataset
    k = size(memory, 1)
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)
    
    # Verify that the prediction has the same type as the desired outputs
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2][1])

    # Caso 3: Prediction with a large value of C
    C = 1000.0
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2][1])

    # Caso 4: Prediction with a small value of C
    C = 0.001
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2][1])

    # Reset k and C for further tests
    k = 3
    C = 1.0

    # Caso 5: Prediction for multiple instances
    instance = rand(Float32, 3, size(memory[1], 2))  # 3 instances
    predicciones = predictKNN_SVM(memory, instance, k, C)
    
    # Verify that the predictions have the same type as the desired outputs
    @test length(predicciones) == size(instance, 1)
    @test all(pred in unique(memory[2][1]) for pred in predicciones)

end
