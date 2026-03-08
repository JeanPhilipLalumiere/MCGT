import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot

with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_combined_res.pkl', 'rb') as f:
    res = pickle.load(f)

labels = [r'$H_0$', r'$\Omega_m$', r'$w_0$', r'$w_a$']
fig, axes = dyplot.cornerplot(res, color='forestgreen', labels=labels,
                              truths=[67.4, 0.315, -1.0, 0.0], truth_color='red',
                              show_titles=True, title_fmt='.3f')

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_combined_real.png')
print("✅ Image sauvegardée : corner_combined_real.png")
