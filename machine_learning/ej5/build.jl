include("35634619Y_48111913F_32740686W.jl");
using Test
using Random

# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 5 --------------------------------------------
# ----------------------------------------------------------------------------------------------

function initializeStreamLearningData(datasetFolder::String, windowSize::Int, batchSize::Int)
    #
    # Codigo a desarrollar
    #
end;

function addBatch!(memory::Batch, newBatch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_SVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_ISVM(datasetFolder::String, windowSize::Int, batchSize::Int, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

function euclideanDistances(memory::Batch, instance::AbstractArray{<:Real,1})
    #
    # Codigo a desarrollar
    #
end;

function predictKNN(memory::Batch, instance::AbstractArray{<:Real,1}, k::Int)
    #
    # Codigo a desarrollar
    #
end;

function predictKNN(memory::Batch, instances::AbstractArray{<:Real,2}, k::Int)
    #
    # Codigo a desarrollar
    #
end;

function streamLearning_KNN(datasetFolder::String, windowSize::Int, batchSize::Int, k::Int)
    #
    # Codigo a desarrollar
    #
end;



# ----------------------------------------------------------------------------------------------
# ------------------------------------------ Tets ----------------------------------------------
# ----------------------------------------------------------------------------------------------
