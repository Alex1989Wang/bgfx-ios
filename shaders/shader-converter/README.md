#  Shader-Converter

用于转换所有在`shaders`文件夹中使用bgfx的着色器语言写的着色器程序。

## 转换

转换着色器程序需要调用bgfx提供的`shadercRelease`命令行工具。

编译 Metal 版本
./shadercRelease  -f vs_cubes.sc -o ./glsl/vs_cubes.bin --depends -i ../../src --varyingdef varying.def.sc --platform linux -p metal 120 --type vertex -O3
./shadercRelease -f fs_cubes.sc -o ./glsl/fs_cubes.bin --depends -i ../../src --varyingdef varying.def.sc --platform linux -p metal 120 --type fragment -O3

