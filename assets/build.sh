#!/bin/bash
set -e
set -x

BUILDDIR="World"


function build_shader()
{
    # TODO: Consider (strongly) dropping shaderc and using google's one.
    local platform="$1"
    local shader_lang="$2"
    local shader_type="$3"
    local filename="$4"
    install -d -D -m 00755 "${BUILDDIR}/shaders/${shader_lang}"
    profile_arg="--profile ${shader_lang}"
    if [[ "${shader_lang}" == "glsl" ]]; then
        profile_arg=""
    fi
    ../../serpent-support/runtime/bin/shaderc -f "shaders/${filename}" -o "${BUILDDIR}/shaders/${shader_lang}/${filename%.sc}.bin" --type "${shader_type}" -i ../../serpent-support/staging/bgfx/src ${profile_arg} --platform "${platform}"
}

rm -rf "${BUILDDIR}"
mkdir "${BUILDDIR}"
mkdir "${BUILDDIR}/shaders"

for shader_type in "vertex" "fragment" ; do
    for i in shaders/*${shader_type}.sc ; do
        nom=$(basename "${i}")
        # OpenGL Linux
        build_shader linux glsl $shader_type "${nom}"
        # Vulkan Linux
        build_shader linux spirv $shader_type "${nom}"
    done
done
