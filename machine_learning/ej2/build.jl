# ----------------------------------------------------------------------------------------------
# ------------------------------------- Ejercicio 2 --------------------------------------------
# ----------------------------------------------------------------------------------------------

using Flux

indexOutputLayer(ann::Chain) = length(ann) - (ann[end]==softmax);

function newClassCascadeNetwork(numInputs::Int, numOutputs::Int)
    #
    # Codigo a desarrollar
    #
end;

function addClassCascadeNeuron(previousANN::Chain; transferFunction::Function=σ)
    #=
    crea  una  RNA  nueva  añadiéndole  una  nueva  capa  oculta  
    con  una  neurona,  pero  que  ante  las  mismas entradas emite las mismas salidas
    =#
    # Reference previus layers and the output
    outputLayer    = previousANN[   indexOutputLayer(previousANN)   ]; 
    previousLayers = previousANN[1:(indexOutputLayer(previousANN)-1)]; 

    numInputsOutputLayer  = size(outputLayer.weight, 2); 
    numOutputsOutputLayer = size(outputLayer.weight, 1); 
    # New neuron layer
    ann = Chain( 
        previousLayers..., 
        SkipConnection(Dense(numInputsOutputLayer, 1, transferFunction), (mx, x) -> vcat(x, mx)), 
        if numOutputsOutputLayer == 2
            ann = Chain(ann..., Dense(numInputsLayer, 1, σ));
        else
            ann = Chain(ann..., Dense(numInputsLayer, numOutputs, identity));
            ann = Chain(ann..., softmax);
        end;    
    );
    # Last col is all 0
    ann[indexOutputLayer(previousANN)].weight[:,-1] .= 0
    ann[indexOutputLayer(previousANN)].weight[:,setdiff(1:size(outputLayer, 2))] .= outputLayer.weight
    ann[indexOutputLayer(previousANN)].bias .= outputLayer.bias
    return ann
end;

function trainClassANN!(ann::Chain, trainingDataset::Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,2}}, trainOnly2LastLayers::Bool;
    maxEpochs::Int=1000, minLoss::Real=0.0, learningRate::Real=0.001, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)
    #
    # Codigo a desarrollar
    #
end;


function trainClassCascadeANN(maxNumNeurons::Int,
    trainingDataset::Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,2}};
    transferFunction::Function=σ,
    maxEpochs::Int=1000, minLoss::Real=0.0, learningRate::Real=0.001, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)
    #
    # Codigo a desarrollar
    #
end;

function trainClassCascadeANN(maxNumNeurons::Int,
    trainingDataset::  Tuple{AbstractArray{<:Real,2}, AbstractArray{Bool,1}};
    transferFunction::Function=σ,
    maxEpochs::Int=100, minLoss::Real=0.0, learningRate::Real=0.01, minLossChange::Real=1e-7, lossChangeWindowSize::Int=5)
    #
    # Codigo a desarrollar
    #
end;
    
