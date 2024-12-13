x = input($\ldots$)
s1 = Dense(10)(x)
s2 = Dense(5)(x)

      _ > 10
[x] -|_ > 5

model = Model(x, {'s1':s1,'s2':s2, [s1,s2]})
model.compile(loss={'s1':$\ldots$, 's2':$\ldots$})

lss_weights -> cuanto queremos que pondere los pesos de las entradas
L = $\alpha$ loss('s1') + $\alpha$ loss('s2')

return_sequences -> devuelve una salida total o para cada entrada

    1 solo _> queremos la total
    mas de uno -> si queremos anidar necesitamos cojer para cada entrada ya que tenemos que pasarselo al siguiente modelo

nunca usar variables fin

el valor de la variable "precio fin" puede ser el incial tras 6h o el final