#!/bin/sh
set -e

JOBS=4

install_nnedi3_weights ()
{
  p="/usr/local/lib/vapoursynth"
  f="$p/nnedi3_weights.bin"
  sum="27f382430435bb7613deb1c52f3c79c300c9869812cfe29079432a9c82251d42"
  if [ ! -f $f ] || [ "$(sha256sum -b $f | head -c64)" != "$sum" ]; then
    sudo mkdir -p $p
    sudo rm -f $f
    sudo wget -O $f https://github.com/dubhater/vapoursynth-nnedi3/raw/master/src/nnedi3_weights.bin
  fi
}

ghdl ()
{
  git clone --depth 1 --recursive https://github.com/$1 build
  cd build
}

strip_copy ()
{
  chmod a-x $1
  strip $1
  nm -D --extern-only $1 | grep -q 'T VapourSynthPluginInit'
  sudo  cp -f $1 /usr/local/lib/vapoursynth
}

finish ()
{
  strip_copy $1
  cd ..
  rm -rf build
}

build ()
{
  if [ -f meson.build ]; then
    meson build
    ninja -C build -j$JOBS
  elif [ -f waf ]; then
    python3 ./waf configure
    python3 ./waf build -j$JOBS
  else
    if [ ! -e configure -a -f configure.ac ]; then
      autoreconf -if
    fi

    if [ -e configure ]; then
      chmod a+x configure
      if grep -q -- '--extra-cflags' configure && grep -q -- '--extra-cxxflags' configure ; then
        ./configure --extra-cflags="$CFLAGS" || cat config.log
      elif grep -q -- '--extra-cflags' configure ; then
        ./configure --extra-cflags="$CFLAGS" || cat config.log
      elif grep -q -- '--extra-cxxflags' configure ; then
        ./configure --extra-cxxflags="$CXXFLAGS" || cat config.log
      else
        ./configure || cat config.log
      fi
    fi

    make -j$JOBS X86=1
  fi

  if [ -e .libs/${1}.so ]; then
    finish .libs/${1}.so
  elif [ -e build/${1}.so ]; then
    finish build/${1}.so
  else
    finish ${1}.so
  fi
}

mkgh ()
{
  ghdl $1
  build $2
}

set -x

export LD_LIBRARY_PATH="/usr/local/lib;/usr/local/lib/vapoursynth"
export CFLAGS="-pipe -O3 -Wno-attributes -fPIC -fvisibility=hidden -fno-strict-aliasing $(pkg-config --cflags vapoursynth) -I/usr/include/compute"
export CXXFLAGS="$CFLAGS -Wno-reorder"
