# Simple JVM implementation

This project was built to help me explore how does the JVM work. It implements a really simple parser and byte code interpreter for Java class files. 

All of the code was written live in about 6 hours on my [twitch channel](https://www.twitch.tv/vexondev), you can find the long form content over on [Youtube](https://www.youtube.com/watch?v=KiPBWRwWLuo&list=PLGgQ-MqLug-YEukOhwPGjRxi9Yzn0JpC9).

## Required tooling
- Java compiler
- [Odin compiler](https://odin-lang.org/docs/install/)

## Running the project
In order to run the VM, you must compile and run the Odin code as module by using the following commands:

`odin build . && ./JavaVM.exe`
or
`odin run .`

Currently, the class filename is hardcoded on top of the Odin file, you might change it if the Java class is renamed.
The above command will use the precompiled `Main.class` file, if you want to modify the java code, do not forget to invoke
the compiler:

`javac Main.java`
