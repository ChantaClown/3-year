include("main.jl");
using Test
using Random

function predictKNN_SVM(dataset::Batch, instance::AbstractArray{<:Real,1}, k::Int, C::Real)


    inputs, targets = dataset
    distance = euclideanDistances(dataset, instance)
    minDistances = partialsortperm(distance, 1:k)
    
    # Todas son de la misma clase
    if length(unique(labels[minDistances])) == 1
        return labels[minDistances[1]]
    end
    
    # Creacion y entrenamiento del modelo
    model = SVC(kernel="linear", C=C, random_state=1)
    inputs = inputs[minDistances, :]
    targets = targets[minDistances]
    fit!(model, inputs, targets)
    
    # Prediccion de la instancia
    pred = predict(model, reshape(instance, 1, :))
    
    return pred
end;

function predictKNN_SVM(dataset::Batch, instances::AbstractArray{<:Real,2}, k::Int, C::Real)
    predictions = [predictKNN_SVM(dataset, instance, k, C) for instance in eachrow(instances)]  
    return predictions
end;

# Configuración de los datos
windowSize = 5
batchSize = 5
memory, _ = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)

# Crear una instancia para realizar la predicción con el mismo número de características
instance = rand(Float32, size(memory[1], 2))
k = 3
C = 1.0

# Caso 1: Predicción con k = 3 y C = 1.0
println("Caso 1: Predicción con k = 3 y C = 1.0")
valor_prediccion_1 = predictKNN_SVM(memory, instance, k, C)
println("Predicción (k=3, C=1.0): ", valor_prediccion_1)

# Caso 2: Predicción con k = 5 y C = 0.5
println("\nCaso 2: Predicción con k = 5 y C = 0.5")
k2 = 5
C2 = 0.5

valor_prediccion_2 = predictKNN_SVM(memory, instance, k2, C2)
println("Predicción (k=5, C=0.5): ", valor_prediccion_2)

# Caso 3: Predicción con k = 1 y C = 1.0
println("\nCaso 3: Predicción con k = 1 y C = 1.0")
k3 = 1

valor_prediccion_3 = predictKNN_SVM(memory, instance, k3, C)
println("Predicción (k=1, C=1.0): ", valor_prediccion_3)



# Configuración de los datos
windowSize = 5
batchSize = 5
memory, _ = initializeStreamLearningData("machine_learning/dataset/", windowSize, batchSize)

# Crear una matriz de instancias para realizar las predicciones
# Suponiendo que las instancias tienen el mismo número de características que los datos en 'memory'
num_features = size(memory[1], 2)
num_instances = 3  # Número de instancias a predecir
instances = rand(Float32, num_instances, num_features)  # Matriz de instancias

k = 3
C = 1.0

# Prueba 2: Predicciones con una sola instancia en la matriz (debe comportarse como una predicción individual)
println("\nPrueba 2: Predicciones con una sola instancia")
single_instance = instances[1:1, :]  # Tomar la primera instancia como una submatriz (1 fila)
valor_prediccion_single = predictKNN_SVM(memory, single_instance, k, C)
println("Predicción para la única instancia:")
println(valor_prediccion_single)

