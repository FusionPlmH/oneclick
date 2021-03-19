#!bin/bash
echo "   Welcome to use This Tool "
echo ""
echo "    Power by Neodev Team"

echo -n "Checking environment... "
echo ""
if cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/os-release | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/os-release | grep -Eqi "debian"; then
    release="debian"
else
    echo "==============="
    echo "Not supported"
    echo "==============="
    exit
fi
clear

echo "Do you want to check the require dependencies ? It is recommned to check at first time .(y/n)"
read check
if [ $check = "y" ] ; then
echo -n "Checking dependencies... "
echo ""
echo "Preparing proper environment.." 
apt update
apt install -y python-dev python3 build-essential libssl-dev libffi-dev python3-dev python3-pip simg2img liblz4-tool curl
clear
echo "Downloading Samloader.."
pip3 install git+https://github.com/nlscc/samloader.git
else
echo "Skip dependencies Check."
echo ""
fi

clear
 
echo "Enter Model(Example:SM-G9550): "
read model
echo "Enter Region (Example:CHC): "
read region
echo ""
check=$(samloader -m $model -r $region checkupdate)
echo "Dowloading firmware..."
samloader -m $model -r $region download -v $check -O .
input=$(find -name "$model*.zip.enc4" | tee log)
cat log > tmpf
sed -i 's/.enc4//' tmpf
name=$(cat tmpf)
echo ""
echo "Decrypting firmware..."
samloader -m $model -r $region decrypt -v $check -V 4 -i $input -o $name
echo "Done!.."
echo ""

echo ""
rm -rf log tmpf $input
echo "You have download the firmware successfully "
echo ""
clear

if [[ "$model" == *"SM-G9500"* || "$model" == *"SM-G9550"* || "$model" == *"SM-N9500"* ]] ; then
echo "Now Deploying firmware "
echo ""
echo "Extrating System Image... "
echo ""
unzip -q -o $name AP*.tar.md5 
tar -xf AP*.tar.md5 system.img.ext4.lz4

rm -rf AP*.tar.md5 

lz4 -d -q system.img.ext4.lz4 system.img.ext4

rm -rf system.img.ext4.lz4

mkdir system

mkdir tempsystem

echo "Converting System Image... "
echo ""
simg2img system.img.ext4 system.img

rm -rf system.img.ext4

echo "Mount System Image... "
echo ""
mount -t ext4 -o loop system.img tempsystem/

cp -arf tempsystem/* system/

umount tempsystem

rm -rf tempsystem system.img

echo "Extrating CSC Files... "
echo ""
unzip -q -o $name CSC*.tar.md5 

tar -xf CSC*.tar.md5 cache.img.ext4.lz4

rm -rf CSC*.tar.md5

lz4 -d -q cache.img.ext4.lz4 cache.img.ext4

rm -rf cache.img.ext4.lz4

simg2img cache.img.ext4 cache.img

rm -rf cache.img.ext4

mkdir cache

mount -t ext4 -o loop cache.img cache/

unzip -q cache/recovery/sec_csc.zip -d csc

cp -arf csc/system/* system/

umount cache

rm -rf cache csc cache.img

echo "Fixing the System ... "
echo ""
wget -q https://raw.githubusercontent.com/neodevpro/resources/master/8sbasefix.zip

unzip -q 8sbasefix.zip

rm -rf 8sbasefix.zip

cp -arf 8sbasefix/system/. system/

rm -rf 8sbasefix

echo "Downloding Installation Scripts ... "
echo ""
if [[ "$model" == *"SM-G9500"* || "$model" == *"SM-G9550"* ]] ; then
wget -q https://raw.githubusercontent.com/neodevpro/resources/master/s8sflash.zip
unzip -q s8sflash.zip
rm -rf s8sflash.zip
else
wget -q https://raw.githubusercontent.com/neodevpro/resources/master/n8sflash.zip
unzip -q n8sflash.zip
rm -rf n8sflash.zip
fi

echo "Downloding Magisk ... "
echo ""

mkdir rootzip

wget -q -O rootzip/Magisk.zip https://github.com/topjohnwu/Magisk/releases/download/v22.0/Magisk-v22.0.apk

echo "Downloding ${model:0:8} Kernel ... "
echo ""
if [[ "$model" == *"SM-G9500"* ]] ; then 
wget -q -O boot.img https://raw.githubusercontent.com/neodevpro/resources/master/G9500.img
elif [[ "$model" == *"SM-G9550"* ]] ; then 
wget -q -O boot.img https://raw.githubusercontent.com/neodevpro/resources/master/G9550.img
elif [[ "$model" == *"SM-N9500"* ]] ; then 
wget -q -O boot.img https://raw.githubusercontent.com/neodevpro/resources/master/N9500.img
fi



echo "Configuring the System ... "
echo ""
sed -i "s/ro.config.tima=1/ro.config.tima=0/g" system/build.prop
sed -i "s/ro.config.timaversion_info=Knox3.2_../ro.config.timaversion_info=0/g" system/build.prop
sed -i "s/ro.config.iccc_version=3.0/ro.config.iccc_version=iccc_disabled/g" system/build.prop
sed -i "s/ro.config.timaversion=3.0/ro.config.timaversion=0/g" system/build.prop

sed -i "s/ro.config.dmverity=A/ro.config.dmverity=false/g" system/build.prop
sed -i "s/ro.config.kap_default_on=true/ro.config.kap_default_on=false/g" system/build.prop
sed -i "s/ro.config.kap=true/ro.config.kap=false/g" system/build.prop

wget -q https://raw.githubusercontent.com/neodevpro/resources/master/add_to_buildprop.sh

bash ./add_to_buildprop.sh

wget -q https://raw.githubusercontent.com/neodevpro/resources/master/csc_tweaks.sh

sh ./csc_tweaks.sh

rm -rf csc_tweaks.sh add_to_buildprop.sh

rm -rf system/recovery-from-boot.p
rm -rf system/app/BBCAgent
rm -rf system/app/KnoxAttestationAgent
rm -rf system/app/MDMApp
rm -rf system/app/SecurityLogAgent
rm -rf system/app/SecurityProviderSEC
rm -rf system/app/UniversalMDMClient
rm -rf system/container
rm -rf system/etc/permissions/knoxsdk_edm.xml
rm -rf system/etc/permissions/knoxsdk_mdm.xml
rm -rf system/etc/recovery-resource.dat
rm -rf system/priv-app/DiagMonAgent
rm -rf system/priv-app/KLMSAgent
rm -rf system/priv-app/KnoxCore
rm -rf system/priv-app/knoxvpnproxyhandler
rm -rf system/priv-app/Rlc
rm -rf system/priv-app/SamsungPayStub
rm -rf system/priv-app/SecureFolder
rm -rf system/priv-app/SPDClient
rm -rf system/priv-app/TeeService

rm -rf system/lib/libvkservice
rm -rf system/lib64/libvkservice

rm -rf system/lib/libvkjni
rm -rf system/lib64/libvkjni

rm -rf system/etc/init/bootchecker.rc
rm -rf system/secure_storage_daemon_system.rc

rm -rf system/lib/liboemcrypto


echo "Packing the Rom ... "
echo ""
zip -r -q -y StockMod.zip META-INF system rootzip

rm -rf META-INF system

echo "You have port the rom successfully " 
echo ""
echo ""


else
echo "Currently Not supported Stock deploy."
echo ""
fi

echo "All the jobs are done , please enjoy !"
echo ""
du -h *.zip
exit 0

