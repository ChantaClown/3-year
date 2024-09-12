#!/bin/bash

export PATH="/usr/local/julia/bin:$PATH"

# Begin Julia package installation
echo "Starting Julia package installation..."

# Install packages in Julia
julia -e '
    using Pkg;
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
'

# Si el comando anterior se ejecuta sin errores, imprime el mensaje de éxito
if [ $? -eq 0 ]; then
  echo "Julia package installation completed."
else
  echo "An error occurred during package installation."
fi
