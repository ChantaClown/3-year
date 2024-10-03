include("35634619Y_48111913F_32740686W.jl");

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
    lenghtTargets = lenght(targets)

    return lenghtInputs == lenghtTargets ? lenghtInputs : error("Las salidas y entradas no coiciden en tamaño")
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
    # Returns Model, vectores de soporte 

    function batchInputs(batch::Batch) 
        batchInputs = batch[1]
    
        return batchIntputs
    end;
    
    
    function batchTargets(batch::Batch) 
        batchTargets = batch[2]
        return batchTargets
    end;
    
    
    function batchLength(batch::Batch) 
        batchInputs = batchInputs(batch)
        lenghtInputs = size(batchInputs, 1)
    
        batchTargets = batchTargets(batch)
        lenghtTargets = lenght(batchTargets)
    
        return lenghtInputs == lenghtTargets ? lenghtInputs : error("Las salidas y entradas no coiciden en tamaño")
    end;
    vector = joinBatches(supportVectors, dataset)

    model = SVC(kernel=kernel, C=C, gamma=gamma, coef0=coef0, degree=degree, random_state=1)
    model.fit!(batchInputs(vector), batchTargets(vector))

    indicesNewSupportVectors = sort(model.support_.+1);
    return model, indicesNewSupportVectors, 

end;

function trainSVM(batches::AbstractArray{<:Batch,1}, kernel::String, C::Real;
    degree::Real=1, gamma::Real=2, coef0::Real=0.)
    #
    # Codigo a desarrollar
    #
end;

