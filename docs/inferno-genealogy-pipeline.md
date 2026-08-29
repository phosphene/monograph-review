---
uri: valence-foundry/inferno-genealogy-pipeline
title: INFERNO Labs Genealogy Pipeline — Design Document
author: The Foundry Engineering
status: design
version: 1.0.0
updated: 2026-08-18
---

# INFERNO Labs Genealogy Pipeline — Design Document

> **T15:** Transposition of the framework genealogy chain into a registered, versioned, DOI-trackable pipeline under the INFERNO Labs framework.

## Table of Contents

1. [Overview](#1-overview)
2. [Registration Schema](#2-registration-schema)
3. [Provenance Chain Specification](#3-provenance-chain-specification)
4. [DOI / Zenodo Workflow](#4-doi--zenodo-workflow)
5. [One-Command Reproduction Script](#5-one-command-reproduction-script)
6. [Integration with INFERNO Labs Infrastructure](#6-integration-with-inferno-labs-infrastructure)
7. [Security: Signed Manifests & Tamper-Evident Hashes](#7-security-signed-manifests--tamper-evident-hashes)
8. [Implementation Roadmap](#8-implementation-roadmap)
9. [References](#9-references)

---

## 1. Overview

### 1.1 What This Is

The relaxation formula `dρ/dt = −k₁(ρ − ρ₁) − k₂(ρ − ρ₂)` is the endpoint of a formal chain spanning four stages:

| Stage | Name | Domain | Code | Status |
|-------|------|--------|------|--------|
| 1 | Ising Model (Metropolis MC) | Statistical physics | `generate_ising.py` | Active |
| 2 | Landau Mean-Field Free Energy | Phase transitions | `generate_landau.py` | Active |
| 3 | Thom Cusp Catastrophe | Catastrophe theory | `generate_cusp.py` | Active |
| 4 | Drift-Selection Boundary | Population genetics | `generate_drift_selection.py` | Archived (falsified) |
| 5 | Percolation Threshold | Network theory | (via R, not ported) | Archived (falsified) |
| 6 | Relaxation Formula (Bi-Exp ODE) | Relaxation dynamics | `generate_relaxation.py` | Active |

Currently these are standalone scripts. This design transposes them into a **registered pipeline** where each stage is a versioned, DOI-trackable artifact with explicit provenance linking.

### 1.2 Design Goals

1. **Registration:** Every stage carries a machine-readable manifest with seed, parameters, runtime environment, code hash, and output hash.
2. **Provenance:** The output of stage N is cryptographically linked as input to stage N+1.
3. **DOI-trackable:** Each stage and the full pipeline can be archived on Zenodo with a resolvable DOI.
4. **Reproducible:** One command runs the entire chain from Ising through relaxation, verifying every hash.
5. **Integrable:** The pipeline feeds into INFERNO Labs' existing WCI scoring and falsifiability tracking.
6. **Secure:** Manifests are signed, hashes are tamper-evident, and the chain is verifiable offline.

### 1.3 Scope

This document specifies the **design** of the pipeline infrastructure. It does not implement the registry backend, the Zenodo deposit automation, or the reproduction runner — those are downstream implementation tasks. What it provides is the schema, the protocol, the workflows, and the integration points that any implementation must satisfy.

---

## 2. Registration Schema

### 2.1 Stage Manifest Schema

Every genealogy stage produces a `stage_manifest.json` alongside its output data. The manifest is the machine-readable identity document for that stage's run.

```json
{
  "schema_version": "1.0.0",
  "stage": {
    "index": 1,
    "name": "ising",
    "title": "Ising Model Simulation — Metropolis Monte Carlo",
    "version": "1.0.0"
  },
  "run": {
    "id": "genealogy-ising-20260818-001",
    "timestamp": "2026-08-18T14:00:00Z",
    "seed": 42,
    "runtime": {
      "executable": "python3",
      "version": "3.12.5",
      "dependencies": {
        "numpy": "1.26.4",
        "scipy": "1.13.1"
      },
      "platform": "Linux-6.1.168-x86_64"
    }
  },
  "parameters": {
    "L": 16,
    "J": 1.0,
    "h": 0.0,
    "n_sweeps": 1000,
    "n_temps": 20,
    "T_range": [1.0, 4.0]
  },
  "hashes": {
    "code_sha256": "a1b2c3d4e5f6...",
    "input_sha256": null,
    "output_sha256": "f6e5d4c3b2a1...",
    "manifest_sha256": "9e8d7c6b5a4f..."
  },
  "provenance": {
    "parent_stage": null,
    "parent_run_id": null,
    "child_stage": "landau",
    "chain_position": 1
  },
  "outputs": {
    "primary": "results/genealogy-ising-results.json",
    "format": "json",
    "size_bytes": 18432,
    "n_data_points": 20
  },
  "verification": {
    "deterministic": true,
    "reproduced_at": null,
    "reproduced_by": null,
    "passed_validation": true
  },
  "signature": {
    "method": "ed25519",
    "public_key_fingerprint": "sha256:...",
    "signature_hex": "..."
  }
}
```

### 2.2 Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `schema_version` | string | yes | Version of the manifest schema (semver) |
| `stage.index` | integer | yes | Position in the genealogy chain (1–6) |
| `stage.name` | string | yes | Machine-readable stage identifier |
| `stage.title` | string | yes | Human-readable stage name |
| `stage.version` | string | yes | Semver of the stage code (not the run) |
| `run.id` | string | yes | Unique run identifier: `{stage}-{date}-{seq}` |
| `run.timestamp` | string | yes | ISO 8601 UTC timestamp of run start |
| `run.seed` | integer | yes | Random seed for deterministic output |
| `run.runtime.executable` | string | yes | Interpreter or binary used |
| `run.runtime.version` | string | yes | Runtime version |
| `run.runtime.dependencies` | object | yes | Map of package name → version |
| `run.runtime.platform` | string | yes | `uname -a` or equivalent platform string |
| `parameters` | object | yes | All stage-specific parameters |
| `hashes.code_sha256` | string | yes | SHA-256 of the source code file |
| `hashes.input_sha256` | string | * | SHA-256 of input data (null for stage 1) |
| `hashes.output_sha256` | string | yes | SHA-256 of the primary output file |
| `hashes.manifest_sha256` | string | yes | SHA-256 of this manifest (self-hash) |
| `provenance.parent_stage` | string | * | Previous stage name (null for stage 1) |
| `provenance.parent_run_id` | string | * | Previous run ID (null for stage 1) |
| `provenance.child_stage` | string | yes | Next stage name |
| `provenance.chain_position` | integer | yes | `1` = start, `N` = intermediate, `6` = end |
| `outputs.primary` | string | yes | Path to primary output data file |
| `outputs.format` | string | yes | File format (json, csv, hdf5, etc.) |
| `outputs.size_bytes` | integer | yes | File size in bytes |
| `outputs.n_data_points` | integer | * | Number of data points (if applicable) |
| `verification.deterministic` | boolean | yes | Whether output is fully deterministic |
| `verification.reproduced_at` | string | * | When the stage was last reproduced |
| `verification.reproduced_by` | string | * | Who/what reproduced the stage |
| `verification.passed_validation` | boolean | yes | Whether the stage passed self-validation |
| `signature.method` | string | yes | Signing method (e.g., `ed25519`, `pgp`) |
| `signature.public_key_fingerprint` | string | yes | Fingerprint of the signing key |
| `signature.signature_hex` | string | yes | Hex-encoded signature of the manifest |

### 2.3 Stage-Specific Parameter Schemas

Each stage has a fixed set of parameters that must be documented in its schema:

**Stage 1 — Ising Model:**
- `L` (int): Lattice linear size (default 16)
- `J` (float): Coupling constant (default 1.0)
- `h` (float): External field (default 0.0)
- `n_sweeps` (int): MC sweeps per temperature (default 1000)
- `n_temps` (int): Number of temperature points (default 20)
- `T_range` (list[float]): Temperature range `[T_min, T_max]` (default `[1.0, 4.0]`)

**Stage 2 — Landau Free Energy:**
- `n_points` (int): Number of `a` values (default 100)
- `a_range` (list[float]): `[a_min, a_max]` (default `[-1.0, 1.0]`)
- `b` (float): Quartic coefficient (default 1.0)
- `h` (float): External field (default 0.0)

**Stage 3 — Cusp Catastrophe:**
- `n_a` (int): Number of `a` values in grid (default 50)
- `n_b` (int): Number of `b` values in grid (default 50)
- `a_range` (list[float]): `[a_min, a_max]` (default `[-2.0, 2.0]`)
- `b_range` (list[float]): `[b_min, b_max]` (default `[-2.0, 2.0]`)

**Stage 6 — Relaxation Formula:**
- `k1` (float): Fast rate constant (default 5.0)
- `k2` (float): Slow rate constant (default 0.3)
- `rho1` (float): Fast equilibrium (default 0.15)
- `rho2` (float): Slow equilibrium (default 0.05)
- `A1` (float): Fast amplitude (default 0.6)
- `A2` (float): Slow amplitude (default 0.25)
- `n_points` (int): Time points (default 50)
- `noise_std` (float): Noise standard deviation (default 0.02)

### 2.4 Archived Stage Schemas

Stages 4 and 5 are archived (falsified) but still registered. Their manifests include a `status: "archived"` field and a `falsification` object linking to the T2 results that falsified them.

**Stage 4 — Percolation:**
- `n_nodes` (int): Network size
- `p_edge` (float): Edge probability
- `theta` (float): Provision threshold
- `falsification_ref`: `inst/results/T2-percolation-results.json`

**Stage 5 — Drift-Selection:**
- `N` (int): Population size (default 100)
- `n_reps` (int): Replicates per δ (default 1000)
- `n_delta` (int): Number of δ values (default 20)
- `delta_range` (list[float]): `[δ_min, δ_max]` (default `[0.0, 0.1]`)
- `falsification_ref`: `inst/results/T2-rho-sat-results.json`

---

## 3. Provenance Chain Specification

### 3.1 Chain Topology

The genealogy chain is a **linear directed graph** (a strict pipeline) with a single branch point for archived stages:

```
Stage 1 (Ising) ──→ Stage 2 (Landau) ──→ Stage 3 (Cusp) ──→ Stage 6 (Relaxation)
                                                                      │
                                                                      ↓
                                                              INFERNO Labs
                                                              WCI / Falsifiability
                                                                      │
                                                                      ↓
                                                              Zenodo Archive
                                                                      │
                                                                      ↓
                                                              DOI Citation
```

Archived stages 4 and 5 are **dead ends** — they are registered but not part of the active chain. Their manifests link to the falsification evidence.

### 3.2 Provenance Linking Protocol

Each stage's output data becomes the **input metadata** for the next stage. The link is made through the manifest hashes:

**Stage N → Stage N+1 link:**

1. Stage N completes, producing `output.json` and `stage_N_manifest.json`.
2. `output_sha256` is computed from `output.json`.
3. Stage N+1 reads `stage_N_manifest.json` and stores the `output_sha256` as `input_sha256` in its own manifest.
4. Stage N+1 verifies the hash before computation begins.

**Implementation:**

```python
# Pseudocode for the linking protocol
class StageLink:
    def __init__(self, parent_manifest_path: str):
        self.parent = json.load(open(parent_manifest_path))
        self.parent_output_hash = self.parent["hashes"]["output_sha256"]
        
    def verify_input(self, input_data_path: str) -> bool:
        """Verify that the input data matches the parent's claimed output hash."""
        actual_hash = sha256_file(input_data_path)
        return actual_hash == self.parent_output_hash
    
    def create_manifest(self, stage_meta, params, output_path, code_path):
        """Create a child manifest with provenance linking."""
        manifest = {
            "schema_version": "1.0.0",
            "stage": stage_meta,
            "hashes": {
                "code_sha256": sha256_file(code_path),
                "input_sha256": self.parent_output_hash,
                "output_sha256": sha256_file(output_path),
                "manifest_sha256": None  # filled after serialization
            },
            "provenance": {
                "parent_stage": self.parent["stage"]["name"],
                "parent_run_id": self.parent["run"]["id"],
                "parent_output_hash": self.parent_output_hash,
                "child_stage": stage_meta["name"],
                "chain_position": stage_meta["index"]
            }
        }
        # Self-hash the manifest
        manifest["hashes"]["manifest_sha256"] = sha256_bytes(
            json.dumps(manifest, sort_keys=True).encode()
        )
        return manifest
```

### 3.3 Chain Integrity Verification

A chain-wide integrity check verifies that every link is valid:

```python
def verify_chain(manifests: list[dict]) -> bool:
    """Verify the entire provenance chain from stage 1 to stage N."""
    for i, manifest in enumerate(manifests):
        # Verify manifest self-integrity
        assert manifest["hashes"]["manifest_sha256"] == \
            sha256_bytes(json.dumps(manifest, sort_keys=True).encode())
        
        # Verify output hash
        assert sha256_file(manifest["outputs"]["primary"]) == \
            manifest["hashes"]["output_sha256"]
        
        # Verify provenance link (except stage 1)
        if i > 0:
            assert manifest["hashes"]["input_sha256"] == \
                manifests[i-1]["hashes"]["output_sha256"]
            assert manifest["provenance"]["parent_run_id"] == \
                manifests[i-1]["run"]["id"]
    
    return True
```

### 3.4 Chain Extension

The chain is designed to be extended. A new stage (e.g., a stage 7 that fits the relaxation formula to real data) would:
1. Accept the relaxation formula output as input
2. Create a manifest with `provenance.parent_stage = "relaxation"`
3. Link its `input_sha256` to the relaxation stage's `output_sha256`

---

## 4. DOI / Zenodo Workflow

### 4.1 Workflow Overview

Each stage and the full pipeline gets a DOI via Zenodo, following the GitHub → Zenodo integration pattern:

```
GitHub Tag (v1.0.0) → GitHub Release → Zenodo Webhook → Zenodo Deposit → DOI
```

The workflow is:

1. **Tag the repository** with a stage-specific version: `ising-v1.0.0`, `landau-v1.0.0`, etc.
2. **Create a GitHub Release** from the tag, including the stage manifest and output data.
3. **Zenodo auto-deposits** via the `zenodo.json` metadata file in the repository root (Zenodo's GitHub integration).
4. **The DOI is minted** and linked to the release.
5. **The DOI is recorded** in the stage manifest as `zenodo_doi`.

### 4.2 Zenodo Metadata File

Each stage includes a `zenodo.json` file in its directory:

```json
{
  "creators": [
    {
      "name": "Ritch-Frel, Jan",
      "affiliation": "Observatory"
    },
    {
      "name": "Phillips, Ed",
      "affiliation": "Phosphene"
    }
  ],
  "title": "INFERNO Labs — Genealogy Stage 1: Ising Model Simulation",
  "description": "Metropolis Monte Carlo simulation of the 2D Ising model on a 16×16 lattice. Part of the relaxation formula genealogy chain: Ising → Landau → Cusp → Relaxation. Output: magnetization vs temperature for 20 temperature points. Seed: 42, deterministic.",
  "keywords": [
    "ising model",
    "metropolis monte carlo",
    "statistical physics",
    "the relaxation formula",
    "genealogy chain",
    "inferno labs"
  ],
  "license": "MIT",
  "upload_type": "software",
  "access_right": "open",
  "related_identifiers": [
    {
      "relation": "isPartOf",
      "identifier": "https://github.com/phosphene/valence-foundry"
    },
    {
      "relation": "isPreviousVersionOf",
      "identifier": "DOI:10.xxxx/zenodo.xxxxx"
    }
  ]
}
```

### 4.3 Full Pipeline DOI

In addition to per-stage DOIs, the full pipeline gets a **pipeline DOI** that aggregates all stages:

| DOI | Artifact | Granularity |
|-----|----------|-------------|
| `10.5281/zenodo.XXXXX` | Stage 1: Ising | Individual simulation |
| `10.5281/zenodo.XXXXX` | Stage 2: Landau | Individual computation |
| `10.5281/zenodo.XXXXX` | Stage 3: Cusp | Individual computation |
| `10.5281/zenodo.XXXXX` | Stage 6: Relaxation | Individual simulation |
| `10.5281/zenodo.XXXXX` | **Full pipeline** | Chain manifest + all stages |

The pipeline DOI is minted from a **meta-release** that packages all stages together with the chain manifest.

### 4.4 Versioning Strategy

| Version element | Scope | Example |
|----------------|-------|---------|
| Stage version | Semantic version of the stage code | `ising-v1.0.0` |
| Pipeline version | Semantic version of the chain topology | `pipeline-v1.0.0` |
| Run version | Date-based run identifier | `20260818-001` |

Version rules:
- **Major:** Breaking change to the mathematical model or stage interface
- **Minor:** New parameters, new output fields, non-breaking additions
- **Patch:** Bug fixes, documentation, parameter defaults

### 4.5 Citation Format

Each stage is citable individually. The recommended citation format:

```
Ritch-Frel, J. & Phillips, E. (2026). INFERNO Labs — Genealogy Stage 1: Ising 
Model Simulation (Version 1.0.0) [Software]. Zenodo. 
https://doi.org/10.5281/zenodo.XXXXX
```

The full pipeline citation:

```
Ritch-Frel, J. & Phillips, E. (2026). INFERNO Labs — Genealogy Pipeline: 
Ising → Landau → Cusp → Relaxation (Version 1.0.0) [Software]. Zenodo. 
https://doi.org/10.5281/zenodo.XXXXX
```

### 4.6 Archive Contents

When archived, each Zenodo deposit contains:
- `stage_manifest.json` — the stage manifest
- `generate_<stage>.py` — the source code
- `output.json` — the primary output data
- `zenodo.json` — the Zenodo metadata
- `README.md` — stage description and reproduction instructions
- `LICENSE` — MIT license

The pipeline deposit additionally contains:
- `pipeline_manifest.json` — the full chain manifest
- `chain_runner.py` — the one-command reproduction script
- `chain_verification.py` — the chain integrity verification script

---

## 5. One-Command Reproduction Script

### 5.1 Specification

The reproduction script, `chain_runner.py`, is the single entry point for executing the full genealogy chain. It must satisfy:

**Interface:**
```bash
python chain_runner.py [--stage N] [--seed N] [--output DIR] [--verify] [--archive]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--stage N` | all | Run only stage N (1, 2, 3, or 6) |
| `--seed N` | 42 | Override the global random seed |
| `--output DIR` | `./results` | Output directory for manifests and data |
| `--verify` | false | Verify chain integrity after execution |
| `--archive` | false | Generate Zenodo-ready archive tarball |
| `--falsified` | false | Include archived stages 4-5 (for reproduction of falsified results) |

### 5.2 Runner Architecture

```python
class ChainRunner:
    """Executes the full genealogy chain with provenance tracking."""
    
    def __init__(self, output_dir: str, seed: int = 42):
        self.output_dir = output_dir
        self.seed = seed
        self.manifests = []
        self.stages = {
            1: IsingStage,
            2: LandauStage,
            3: CuspStage,
            6: RelaxationStage,
        }
    
    def run_stage(self, index: int, parent_manifest: dict = None) -> dict:
        """Run a single stage and return its manifest."""
        stage_class = self.stages[index]
        stage = stage_class(seed=self.seed, parent=parent_manifest)
        manifest = stage.execute(output_dir=self.output_dir)
        self.manifests.append(manifest)
        return manifest
    
    def run_chain(self, stages: list[int] = [1, 2, 3, 6]) -> list[dict]:
        """Run the full chain from stage 1 through stage N."""
        parent = None
        for idx in stages:
            parent = self.run_stage(idx, parent_manifest=parent)
        return self.manifests
    
    def verify_chain(self) -> bool:
        """Verify all provenance links and output hashes."""
        return verify_chain(self.manifests)
    
    def create_archive(self) -> str:
        """Create a Zenodo-ready tarball of all manifests and outputs."""
        ...
```

### 5.3 Stage Base Class

Each stage extends a common base that handles manifest creation, hash computation, and provenance linking:

```python
class StageBase:
    """Base class for all genealogy stages."""
    
    STAGE_INDEX: int
    STAGE_NAME: str
    
    def __init__(self, seed: int, parent_manifest: dict = None):
        self.seed = seed
        self.parent_manifest = parent_manifest
        self.manifest = None
    
    def execute(self, output_dir: str) -> dict:
        """Execute the stage, produce output, return manifest."""
        self._validate_inputs()
        output = self._compute()
        self._write_output(output, output_dir)
        self._create_manifest(output_dir)
        self._sign_manifest()
        return self.manifest
    
    def _compute(self) -> dict:
        """Override in subclass. The actual computation."""
        raise NotImplementedError
    
    def _validate_inputs(self):
        """Verify parent output hash if this is not stage 1."""
        ...
    
    def _create_manifest(self, output_dir: str):
        """Build the stage manifest with provenance links."""
        ...
    
    def _sign_manifest(self):
        """Sign the manifest with the ED25519 key."""
        ...
```

### 5.4 Reproducibility Guarantees

The runner guarantees bitwise reproducibility when:

1. **Same seed** (default: 42)
2. **Same runtime version** (recorded in manifest)
3. **Same dependency versions** (recorded in manifest)
4. **Same platform** (recorded in manifest)

If any of these differ, the runner warns but does not block. The manifests record the differences for comparison.

### 5.5 Verification Mode

With `--verify`, the runner:
1. Runs the full chain
2. Computes all hashes
3. Verifies all provenance links
4. Compares output hashes against the canonical chain (if a reference manifest is available)
5. Reports pass/fail for each stage and the full chain

```bash
$ python chain_runner.py --verify
✓ Stage 1 (Ising): output hash matches reference
✓ Stage 2 (Landau): output hash matches reference
✓ Stage 3 (Cusp): output hash matches reference
✓ Stage 6 (Relaxation): output hash matches reference
✓ Chain integrity: all provenance links valid
✓ Full chain: PASS
```

---

## 6. Integration with INFERNO Labs Infrastructure

### 6.1 Existing INFERNO Labs Components

The INFERNO Labs framework already provides:

| Component | Location | Purpose |
|-----------|----------|---------|
| WCI Scoring | `docs/inferno-testing-plan.md` | 6-dimension scoring (0–100) for each prediction |
| Falsifiability Tracking | `docs/inferno-testing-plan.md` | 8 predictions (P1–P8) with explicit falsification criteria |
| Prediction Search Space | `docs/prediction-search-space.md` | Dataset requirements for each prediction |
| Simulacra Protocol | `docs/simulacra.md` | Synthetic data generation for prediction testing |
| WCI Standard | `TOOLS.md` | 0–100 scale, 6 dimensions, 3 tiers |

### 6.2 Pipeline → WCI Bridge

The genealogy pipeline integrates with INFERNO Labs WCI scoring through a **pipeline contribution metric**:

For each WCI dimension, the pipeline contributes evidence:

| WCI Dimension | Pipeline Contribution | Measurement |
|---------------|----------------------|-------------|
| **Theoretical coherence** (87) | The chain provides formal proofs from Ising → Landau → Cusp → Relaxation. Each link is a formal identity, not an analogy. | Score from `mathematical-genealogy.md` formal verification |
| **Empirical support** (72) | The relaxation simulation (stage 6) demonstrates that the formula passes AIC-based model comparison against mono-exp and linear nulls. | ΔAIC from stage 6 output |
| **Replicability** (73) | The one-command runner ensures bitwise reproducibility. Anyone can reproduce the chain. | Verified reproduction count |
| **Independent uptake** (28) | Zenodo DOIs enable independent citation and reuse. Each stage is independently citable. | DOI citation count |
| **Explanatory power** (88) | The chain explains why the formula has two channels (cusp bifurcation geometry) and why relaxation is gradient descent (Landau-Lifshitz). | Formal proof coverage |
| **Falsifiability** (82) | Explicit falsification criteria for stages 4–5; archived stages preserve the falsified results. | Archived stage count |

### 6.3 Pipeline → Falsifiability Tracking

The falsified stages (4, 5) are not discarded — they are **registered archives** with a specific link to the falsification evidence:

```json
{
  "stage": {
    "index": 5,
    "name": "drift_selection",
    "status": "archived"
  },
  "falsification": {
    "claim": "ρ_sat ≈ 0.35 is a universal constant",
    "tested_by": "T2 simulation campaign",
    "evidence": "inst/results/T2-rho-sat-results.json",
    "result": "ρ_sat varies from ~0.0 to ~0.99. Closest match: 0.247 (N=1000, δ=[0,0.05]).",
    "conclusion": "Not supported. ρ_sat is not universal."
  }
}
```

The pipeline's falsification arm integrates with the INFERNO Labs P1–P8 prediction framework:

| Prediction | Pipeline Stage | Evidence Level |
|-----------|----------------|----------------|
| P1 (Bi-exp kinetics) | Stage 6: Relaxation simulation | L1 — direct simulation |
| P2 (k₁ ≫ k₂) | Stage 6: Parameter recovery | L2 — ratio from ground truth |
| P3 (Integration-depth ordering) | External (not in pipeline) | L3 — cross-system analysis |
| P4 (Behavior before morphology) | External (not in pipeline) | L2 — dating analysis |
| P5 (Niche mismatch > Nₑ) | External (not in pipeline) | L2 — partial correlation |
| P6 (Substrate independence) | Stage 6 (extensible) | L2 — bi-exp on non-DNA |
| P7 (Sign reversal) | External (not in pipeline) | L2 — DD analysis |
| P8 (Irreversibility) | Archived stages 4–5 | L2 — falsified hypotheses |

### 6.4 Pipeline as INFERNO Labs Evidence Backend

The pipeline serves as the **computational evidence backend** for the INFERNO Labs framework:

1. **Simulacra feeds:** Stage 6 (relaxation simulation) generates data that tests the simulacra protocol (Simulacra 9–13).
2. **WCI updates:** Each stage run updates the WCI score for the relevant dimension.
3. **Falsifiability tracking:** Archived stages are registered with falsification evidence, preventing re-proposal of falsified claims.
4. **DOI citations:** Each stage's DOI is indexed in the INFERNO Labs citation registry.

### 6.5 INFERNO Labs Manifest Extension

The INFERNO Labs framework extends the stage manifest with additional fields:

```json
{
  "inferno_labs": {
    "wci_contribution": {
      "dimension": "theoretical_coherence",
      "current_score": 87,
      "contribution": "+1",
      "rationale": "Formal proof of Ising↔Landau identity"
    },
    "predictions_tested": ["P1", "P2"],
    "predictions_supported": ["P1", "P2"],
    "predictions_falsified": [],
    "simulacra_referenced": ["simulacrum_9", "simulacrum_10"],
    "evidence_level": "L1",
    "registration_id": "INFERNO-2026-001"
  }
}
```

---

## 7. Security: Signed Manifests & Tamper-Evident Hashes

### 7.1 Trust Model

The pipeline operates under a **reproducible trust** model:

- **Trust the code, not the author:** Anyone can verify the chain by re-running the reproduction script from source. If the output hashes match, the chain is trustworthy regardless of author identity.
- **Forge resistance:** Manifests are signed, preventing undetected tampering with claimed outputs.
- **Offline verifiability:** Chain integrity can be verified without network access, using only the manifest files.

### 7.2 Hash Chain

The pipeline uses a **hash chain** (not a Merkle tree, because the chain is linear):

```
Stage 1 manifest hash (self) ──→ Stage 1 output hash ──→ Stage 2 input hash
                                                                      │
                                                                      ↓
Stage 2 manifest hash (self) ──→ Stage 2 output hash ──→ Stage 3 input hash
                                                                      │
                                                                      ↓
                                                                    ...
```

Each manifest contains:
- `manifest_sha256`: SHA-256 of the manifest itself (preventing manifest tampering)
- `output_sha256`: SHA-256 of the output data (preventing data tampering)
- `input_sha256`: SHA-256 of the parent's output (preventing chain substitution)

### 7.3 Signing Protocol

Manifests are signed using **ED25519** keys:

```python
import ed25519  # or via cryptography library

class ManifestSigner:
    def __init__(self, private_key_path: str):
        with open(private_key_path, "rb") as f:
            self.private_key = ed25519.SigningKey(f.read())
        self.public_key_fingerprint = sha256(
            self.private_key.get_verifying_key().to_bytes()
        ).hexdigest()
    
    def sign(self, manifest: dict) -> dict:
        """Sign the manifest by signing the manifest_sha256."""
        manifest_bytes = json.dumps(manifest, sort_keys=True).encode()
        manifest["signature"] = {
            "method": "ed25519",
            "public_key_fingerprint": self.public_key_fingerprint[:16],
            "signature_hex": self.private_key.sign(manifest_bytes).hex()
        }
        return manifest
    
    def verify(self, manifest: dict, public_key_bytes: bytes) -> bool:
        """Verify a signed manifest."""
        verifying_key = ed25519.VerifyingKey(public_key_bytes)
        manifest_bytes = json.dumps(manifest, sort_keys=True).encode()
        signature = bytes.fromhex(manifest["signature"]["signature_hex"])
        try:
            verifying_key.verify(signature, manifest_bytes)
            return True
        except ed25519.BadSignatureError:
            return False
```

### 7.4 Key Management

| Key | Purpose | Storage | Rotation |
|-----|---------|---------|----------|
| Pipeline signing key (private) | Signing all stage manifests | Vault / encrypted file | Annual |
| Pipeline verification key (public) | Verification by anyone | GitHub repo, Zenodo deposit | Static |
| Developer signing keys | Pre-release verification | Individual developer machines | Per-developer |

The public key is distributed with the pipeline:
- In `keys/pipeline_verify.pub`
- In the Zenodo deposit metadata
- In the GitHub release notes

### 7.5 Tamper-Evident Chain

An attacker who modifies any stage's output will be detected because:

1. **Output hash mismatch:** The modified output's SHA-256 will not match the `output_sha256` in the manifest.
2. **Chain link break:** The next stage's `input_sha256` will not match the modified output.
3. **Signature verification:** The manifest signature will fail if the manifest is modified.
4. **Re-run verification:** Anyone can re-run the chain with `--verify` and compare hashes.

### 7.6 Security Considerations

| Threat | Mitigation |
|--------|------------|
| Manifest tampering | ED25519 signature on the manifest |
| Output data tampering | SHA-256 hash in manifest |
| Chain substitution | Input hash linked to parent output hash |
| Man-in-the-middle on Zenodo | Zenodo's HTTPS + SHA-256 verification |
| Private key compromise | Key rotation, multi-signature for critical releases |
| Determinism failure | Runtime fingerprint in manifest, verification failure detection |

---

## 8. Implementation Roadmap

### Phase 1: Manifest Infrastructure (estimated: 2 days)

- [ ] Create `chain_runner.py` base class with StageBase
- [ ] Implement manifest schema validation (Pydantic model)
- [ ] Implement SHA-256 hashing for all outputs
- [ ] Implement ED25519 signing (placeholder key for development)
- [ ] Write tests for manifest creation and verification

### Phase 2: Stage Registration (estimated: 2 days)

- [ ] Wrap each stage script in a StageBase subclass
- [ ] Add `input_sha256` verification to stages 2, 3, 6
- [ ] Add `zenodo.json` metadata to each stage directory
- [ ] Write tests for full chain execution

### Phase 3: Chain Runner (estimated: 1 day)

- [ ] Implement `chain_runner.py --stage`, `--seed`, `--output`, `--verify`, `--archive`
- [ ] Implement chain verification (`verify_chain`)
- [ ] Implement archive tarball creation (`--archive`)
- [ ] Write end-to-end test: run chain → verify → archive

### Phase 4: INFERNO Labs Integration (estimated: 1 day)

- [ ] Add `inferno_labs` extension to manifest schema
- [ ] Wire WCI contribution tracking into each stage
- [ ] Wire falsification tracking into archived stages 4–5
- [ ] Write integration test: pipeline → WCI bridge

### Phase 5: Zenodo / DOI (estimated: 1 day)

- [ ] Create GitHub release workflow for stage tags
- [ ] Configure Zenodo webhook for the repository
- [ ] Test DOI minting for a single stage
- [ ] Test DOI minting for the full pipeline

### Phase 6: Production Deployment (estimated: 1 day)

- [ ] Generate and distribute the pipeline signing key
- [ ] Sign all existing stage outputs
- [ ] Create the first pipeline release on GitHub
- [ ] Archive on Zenodo
- [ ] Update `ticket-queue.md` with T15 completion

---

## 9. References

| Reference | Location |
|-----------|----------|
| Mathematical genealogy (active chain) | `docs/mathematical-genealogy.md` |
| INFERNO testing plan (WCI, P1-P8) | `docs/inferno-testing-plan.md` |
| Prediction search space | `docs/prediction-search-space.md` |
| Stage 1: Ising model | `scripts/genealogy/generate_ising.py` |
| Stage 2: Landau free energy | `scripts/genealogy/generate_landau.py` |
| Stage 3: Cusp catastrophe | `scripts/genealogy/generate_cusp.py` |
| Stage 5 (archived): Drift-selection | `scripts/genealogy/generate_drift_selection.py` |
| Stage 6: Relaxation simulation | `inst/genealogy/generate_relaxation.py` |
| Ising results (reference) | `results/genealogy-ising-results.json` |
| Landau results (reference) | `results/genealogy-landau-results.json` |
| Cusp results (reference) | `results/genealogy-cusp-results.json` |
| Relaxation results (reference) | `results/genealogy-relaxation-results.json` |
| R package (original tests) | `R/`, `tests/testthat/` |
| Ticket queue | `docs/ticket-queue.md` |
| Pipeline manifest schema | `schemas/pipeline-manifest-schema.json` |
| Zenodo guide | https://developers.zenodo.org |
| WCI scoring standard | `TOOLS.md` (workspace root) |
| INFERNO Labs framework | `docs/inferno-testing-plan.md` |

---

## Appendix A: Pipeline Manifest Schema (JSON Schema)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "INFERNO Labs Genealogy Pipeline Manifest",
  "type": "object",
  "required": ["schema_version", "stage", "run", "parameters", "hashes", "provenance", "outputs", "verification"],
  "properties": {
    "schema_version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
    "stage": {
      "type": "object",
      "required": ["index", "name", "title", "version", "status"],
      "properties": {
        "index": {"type": "integer", "minimum": 1, "maximum": 6},
        "name": {"type": "string"},
        "title": {"type": "string"},
        "version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
        "status": {"type": "string", "enum": ["active", "archived"]}
      }
    },
    "run": {
      "type": "object",
      "required": ["id", "timestamp", "seed"],
      "properties": {
        "id": {"type": "string"},
        "timestamp": {"type": "string", "format": "date-time"},
        "seed": {"type": "integer"},
        "runtime": {
          "type": "object",
          "properties": {
            "executable": {"type": "string"},
            "version": {"type": "string"},
            "dependencies": {"type": "object"},
            "platform": {"type": "string"}
          }
        }
      }
    },
    "parameters": {"type": "object"},
    "hashes": {
      "type": "object",
      "required": ["code_sha256", "output_sha256", "manifest_sha256"],
      "properties": {
        "code_sha256": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
        "input_sha256": {"type": ["string", "null"], "pattern": "^[a-f0-9]{64}$|^null$"},
        "output_sha256": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
        "manifest_sha256": {"type": "string", "pattern": "^[a-f0-9]{64}$"}
      }
    },
    "provenance": {
      "type": "object",
      "required": ["parent_stage", "parent_run_id", "child_stage", "chain_position"],
      "properties": {
        "parent_stage": {"type": ["string", "null"]},
        "parent_run_id": {"type": ["string", "null"]},
        "parent_output_hash": {"type": ["string", "null"]},
        "child_stage": {"type": "string"},
        "chain_position": {"type": "integer", "minimum": 1, "maximum": 6}
      }
    },
    "outputs": {
      "type": "object",
      "required": ["primary", "format", "size_bytes"],
      "properties": {
        "primary": {"type": "string"},
        "format": {"type": "string"},
        "size_bytes": {"type": "integer"},
        "n_data_points": {"type": "integer"}
      }
    },
    "verification": {
      "type": "object",
      "required": ["deterministic", "passed_validation"],
      "properties": {
        "deterministic": {"type": "boolean"},
        "reproduced_at": {"type": ["string", "null"]},
        "reproduced_by": {"type": ["string", "null"]},
        "passed_validation": {"type": "boolean"}
      }
    },
    "signature": {
      "type": "object",
      "properties": {
        "method": {"type": "string", "enum": ["ed25519", "pgp"]},
        "public_key_fingerprint": {"type": "string"},
        "signature_hex": {"type": "string"}
      }
    },
    "inferno_labs": {
      "type": "object",
      "properties": {
        "wci_contribution": {"type": "object"},
        "predictions_tested": {"type": "array", "items": {"type": "string"}},
        "predictions_supported": {"type": "array", "items": {"type": "string"}},
        "predictions_falsified": {"type": "array", "items": {"type": "string"}},
        "simulacra_referenced": {"type": "array", "items": {"type": "string"}},
        "evidence_level": {"type": "string", "enum": ["L1", "L2", "L3", "L4"]},
        "registration_id": {"type": "string"}
      }
    },
    "falsification": {
      "type": "object",
      "properties": {
        "claim": {"type": "string"},
        "tested_by": {"type": "string"},
        "evidence": {"type": "string"},
        "result": {"type": "string"},
        "conclusion": {"type": "string"}
      }
    }
  }
}
```

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Stage** | A single computation in the genealogy chain (Ising, Landau, Cusp, Relaxation) |
| **Manifest** | The machine-readable identity document for a stage run |
| **Provenance** | The cryptographic link between consecutive stages (output hash N → input hash N+1) |
| **Chain** | The ordered sequence of stages forming the full pipeline |
| **Hash** | SHA-256 digest of a file or data structure |
| **Signature** | ED25519 digital signature of a manifest |
| **DOI** | Digital Object Identifier — a persistent identifier for a digital artifact |
| **Zenodo** | The open-access repository where the pipeline is archived |
| **WCI** | Weighted Confidence Index — the 0–100 scoring system for INFERNO Labs predictions |
| **Falsification** | The explicit documentation of a tested-and-failed hypothesis |
| **Chain runner** | The `chain_runner.py` script that executes the full pipeline |
| **Reproduction** | Re-running the chain from source code and verifying output hashes match |