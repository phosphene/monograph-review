# Pre-Foundry Scripts (Archived)

These are the original scattered R scripts that were refactored into
the valence.foundry R package. They are preserved here for historical reference.

## Migration Map

| Original Script | Foundry Function | Phase |
|----------------|------------------|-------|
| 01_orobanchaceae_pgls.R | R/empirical_tests.R::pgls_orobanchaceae() | 2 |
| 02_cross_family_pgls.R | R/empirical_tests.R::pgls_cross_family() | 2 |
| 03_endosymbiont_models.R | R/empirical_tests.R::endosymbiont_biphasic() | 2 |
| 04_bobay_ochman.R | R/empirical_tests.R::niche_vs_ne() | 2 |
| 05_dewar_pangenome.R | R/empirical_tests.R::pangenome_fluidity() | 2 |
| 06_gene_category_ordering.R | R/empirical_tests.R::gene_loss_ordering() | 2 |
| 07_ltee_function_loss.R | R/empirical_tests.R::ltee_cosegregation() | 2 |
| run_formal_model.R | R/formal_model.R::threshold_model() | 3 |
| run_cross_kingdom_L3.R | R/cross_kingdom_transfer.R::transfer_test() | 3 |
| run_all_section12.R | (integration test, not a function) | — |
| buchnera-reanalysis.R | (merged into endosymbiont_biphasic) | 2 |
| interaction-reanalysis.R | (merged into gene_loss_ordering) | 2 |
| r-enhancements.R | (merged into empirical_tests) | 2 |
| r-deliberative.R | (merged into empirical_tests) | 2 |
| fcar_probe.R | (exploratory, not migrated) | — |
| fcar_probe2.R | (exploratory, not migrated) | — |

## Economics scripts (Phase 6)
| paper1_option_destruction.R | R/economics.R::option_destruction() | 6 |
| paper2_stochastic_cdi.R | R/economics.R::stochastic_cdi() | 6 |
| paper3_integration_depth.R | R/economics.R::cdi_economics() | 6 |
| paper4_threshold_disruption.R | R/economics.R::threshold_disruption() | 6 |

## Note
The duplicate directory tools/vi-testing/R-reproducibility/ contained
identical copies (verified by md5sum) of vi-quantitative-package/ scripts.
It can be safely removed from the workspace.
