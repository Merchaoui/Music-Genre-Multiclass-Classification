# Test for the best ANN Model
function test_ANN_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1}, 
    kFoldIndices::Array{Int64,1}, transfer_function::Any, update_file::Bool, path::String)
    parameters = Dict();

    # For ANNs, test at least 8 different architectures, between one and 2 hidden layers.
    parameters["maxEpochs"] = 500
    parameters["minLoss"] = 0.0
    parameters["learningRate"] = 0.01
    parameters["repetitionsTraining"] = 3
    parameters["maxEpochsVal"] = 20
    parameters["validationRatio"] = 0

    # Output is the number of classes
    parameters["topology"] = [8,8,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))

    parameters["topology"] = [16,12,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [32,16,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [16,4,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [24,16,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [32,24,16,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [64,32,16,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [20,16,12,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = [8,8,8,8]
    parameters["transferFunctions"] = fill(transfer_function, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    # Assign the best topology of previous test to check some others hyperparameters
    parameters["topology"] = res[2]["topology"];

    # Learning rate   
    parameters["learningRate"] = 0.1
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["learningRate"] = 0.001
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["learningRate"] = 0.01

    # Transfer functions
    parameters["transferFunctions"] = fill(sigmoid, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["transferFunctions"] = fill(logsigmoid, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["transferFunctions"] = fill(tanh_fast, length(parameters["topology"]))
    res = evaluateModel(:ANN, parameters, train_inputs, train_targets, kFoldIndices, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:ANN, res[2], train_inputs, train_targets, kFoldIndices)
    
    # Save the model in disk
    if update_file
        @save path model
    end

    # Get prediction and transform outputs
    outputs = model(test_inputs')

    vmax = maximum(outputs', dims=2);
    outputs = (outputs' .== vmax);

    oh_targets = oneHotEncoding(test_targets)

    metrics = confusionMatrix(outputs, oh_targets);
     
    println("Test: Accuracy: ", metrics[1], " Error rate: ", metrics[2], 
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best knn and train it
function get_Best_ANN(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: Dict{Any, Any}("repetitionsTraining" => 5, "maxEpochs" => 1000, "learningRate" => 0.01, "topology" => [32, 24, 16, 8], "validationRatio" => 0, "maxEpochsVal" => 20, "minLoss" => 0.0, "transferFunctions" => [NNlib.σ, NNlib.σ, NNlib.σ, NNlib.σ]) Best accuracy: 0.2379375907273691
    parameters["maxEpochs"] = 1000
    parameters["minLoss"] = 0.0
    parameters["learningRate"] = 0.01
    parameters["repetitionsTraining"] = 5
    parameters["maxEpochsVal"] = 20
    parameters["validationRatio"] = 0

    parameters["topology"] = [32, 24, 16, 8]
    parameters["transferFunctions"] = fill(sigmoid, length(parameters["topology"]))

    best_model, = modelCrossValidation(:ANN, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best SVM Model
function test_SVM_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();

    # For SVM, test with different kernels and values of C. At least 8 SVM hyperparameter configurations.
    parameters["kernel"] = "rbf";
    parameters["kernelDegree"] = 3;
    parameters["kernelGamma"] = 2;
    parameters["C"] = 1;

    # Additional optional parameters
    parameters["coef0"] =  0.0
    parameters["shrinking"] = true
    parameters["probability"] = true
    parameters["tol"] = 0.001
    
    println("Test results for SVM model: ")

    # Test combination of Kernel and C values
    parameters["kernel"] = "rbf";
    parameters["C"] = 1;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    parameters["C"] = 2;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["C"] = 3;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["C"] = 4;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 10;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["kernel"] = "linear";
    parameters["C"] = 1;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 2;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 10;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["kernel"] = "poly";
    parameters["C"] = 1;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 2;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 10;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["kernel"] = "sigmoid";
    parameters["C"] = 1;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 2;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 10;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    # Assign the best kernel and C of previous test to check the rest of the hyperparameters
    parameters["kernel"] = res[2]["kernel"];
    parameters["C"] = res[2]["C"];

    # Degree test   
    parameters["kernelDegree"] = 5;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
 
    parameters["kernelDegree"] = 1;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["kernelDegree"] = 3;

    # Gamma test
    parameters["kernelGamma"] = 3;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["kernelGamma"] = 2;

    # Tolerance for stopping criterion
    parameters["tol"] = 0.01;
    res = evaluateModel(:SVM, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:SVM, res[2], train_inputs, train_targets, kFoldIndices)
    
    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1], " Error rate: ", metrics[2], 
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best SVM and train it
function get_Best_SVM(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: ("tol" => 0.001, "kernelGamma" => 2, "C" => 4, "kernel" => "rbf", "shrinking" => true, "probability" => true, "coef0" => 0.0, "kernelDegree" => 3))
    parameters["tol"]=0.001
    parameters["kernelGamma"]=2
    parameters["C"] = 4
    parameters["kernel"] = "rbf"
    parameters["shrinking"] = true
    parameters["probability"] = true
    parameters["coef0"] = 0.0
    parameters["kernelDegree"] = 3

    best_model, = modelCrossValidation(:SVM, parameters, train_inputs, train_targets, kFoldIndices)   

    return best_model
end

# Test for the best decision tree Model
function test_DT_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},   
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();

    # For decision trees, test at least 6 different depth values.
    parameters["max_depth"]=4
    parameters["random_state"]=1

    # Additional optional parameters
    parameters["criterion"] = "gini"
    parameters["splitter"] = "best"
    parameters["min_samples_split"] = 2
    
    println("Test results for Decision tree model: ")

    # Test max depth values
    parameters["max_depth"]=4
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    parameters["max_depth"]=3
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["max_depth"]=2
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"]=1
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["max_depth"]=5
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["max_depth"]=6
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"]=7
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"]=8
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"]=9
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)
  
    # Assign the best kernel and C of previous test to check the rest of the hyperparameters
    parameters["max_depth"] = res[2]["max_depth"];

    # Splitter  
    parameters["splitter"] = "random";
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["splitter"] = "best"
 
    # min_samples_split
    parameters["min_samples_split"] = 4;
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["min_samples_split"] = 3;
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["min_samples_split"] = 5;
    res = evaluateModel(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:DecisionTree, res[2], train_inputs, train_targets, kFoldIndices)
    
    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
    
    println("Test: Accuracy: ", metrics[1], " Error rate: ", metrics[2], 
    " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
    " FScore: ", metrics[7])
end

# Get best decition tree and train it
function get_Best_DT(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: ("max_depth" => 6, "random_state" => 1, "splitter" => "best", "criterion" => "gini", "min_samples_split" => 2)
    parameters["max_depth"]=6
    parameters["random_state"]=1
    parameters["criterion"] = "gini"
    parameters["splitter"] = "best"
    parameters["min_samples_split"] = 2

    best_model, = modelCrossValidation(:DecisionTree, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best KNN Model
function test_KNN_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();

    # For kNN, test at least 6 different k values.
    parameters["n_neighbors"]=3

    # Additional optional parameters
    parameters["weights"] = "uniform"
    parameters["metric"] = "nan_euclidean"
    
    println("Test results for KNN model: ")

    # Test max depth values
    parameters["n_neighbors"]=3
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    parameters["n_neighbors"]=2
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["n_neighbors"]=1
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)
 
    parameters["n_neighbors"]=5
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["n_neighbors"]=7
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=10
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=20
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=50
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=60
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=70
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=80
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_neighbors"]=100
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)
   
    # Assign the best k of previous test to check the rest of the hyperparameters
    parameters["n_neighbors"] = res[2]["n_neighbors"];

    # weights  
    parameters["weights"] = "distance";
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["weights"] = "uniform"
 
    # metric
    parameters["metric"] = "minkowski";
    res = evaluateModel(:kNN, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:kNN, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best knn and train it
function get_Best_KNN(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: ("n_neighbors" => 70, "metric" => "minkowski", "weights" => "uniform")
    parameters["n_neighbors"]=70
    parameters["metric"]="minkowski"
    parameters["weights"] = "uniform"

    best_model, = modelCrossValidation(:kNN, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best MLP Model
function test_MLP_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1}, 
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();

    # For ANNs, test at least 8 different architectures, between one and 2 hidden layers.
    parameters["validationRatio"] = 0.0
    parameters["maxEpochs"] = 500
    parameters["learningRate"] = 0.01
    parameters["activation"] = "logistic" # activation{'identity', 'logistic', 'tanh', 'relu'}
    
    parameters["topology"] = (8,8,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))

    parameters["topology"] = (16,12,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (32,16,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (16,4,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (24,16,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (32,24,16,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (64,32,16,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (20,16,12,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (8,8,8,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["topology"] = (64,32,24,16,8)
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    # Assign the best topology of previous test to check some others hyperparameters
    parameters["topology"] = res[2]["topology"];

    # Learning rate   
    parameters["learningRate"] = 10
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["learningRate"] = 0.1
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["learningRate"] = 0.001
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["learningRate"] = 0.01

    parameters["activation"] = "tanh"
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["activation"] = "relu"
    res = evaluateModel(:MLP, parameters, train_inputs, train_targets, kFoldIndices, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:MLP, res[2], train_inputs, train_targets, kFoldIndices)
    
    # Save the model in disk
    if update_file
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best knn and train it
function get_Best_MLP(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: ("maxEpochs" => 1000, "learningRate" => 0.01, "topology" => (64, 32, 24, 16, 8), "validationRatio" => 0.0, "activation" => "relu")
    parameters["maxEpochs"] = 1000
    parameters["learningRate"] = 0.01
    parameters["validationRatio"] = 0
    parameters["activation"] = "relu"

    parameters["topology"] = (64, 32, 24, 16, 8)

    best_model, = modelCrossValidation(:MLP, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best GB Model
function test_GB_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();
    
    println("Test results for GB model: ")

    res = evaluateModel(:GB, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:GB, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best gb and train it
function get_Best_GB(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();
    
    best_model, = modelCrossValidation(:GB, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best LR Model
function test_LR_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();

    parameters["max_iter"] = 1000
    parameters["multi_class"]="multinomial"
    
    println("Test results for LR model: ")

    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))

    parameters["max_iter"] = 500
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 0.5
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 3
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 10
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 30
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["C"] = 1
    parameters["solver"] = "saga"
    res = evaluateModel(:LR, parameters, train_inputs, train_targets, kFoldIndices, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:LR, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best LR and train it
function get_Best_LR(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();

    # Best parameters: ("max_iter" => 1000, "multi_class" => "multinomial")
    parameters["max_iter"] = 1000
    parameters["multi_class"]="multinomial"

    best_model, = modelCrossValidation(:LR, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best NC Model
function test_NC_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();
    
    println("Test results for NC model: ")

    res = evaluateModel(:NC, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:NC, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best nc and train it
function get_Best_NC(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();
    
    best_model, = modelCrossValidation(:NC, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best RN Model
function test_RN_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();
    
    println("Test results for RN model: ")

    res = evaluateModel(:RN, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:RN, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best rn and train it
function get_Best_RN(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();
    
    best_model, = modelCrossValidation(:RN, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best RR Model
function test_RR_Model(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},   
    test_inputs::AbstractArray{<:Real,2}, test_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1}, update_file::Bool, path::String)
    parameters = Dict();
    
    println("Test results for RR model: ")

    res = evaluateModel(:RR, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:RR, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best gb and train it
function get_Best_RR(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1},  
    kFoldIndices::Array{Int64,1})
    parameters = Dict();
    
    best_model, = modelCrossValidation(:RR, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Test for the best Majority voting ensemble
function  test_MV_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , models::Dict, update_file::Bool, path::String)
    
    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = VotingClassifier(estimators = test_models, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = [("SVM", models["SVM"]), ("LR", models["LR"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = VotingClassifier(estimators = test_models, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"]), ("LR", models["LR"]), ("RR", models["RR"])]
    model = VotingClassifier(estimators = test_models, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("SVM", models["SVM"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = VotingClassifier(estimators = test_models, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("SVM", models["SVM"]), ("RR", models["RR"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = VotingClassifier(estimators = test_models, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best mv and train it
function get_Best_MV(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1}, best_models::Dict)
    
    models = [("SVM", best_models["SVM"]), ("KNN", best_models["KNN"]), ("MLP", best_models["MLP"])]
    model = VotingClassifier(estimators = models, n_jobs=-1)

    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best Weighted Majority voting ensemble
function test_WM_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , models::Dict, update_file::Bool, path::String)
    
    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    list_weights=[4,1,2,3]
    model = VotingClassifier(estimators = test_models, n_jobs=-1,weights=list_weights)
    res = evaluateEnsemble(model, (test_models,list_weights) , train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = [("SVM", models["SVM"]), ("LR", models["LR"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    list_weights=[4,2,1,3]
    model = VotingClassifier(estimators = test_models, n_jobs=-1,weights=list_weights)
    res = evaluateEnsemble(model, (test_models,list_weights), train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"]), ("LR", models["LR"]), ("RR", models["RR"])]
    list_weights=[6,2,3,5,2,1]
    model = VotingClassifier(estimators = test_models, n_jobs=-1,weights=list_weights)
    res = evaluateEnsemble(model, (test_models,list_weights), train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
    
    println("Test: Accuracy: ", metrics[1],  
    " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
    " FScore: ", metrics[7])
end

# Get best wm and train it
function get_Best_WM(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1}, best_models::Dict)

    models = [("SVM", best_models["SVM"]), ("DT", best_models["DT"]), ("KNN", best_models["KNN"]), ("MLP", best_models["MLP"]), ("LR", best_models["LR"]), ("RR", best_models["RR"])]
    list_weights=[6,2,3,5,2,1]
    model = VotingClassifier(estimators = models, n_jobs=-1,weights=list_weights)

    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best Stacking ensemble 
function test_ST_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , models::Dict, update_file::Bool, path::String)

    #n_jobs=-1 causes the model to use as many available CPU resources as possible, we change n_jobs=1 to avoid the warning
    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = StackingClassifier(estimators = test_models, final_estimator=SVC(probability=true), n_jobs=1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = [("SVM", models["SVM"]), ("LR", models["LR"]), ("KNN", models["KNN"]), ("MLP", models["MLP"])]
    model = StackingClassifier(estimators = test_models, final_estimator=SVC(probability=true), n_jobs=1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("SVM", models["SVM"]), ("DT", models["DT"]), ("KNN", models["KNN"]), ("MLP", models["MLP"]), ("LR", models["LR"]), ("RR", models["RR"])]
    model = StackingClassifier(estimators = test_models, final_estimator=SVC(probability=true), n_jobs=1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best st and train it
function get_Best_ST(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1}, best_models::Dict)

    models = [("SVM", best_models["SVM"]), ("DT", best_models["DT"]), ("KNN", best_models["KNN"]), ("MLP", best_models["MLP"])]
    model = StackingClassifier(estimators = models, final_estimator=SVC(probability=true), n_jobs=1)

    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best Bagging ensemble 
function test_BG_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , models::Dict, update_file::Bool, path::String)
    
    test_models = [("SVM", models["SVM"], 10, 0.5)]
    model = BaggingClassifier(base_estimator=models["SVM"],n_estimators=10, max_samples=0.5, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = [("SVM", models["SVM"], 10, 0.9)]
    model = BaggingClassifier(base_estimator=models["SVM"],n_estimators=10, max_samples=0.9, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("DT", models["DT"], 10, 0.5)]
    model = BaggingClassifier(base_estimator=models["DT"],n_estimators=10, max_samples=0.5, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("KNN", models["KNN"], 10, 0.5)]
    model = BaggingClassifier(base_estimator=models["KNN"],n_estimators=10, max_samples=0.5, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("MLP", models["MLP"], 10, 0.5)]
    model = BaggingClassifier(base_estimator=models["MLP"],n_estimators=10, max_samples=0.5, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = [("LR", models["LR"], 10, 0.5)]
    model = BaggingClassifier(base_estimator=models["LR"],n_estimators=10, max_samples=0.5, n_jobs=-1)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best bg and train it
function get_Best_BG(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1})
    model = SVC(kernel="rbf", degree=3, gamma = 2, C=4, tol=0.001);
    
    
    model = BaggingClassifier(base_estimator=model,n_estimators=10, max_samples=0.5, n_jobs=-1)
    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best boosting ADA ensemble 
function test_BA_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , models::Dict, update_file::Bool, path::String)
    
    test_models = Dict("SVM" => models["SVM"], "n_estimators" => 10, "algorithm" =>"SAMME", "learning_rate" => 1.0, "random_state" => 0)
    model = AdaBoostClassifier(base_estimator=models["SVM"],n_estimators =10 ,algorithm = "SAMME", learning_rate = 1.0 , random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = Dict("DT" => models["DT"],"n_estimators" => 10, "algorithm" =>"SAMME", "learning_rate" => 1.0, "random_state" => 0)
    model = AdaBoostClassifier(base_estimator=models["DT"],n_estimators =10 ,algorithm = "SAMME", learning_rate = 1.0 , random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = Dict("LR" => models["LR"],"n_estimators" => 10, "algorithm" =>"SAMME", "learning_rate" => 1.0, "random_state" => 0)
    model = AdaBoostClassifier(base_estimator=models["LR"],n_estimators =10 ,algorithm = "SAMME", learning_rate = 1.0 , random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = Dict("RR" => models["RR"],"n_estimators" => 10, "algorithm" =>"SAMME", "learning_rate" => 1.0, "random_state" => 0)
    model = AdaBoostClassifier(base_estimator=models["RR"],n_estimators =10 ,algorithm = "SAMME", learning_rate = 1.0 , random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best bg and train it
function get_Best_BA(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1}, best_models::Dict)
    
    model = AdaBoostClassifier(base_estimator=best_models["DT"],n_estimators =10 ,algorithm = "SAMME", learning_rate = 1.0 , random_state = 0)
    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best boosting Gradient ensemble 
function test_GR_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , update_file::Bool, path::String)

    test_models = Dict("n_estimators" => 10, "max_depth" =>2, "learning_rate" => 1.0, "random_state" => 0)
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=1, max_depth = 2, random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets,(convert(Float64, 0), Dict()))

    test_models = Dict("n_estimators" => 10, "max_depth" =>2, "learning_rate" => 0.1, "random_state" => 0)
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=0.1, max_depth = 2, random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = Dict("n_estimators" => 10, "max_depth" =>2, "learning_rate" => 0.01, "random_state" => 0)
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=0.1, max_depth = 2, random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = Dict("n_estimators" => 10, "max_depth" =>5, "learning_rate" => 1, "random_state" => 0)
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=1, max_depth = 5, random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    test_models = Dict("n_estimators" => 10, "max_depth" =>5, "learning_rate" => 0.1, "random_state" => 0)
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=0.1, max_depth = 5, random_state = 0)
    res = evaluateEnsemble(model, test_models, train_inputs, train_targets, test_inputs, test_targets, res)

    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    model = res[3]

    if update_file
        # Save the model in disk
        @save path model
    end
    
    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best bg and train it
function get_Best_GR(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1})
    
    model= GradientBoostingClassifier(n_estimators =10, learning_rate=0.1, max_depth = 5, random_state = 0)

    fit!(model,train_inputs, train_targets)

    return model
end

# Test for the best Random Forest ensemble 
function test_RF_Model(train_inputs::AbstractArray{<:Real,2},train_targets::AbstractArray{<:Any,1},test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1} , update_file::Bool, path::String)

    parameters = Dict();

    parameters["n_estimators"] = 50
    parameters["max_depth"]= 5
    parameters["max_features"]= "auto"
    
    println("Test results for RF model: ")

    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, (convert(Float64, 0), Dict()))

    parameters["max_depth"]= 10
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"] = 20
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_estimators"] = 180
    parameters["max_depth"] = 11
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["n_estimators"] = 250
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["n_estimators"] = 50
    parameters["max_depth"]= 5
    parameters["max_features"]= "sqrt"
    
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["max_depth"]= 10
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["max_depth"] = 20
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)

    parameters["n_estimators"] = 180
    parameters["max_depth"] = 11
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    parameters["n_estimators"] = 250
    res = evaluateModel(:RF, parameters, train_inputs, train_targets, kFoldIndices, res)
    
    println("//////////////////////////////////////////")
    println("Best parameters: ", res[2], " Best accuracy: ", res[1])

    # Once a configuration has been chosen, perform a new train on the dataset and evaluates the test by obtaining the confusion matrix
    model, = modelCrossValidation(:RF, res[2], train_inputs, train_targets, kFoldIndices)

    if update_file
        # Save the model in disk
        @save path model
    end

    testOutputs = predict(model, test_inputs);
    metrics = confusionMatrix(testOutputs, test_targets);
     
    println("Test: Accuracy: ", metrics[1],  
     " Sensitivity: ", metrics[3], " Specificity rate: ", metrics[4], 
     " FScore: ", metrics[7])
end

# Get best rf and train it
function get_Best_RF(train_inputs::AbstractArray{<:Real,2}, train_targets::AbstractArray{<:Any,1})
    parameters = Dict();

    parameters["n_estimators"] = 180
    parameters["max_depth"]=11

    best_model, = modelCrossValidation(:RF, parameters, train_inputs, train_targets, kFoldIndices)

    return best_model
end

# Evaluate if this model is better than the previous one
function evaluateModel(modelType::Symbol,
    modelHyperParameters::Dict,
    train_inputs::AbstractArray{<:Real,2},
    train_targets::AbstractArray{<:Any,1},
    crossValidationIndices::Array{Int64,1}, 
    previousModel::Tuple{Float64, Dict})

    model_accuracy = modelCrossValidation(modelType, modelHyperParameters, train_inputs, train_targets, crossValidationIndices)
    println("Parameters: ", modelHyperParameters, " Accuracy: ", model_accuracy[2][1], " Fscore: ", model_accuracy[2][5])

    if (model_accuracy[2][1] > previousModel[1])
        best_parameters = copy(modelHyperParameters)
        best_accuracy = model_accuracy[2][1]
    else
        best_parameters = copy(previousModel[2])
        best_accuracy = previousModel[1]
    end

    return (best_accuracy, best_parameters)
end

# Evaluate if this ensemble is better than the previous one
function evaluateEnsemble(
    model::Any,
    modelHyperParameters::Any,
    train_inputs::AbstractArray{<:Real,2},
    train_targets::AbstractArray{<:Any,1},
    test_inputs::AbstractArray{<:Real,2},
    test_targets::AbstractArray{<:Any,1},
    previousModel::Any)

    fit!(model,train_inputs, train_targets)

    testOutputs = predict(model, test_inputs)
    metrics = confusionMatrix(testOutputs, test_targets);

    println("Parameters: ", modelHyperParameters, " Accuracy: ", metrics[1], " Fscore: ", metrics[7])

    if (metrics[1] > previousModel[1])
        best_parameters = modelHyperParameters
        best_accuracy = metrics[1]
        best_model = model
    else
        best_parameters = previousModel[2]
        best_accuracy = previousModel[1]
        best_model = previousModel[3]
    end

    return (best_accuracy, best_parameters, best_model)
end

# load the model from disk
function loadModel(path::String)
    try
        @load path model

        return model
    catch e
        println("An error has occurred while loading the model from disk: ", e.msg)
        println("A custom model while be created instead")
    end
end