cmake_minimum_required (VERSION 3.6)

project(glare_detector)
set(CMAKE_BUILD_TYPE Release)

find_package( OpenCV REQUIRED )

#Bring headers into the project
include_directories(include)

file(GLOB SOURCES "src/*.cpp")

#Generate the static library from the sources
add_library(GlareDetector STATIC ${SOURCES})

#link OpenCV library
target_link_libraries( GlareDetector ${OpenCV_LIBS} )