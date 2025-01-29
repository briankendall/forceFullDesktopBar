#!/bin/bash

FRIDA_VERSON=16.6.6

mkdir -p temp
cd temp

if test -f "frida-core-x86_64.xz"; then
    echo frida-core-x86_64.xz already exists, skiping...
else
    echo Downloading frida-core-x86_64.xz...
    curl -L --output frida-core-x86_64.xz https://github.com/frida/frida/releases/download/$FRIDA_VERSON/frida-core-devkit-$FRIDA_VERSON-macos-x86_64.tar.xz
fi

if test -f "frida-core-arm64e.xz"; then
    echo frida-core-arm64e.xz already exists, skiping...
else
    echo Downloading frida-core-arm64e.xz...
    curl -L --output frida-core-arm64e.xz https://github.com/frida/frida/releases/download/$FRIDA_VERSON/frida-core-devkit-$FRIDA_VERSON-macos-arm64e.tar.xz
fi

if test -f "frida-gum-x86_64.xz"; then
    echo frida-gum-x86_64.xz already exists, skiping...
else
    echo Downloading frida-gum-x86_64.xz...
    curl -L --output frida-gum-x86_64.xz https://github.com/frida/frida/releases/download/$FRIDA_VERSON/frida-gum-devkit-$FRIDA_VERSON-macos-x86_64.tar.xz
fi

if test -f "frida-gum-arm64e.xz"; then
    echo frida-gum-arm64e.xz already exists, skiping...
else
    echo Downloading frida-gum-arm64e.xz...
    curl -L --output frida-gum-arm64e.xz https://github.com/frida/frida/releases/download/$FRIDA_VERSON/frida-gum-devkit-$FRIDA_VERSON-macos-arm64e.tar.xz
fi


echo "Extracting x86_64 libfrida-core.a..."
tar xf frida-core-x86_64.xz libfrida-core.a
mv libfrida-core.a libfrida-core-x86_64.a

if ! test -f "libfrida-core-x86_64.a"; then
    echo Failed to extract libfrida-core-x86_64.a
    exit 1
fi


echo "Extracting arm64e libfrida-core.a..."
tar xf frida-core-arm64e.xz libfrida-core.a
mv libfrida-core.a libfrida-core-arm64e.a

if ! test -f "libfrida-core-arm64e.a"; then
    echo Failed to extract libfrida-core-arm64e.a
    exit 1
fi


echo "Creating FAT libfrida-core.a..."
lipo -create libfrida-core-x86_64.a libfrida-core-arm64e.a -output libfrida-core-x86_64-arm64e.a

if ! test -f "libfrida-core-x86_64-arm64e.a"; then
    echo Failed to create libfrida-core-x86_64-arm64e.a
    exit 1
fi

mv libfrida-core-x86_64-arm64e.a ../forceFullDesktopBar/


echo "Extracting x86_64 libfrida-gum.a..."
tar xf frida-gum-x86_64.xz libfrida-gum.a
mv libfrida-gum.a libfrida-gum-x86_64.a

if ! test -f "libfrida-gum-x86_64.a"; then
    echo Failed to extract libfrida-gum-x86_64.a
    exit 1
fi


echo "Extracting arm64e libfrida-gum.a..."
tar xf frida-gum-arm64e.xz libfrida-gum.a
mv libfrida-gum.a libfrida-gum-arm64e.a

if ! test -f "libfrida-gum-arm64e.a"; then
    echo Failed to extract libfrida-gum-arm64e.a
    exit 1
fi


echo "Creating FAT libfrida-gum.a..."
lipo -create libfrida-gum-x86_64.a libfrida-gum-arm64e.a -output libfrida-gum-x86_64-arm64e.a

if ! test -f "libfrida-gum-x86_64-arm64e.a"; then
    echo Failed to create libfrida-gum-x86_64-arm64e.a
    exit 1
fi

mv libfrida-gum-x86_64-arm64e.a ../dockInjection/


echo "Extracting frida-core.h..."
tar xf frida-core-arm64e.xz frida-core.h

if ! test -f "frida-core.h"; then
    echo Failed to extract frida-core.h
    exit 1
fi

rm -rf ../forceFullDesktopBar/frida-core.h
mv frida-core.h ../forceFullDesktopBar/frida-core.h


echo "Extracting frida-gum.h..."
tar xf frida-gum-arm64e.xz frida-gum.h

if ! test -f "frida-gum.h"; then
    echo Failed to extract frida-gum.h
    exit 1
fi

rm -rf ../dockInjection/frida-gum.h
mv frida-gum.h ../dockInjection/frida-gum.h
# Need to replace these lines otherwise we get compiler errors
# due to conflicting definition of bpf_insn:
sed -i '' '/^typedef enum bpf_insn {$/s//typedef enum bpf_insn2 {/' ../dockInjection/frida-gum.h
sed -i '' '/^} bpf_insn;$/s//} bpf_insn2;/' ../dockInjection/frida-gum.h

echo "Cleaning up..."

rm frida-core-arm64e.xz
rm frida-core-x86_64.xz
rm frida-gum-arm64e.xz
rm frida-gum-x86_64.xz
rm libfrida-core-arm64e.a
rm libfrida-core-x86_64.a
rm libfrida-gum-arm64e.a
rm libfrida-gum-x86_64.a

cd ..
rmdir temp
