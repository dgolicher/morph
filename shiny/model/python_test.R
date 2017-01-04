library("rPython")

a<-"
import numpy as np
x = [3, 4, 5]
print(type(x))
"
python.exec(a)

x<-rnorm(100000)
python.assign("x",x)
python.exec("for i in x: x=x*100")
python.exec("print i[:]")
python.exec("x=np.array(x)")
system.time(python.exec("x=x*100"))
system.time(x<-x*100)
system.time(
  {python.assign("x",x)
y<-python.get("sorted(x)")})
system.time(sort(x))

d<-data.frame(x=rnorm(100),y=rnorm(100))
python.assign("d",d)
python.exec("print(d['x'][1])")


