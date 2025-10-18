# Compile failures: contexte par fichier


## zz-scripts/_common/cli.py :: SyntaxError L16: unexpected indent
```text
      10: 
      11: parser.add_argument('--transparent', action='store_true')
      12: 
      13: parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none')
      14: 
      15: parser.add_argument('--verbose', action='store_true')
>>    16:     return parser
```

## zz-scripts/chapter01/plot_fig01_early_plateau.py :: SyntaxError L75: unexpected indent
```text
      69: 
      70: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      71: 
      72: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      73: 
      74: args = parser.parse_args()
>>    75:         try:
      76:             os.makedirs(args.outdir, exist_ok=True)
      77:         os.environ["MCGT_OUTDIR"] = args.outdir
      78: import matplotlib as mpl
      79:         mpl.rcParams["savefig.dpi"] = args.dpi
      80:         mpl.rcParams["savefig.format"] = args.format
      81:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter01/plot_fig02_logistic_calibration.py :: SyntaxError L60: unexpected indent
```text
      54: 
      55: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      56: 
      57: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      58: 
      59: args = parser.parse_args()
>>    60:         try:
      61:             os.makedirs(args.outdir, exist_ok=True)
      62:         os.environ["MCGT_OUTDIR"] = args.outdir
      63: import matplotlib as mpl
      64:         mpl.rcParams["savefig.dpi"] = args.dpi
      65:         mpl.rcParams["savefig.format"] = args.format
      66:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter01/plot_fig03_relative_error_timeline.py :: SyntaxError L56: unexpected indent
```text
      50: 
      51: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      52: 
      53: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      54: 
      55: args = parser.parse_args()
>>    56:         try:
      57:             os.makedirs(args.outdir, exist_ok=True)
      58:         os.environ["MCGT_OUTDIR"] = args.outdir
      59: import matplotlib as mpl
      60:         mpl.rcParams["savefig.dpi"] = args.dpi
      61:         mpl.rcParams["savefig.format"] = args.format
      62:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter01/plot_fig04_P_vs_T_evolution.py :: SyntaxError L61: unexpected indent
```text
      55: 
      56: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      57: 
      58: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      59: 
      60: args = parser.parse_args()
>>    61:         try:
      62:             os.makedirs(args.outdir, exist_ok=True)
      63:         os.environ["MCGT_OUTDIR"] = args.outdir
      64: import matplotlib as mpl
      65:         mpl.rcParams["savefig.dpi"] = args.dpi
      66:         mpl.rcParams["savefig.format"] = args.format
      67:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter01/plot_fig05_I1_vs_T.py :: SyntaxError L53: unexpected indent
```text
      47: 
      48: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      49: 
      50: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      51: 
      52: args = parser.parse_args()
>>    53:         try:
      54:             os.makedirs(args.outdir, exist_ok=True)
      55:         os.environ["MCGT_OUTDIR"] = args.outdir
      56: import matplotlib as mpl
      57:         mpl.rcParams["savefig.dpi"] = args.dpi
      58:         mpl.rcParams["savefig.format"] = args.format
      59:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter01/plot_fig06_P_derivative_comparison.py :: SyntaxError L58: unexpected indent
```text
      52: 
      53: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      54: 
      55: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      56: 
      57: args = parser.parse_args()
>>    58:         try:
      59:             os.makedirs(args.outdir, exist_ok=True)
      60:         os.environ["MCGT_OUTDIR"] = args.outdir
      61: import matplotlib as mpl
      62:         mpl.rcParams["savefig.dpi"] = args.dpi
      63:         mpl.rcParams["savefig.format"] = args.format
      64:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter02/generate_data_chapter02.py :: SyntaxError L100: unexpected indent
```text
      94: 
      95: parser.add_argument(
      96:         "--spectre",
      97:         action="store_true",
      98:         help="Après calibrage, génère 02_primordial_spectrum_spec.json & fig_00_spectre.png",
      99:     )
>>   100:     return parser.parse_args()
     101: 
     102: 
     103: # --- Section 3 : Pipeline principal ---
     104: def main(spectre=False):
     105:     ROOT = Path(__file__).resolve().parents[2]
     106:     DATA_DIR = ROOT / "zz-data" / "chapter02"
```

## zz-scripts/chapter02/plot_fig00_spectrum.py :: SyntaxError L63: unexpected indent
```text
      57: 
      58: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      59: 
      60: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      61: 
      62: args = parser.parse_args()
>>    63:         try:
      64:             os.makedirs(args.outdir, exist_ok=True)
      65:         os.environ["MCGT_OUTDIR"] = args.outdir
      66: import matplotlib as mpl
      67:         mpl.rcParams["savefig.dpi"] = args.dpi
      68:         mpl.rcParams["savefig.format"] = args.format
      69:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter02/plot_fig01_P_vs_T_evolution.py :: SyntaxError L60: unexpected indent
```text
      54: 
      55: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      56: 
      57: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      58: 
      59: args = parser.parse_args()
>>    60:         try:
      61:             os.makedirs(args.outdir, exist_ok=True)
      62:         os.environ["MCGT_OUTDIR"] = args.outdir
      63: import matplotlib as mpl
      64:         mpl.rcParams["savefig.dpi"] = args.dpi
      65:         mpl.rcParams["savefig.format"] = args.format
      66:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter02/plot_fig02_calibration.py :: SyntaxError L60: unexpected indent
```text
      54: 
      55: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      56: 
      57: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      58: 
      59: args = parser.parse_args()
>>    60:         try:
      61:             os.makedirs(args.outdir, exist_ok=True)
      62:         os.environ["MCGT_OUTDIR"] = args.outdir
      63: import matplotlib as mpl
      64:         mpl.rcParams["savefig.dpi"] = args.dpi
      65:         mpl.rcParams["savefig.format"] = args.format
      66:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter02/plot_fig03_relative_errors.py :: SyntaxError L73: unexpected indent
```text
      67: 
      68: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      69: 
      70: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      71: 
      72: args = parser.parse_args()
>>    73:         try:
      74:             os.makedirs(args.outdir, exist_ok=True)
      75:         os.environ["MCGT_OUTDIR"] = args.outdir
      76: import matplotlib as mpl
      77:         mpl.rcParams["savefig.dpi"] = args.dpi
      78:         mpl.rcParams["savefig.format"] = args.format
      79:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter02/plot_fig04_pipeline_diagram.py :: SyntaxError L74: unexpected indent
```text
      68: 
      69: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      70: 
      71: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      72: 
      73: args = parser.parse_args()
>>    74:         try:
      75:             os.makedirs(args.outdir, exist_ok=True)
      76:         os.environ["MCGT_OUTDIR"] = args.outdir
      77: import matplotlib as mpl
      78:         mpl.rcParams["savefig.dpi"] = args.dpi
      79:         mpl.rcParams["savefig.format"] = args.format
      80:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter03/plot_fig07_ricci_fR_vs_z.py :: SyntaxError L10: invalid decimal literal
```text
       4: 
       5: """
       6: Trace f_R et f_{RR} aux points jalons en fonction du redshift - Chapitre 3
       7: ========================================================================
       8: 
       9: Entrée :
>>    10:     zz-data/chapter03/03_ricci_fR_vs_z.csv
      11: Colonnes requises :
      12:     R_over_R0, f_R, f_RR, z
      13: 
      14: Sortie :
      15:     zz-figures/chapter03/03_fig_07_ricci_fr_vs_z.png
      16: """
```

## zz-scripts/chapter03/plot_fig08_ricci_fR_vs_T.py :: SyntaxError L10: invalid decimal literal
```text
       4: 
       5: """
       6: Trace f_R et f_RR aux points jalons en fonction de l'âge de l'Univers (Gyr) - Chapitre 3
       7: =======================================================================================
       8: 
       9: Entrée :
>>    10:     zz-data/chapter03/03_ricci_fR_vs_T.csv
      11: Colonnes requises :
      12:     R_over_R0, f_R, f_RR, T_Gyr
      13: 
      14: Sortie :
      15:     zz-figures/chapter03/03_fig_08_ricci_fr_vs_t.png
      16: """
```

## zz-scripts/chapter04/plot_fig04_relative_deviations.py :: SyntaxError L27: expected an indented block after 'for' statement on line 26
```text
      21:     possible_paths = [
      22:         "zz-data/chapter04/04_dimensionless_invariants.csv",
      23:         "/mnt/data/04_dimensionless_invariants.csv",
      24:     ]
      25:     df = None
      26:     for path in possible_paths:
>>    27:     if os.path.isfile(path):
      28:         df = pd.read_csv(path)
      29:         print(f"Chargé {path}")
      30: 
      31:             df = pd.read_csv( path )
      32:             print(f"Chargé {path}")
      33: 
```

## zz-scripts/chapter05/generate_data_chapter05.py :: SyntaxError L141: unexpected indent
```text
     135: 
     136: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     137: 
     138: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     139: 
     140: args = parser.parse_args()
>>   141:         try:
     142:             os.makedirs(args.outdir, exist_ok=True)
     143:         os.environ["MCGT_OUTDIR"] = args.outdir
     144: import matplotlib as mpl
     145:         mpl.rcParams["savefig.dpi"] = args.dpi
     146:         mpl.rcParams["savefig.format"] = args.format
     147:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter05/plot_fig02_dh_model_vs_obs.py :: SyntaxError L110: unexpected indent
```text
     104: 
     105: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     106: 
     107: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     108: 
     109: args = parser.parse_args()
>>   110:         try:
     111:             os.makedirs(args.outdir, exist_ok=True)
     112:         os.environ["MCGT_OUTDIR"] = args.outdir
     113: import matplotlib as mpl
     114:         mpl.rcParams["savefig.dpi"] = args.dpi
     115:         mpl.rcParams["savefig.format"] = args.format
     116:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter05/plot_fig04_chi2_vs_T.py :: SyntaxError L172: unexpected indent
```text
     166: 
     167: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     168: 
     169: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     170: 
     171: args = parser.parse_args()
>>   172:         try:
     173:             os.makedirs(args.outdir, exist_ok=True)
     174:         os.environ["MCGT_OUTDIR"] = args.outdir
     175: import matplotlib as mpl
     176:         mpl.rcParams["savefig.dpi"] = args.dpi
     177:         mpl.rcParams["savefig.format"] = args.format
     178:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/generate_data_chapter06.py :: SyntaxError L155: unindent does not match any outer indentation level
```text
     149:                     results.replace_transfer(0, tm_data)
     150:         except Exception:
     151:             # If matter transfer access fails, silently continue
     152:             pass
     153:         return results
     154: 
>>   155:     pars.post_process = post_process
     156: 
     157: 
     158: # ---1. LOAD pdot_plateau_z (configuration)---
     159: PDOT_FILE = CONF_DIR / "pdot_plateau_z.dat"
     160: logging.info("1) Reading pdot_plateau_z.dat …")
     161: z_h, pdot = np.loadtxt(PDOT_FILE, unpack=True)
```

## zz-scripts/chapter06/generate_pdot_plateau_vs_z.py :: SyntaxError L81: unexpected indent
```text
      75: 
      76: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      77: 
      78: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      79: 
      80: args = parser.parse_args()
>>    81:         try:
      82:             os.makedirs(args.outdir, exist_ok=True)
      83:         os.environ["MCGT_OUTDIR"] = args.outdir
      84: import matplotlib as mpl
      85:         mpl.rcParams["savefig.dpi"] = args.dpi
      86:         mpl.rcParams["savefig.format"] = args.format
      87:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/plot_fig01_cmb_dataflow_diagram.py :: SyntaxError L140: unexpected indent
```text
     134: 
     135: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     136: 
     137: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     138: 
     139: args = parser.parse_args()
>>   140:         try:
     141:             os.makedirs(args.outdir, exist_ok=True)
     142:         os.environ["MCGT_OUTDIR"] = args.outdir
     143: import matplotlib as mpl
     144:         mpl.rcParams["savefig.dpi"] = args.dpi
     145:         mpl.rcParams["savefig.format"] = args.format
     146:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/plot_fig02_cls_lcdm_vs_mcgt.py :: SyntaxError L152: unexpected indent
```text
     146: 
     147: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     148: 
     149: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     150: 
     151: args = parser.parse_args()
>>   152:         try:
     153:             os.makedirs(args.outdir, exist_ok=True)
     154:         os.environ["MCGT_OUTDIR"] = args.outdir
     155: import matplotlib as mpl
     156:         mpl.rcParams["savefig.dpi"] = args.dpi
     157:         mpl.rcParams["savefig.format"] = args.format
     158:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/plot_fig03_delta_cls_relative.py :: SyntaxError L104: unexpected indent
```text
      98: 
      99: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     100: 
     101: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     102: 
     103: args = parser.parse_args()
>>   104:         try:
     105:             os.makedirs(args.outdir, exist_ok=True)
     106:         os.environ["MCGT_OUTDIR"] = args.outdir
     107: import matplotlib as mpl
     108:         mpl.rcParams["savefig.dpi"] = args.dpi
     109:         mpl.rcParams["savefig.format"] = args.format
     110:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/plot_fig04_delta_rs_vs_params.py :: SyntaxError L94: unexpected indent
```text
      88: 
      89: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      90: 
      91: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      92: 
      93: args = parser.parse_args()
>>    94:         try:
      95:             os.makedirs(args.outdir, exist_ok=True)
      96:         os.environ["MCGT_OUTDIR"] = args.outdir
      97: import matplotlib as mpl
      98:         mpl.rcParams["savefig.dpi"] = args.dpi
      99:         mpl.rcParams["savefig.format"] = args.format
     100:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter06/plot_fig05_delta_chi2_heatmap.py :: SyntaxError L107: unexpected indent
```text
     101: 
     102: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     103: 
     104: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     105: 
     106: args = parser.parse_args()
>>   107:         try:
     108:             os.makedirs(args.outdir, exist_ok=True)
     109:         os.environ["MCGT_OUTDIR"] = args.outdir
     110: import matplotlib as mpl
     111:         mpl.rcParams["savefig.dpi"] = args.dpi
     112:         mpl.rcParams["savefig.format"] = args.format
     113:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter07/generate_data_chapter07.py :: SyntaxError L7: invalid character '²' (U+00B2)
```text
       1: #!/usr/bin/env python3
       2: """(auto-wrapped header)
       3: # ruff: noqa: E402
       4: """
       5: generate_data_chapter07.py
       6: 
>>     7: Génération du scan brut c_s²(k,a) et δφ/φ(k,a) pour le Chapitre 7 - Perturbations scalaires MCGT.
       8: Version francisée : noms d'arguments et fichiers en français (identique en logique).
       9: """
      10: 
      11: """
      12: import argparse
      13: import configparser
```

## zz-scripts/chapter07/plot_fig01_cs2_heatmap.py :: SyntaxError L150: unexpected indent
```text
     144: 
     145: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     146: 
     147: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     148: 
     149: args = parser.parse_args()
>>   150:         try:
     151:             os.makedirs(args.outdir, exist_ok=True)
     152:         os.environ["MCGT_OUTDIR"] = args.outdir
     153: import matplotlib as mpl
     154:         mpl.rcParams["savefig.dpi"] = args.dpi
     155:         mpl.rcParams["savefig.format"] = args.format
     156:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter07/plot_fig02_delta_phi_heatmap.py :: SyntaxError L156: unexpected indent
```text
     150: 
     151: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     152: 
     153: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     154: 
     155: args = parser.parse_args()
>>   156:         try:
     157:             os.makedirs(args.outdir, exist_ok=True)
     158:         os.environ["MCGT_OUTDIR"] = args.outdir
     159: import matplotlib as mpl
     160:         mpl.rcParams["savefig.dpi"] = args.dpi
     161:         mpl.rcParams["savefig.format"] = args.format
     162:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter07/plot_fig03_invariant_I1.py :: SyntaxError L116: unexpected indent
```text
     110: 
     111: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     112: 
     113: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     114: 
     115: args = parser.parse_args()
>>   116:         try:
     117:             os.makedirs(args.outdir, exist_ok=True)
     118:         os.environ["MCGT_OUTDIR"] = args.outdir
     119: import matplotlib as mpl
     120:         mpl.rcParams["savefig.dpi"] = args.dpi
     121:         mpl.rcParams["savefig.format"] = args.format
     122:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter07/plot_fig04_dcs2_vs_k.py :: SyntaxError L141: unexpected indent
```text
     135: 
     136: parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosité cumulable")
     137: 
     138: args = parser.parse_args(argv)
     139: 
     140:     # Logging level
>>   141:     if args.verbose >= 2:
     142:         logging.getLogger().setLevel(logging.DEBUG)
     143:     elif args.verbose == 1:
     144:         logging.getLogger().setLevel(logging.INFO)
     145:     else:
     146:         logging.getLogger().setLevel(logging.WARNING)
     147: 
```

## zz-scripts/chapter07/plot_fig05_ddelta_phi_vs_k.py :: SyntaxError L124: unexpected indent
```text
     118: 
     119: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     120: 
     121: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     122: 
     123: args = parser.parse_args()
>>   124:         try:
     125:             os.makedirs(args.outdir, exist_ok=True)
     126:         os.environ["MCGT_OUTDIR"] = args.outdir
     127: import matplotlib as mpl
     128:         mpl.rcParams["savefig.dpi"] = args.dpi
     129:         mpl.rcParams["savefig.format"] = args.format
     130:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter07/plot_fig06_comparison.py :: SyntaxError L98: unexpected indent
```text
      92: ax.axvline(k_split, ls="--", color="k", lw=1)
      93: zoom_plateau(ax, k2, np.abs(dcs2))
      94: ax.set_ylabel(r"$|\partial_k c_s^2|$", fontsize=10)
      95: ax.legend(loc="upper right", fontsize=8, framealpha=0.8)
      96: ax.grid(True, which="both", ls=":", linewidth=0.5)
      97: 
>>    98:     if args.out:
      99:         fig.savefig(args.out, dpi=args.dpi)
     100:         print(f"Wrote: {args.out}")
     101:     else:
     102:         # Pas de show() en mode homogénéisation/CI
     103:         print("No --out provided; stub generated but not saved.")
     104: 
```

## zz-scripts/chapter08/generate_coupling_milestones.py :: SyntaxError L67: unexpected indent
```text
      61: 
      62: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      63: 
      64: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      65: 
      66: args = parser.parse_args()
>>    67:         try:
      68:             os.makedirs(args.outdir, exist_ok=True)
      69:         os.environ["MCGT_OUTDIR"] = args.outdir
      70: import matplotlib as mpl
      71:         mpl.rcParams["savefig.dpi"] = args.dpi
      72:         mpl.rcParams["savefig.format"] = args.format
      73:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter08/plot_fig03_mu_vs_z.py :: SyntaxError L90: unexpected indent
```text
      84: 
      85: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
      86: 
      87: parser.add_argument("--transparent", action="store_true", help="Transparent background")
      88: 
      89: args = parser.parse_args()
>>    90:         try:
      91:             os.makedirs(args.outdir, exist_ok=True)
      92:         os.environ["MCGT_OUTDIR"] = args.outdir
      93: import matplotlib as mpl
      94:         mpl.rcParams["savefig.dpi"] = args.dpi
      95:         mpl.rcParams["savefig.format"] = args.format
      96:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter08/plot_fig04_chi2_heatmap.py :: SyntaxError L128: unexpected indent
```text
     122: 
     123: parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
     124: 
     125: parser.add_argument("--transparent", action="store_true", help="Transparent background")
     126: 
     127: args = parser.parse_args()
>>   128:         try:
     129:             os.makedirs(args.outdir, exist_ok=True)
     130:         os.environ["MCGT_OUTDIR"] = args.outdir
     131: import matplotlib as mpl
     132:         mpl.rcParams["savefig.dpi"] = args.dpi
     133:         mpl.rcParams["savefig.format"] = args.format
     134:         mpl.rcParams["savefig.transparent"] = args.transparent
```

## zz-scripts/chapter09/check_p95_methods.py :: SyntaxError L8: invalid decimal literal
```text
       2: """(auto-wrapped header)
       3: # check_p95_methods.py
       4: """
       5: Compare p95 (et autres stats) pour trois traitements du résidu de phase:
       6:   - raw:    abs(phi_mcgt - phi_ref)
       7:   - unwrap: abs( unwrap(phi_mcgt - phi_ref) )
>>     8:   - rebranch: alignement par k cycles entières: phi_mcgt - k*2pi
       9: 
      10: Usage (exemple):
      11: python zz-scripts/chapter09/check_p95_methods.py \
      12:   --csv zz-data/chapter09/09_phases_mcgt.csv \
      13:   --window 20 300 \
      14:   --bins 30 50 80 \
```

## zz-scripts/chapter09/generate_mcgt_raw_phase.py :: SyntaxError L133: unexpected indent
```text
     127:         choices=["DEBUG", "INFO", "WARNING", "ERROR"],
     128:         default="INFO",
     129:         help="Niveau de verbosité",
     130:     )
     131: 
     132: parser.add_argument("--log-file", type=Path, help="Chemin vers un fichier de log")
>>   133:     return parser.parse_args()
     134: 
     135: 
     136: def setup_logger(level: str, logfile: Path = None):
     137:     handlers = [logging.StreamHandler()]
     138:     if logfile:
     139:         handlers.append(logging.FileHandler(logfile, encoding="utf-8"))
```

## zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py :: SyntaxError L98: expected an indented block after function definition on line 97
```text
      92:     return p.parse_args()
      93: 
      94: 
      95: # -------- Main
      96: 
      97: def main():
>>    98: args = parse_args()
      99: log = setup_logger(args.log_level)
     100: 
     101:     # --- Charger données
     102: data_label = None,
     103: f = None,
     104: abs_dphi = None,
```

## zz-scripts/chapter09/plot_fig04_absdphi_milestones_vs_f.py :: SyntaxError L79: expected an indented block after function definition on line 78
```text
      73:     low = np.clip(np.minimum(s, y - eps), 0.0, None)
      74:     high = np.copy(s)
      75:     return np.vstack([low, high])
      76: 
      77: 
      78: def _auto_xlim(f_all: np.ndarray, xmin_hint: float = 10.0):
>>    79: f = np.asarray(f_all, float)
      80: f = f[np.isfinite(f) & (f > 0)]
      81: if f.size ==== 0:
      82:     pass
      83: return xmin_hint, 2000.0
      84: lo = float(np.min(f)) / (10**0.05)
      85: hi = float(np.max(f)) * (10**0.05)
```

## zz-scripts/chapter09/plot_fig05_scatter_phi_at_fpeak.py :: SyntaxError L81: unmatched ')'
```text
      75: parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
      76: 
      77: parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
      78: 
      79: parser.add_argument('--verbose', action='store_true', help='Verbosity CLI')
      80: args = ap.parse_args()
>>    81: description="Fig.05 - φ_ref vs φ_MCGT aux f_peak (±σ)")
      82: return apap.add_argument(
      83: # "--outdir",
      84: # MCGT(fixed): type=str,
      85: 
      86: 
      87: def class_color_map() -> dict[str, str]:
```

## zz-scripts/chapter10/add_phi_at_fpeak.py :: SyntaxError L89: unexpected indent
```text
      83:     logging.getLogger().addHandler(logging.StreamHandler())
      84: 
      85:     # read files
      86:     df = pd.read_csv(args.results)
      87: df = ci.ensure_fig02_cols(df)
      88: 
>>    89:     if args.backup:
      90:         bak = args.results + ".bak"
      91:         if not os.path.exists(bak):
      92:             shutil.copy2(args.results, bak)
      93:             logging.info(f"Backup written: {bak}")
      94: 
      95:     # read reference grid
```

## zz-scripts/chapter10/check_metrics_consistency.py :: SyntaxError L82: unexpected indent
```text
      76: 
      77:     logger.info("Chargement results: %s", results_p)
      78:     df = pd.read_csv(results_p)
      79: df = ci.ensure_fig02_cols(df)
      80: 
      81:     # normalisation noms colonnes courants (tolérance)
>>    82:     _df_cols = {c: c for c in df.columns}
      83:     # required metrics expected
      84:     required_cols = [
      85:         "id",
      86:         "p95_20_300",
      87:         "mean_20_300",
      88:         "max_20_300",
```

## zz-scripts/chapter10/diag_phi_fpeak.py :: SyntaxError L66: unexpected indent
```text
      60:     )
      61:     args = p.parse_args()
      62: 
      63:     df = pd.read_csv(args.results)
      64: df = ci.ensure_fig02_cols(df)
      65: 
>>    66:     f_ref = np.loadtxt(args.ref_grid, delimiter=",", skiprows=1, usecols=[0])
      67:     # ensure sorted and finite
      68:     f_ref = np.asarray(f_ref)
      69:     f_ref = f_ref[np.isfinite(f_ref)]
      70:     if f_ref.size < 2:
      71:         raise SystemExit("La grille de référence contient <2 points après nettoyage.")
      72: 
```

## zz-scripts/chapter10/generate_data_chapter10.py :: SyntaxError L333: unexpected indent
```text
     327:     Boîte englobante du top-K sur {m1,m2,q0star,alpha}, resserrée par facteur 'shrink'.
     328:     Stratégie : on prend [min,max] sur le top-K, on recentre à la médiane, et
     329:     on réduit la demi-largeur -> demi_largeur/shrink.
     330:     """
     331: import numpy as np
     332: 
>>   333:     keys = ["m1", "m2", "q0star", "alpha"]
     334:     out = {}
     335:     for k in keys:
     336:         vals = np.array([float(t[k]) for t in topk if k in t], dtype=float)
     337:         vmin, vmax = float(vals.min()), float(vals.max())
     338:         vmed = float(np.median(vals))
     339:         half = (vmax - vmin) / 2.0
```

## zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py :: SyntaxError L27: expected 'except' or 'finally' block
```text
      21: 
      22: from zz_tools import common_io as ci
      23: 
      24: # import fonctions existantes
      25: try:
      26:     from mcgt.backends.ref_phase import compute_phi_ref
>>    27: from mcgt.phase import phi_mcgt
      28: except Exception as e:
      29:     raise SystemExit(f"Erreur import mcgt : {e}")
      30: 
      31: 
      32: def circ_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
      33:     """Distance angulaire minimale a-b renvoyée dans [-pi,pi]."""
```

## zz-scripts/chapter10/recompute_p95_circular.py :: SyntaxError L49: unexpected indent
```text
      43: parser.add_argument("--ref-grid", required=True)
      44: 
      45: parser.add_argument("--out", default=None)
      46: 
      47: args = parser.parse_args( argv)
      48: 
>>    49:     df_res = pd.read_csv(args.results)
      50:     df_samp = pd.read_csv(args.samples)
      51:     fgrid = np.loadtxt(args.ref_grid, delimiter=",", skiprows=1, usecols=[0])
      52: 
      53: mask = ( fgrid >= 20.0) & ( fgrid <= 300.0)
      54: 
      55:     # prepare output df copy
```

## zz-scripts/chapter10/regen_fig05_using_circp95.py :: SyntaxError L83: unexpected indent
```text
      77:     args = ap.parse_args()
      78: 
      79:     # --- lecture & colonne p95 ---
      80:     df = pd.read_csv(args.results)
      81: df = ci.ensure_fig02_cols(df)
      82: 
>>    83:     p95_col = detect_p95_column(df)
      84:     p95 = df[p95_col].dropna().astype(float).values
      85: 
      86:     # Heuristique : si colonne "originale" dispo, compter les corrections unwrap
      87:     wrapped_corrected = None
      88:     for cand in ("p95_20_300", "p95_raw", "p95_orig", "p95_20_300_raw"):
      89:         if cand in df.columns and cand != p95_col:
```
