# Archive technique `_attic/` - LAVA_Virus-Interface

**AVERTISSEMENT : Rien dans ce repertoire n'est autoritatif. Aucun fichier de `_attic/` ne doit etre execute, importe ni edite.**

Ce repertoire conserve sur disque les scripts d'audit et de debogage de premiere generation qui se trouvaient a la racine du depot avant leur remplacement par la suite d'audit officielle sous `t/` (`t/test_form_names.py`, `t/test_flask_param_mapping.py`, `t/test_param_mapping.py`).

Date du deplacement vers `_attic/` : **2026-10-26**

## Tableau de tracabilite

| Fichier | Date d'origine | Lignes | Role initial | Commit d'origine (`LAVA_Virus-Interface`) | Remplace par |
| :--- | :--- | ---: | :--- | :--- | :--- |
| `test_param_mapping.py` | 2026-07-28 | 88 | Verification de premier niveau entre `common_params`/`loop_only_params`/`stem_only_params` de `lava_flask_app.py` et `GetOptions` des scripts `.pl` (avec chemin code en dur vers `../lava-dna-public`) | `f09c02e` | `t/test_flask_param_mapping.py` (maillon 2, commit `d7b24cc` dans `lava-dna-portable`) et `t/test_param_mapping.py` (maillon 3, commit `dfc0049`) |
| `test_flask_filter.py` | 2026-07-28 | 34 | Script one-shot de debogage manuel affichant la construction de la ligne de commande CLI Flask vers Perl sur un dictionnaire de 4 parametres sans assertion | `aab9613` | `t/test_flask_param_mapping.py` (commit `d7b24cc` dans `lava-dna-portable`) |
| `test_loop_params.py` | 2026-07-28 | 52 | Brouillon anterieur a `test_param_mapping.py` (88 lignes), limite au script `lava_loop_primer.pl` et pointant vers `../lava-dna-public` sans `sys.exit(1)` | `aab9613` | `t/test_flask_param_mapping.py` (commit `d7b24cc` dans `lava-dna-portable`) |
