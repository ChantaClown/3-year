include("35634619Y_48111913F_32740686W.jl");
using Test
using IterTools
using Random

using ScikitLearn: @sk_import, fit!, predict
@sk_import svm: SVC

Batch = Tuple{AbstractArray{<:Real,2}, AbstractArray{<:Any,1}}

function batchInputs(batch::Batch) 
    inputs = batch[1]

    return inputs
end;


function batchTargets(batch::Batch) 
    targets = batch[2]
    return targets
end;


function batchLength(batch::Batch) 
    inputs = batchInputs(batch)
    lenghtInputs = size(inputs, 1)

    targets = batchTargets(batch)
    lenghtTargets = length(targets)
                
    return lenghtInputs == lenghtTargets ? lenghtInputs : error("Las salidas y entradas no coiciden en tamaño")
end;

function selectInstances(batch::Batch, indices::Any) 
    # Extraer entradas y salidas del batch
    inputs = batchInputs(batch)
    targets = batchTargets(batch)

    # Seleccionar las instancias correspondientes
    selected_inputs = inputs[indices, :]
    selected_targets = targets[indices]

    # Devolver un nuevo batch con las instancias seleccionadas
    return (selected_inputs, selected_targets)
end


function joinBatches(batch1::Batch, batch2::Batch)
    new_inputs = vcat(batchInputs(batch1), batchInputs(batch2))
    new_targets = vcat(batchTargets(batch1), batchTargets(batch2))
    return (new_inputs, new_targets)
end;


function divideBatches(dataset::Batch, batchSize::Int; shuffleRows::Bool=false)
    inputs = batchInputs(dataset)
    targets = batchTargets(dataset)
    rows = size(inputs, 1)
    
    # Si shuffleRows es verdadero, desordenamos las filas
    if shuffleRows
        indices = shuffle(1:rows)
        inputs = inputs[indices, :]
        targets = targets[indices]
    end

    # Dividir el conjunto de datos en particiones (lotes)
    #=
    * partition(1:size(inputs, 1), batchSize)] -> devuelve un batch de tamaño x con los indices de cada fila
    * partition(1:10, 3)
    * Primer lote: [1, 2, 3]
    * Segundo lote: [4, 5, 6]
    * Tercer lote: [7, 8, 9]
    =#
    batches = [selectInstances((inputs, targets), collect(batch)) for batch in partition(1:rows, batchSize)]

    remaining = rows % batchSize
    if remaining > 0
        last_batch_indices = (rows - remaining + 1):rows
        push!(batches, selectInstances(dataset, collect(last_batch_indices)))
    end
    
    return batches
end;

function trainSVM(dataset::Batch, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.,
    supportVectors::Batch=( Array{eltype(dataset[1]),2}(undef,0,size(dataset[1],2)) , Array{eltype(dataset[2]),1}(undef,0) ) )

    # Concatenar los vectores de soporte con el dataset original si se han pasado
    trainingData = isnothing(supportVectors) ? dataset : joinBatches(supportVectors, dataset)

    inputs = batchInputs(trainingData)
    targets = batchTargets(trainingData)

    # Entrenar el modelo
    model = SVC(kernel=kernel, C=C, gamma=gamma, coef0=coef0, degree=degree, random_state=1)
    fit!(model, inputs, targets)

    indicesNewSupportVectors = sort(model.support_.+1); 

    # Número de vectores de soporte previos
    numOldSupportVectors = isnothing(supportVectors) ? 0 : batchLength(supportVectors)

    # Separar los índices en: vectores de soporte antiguos y los nuevos
    oldSupportIndices = indicesNewSupportVectors[indicesNewSupportVectors .<= numOldSupportVectors]
    newSupportIndices = indicesNewSupportVectors[indicesNewSupportVectors .> numOldSupportVectors] .- numOldSupportVectors
    
    # Crear los lotes de vectores de soporte
    oldSupportVectorsBatch = isnothing(supportVectors) ? nothing : selectInstances(supportVectors, oldSupportIndices)
    newSupportVectorsBatch = selectInstances(dataset, newSupportIndices)
    
    # Concatenar los lotes de vectores de soporte
    finalSupportVectorsBatch = isnothing(oldSupportVectorsBatch) ? newSupportVectorsBatch : joinBatches(oldSupportVectorsBatch, newSupportVectorsBatch)
    
    # Devolver el modelo, los vectores de soporte y el tuple con los índices
    return model, finalSupportVectorsBatch, (oldSupportIndices, newSupportIndices)
end;

function trainSVM(batches::AbstractArray{<:Batch,1}, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    
    supportVectors = nothing

    for batch in batches
        if isnothing(supportVectors)
            # Si no hay vectores de soporte aún, entrenar el modelo sin ellos
            model, supportVectors, _ = trainSVM(batch, kernel, C; degree=degree, gamma=gamma, coef0=coef0)
        else
            # Si ya hay vectores de soporte, usarlos en el entrenamiento
            model, supportVectors, _ = trainSVM(batch, kernel, C; degree=degree, gamma=gamma, coef0=coef0, supportVectors=supportVectors)
        end
    end

    return model
end;


# ----------------------------------------------------------------------------------------------
# ------------------------------------- Test ---------------------------------------------------
# ----------------------------------------------------------------------------------------------


@testset "selectInstances" begin
    # Crear un lote de datos (Batch) con entradas reales y targets booleanos
    inputs_real = rand(Float32, 10, 4)  # 10 instancias con 4 características
    targets_real = rand(Bool, 10)  # 10 salidas booleanas
    batch_real = (inputs_real, targets_real)

    # Seleccionar algunas instancias
    indices_real = [1, 3, 5]
    new_batch_real = selectInstances(batch_real, indices_real)

    # Verificar que las entradas y salidas del nuevo batch tienen el tipo correcto
    @test typeof(new_batch_real[1]) == Matrix{Float32}
    @test typeof(new_batch_real[2]) == Vector{Bool}

    # Verificar que las entradas y salidas seleccionadas tienen el tamaño correcto
    @test size(new_batch_real[1]) == (3, 4)  # 3 instancias seleccionadas, 4 características
    @test length(new_batch_real[2]) == 3     # 3 salidas seleccionadas

    # Verificar que las entradas y salidas seleccionadas coinciden con las originales
    @test new_batch_real[1] == inputs_real[indices_real, :]
    @test new_batch_real[2] == targets_real[indices_real]

    # Crear un lote de datos con entradas y targets de tipo Bool
    inputs_bool = rand(Bool, 8, 3)  # 8 instancias con 3 características
    targets_bool = rand(Bool, 8)    # 8 salidas booleanas
    batch_bool = (inputs_bool, targets_bool)

    # Seleccionar instancias del lote de datos booleano
    indices_bool = [2, 4, 6]
    new_batch_bool = selectInstances(batch_bool, indices_bool)

    # Verificar que las entradas y salidas del nuevo batch booleano son correctas
    @test typeof(new_batch_bool[1]) == Matrix{Bool}
    @test typeof(new_batch_bool[2]) == Vector{Bool}
    @test size(new_batch_bool[1]) == (3, 3)  # 3 instancias seleccionadas, 3 características
    @test length(new_batch_bool[2]) == 3     # 3 salidas seleccionadas
    @test new_batch_bool[1] == inputs_bool[indices_bool, :]
    @test new_batch_bool[2] == targets_bool[indices_bool]
end

@testset "joinBatches" begin
    # Crear dos lotes de datos de tipo Batch (con entradas reales y targets booleanos)
    inputs1 = rand(Float32, 5, 4)  # 5 instancias, 4 características
    targets1 = rand(Bool, 5)       # 5 salidas booleanas
    batch1 = (inputs1, targets1)
    
    inputs2 = rand(Float32, 3, 4)  # 3 instancias, 4 características
    targets2 = rand(Bool, 3)       # 3 salidas booleanas
    batch2 = (inputs2, targets2)
    
    # Combinar los lotes
    combined_batch = joinBatches(batch1, batch2)
    
    # Verificar que las entradas y salidas combinadas tienen el tipo correcto
    @test typeof(combined_batch[1]) == Matrix{Float32}
    @test typeof(combined_batch[2]) == Vector{Bool}
    
    # Verificar que las entradas y salidas combinadas tienen el tamaño correcto
    @test size(combined_batch[1]) == (8, 4)  # 5 + 3 instancias, 4 características
    @test length(combined_batch[2]) == 8     # 5 + 3 salidas
    
    # Verificar que las entradas y salidas combinadas coinciden con las originales
    @test combined_batch[1] == vcat(inputs1, inputs2)
    @test combined_batch[2] == vcat(targets1, targets2)
    
    # Probar con otro lote de datos de tipo Batch (valores booleanos)
    inputs3 = rand(Bool, 4, 3)   # 4 instancias, 3 características
    targets3 = rand(Bool, 4)     # 4 salidas booleanas
    batch3 = (inputs3, targets3)
    
    inputs4 = rand(Bool, 6, 3)   # 6 instancias, 3 características
    targets4 = rand(Bool, 6)     # 6 salidas booleanas
    batch4 = (inputs4, targets4)
    
    # Combinar los nuevos lotes
    combined_batch_bool = joinBatches(batch3, batch4)
    
    # Verificar los tamaños y los resultados de las entradas booleanas
    @test typeof(combined_batch_bool[1]) == Matrix{Bool}
    @test typeof(combined_batch_bool[2]) == Vector{Bool}
    @test size(combined_batch_bool[1]) == (10, 3)  # 4 + 6 instancias, 3 características
    @test length(combined_batch_bool[2]) == 10     # 4 + 6 salidas
    @test combined_batch_bool[1] == vcat(inputs3, inputs4)
    @test combined_batch_bool[2] == vcat(targets3, targets4)
end

# Maybe falla en la aleatoriedad
@testset "divideBatches" begin
    # Crear un conjunto de datos ejemplo
    inputs = rand(Float32, 10, 4)  # 10 instancias con 4 características
    targets = rand(Bool, 10)       # 10 salidas booleanas
    dataset = (inputs, targets)

    # Caso 1: Dividir el conjunto de datos en lotes de tamaño 3, sin desordenar
    batchSize = 3
    batches = divideBatches(dataset, batchSize, shuffleRows=false)
    
    # Verificar que el número de lotes es correcto
    @test length(batches) == 4  # Deberían ser 3 lotes completos y 1 lote con 1 instancia
    
    # Verificar que los tamaños de los lotes son correctos
    @test size(batchInputs(batches[1])) == (3, 4)  # Primer lote debe tener 3 instancias y 4 características
    @test size(batchInputs(batches[2])) == (3, 4)  # Segundo lote debe tener 3 instancias
    @test size(batchInputs(batches[3])) == (3, 4)  # Tercer lote debe tener 3 instancias
    @test size(batchInputs(batches[4])) == (1, 4)  # Último lote debe tener 1 instancia

    # Verificar que el orden de las instancias no se ha desordenado
    combined_inputs = vcat([batchInputs(batch) for batch in batches]...)
    combined_targets = vcat([batchTargets(batch) for batch in batches]...)
    @test combined_inputs == inputs
    @test combined_targets == targets

    # Caso 2: Dividir el conjunto de datos en lotes de tamaño 4, con desorden
    batches_shuffled = divideBatches(dataset, 4, shuffleRows=true)

    # Verificar que el número de lotes es correcto
    @test length(batches_shuffled) == 3  # 2 lotes completos y 1 lote con 2 instancias

    # Verificar que los tamaños de los lotes son correctos
    @test size(batchInputs(batches_shuffled[1])) == (4, 4)  # Primer lote debe tener 4 instancias
    @test size(batchInputs(batches_shuffled[2])) == (4, 4)  # Segundo lote debe tener 4 instancias
    @test size(batchInputs(batches_shuffled[3])) == (2, 4)  # Último lote debe tener 2 instancias

    # Verificar que las entradas y salidas se han desordenado correctamente
    combined_inputs_shuffled = vcat([batchInputs(batch) for batch in batches_shuffled]...)
    combined_targets_shuffled = vcat([batchTargets(batch) for batch in batches_shuffled]...)
    @test combined_inputs_shuffled != inputs  # Verificar que están desordenadas
    @test combined_targets_shuffled != targets

end

@testset "trainSVM" begin
    # Caso 1: Entrenamiento básico de un SVM sin vectores de soporte previos
    inputs = rand(Float32, 10, 4)  # 10 instancias, 4 características
    targets = rand(Bool, 10)       # 10 salidas booleanas
    dataset = (inputs, targets)
    
    model, supportVectors, indicesTuple = trainSVM(dataset, "linear", 1.0)

    # Verificar que los vectores de soporte no son vacíos
    @test length(batchInputs(supportVectors)) > 0
    @test length(batchTargets(supportVectors)) > 0

    # Verificar que los índices devueltos tienen sentido
    oldSupportIndices, newSupportIndices = indicesTuple
    @test typeof(oldSupportIndices) == Vector{Int}
    @test typeof(newSupportIndices) == Vector{Int}
    
    # Verificar que los índices nuevos no estén vacíos
    @test length(newSupportIndices) > 0
    
    # Caso 2: Entrenamiento con vectores de soporte previos
    supportInputs = rand(Float32, 3, 4)  # 3 vectores de soporte previos
    supportTargets = rand(Bool, 3)       # 3 salidas booleanas de soporte
    supportVectors = (supportInputs, supportTargets)
    
    model_with_support, supportVectors_new, indicesTuple_new = trainSVM(dataset, "linear", 1.0, 
                                                                        supportVectors=supportVectors)

    
    # Verificar que los vectores de soporte combinados tienen más de 3 instancias (debería incluir los anteriores)
    @test size(batchInputs(supportVectors_new), 1) > 3

    # Verificar que los índices de soporte anteriores y nuevos tienen sentido
    oldSupportIndices_new, newSupportIndices_new = indicesTuple_new
    
    # =====================COMPROBAR ESTE=============================
    # @test length(oldSupportIndices_new) == 3  # Deben coincidir con los vectores de soporte previos
    @test length(newSupportIndices_new) > 0   # Debe haber nuevos vectores de soporte

    # Verificar que las entradas y salidas de los vectores de soporte no están vacías
    @test length(batchInputs(supportVectors_new)) > 0
    @test length(batchTargets(supportVectors_new)) > 0
    
    # Caso 3: Verificar comportamiento con diferentes kernels
    model_rbf, supportVectors_rbf, indicesTuple_rbf = trainSVM(dataset, "rbf", 1.0, gamma=0.1)
    
    # Verificar que el modelo con kernel rbf tiene vectores de soporte no vacíos
    @test length(batchInputs(supportVectors_rbf)) > 0
    @test length(batchTargets(supportVectors_rbf)) > 0
    
    # Verificar que los índices devueltos tienen sentido
    oldSupportIndices_rbf, newSupportIndices_rbf = indicesTuple_rbf
    @test typeof(oldSupportIndices_rbf) == Vector{Int}
    @test typeof(newSupportIndices_rbf) == Vector{Int}
end

@testset "trainSVM Incremental tests" begin
    # Crear lotes de datos de ejemplo
    batch1 = (rand(Float32, 5, 4), rand(Bool, 5))  # 5 instancias, 4 características
    batch2 = (rand(Float32, 5, 4), rand(Bool, 5))  # Otro lote con 5 instancias, 4 características
    batch3 = (rand(Float32, 5, 4), rand(Bool, 5))  # Otro lote con 5 instancias, 4 características

    # Vector de lotes
    batches = [batch1, batch2, batch3]

    # Caso 1: Entrenamiento incremental con kernel lineal
    model = trainSVM(batches, "linear", 1.0)
    
    # Verificar que el modelo tiene vectores de soporte
    @test length(model.support_) > 0

    # Caso 2: Entrenamiento incremental con kernel RBF
    model_rbf = trainSVM(batches, "rbf", 1.0, gamma=0.1)
    
    # Verificar que el modelo con kernel RBF tiene vectores de soporte
    @test length(model_rbf.support_) > 0

    # Caso 3: Verificar entrenamiento incremental no causa error
    model_incremental = trainSVM(batches, "linear", 1.0)
    
    # Verificar que el modelo incremental tiene vectores de soporte
    @test length(model_incremental.support_) > 0
    
    # Verificar que el número de vectores de soporte no es mayor al total de instancias
    total_instances = sum(size(batch[1], 1) for batch in batches)
    @test length(model_incremental.support_) <= total_instances
end
