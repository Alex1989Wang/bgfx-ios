#  Shader-Converter

用于转换所有在`shaders`文件夹中使用bgfx的着色器语言写的着色器程序。

## 转换

转换着色器程序需要调用bgfx提供的`shadercRelease`命令行工具。

```
Options:
  -h, --help                    Help.
  -v, --version                 Version information only.
  -f <file path>                Input file path.
  -i <include path>             Include path (for multiple paths use -i multiple times).
  -o <file path>                Output file path.
      --bin2c [array name]      Generate C header file. If array name is not specified base file name will be used as name.
      --depends                 Generate makefile style depends file.
      --platform <platform>     Target platform.
           android
           asm.js
           ios
           linux
           orbis
           osx
           windows
      -p, --profile <profile>   Shader model (default GLSL).
           s_3
           s_4
           s_4_0_level
           s_5
           metal
           pssl
           spirv              Alias for spirv10-10.
           spirv10-10
           spirv13-11
           spirv14-11
           spirv15-12
      --preprocess              Preprocess only.
      --define <defines>        Add defines to preprocessor (semicolon separated).
      --raw                     Do not process shader. No preprocessor, and no glsl-optimizer (GLSL only).
      --type <type>             Shader type (vertex, fragment)
      --varyingdef <file path>  Path to varying.def.sc file.
      --verbose                 Verbose.

Options (DX9 and DX11 only):

      --debug                   Debug information.
      --disasm                  Disassemble compiled shader.
  -O <level>                    Optimization level (0, 1, 2, 3).
      --Werror                  Treat warnings as errors.
```

### 示例

编译针对ios Metal 版本

```
./shadercRelease  -f vs_cubes.sc -o ./metal/vs_cubes.bin --depends -i ../../src --varyingdef varying.def.sc --platform ios -p metal  --type vertex -O 3

./shadercRelease -f fs_cubes.sc -o ./metal/fs_cubes.bin --depends -i ../../src --varyingdef varying.def.sc --platform ios -p metal  --type fragment -O 3
```
