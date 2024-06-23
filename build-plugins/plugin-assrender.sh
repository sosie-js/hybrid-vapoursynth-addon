
##
## Note a .so exists for linux in the releases
##

#requires meson build >= 0.64.0
retry_git_clone https://github.com/mesonbuild/meson
cd meson
sudo python3 setup.py  install 
cd ..

# last libass 0.17.2
retry_git_clone https://github.com/libass/libass
cd libass
autoreconf -fiv
./configure --prefix="/usr" 
make -j$(nproc)
sudo make install distclean
cd ..

retry_git_clone https://github.com/AmusementClub/assrender
cd assrender
cmake -B build -S .
cmake --build build --clean-first
cd build/src
ls
chmod a-x libassrender.so
strip libassrender.so
nm -D --extern-only libassrender.so
sudo mkdir -p "$VSPREFIX/vsplugins"
sudo cp -f libassrender.so "$VSPREFIX/vsplugins/"
cd ..
cd ..
rm -rf assrender
rm -rf libass
rm -rf meson
