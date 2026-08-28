# T2 Redesigned — Cross-Family Gene-Loss Ordering

## Design

**Original T2 (non-discriminating):** Does the plastome-size-vs-parasitism gradient replicate across 9 independent origins? Everyone predicts this — relaxed selection, neutral evolution, niche construction all predict smaller genomes in more dependent lineages.

**Redesigned T2:** Does the same dependency ranking predict gene-loss ORDER across independent parasitic lineages? If VI is correct, the ordering should be consistent across families — ndh lost first, then rpo, then psa/psb, then atp, then rpl/rps. Relaxed selection has no reason to predict the same ordering across lineages with different evolutionary histories.

## Data Needed

Current cross-family data (`data/cross_family_plastome_data.tsv`) has 92 species across 14 families but only genome-level data (plastome_bp + parasitism_level). No gene categories.

### To build cross-family gene retention matrices:

For each of the 14 families, we need:
1. **Download reference plastome** from NCBI GenBank for each species
2. **Annotate gene categories** from the GenBank file:
   - ndh (NADH dehydrogenase) — dep=0
   - rpo (RNA polymerase) — dep=1
   - psa (photosystem I) — dep=1
   - psb (photosystem II) — dep=2
   - atp (ATP synthase) — dep=3
   - rpl/rps (ribosomal proteins) — dep=5
3. **Score presence/absence** for each gene category
4. **Compute Spearman ρ** between dep rank and retention rank within each family
5. **Test whether ρ values are consistently positive** across families (Stouffer's or sign test)

### Best families for the test (independent parasitic origins):

| Family | Species count | Parasitism range | NCBI plastomes |
|--------|--------------|-----------------|----------------|
| Balanophoraceae | 21 | Holoparasite | Several available |
| Loranthaceae | 19 | Hemiparasite-Holoparasite | Available |
| Santalaceae | 16 | Root hemiparasite | Available |
| Viscaceae | 10 | Aerial hemiparasite | Available |
| Hydnoraceae | 9 | Holoparasite | Available |
| Rafflesiaceae | 3 | Holoparasite | Available |
| Krameriaceae | 3 | Root hemiparasite | Available |
| Lennoaceae | 2 | Holoparasite | Available |
| Apodanthaceae | 2 | Holoparasite | Available |

### Data acquisition approach:

1. Query NCBI Entrez for plastome records in each family
2. Download GenBank files (`.gb` format)
3. Parse gene annotations with Biopython's `SeqIO`
4. Classify each gene into category (ndh/rpo/psa/psb/atp/rpl/rps)
5. Build retention matrix: species × gene_category → present(1)/absent(0)
6. Compute dep score × retention correlation per family

### Estimated effort:
- ~2-3 hours for data download and parsing
- ~1 hour for retention matrix construction
- ~30 min for statistical analysis
- Total: ~4-5 hours of automated work

### Alternative approach (faster but less precise):
Use plastome SIZE as a proxy for gene retention within each family. If we can't get gene-level annotations for all families, we can at least test whether the dep-retention relationship holds at the genome level across families — but this would be a weaker test, closer to the original T2.

## Status

**NOT YET STARTED.** Data acquisition needed. All 14 families have species in the existing cross-family dataset; NCBI plastome availability needs to be checked per family.
