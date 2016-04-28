cmake_minimum_required(VERSION 3.0)
find_package(DynamoRIO)
find_package(DrStackVis)

set (SOURCES annotation-app.c)
use_DrStackVis_annotations (annotation-app.out SOURCES)
include_directories(${DynamoRIO_INCLUDE_DIRS})
include_directories(${DrStackVis_INCLUDE_DIRS})
add_executable(annotation-app.out ${SOURCES})
