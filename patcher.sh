VERSION="15_2"
OUTPUT="am2r_"${VERSION}
INPUT=""

# Cleanup in case the dirs exists 
if [ -d "$OUTPUT" ]; then
    rm -r ${OUTPUT}
fi

if [ -d "assets/" ]; then
    rm -rf assets/
fi

if [ -d "AM2RWrapper/" ]; then
    rm -rf AM2RWrapper/
fi

if [ -d "data/" ]; then
    rm -rf data/
fi
if [ -d "HDR_HQ_in-game_music/" ]; then
    rm -rf HDR_HQ_in-game_music
fi

echo "-------------------------------------------"
echo ""
echo "AM2R 1.5.2 Shell Autopatching Utility"
echo "Scripted by Miepee and help from Lojemiru"
echo ""
echo "-------------------------------------------"

#install dependencies
pkg install subversion zip unzip xdelta3 -y

#check if apkmod is instaled, if not install it. I only use this for signing 'cause it's the only way I found this to work
if ! [ -f /data/data/com.termux/files/usr/bin/apkmod ]; then
    wget https://raw.githubusercontent.com/Hax4us/Apkmod/master/setup.sh
    sh setup.sh
    rm -f setup.sh
fi

#download the patch data
svn export https://github.com/Miepee/AM2R-Autopatcher-Android/trunk/data

#check if termux-storage has been setup
if ! [ -d ~/storage ]; then
    #create if no
    termux-setup-storage
fi

echo ""

#check for AM2R_11.zip in downloads
if [ -f ~/storage/downloads/AM2R_11.zip ]; then
    echo "AM2R_11.zip found! Extracting to ${OUTPUT}"
    #extract the content to the am2r_xx folder
    unzip -q ~/storage/downloads/AM2R_11.zip -d "${OUTPUT}"
else
    echo -e "\033[0;31mAM2R_11 not found. Place AM2R_11.zip (case sensitive) into your Downloads folder and try again."
    echo -e "\033[1;37m"
    exit -1
fi

echo "Applying Android patch..."
xdelta3 -dfs "${OUTPUT}"/data.win data/droid.xdelta  "${OUTPUT}"/game.droid
#cp data/android/AM2RWrapper.apk utilities/android/

#delete unnecessary files
rm "${OUTPUT}"/D3DX9_43.dll "${OUTPUT}"/AM2R.exe "${OUTPUT}"/data.win 

#cp -RTp "${OUTPUT}"/ utilities/android/assets/
cp -p data/android/AM2R.ini "${OUTPUT}"/


# Music
#mkdir -p utilities/android/assets/lang
cp data/files_to_copy/*.ogg "${OUTPUT}"/

echo ""
echo -e "\033[0;32mInstall high quality in-game music? Increases filesize by 230 MB and may lag the game\!"
echo -e "\033[1;37m"
echo "[y/n]"

read -n1 INPUT
echo ""

if [ $INPUT = "y" ]; then
    echo "Downloading HQ music..."
    svn export https://github.com/Miepee/AM2R-Autopatcher-Android/trunk/HDR_HQ_in-game_music
    echo "Copying HQ music..."
    cp -f HDR_HQ_in-game_music/*.ogg "${OUTPUT}"/
    rm -rf HDR_HQ_in-game_music/
fi

echo "Updating lang folder..."
#remove old lang
rm -R "${OUTPUT}"/lang/
#install new lang
cp -RTp data/files_to_copy/lang/ "${OUTPUT}"/lang/

echo "Renaming music to lowercase..."
#I can't figure out a better way to mass rename files to lowercase
#so zipping them without compression and extracting them as all lowercase it is
#music needs to be all lowercase
zip -0qr temp.zip "${OUTPUT}"/*.ogg
rm "${OUTPUT}"/*.ogg
unzip -qLL temp.zip
rm temp.zip

echo "Packaging APK..."
#decompile the apk
apkmod -d data/android/AM2RWrapper.apk -o AM2RWrapper
#copy
mv "${OUTPUT}" assets
cp -Rp assets AM2RWrapper
#edited yaml thing to not compress ogg's
echo "Editing apktool.yml..."
sed -i "s/doNotCompress:/doNotCompress:\n- ogg/" AM2RWrapper/apktool.yml
#build
apkmod -r AM2RWrapper -o AM2R-"${VERSION}".apk
#Sign apk
apkmod -s AM2R-"${VERSION}".apk -o AM2R-"${VERSION}"-signed.apk

# Cleanup
rm -R assets/ AM2RWrapper/ data/ AM2R-"${VERSION}".apk

# Move signed APK
mv AM2R-"${VERSION}"-signed.apk ~/storage/downloads/AM2R-"${VERSION}"-signed.apk

echo ""
echo -e "\033[0;32mThe operation was completed successfully and the APK can be found in your Downloads folder as \"AM2R-${VERSION}-signed.apk\"."
echo -e "\033[0;32mSee you next mission\!"
echo -e "\033[1;37m"
xdg-open ~/storage/downloads/AM2R-"${VERSION}"-signed.apk
