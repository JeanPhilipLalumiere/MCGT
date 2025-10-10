#!/usr/bin/env python3
import os
r"""
plot_fig02_delta_phi_heatmap.py

Figure 02 - Carte de chaleur de $\delta\phi/\phi(k,a)$
pour le Chapitre 7 (Perturbations scalaires) du projet MCGT.
"""

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import PowerNorm

# --- CONFIGURATION DU LOGGING ---


# --- RACINE DU PROJET ---
RACINE = Path( __file__).resolve().parents[ 2]
