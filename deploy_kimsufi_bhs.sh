#!/bin/bash
# =================================================================
# Deployment Script for PTMG v3.3.0 on Kimsufi (Beauharnois/BHS)
# Target OS: Ubuntu 24.04 LTS
# =================================================================

set -e

echo "--- Initialisation du serveur Kimsufi (BHS) ---"
sudo apt update && sudo apt upgrade -y

echo "--- Installation des outils de compilation et bibliothèques ---"
sudo apt install -y build-essential gcc gfortran git \
    libopenblas-dev liblapack-dev libhdf5-serial-dev \
    python3-pip python3-venv python3-dev pkg-config

echo "--- Configuration de l'environnement Python ---"
python3 -m venv env_ptmg
source env_ptmg/bin/activate
pip install --upgrade pip
pip install numpy scipy matplotlib emcee h5py pyyaml getdist pandas

echo "--- Clonage et Compilation de PTMG v3.3.0 ---"
if [ ! -d "MCGT" ]; then
    git clone --branch v3.3.0 https://github.com/JeanPhilipLalumiere/MCGT.git
fi
cd MCGT

echo "--- Installation du moteur CLASS (cosmology) ---"
if [ -d "dependencies/class_public" ]; then
    cd dependencies/class_public
    make clean && make -j"$(nproc)"
    cd ../..
fi

echo "--- Configuration du Pare-feu (UFW) ---"
sudo ufw allow ssh
sudo ufw --force enable

echo "--- Vérification finale ---"
python3 -c "import numpy; import emcee; print('Pipeline PTMG prêt sur Kimsufi BHS.')"

echo "-------------------------------------------------------"
echo "Déploiement v3.3.0 terminé."
echo "Active l'environnement avec : source env_ptmg/bin/activate"
echo "-------------------------------------------------------"
