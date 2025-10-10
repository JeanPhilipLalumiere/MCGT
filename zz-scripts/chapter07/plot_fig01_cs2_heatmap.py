#!/usr/bin/env python3
import os
"""
plot_fig01_cs2_heatmap.py

Figure 01 - Carte de chaleur de $c_s^2(k,a)$
pour le Chapitre 7 (Perturbations scalaires) du projet MCGT.
"""

import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LogNorm

# --- CONFIGURATION DU LOGGING ---


# --- RACINE DU PROJET ---
RACINE = Path( __file__).resolve().parents[ 2]
