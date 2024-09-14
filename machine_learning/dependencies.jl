begin
    import Pkg;
    Pkg.add("XLSX");
    Pkg.add("FileIO");
    Pkg.add("JLD2");
    Pkg.add("Flux");
    Pkg.add("ScikitLearn");
    Pkg.add("Plots");
    Pkg.add("MAT");
    Pkg.add("Images");
    Pkg.add("DelimitedFiles");
    Pkg.add("CSV");
    Pkg.update()
end

Pkg.build("PyCall");
Pkg.build("ScikitLearn");
Pkg.update()