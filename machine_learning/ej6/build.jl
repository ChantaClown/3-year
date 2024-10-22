include("main.jl");
using Test
using Random

function predictKNN_SVM(dataset::Batch, instance::AbstractArray{<:Real,1}, k::Int, C::Real)

    inputs, targets = dataset
    distance = euclideanDistances(dataset, instance)
    minDistances = partialsortperm(distance, 1:k)
    
    # Todas son de la misma clase
    if length(unique(targets[minDistances])) == 1
        return targets[minDistances[1]]
    end
    
    # Creacion y entrenamiento del modelo
    model = SVC(kernel="linear", C=C, random_state=1)
    inputs = inputs[minDistances, :]
    targets = targets[minDistances]
    fit!(model, inputs, targets)
    
    # Prediccion de la instancia
    pred = predict(model, reshape(instance, 1, :))[1]
    
    return pred
end;

function predictKNN_SVM(dataset::Batch, instances::AbstractArray{<:Real,2}, k::Int, C::Real)
    predictions = [predictKNN_SVM(dataset, instance, k, C) for instance in eachrow(instances)]  
    return predictions
end;

using Test

@testset "predictKNN_SVM tests" begin
    windowSize = 5
    batchSize = 5
    memory, _ = initializeStreamLearningData("machine_learning/test/", windowSize, batchSize)

    # Create a random instance for prediction with 7 features
    instance = rand(Float32, 7)
    k = 3
    C = 1.0  # SVM regularization parameter

    # Case 1: Prediction with k = 3 for a single instance
    valor_prediccion = predictKNN_SVM(memory, instance, k, C)

    # Verify that the prediction has the same type as the desired outputs
    @test typeof(valor_prediccion) == typeof(memory[2][1])
    @test valor_prediccion in unique(memory[2])

    # Case 2: Prediction for multiple instances
    instances = rand(Float32, 3, 7)  # 3 instances, each with 7 features
    predicciones = predictKNN_SVM(memory, instances, k, C)

    # Verify that the predictions have the same type as the desired outputs
    @test length(predicciones) == size(instances, 1)
    @test all(typeof(pred) == typeof(memory[2][1]) for pred in predicciones)
    @test all(pred in unique(memory[2]) for pred in predicciones)
end
