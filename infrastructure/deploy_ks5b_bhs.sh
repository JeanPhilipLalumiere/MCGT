#!/bin/bash
# =================================================================
# Déploiement PTMG v3.3.1 - Laboratoire de Beauharnois (KS-5-B)
# Matériel : Intel Xeon (6c/12t) | RAM : 64 Go | OS : Ubuntu 22.04
# =================================================================

set -e

echo "--- [1/5] Nettoyage et Mise à jour Système ---"
# On efface les restes d'une installation ratée si nécessaire
sudo rm -rf MCGT
sudo apt update && sudo apt upgrade -y

echo "--- [2/5] Installation des outils de calcul (C++, Fortran, Python) ---"
sudo apt install -y build-essential gcc gfortran git \
    libopenblas-dev liblapack-dev libhdf5-serial-dev \
    python3-pip python3-venv python3-dev pkg-config htop

echo "--- [3/5] Création de l'environnement Python env_ptmg ---"
rm -rf env_ptmg
python3 -m venv env_ptmg
source env_ptmg/bin/activate
pip install --upgrade pip
pip install numpy scipy matplotlib emcee h5py pyyaml getdist pandas

echo "--- [4/5] Clonage sécurisé de PTMG v3.3.1 ---"
# Utilisation de l'URL publique du dépôt; l'authentification se gère via SSH ou gh auth si nécessaire.
git clone https://github.com/JeanPhilipLalumiere/MCGT.git

cd MCGT
# On s'assure d'être sur la bonne branche/tag si applicable
git checkout v3.3.1 || echo "Note : Utilisation de la branche par défaut."

# Compilation de CLASS (Moteur de Boltzmann)
# On utilise -j12 pour exploiter les 12 threads du Xeon
if [ -d "dependencies/class_public" ]; then
    echo "--- Compilation de CLASS sur 12 threads ---"
    cd dependencies/class_public
    make clean
    make -j12
    cd ../..
else
    echo "ATTENTION : Dossier CLASS non trouvé dans dependencies/class_public"
fi

echo "--- [5/5] Configuration finale ---"
echo "-----------------------------------------------------------"
echo "  INSTALLATION RÉUSSIE SUR LE SERVEUR BHS (ns501460)"
echo "  Puissance disponible : $(nproc) threads"
echo "-----------------------------------------------------------"
echo "  POUR COMMENCER : "
echo "  1. source env_ptmg/bin/activate"
echo "  2. cd MCGT"
echo "  3. python3 main.py (ou ton script de lancement)"
echo "-----------------------------------------------------------"
