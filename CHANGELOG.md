# Changelog

## 3.1.0 (2026-02-25)
- Release Majeure : Intégration du solveur ODE pour la croissance des structures linéaires et ajout de la fonction de vraisemblance RSD. Résolution simultanée confirmée pour les tensions H_0 et S_8.
- Contraintes MCMC consolidées : $\Omega_m = 0.243 \pm 0.007$, $H_0 = 72.97^{+0.32}_{-0.30}$ km/s/Mpc, $w_0 = -0.69 \pm 0.05$, $w_a = -2.81^{+0.29}_{-0.14}$, $S_8 = 0.718 \pm 0.030$.

## 2.7.2 (2026-02-24)
- v2.7.2 : Intégration complète de l'échantillonneur MCMC (emcee) et génération automatisée du Corner Plot de qualité publication. Validation de la convergence du modèle démontrant la résolution de la tension de Hubble et la dynamique de l'énergie sombre (w_0, w_a).
- Inclusion du Corner Plot MCMC directement dans le manuscrit PDF.
- Bump des références de version vers v2.7.2 dans le code, le README et le manuscrit.

## 2.6.0 (2025-12-22)
- Update version references across manuscript and project metadata.

## 0.2.64
- Packaging: sanitizer stable (wheel+sdist), sonde PyPI + smoke-install plus robustes.
- Script `tools/release.sh`: logs, garde-fou, retries CDN, fenêtre bloquée en fin.

## 0.2.63
- Corrections sanitizer sdist (écriture temp + replace atomique).

## 0.2.60–0.2.62
- Itérations publication, fiabilisation pipeline (build, checks, probes, smoke).

## 0.2.55–0.2.59
- Expo `__version__`, compat méta PEP639 nettoyée, stabilisation packaging.

## 0.2.65
- Upload Twine rétabli (token correct), publication OK.
- Probes JSON + /simple et smoke install : OK.

## 0.2.66
- Publication OK ; probes `/simple` + smoke install stables.
- Pipeline release: stabilité et latences PyPI mieux gérées.

## 0.2.67
- Publication OK ; latence `/simple` observée (CDN). Probe + smoke: OK dès visibilité.

## 0.2.67
- Publication OK ; latence `/simple` observée (CDN). Probe + smoke: OK dès visibilité.

## 0.2.67
- Publication OK ; latence `/simple` observée (CDN). Probe + smoke: OK dès visibilité.

## 0.2.69
- Publication OK ; probe `/simple` validée ; smoke-install no-cache OK.

## 0.2.69
- Publication OK ; probe `/simple` validée ; smoke-install no-cache OK.

## 0.2.69
- Publication OK ; probe `/simple` validée ; smoke-install no-cache OK.

## 0.2.70
- Publication OK ; probe `/simple` + smoke-install no-cache OK.

## 0.2.71
- Publication OK ; probe `/simple` et smoke isolée validées.
