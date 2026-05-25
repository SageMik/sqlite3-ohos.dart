# SQLCipher Flutter Libs for HarmonyOS
# 预编译库引用配置

cmake_minimum_required(VERSION 3.14)
project(sqlcipher_flutter_libs)

# 设置库文件路径
set(SQLCIPHER_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libs/${OHOS_ARCH}")

# 验证库文件是否存在
if(NOT EXISTS "${SQLCIPHER_LIB_DIR}/libsqlcipher.so")
    message(FATAL_ERROR "找不到预编译的 libsqlcipher.so: ${SQLCIPHER_LIB_DIR}/libsqlcipher.so")
endif()

# 添加预编译的共享库
add_library(sqlcipher SHARED IMPORTED GLOBAL)
set_target_properties(sqlcipher PROPERTIES
    IMPORTED_LOCATION "${SQLCIPHER_LIB_DIR}/libsqlcipher.so"
)

# 打印配置信息
message(STATUS "==================== SQLCipher Flutter Libs ====================")
message(STATUS "架构: ${OHOS_ARCH}")
message(STATUS "库文件: ${SQLCIPHER_LIB_DIR}/libsqlcipher.so")
message(STATUS "==============================================================")
