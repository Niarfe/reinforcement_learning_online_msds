# CI Review: Automated Checks for Course Materials

Prepared as part of the annual UVA course review. This repository now runs a
GitHub Action on every push, on pull requests, and once a week. The workflow
calls the repository `makefile`, so every check can also be run locally with
the same command.

| Check | Command | Tool | What it catches |
|-------|---------|------|-----------------|
| Install | `make update` | pip + venv | Package conflicts, packages with no build for a Python version |
| Lint | `make lint` | [ruff](https://docs.astral.sh/ruff/) | Syntax errors and undefined names in notebooks |
| Spelling | `make spell` | [codespell](https://github.com/codespell-project/codespell) | Common misspellings in `.md`, `.txt`, `.ipynb` |
| Tests | `make test` | pytest | Each course package imports, CartPole runs and renders, all notebooks are valid |

The tests run on three Python versions:

* **3.12**: the Google Colab runtime, which is what the README tells students to use. This run must pass.
* **3.14**: the current stable Python. Informational only; a failure here does not fail the build.
* **3.15**: the next Python release. Informational only, to warn before students upgrade.

## Findings

### 1. TensorFlow cannot be installed on current Python (high impact)

We checked which Python versions each course package publishes Linux install
packages ("wheels") for:

| Package | Python 3.12 | Python 3.14 | Python 3.15 |
|---------|:-----------:|:-----------:|:-----------:|
| tensorflow | yes | **no** | **no** |
| torch | yes | yes | **no** |
| gymnasium, renderlab, numpy, ... | yes | yes | yes |

**What students should know if they set up their own environment instead of using Colab:**

* A student who installs the latest Python (3.14) and runs `pip install tensorflow` gets
  `No matching distribution found for tensorflow`. The notebooks that use Keras/TensorFlow
  (`05_deep_q_networks/deep_q_networks.ipynb`, `09_policy_gradients_extensions/ppo_cartpole.ipynb`)
  will not run.
* **Recommendation:** use Google Colab, or create the environment with Python 3.12:
  `python3.12 -m venv env`.
* PyTorch will have the same problem on Python 3.15. The weekly CI run will show
  when upstream support arrives.

### 2. The repository had no dependency list

There was no `requirements.txt`. Students only found out what to install from
`!pip install` lines spread across notebooks. We added `requirements.txt`, built
from every `import` in the notebooks, so `make update` creates a working
environment in one step.

### 3. Spelling

codespell reports misspellings in notebook text. Examples:

* `01_rl_fundamentals/ungraded_rl_exercises1.ipynb`: "devation" (deviation)
* `02_k_armed_bandit_and_mdp_intro/k_armed_bandit.ipynb`: "exploition" (exploitation)

These are left in place on purpose so the instructor can review them; the CI
spelling job will stay red until they are fixed.

### 4. Lint is clean

No syntax errors or undefined names in any notebook. The lint rules are kept
narrow on purpose, so the blanks students fill in do not trigger failures.

## Next Steps

Each of these is a small addition to the same `makefile` and workflow:

1. **Lunar Lander dependency.** `07_deep_q_networks_extensions2/lab_dueling_q_network.ipynb`
   needs `gymnasium[box2d]`, which often needs a C toolchain (`swig`) to build.
   Add it to CI to find out early whether students will hit build errors.
2. **Pin a known-good environment.** Once Python 3.12 passes, freeze exact versions
   (`pip freeze > requirements.lock`) so every semester starts from a setup that
   is known to work. Keep the unpinned weekly run to see upcoming breakage.
3. **Run demo notebooks end to end** with `nbmake` / `nbclient`, for the short
   demos that don't train models for minutes. This catches API changes such as
   gym → gymnasium or Keras 2 → 3 that importing alone can't catch.
4. **Link checking** (e.g. `lychee`) on `reading.md` files. They are mostly links
   to papers and external resources, which break quietly over time.
5. **Strip notebook outputs** (`nbstripout --verify`) so the repository stays small
   and diffs show content changes rather than regenerated images.
6. **Course-specific word list** for codespell, so RL terms don't produce false positives
   as the spelling checks cover more files.
7. **Reuse across courses.** The workflow only calls `make`, so the same
   `ci.yml` can go into other course repos without changes, giving every course
   in the review the same checks.
