include("35634619Y_48111913F_32740686W.jl");

using ScikitLearn: @sk_import, fit!, predict
@sk_import svm: SVC

Batch = Tuple{AbstractArray{<:Real,2}, AbstractArray{<:Any,1}}


function batchInputs(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function batchTargets(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function batchLength(batch::Batch)
    #
    # Codigo a desarrollar
    #
end;

function selectInstances(batch::Batch, indices::Any)
    #
    # Codigo a desarrollar
    #
end;

function joinBatches(batch1::Batch, batch2::Batch)
    #
    # Codigo a desarrollar
    #
end;


function divideBatches(dataset::Batch, batchSize::Int; shuffleRows::Bool=false)
    #
    # Codigo a desarrollar
    #
end;

function trainSVM(dataset::Batch, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.,
    supportVectors::Batch=( Array{eltype(dataset[1]),2}(undef,0,size(dataset[1],2)) , Array{eltype(dataset[2]),1}(undef,0) ) )
    #
    # Codigo a desarrollar
    #
end;

function trainSVM(batches::AbstractArray{<:Batch,1}, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

